import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'tool_usage_record.dart';

/// Store for managing tool usage history
/// Uses atomic file operations for persistence, similar to AchievementsStore
class ToolUsageStore extends ChangeNotifier {
  static const int _maxRecords = 100;
  static ToolUsageStore? _instance;
  
  List<ToolUsageRecord> _usageHistory = [];
  String? _filePath;
  bool _initialized = false;

  /// Singleton instance
  static ToolUsageStore get instance {
    _instance ??= ToolUsageStore._();
    return _instance!;
  }

  ToolUsageStore._();

  /// For testing - reset the singleton
  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  /// Initialize the store with optional file path
  Future<void> init({String? filePath}) async {
    if (_initialized) return;
    
    _filePath = filePath ?? await _getDefaultFilePath();
    await _loadFromFile();
    _initialized = true;
  }

  /// Get default file path in app data directory
  Future<String> _getDefaultFilePath() async {
    // Use same approach as other stores - local app data
    const fileName = 'tool_usage_history.json';
    
    // For now, use current directory (same as achievements)
    // In production, this would use proper app data directory
    return fileName;
  }

  /// Load usage history from file
  Future<void> _loadFromFile() async {
    if (_filePath == null) return;
    
    try {
      final file = File(_filePath!);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final data = jsonDecode(jsonString) as Map<String, dynamic>;
        
        final recordsList = (data['usageHistory'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _usageHistory = recordsList
            .map((json) => ToolUsageRecord.fromJson(json))
            .toList();
        
        // Ensure records are sorted by timestamp (newest first)
        _usageHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Trim to max records if needed
        if (_usageHistory.length > _maxRecords) {
          _usageHistory = _usageHistory.take(_maxRecords).toList();
        }
      }
    } catch (e) {
      // Graceful fallback on any error
      _usageHistory = [];
    }
  }

  /// Save usage history to file atomically
  Future<void> _saveToFile() async {
    if (_filePath == null) return;
    
    try {
      final data = {
        'usageHistory': _usageHistory.map((record) => record.toJson()).toList(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      final jsonString = jsonEncode(data);
      
      // Atomic write using temp file
      final tempFile = File('${_filePath!}.tmp');
      await tempFile.writeAsString(jsonString);
      await tempFile.rename(_filePath!);
    } catch (e) {
      // Silent failure - don't crash app if file operations fail
    }
  }

  /// Add a usage record
  Future<void> addUsageRecord(ToolUsageRecord record) async {
    _usageHistory.insert(0, record); // Add to front (most recent first)
    
    // Trim to max records
    if (_usageHistory.length > _maxRecords) {
      _usageHistory = _usageHistory.take(_maxRecords).toList();
    }
    
    await _saveToFile();
    notifyListeners();
  }

  /// Record usage of a tool with current timestamp
  Future<void> recordUsage(String toolId) async {
    final record = ToolUsageRecord.now(toolId);
    await addUsageRecord(record);
  }

  /// Get recent usage records (limited count, newest first)
  List<ToolUsageRecord> getRecentUsage(int limit) {
    return _usageHistory.take(limit).toList();
  }

  /// Get recent unique tool IDs (most recent first, no duplicates)
  List<String> getRecentUniqueTools(int limit) {
    final seen = <String>{};
    final unique = <String>[];
    
    for (final record in _usageHistory) {
      if (!seen.contains(record.toolId)) {
        seen.add(record.toolId);
        unique.add(record.toolId);
        
        if (unique.length >= limit) break;
      }
    }
    
    return unique;
  }

  /// Get all usage history (newest first)
  List<ToolUsageRecord> getAllUsage() {
    return List.from(_usageHistory);
  }

  /// Get usage count for a specific tool
  int getUsageCount(String toolId) {
    return _usageHistory.where((record) => record.toolId == toolId).length;
  }

  /// Get last usage time for a specific tool
  DateTime? getLastUsageTime(String toolId) {
    for (final record in _usageHistory) {
      if (record.toolId == toolId) {
        return record.timestamp;
      }
    }
    return null;
  }

  /// Get total number of usage records
  int get totalUsageCount => _usageHistory.length;

  /// Check if there is any usage history
  bool get hasUsageHistory => _usageHistory.isNotEmpty;

  /// Clear all usage history
  Future<void> clearHistory() async {
    _usageHistory.clear();
    await _saveToFile();
    notifyListeners();
  }
}
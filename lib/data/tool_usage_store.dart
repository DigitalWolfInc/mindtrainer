import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../settings/diagnostics.dart';

/// Model for tool usage record
class ToolUsage {
  final String toolId;
  final DateTime ts;

  const ToolUsage({
    required this.toolId,
    required this.ts,
  });

  factory ToolUsage.fromJson(Map<String, dynamic> json) {
    return ToolUsage(
      toolId: json['toolId'] as String,
      ts: DateTime.parse(json['tsIsoString'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toolId': toolId,
      'tsIsoString': ts.toIso8601String(),
    };
  }

  factory ToolUsage.now(String toolId) {
    return ToolUsage(
      toolId: toolId,
      ts: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolUsage &&
        other.toolId == toolId &&
        other.ts == ts;
  }

  @override
  int get hashCode => Object.hash(toolId, ts);

  @override
  String toString() => 'ToolUsage(toolId: $toolId, ts: $ts)';
}

/// Store for tool usage history - persistent JSON list capped at 100 entries
class ToolUsageStore {
  static ToolUsageStore? _instance;
  
  List<ToolUsage> _usageHistory = [];
  bool _initialized = false;

  ToolUsageStore._();

  static ToolUsageStore get instance {
    _instance ??= ToolUsageStore._();
    return _instance!;
  }

  /// For testing - reset the singleton
  static void resetInstance() {
    _instance = null;
  }

  /// Load usage history from persistent storage
  Future<void> load() async {
    if (_initialized) return;
    
    final data = await _readJsonSafe();
    if (data != null) {
      try {
        final List<dynamic> jsonList = data as List<dynamic>;
        _usageHistory = jsonList
            .cast<Map<String, dynamic>>()
            .map((json) => ToolUsage.fromJson(json))
            .toList();
        
        // Ensure sorted by timestamp (newest first)
        _usageHistory.sort((a, b) => b.ts.compareTo(a.ts));
        
        // Cap at 100 entries
        if (_usageHistory.length > 100) {
          _usageHistory = _usageHistory.take(100).toList();
        }
      } catch (e) {
        // Corrupted JSON - recover with empty list and log
        Diag.d('ToolUsageStore', 'load() - corrupted JSON, recovering with empty list: $e');
        _usageHistory = [];
      }
    } else {
      _usageHistory = [];
    }
    
    _initialized = true;
  }

  /// Record new tool usage
  Future<void> record(String toolId) async {
    if (toolId.isEmpty) return;
    
    final usage = ToolUsage.now(toolId);
    _usageHistory.insert(0, usage); // Add to front (newest first)
    
    // Cap at 100 entries
    if (_usageHistory.length > 100) {
      _usageHistory = _usageHistory.take(100).toList();
    }
    
    await _writeJsonAtomic(_usageHistory.map((u) => u.toJson()).toList());
  }

  /// Get recent usage entries
  List<ToolUsage> recent({int limit = 100}) {
    final actualLimit = limit > 100 ? 100 : limit;
    return _usageHistory.take(actualLimit).toList();
  }

  // Private methods

  Future<String> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/tool_usage.json';
  }

  Future<dynamic> _readJsonSafe() async {
    try {
      final file = File(await _path());
      if (!await file.exists()) return null;
      
      final content = await file.readAsString();
      if (content.trim().isEmpty) return null;
      
      return jsonDecode(content);
    } catch (e) {
      // Ignore any read errors - start fresh
      return null;
    }
  }

  Future<void> _writeJsonAtomic(List<Map<String, dynamic>> data) async {
    final path = await _path();
    final file = File(path);
    final tempFile = File('$path.tmp');

    try {
      // Ensure parent directory exists
      await file.parent.create(recursive: true);
      
      // Write to temp file
      final content = jsonEncode(data);
      await tempFile.writeAsString(content);
      
      // Atomic rename
      await tempFile.rename(path);
    } catch (e) {
      // Clean up temp file if it exists
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {
          // Ignore cleanup errors
        }
      }
      // Re-throw the original error
      rethrow;
    }
  }
}
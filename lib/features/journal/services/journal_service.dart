import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/journal_entry.dart';
import '../../../support/logger.dart';

/// Service for managing journal entries with offline-first storage
class JournalService extends ChangeNotifier {
  static JournalService? _instance;
  static JournalService get instance => _instance ??= JournalService._();
  
  JournalService._();
  
  final List<JournalEntry> _entries = [];
  bool _isLoaded = false;
  
  static const String _entriesKey = 'mt_journal_entries_v1';
  static const String _journalDirName = 'journal';
  
  /// Get all entries (most recent first)
  List<JournalEntry> get entries => List.unmodifiable(_entries);
  
  /// Check if entries are loaded
  bool get isLoaded => _isLoaded;
  
  /// Initialize service and load existing entries
  Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      await _loadEntries();
      _isLoaded = true;
      Log.debug('JournalService initialized with ${_entries.length} entries');
    } catch (e) {
      Log.debug('Failed to initialize JournalService: $e');
      _isLoaded = true; // Continue with empty state
    }
  }
  
  /// Add new journal entry
  Future<void> addEntry(JournalEntry entry) async {
    try {
      _entries.insert(0, entry); // Most recent first
      await _saveEntries();
      notifyListeners();
      Log.debug('Added journal entry: ${entry.id}');
    } catch (e) {
      _entries.removeAt(0); // Rollback on failure
      Log.debug('Failed to add journal entry: $e');
      rethrow;
    }
  }
  
  /// Delete journal entry
  Future<void> deleteEntry(String entryId) async {
    final index = _entries.indexWhere((entry) => entry.id == entryId);
    if (index == -1) return;
    
    final entry = _entries[index];
    _entries.removeAt(index);
    
    try {
      // Clean up media file if exists
      if (entry.mediaPath != null) {
        await _deleteMediaFile(entry.mediaPath!);
      }
      
      await _saveEntries();
      notifyListeners();
      Log.debug('Deleted journal entry: $entryId');
    } catch (e) {
      _entries.insert(index, entry); // Rollback on failure
      Log.debug('Failed to delete journal entry: $e');
      rethrow;
    }
  }
  
  /// Save media file and return path
  Future<String> saveMediaFile(List<int> data, String extension) async {
    final dir = await _getJournalDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'media_${timestamp}.$extension';
    final file = io.File('${dir.path}/$filename');
    
    await file.writeAsBytes(data);
    return file.path;
  }
  
  /// Load entries from storage
  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final entriesJson = prefs.getStringList(_entriesKey) ?? [];
    
    _entries.clear();
    for (final entryJson in entriesJson) {
      try {
        final entry = JournalEntry.fromJson(jsonDecode(entryJson));
        _entries.add(entry);
      } catch (e) {
        Log.debug('Failed to parse journal entry: $e');
        // Skip corrupted entries but continue loading others
      }
    }
    
    // Sort by timestamp (most recent first)
    _entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  /// Save entries to storage
  Future<void> _saveEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entriesJson = _entries
          .map((entry) => jsonEncode(entry.toJson()))
          .toList();
      
      await prefs.setStringList(_entriesKey, entriesJson);
    } catch (e) {
      Log.debug('Failed to save journal entries: $e');
      rethrow;
    }
  }
  
  /// Get journal directory for media files
  Future<io.Directory> _getJournalDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final journalDir = io.Directory('${appDir.path}/$_journalDirName');
    
    if (!await journalDir.exists()) {
      await journalDir.create(recursive: true);
    }
    
    return journalDir;
  }
  
  /// Delete media file
  Future<void> _deleteMediaFile(String path) async {
    try {
      final file = io.File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      Log.debug('Failed to delete media file: $e');
      // Non-critical failure, don't propagate
    }
  }
  
  /// Clear all entries (for testing/reset)
  Future<void> clearAll() async {
    // Delete all media files
    for (final entry in _entries) {
      if (entry.mediaPath != null) {
        await _deleteMediaFile(entry.mediaPath!);
      }
    }
    
    _entries.clear();
    await _saveEntries();
    notifyListeners();
    Log.debug('Cleared all journal entries');
  }
  
  /// Reset instance for testing
  static void resetForTesting() {
    _instance = null;
  }
}
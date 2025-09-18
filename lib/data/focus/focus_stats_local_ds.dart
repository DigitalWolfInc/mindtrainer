import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/focus/focus_stats.dart';
import '../../support/logger.dart';

/// Private data source for focus stats using SharedPreferences
/// Implements corruption-resistant storage with additive keys
abstract class FocusStatsLocalDataSource {
  Future<FocusStats> read();
  Future<void> write(FocusStats stats);
  Future<void> clear();
}

class _FocusStatsLocalDataSourceImpl implements FocusStatsLocalDataSource {
  // Additive SharedPreferences keys (migration-free)
  static const String _keyTotalMinutes = 'mt_focus_total_minutes_v1';
  static const String _keySessionCount = 'mt_focus_session_count_v1';
  static const String _keySchemaVersion = 'mt_focus_schema_version';
  static const int _schemaVersion = 1;
  
  @override
  Future<FocusStats> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Ensure schema version is set
      await _ensureSchemaVersion(prefs);
      
      final totalMinutes = _readIntWithRepair(prefs, _keyTotalMinutes, 'totalMinutes');
      final sessionCount = _readIntWithRepair(prefs, _keySessionCount, 'sessionCount');
      
      return FocusStats(
        totalMinutes: totalMinutes,
        sessionCount: sessionCount,
      );
    } catch (e) {
      Log.debug('FocusStats read error: $e, returning zero state');
      return FocusStats.zero;
    }
  }
  
  @override
  Future<void> write(FocusStats stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _ensureSchemaVersion(prefs);
      
      // Validate input before writing
      final safeTotal = _clampToSafe(stats.totalMinutes);
      final safeCount = _clampToSafe(stats.sessionCount);
      
      await prefs.setInt(_keyTotalMinutes, safeTotal);
      await prefs.setInt(_keySessionCount, safeCount);
    } catch (e) {
      Log.debug('FocusStats write error: $e');
      // Don't throw - allow app to continue with stale data
    }
  }
  
  @override
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyTotalMinutes);
      await prefs.remove(_keySessionCount);
      await prefs.remove(_keySchemaVersion);
    } catch (e) {
      Log.debug('FocusStats clear error: $e');
    }
  }
  
  /// Read integer with corruption repair
  int _readIntWithRepair(SharedPreferences prefs, String key, String fieldName) {
    try {
      final value = prefs.getInt(key);
      if (value == null) return 0; // Missing key = zero
      
      if (value < 0 || value > 1000000) { // Sanity bounds
        Log.debug('FocusStats corruption detected in $fieldName: $value, repairing to 0');
        _repairField(prefs, key, fieldName);
        return 0;
      }
      
      return value;
    } catch (e) {
      Log.debug('FocusStats read error for $fieldName: $e, using 0');
      _repairField(prefs, key, fieldName);
      return 0;
    }
  }
  
  /// Repair corrupted field by resetting to 0
  void _repairField(SharedPreferences prefs, String key, String fieldName) {
    try {
      prefs.setInt(key, 0);
    } catch (e) {
      Log.debug('FocusStats repair failed for $fieldName: $e');
    }
  }
  
  /// Clamp value to safe range
  int _clampToSafe(int value) {
    if (value < 0) return 0;
    if (value > 1000000) return 1000000; // Reasonable upper bound
    return value;
  }
  
  /// Ensure schema version is set
  Future<void> _ensureSchemaVersion(SharedPreferences prefs) async {
    final currentVersion = prefs.getInt(_keySchemaVersion);
    if (currentVersion != _schemaVersion) {
      await prefs.setInt(_keySchemaVersion, _schemaVersion);
    }
  }
}

/// Factory for data source instance
FocusStatsLocalDataSource createFocusStatsLocalDataSource() {
  return _FocusStatsLocalDataSourceImpl();
}
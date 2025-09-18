import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../support/logger.dart';

/// Focus timer preferences with persistence
class FocusTimerPrefs {
  static FocusTimerPrefs? _instance;
  static FocusTimerPrefs get instance => _instance ??= FocusTimerPrefs._();
  
  FocusTimerPrefs._();
  
  static const String _lastDurationKey = 'mt_focus_last_duration_sec_v1';
  static const int _defaultDurationSeconds = 1500; // 25 minutes
  static const int _minimumDurationSeconds = 60; // 1 minute
  
  Duration? _cachedLastDuration;
  
  /// Get last used duration
  Future<Duration> getLastDuration() async {
    if (_cachedLastDuration != null) {
      return _cachedLastDuration!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final seconds = prefs.getInt(_lastDurationKey) ?? _defaultDurationSeconds;
      
      // Ensure minimum duration
      final validSeconds = seconds < _minimumDurationSeconds ? _defaultDurationSeconds : seconds;
      
      _cachedLastDuration = Duration(seconds: validSeconds);
      return _cachedLastDuration!;
    } catch (e) {
      Log.debug('Failed to load last duration, using default: $e');
      _cachedLastDuration = Duration(seconds: _defaultDurationSeconds);
      return _cachedLastDuration!;
    }
  }
  
  /// Save last used duration
  Future<void> setLastDuration(Duration duration) async {
    // Enforce minimum duration
    final seconds = duration.inSeconds < _minimumDurationSeconds 
        ? _minimumDurationSeconds 
        : duration.inSeconds;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastDurationKey, seconds);
      _cachedLastDuration = Duration(seconds: seconds);
      Log.debug('Saved last duration: ${seconds}s');
    } catch (e) {
      Log.debug('Failed to save last duration: $e');
    }
  }
  
  /// Get predefined duration options
  static List<Duration> get standardDurations => [
    const Duration(minutes: 5),
    const Duration(minutes: 10),
    const Duration(minutes: 20),
    const Duration(minutes: 25),
  ];
  
  /// Check if duration is valid (meets minimum)
  static bool isValidDuration(Duration duration) {
    return duration.inSeconds >= _minimumDurationSeconds;
  }
  
  /// Get default duration
  static Duration get defaultDuration => Duration(seconds: _defaultDurationSeconds);
  
  /// Get minimum duration
  static Duration get minimumDuration => Duration(seconds: _minimumDurationSeconds);
  
  /// Clear cached value (for testing)
  void clearCache() {
    _cachedLastDuration = null;
  }
  
  /// Reset for testing
  static void resetForTesting() {
    _instance = null;
  }
}
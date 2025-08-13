import 'package:shared_preferences/shared_preferences.dart';

/// Manages preferences for focus timer duration settings
class FocusTimerPrefs {
  static const String _lastDurationKey = 'focus_timer_last_duration_minutes';
  static const int _defaultDurationMinutes = 25;
  
  static FocusTimerPrefs? _instance;
  
  static FocusTimerPrefs get instance {
    _instance ??= FocusTimerPrefs();
    return _instance!;
  }
  
  /// Gets the last used session duration, or default if none saved
  Future<Duration> getLastDuration() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_lastDurationKey) ?? _defaultDurationMinutes;
    return Duration(minutes: minutes);
  }
  
  /// Saves the duration for next session use
  Future<void> setLastDuration(Duration duration) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastDurationKey, duration.inMinutes);
  }
}
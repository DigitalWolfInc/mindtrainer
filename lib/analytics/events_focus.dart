/// Privacy-respecting analytics events for focus features
/// Only emitted when analytics is globally enabled
class FocusAnalyticsEvents {
  /// User viewed focus stats in the UI
  static Map<String, dynamic> focusStatsViewed({required String surface}) => {
    'event': 'focus_stats_viewed',
    'surface': surface,
  };
  
  /// Focus session was recorded in stats
  /// Note: Only sessions >= 1 minute are recorded
  static Map<String, dynamic> focusSessionRecorded({required int minutes}) => {
    'event': 'focus_session_recorded',
    'minutes': minutes,
  };
  
  /// Focus stats data was repaired due to corruption (debug builds only)
  static Map<String, dynamic> focusStatsRepaired({required String field}) => {
    'event': 'focus_stats_repaired',
    'field': field,
  };
}
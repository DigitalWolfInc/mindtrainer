class AppSettings {
  static const String version = '1.0.0';
  static const String privacyStatement = 'All your data stays on your device and never leaves without your permission.';
  static const String offlineNotice = 'This app works completely offline - no internet connection required.';
  
  // Privacy-first settings
  static const bool analyticsEnabled = false;
  static const bool crashReportingEnabled = false;
  static const bool networkRequestsEnabled = false;
  
  // Local storage keys
  static const String keyUserPreferences = 'user_preferences';
  static const String keyThemeMode = 'theme_mode';
  static const String keyNotificationsEnabled = 'notifications_enabled';
  static const String keyWeeklyGoalMinutes = 'weekly_goal_minutes';
  
  // Focus session defaults
  static const int defaultWeeklyGoalMinutes = 300;
}
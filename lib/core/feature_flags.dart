/// Feature flag system for MindTrainer
/// Controls rollout of new features
class FeatureFlags {
  static const bool _defaultDebugValue = true;
  static const bool _defaultReleaseValue = false;
  
  /// Default based on build mode
  static bool get _defaultValue => _defaultDebugValue;
  
  /// Focus Stats Module v1
  /// Enables focus session statistics tracking and display
  static const bool ff_focus_stats_v1 = bool.fromEnvironment('ff_focus_stats_v1', defaultValue: _defaultReleaseValue);
  
  /// 6-Tab Navigation Shell
  static const bool ff_nav_tabs6 = bool.fromEnvironment('FF_NAV_TABS6', defaultValue: _defaultDebugValue);
  
  /// Block Grid Layout v1
  static const bool ff_blocks_grid_v1 = bool.fromEnvironment('FF_BLOCKS_GRID_V1', defaultValue: _defaultDebugValue);
  
  /// Passkey Authentication
  static const bool ff_auth_passkey = bool.fromEnvironment('FF_AUTH_PASSKEY', defaultValue: _defaultDebugValue);
  
  /// Account Screen
  static const bool ff_account_screen = bool.fromEnvironment('FF_ACCOUNT_SCREEN', defaultValue: _defaultDebugValue);
  
  /// Home Cards for Journal and Coach
  static const bool ff_home_cards_journal_coach = bool.fromEnvironment('FF_HOME_CARDS', defaultValue: _defaultDebugValue);
  
  /// Show Focus card on Today screen
  static const bool ff_home_show_focus_card = bool.fromEnvironment('FF_HOME_FOCUS_CARD', defaultValue: _defaultReleaseValue);
  
  /// Guest Passkey support
  static const bool ff_auth_guest_pass = bool.fromEnvironment('FF_AUTH_GUEST_PASS', defaultValue: _defaultDebugValue);

  /// Email registration support 
  static const bool ff_auth_email_register = bool.fromEnvironment('FF_AUTH_EMAIL_REGISTER', defaultValue: _defaultDebugValue);

  /// Forgot password flow
  static const bool ff_auth_forgot_pw = bool.fromEnvironment('FF_AUTH_FORGOT_PW', defaultValue: _defaultDebugValue);

  /// Profile avatar support
  static const bool ff_profile_avatar = bool.fromEnvironment('FF_PROFILE_AVATAR', defaultValue: _defaultDebugValue);

  /// Journal Voice and Photo support
  static const bool ff_journal_voice_photo = bool.fromEnvironment('ff_journal_voice_photo', defaultValue: _defaultDebugValue);
  
  /// Coach Entry Rules (AOY6 fallback)
  static const bool ff_coach_entry_rules = bool.fromEnvironment('ff_coach_entry_rules', defaultValue: _defaultDebugValue);
  
  /// Core Toolbelt v1 (minimum 6 tools)
  static const bool ff_core_toolbelt_v1_min6 = bool.fromEnvironment('ff_core_toolbelt_v1_min6', defaultValue: _defaultDebugValue);
  
  /// Focus Timer Chips v1
  static const bool ff_focus_timer_chips_v1 = bool.fromEnvironment('ff_focus_timer_chips_v1', defaultValue: _defaultDebugValue);
  
  /// PRO Soft Lock Preview
  static const bool ff_pro_soft_lock_preview = bool.fromEnvironment('ff_pro_soft_lock_preview', defaultValue: _defaultDebugValue);
  
  // MTDS Design System v1 (OFF by default for release safety)
  /// MTDS Midnight Calm Theme
  static const bool ff_mtds_theme_midnight_calm = bool.fromEnvironment('ff_mtds_theme_midnight_calm', defaultValue: _defaultReleaseValue);
  
  /// MTDS Shared Components
  static const bool ff_mtds_components_v1 = bool.fromEnvironment('ff_mtds_components_v1', defaultValue: _defaultReleaseValue);
  
  /// MTDS Primary Screen Restyling
  static const bool ff_mtds_restyle_primary_screens = bool.fromEnvironment('ff_mtds_restyle_primary_screens', defaultValue: _defaultDebugValue);
  
  /// MTDS Debug Showcase
  static const bool ff_mtds_showcase_debug = bool.fromEnvironment('ff_mtds_showcase_debug', defaultValue: _defaultReleaseValue);
  
  /// Convenience getters
  static bool get focusStatsEnabled => ff_focus_stats_v1;
  static bool get navTabs6Enabled => ff_nav_tabs6;
  static bool get blocksGridEnabled => ff_blocks_grid_v1;
  static bool get authPasskeyEnabled => ff_auth_passkey;
  static bool get accountScreenEnabled => ff_account_screen;
  static bool get homeCardsEnabled => ff_home_cards_journal_coach;
  static bool get homeFocusCardEnabled => ff_home_show_focus_card;
  static bool get journalVoicePhotoEnabled => ff_journal_voice_photo;
  static bool get coachRulesEnabled => ff_coach_entry_rules;
  static bool get coreToolbeltEnabled => ff_core_toolbelt_v1_min6;
  static bool get focusTimerChipsEnabled => ff_focus_timer_chips_v1;
  static bool get proSoftLockEnabled => ff_pro_soft_lock_preview;
  
  // MTDS convenience getters
  static bool get mtdsThemeEnabled => ff_mtds_theme_midnight_calm;
  static bool get mtdsComponentsEnabled => ff_mtds_components_v1;
  static bool get mtdsRestyleEnabled => ff_mtds_restyle_primary_screens;
  static bool get mtdsShowcaseEnabled => ff_mtds_showcase_debug;
}
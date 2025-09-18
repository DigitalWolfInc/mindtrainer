/// Pro Feature Gates for MindTrainer
/// 
/// Provides fine-grained feature access control based on Pro subscription status.
/// Each gate method returns true if the feature is available to the current user.

import 'pro_manager.dart';
import '../coach/conversational_coach.dart';
import '../../payments/entitlement_resolver.dart';

/// Specific feature gates for MindTrainer Pro functionality
class MindTrainerProGates {
  final bool Function() _isProActive;
  
  const MindTrainerProGates(this._isProActive);
  
  /// Create gates from any Pro status provider
  factory MindTrainerProGates.fromProManager(ProManager manager) {
    return MindTrainerProGates(() => manager.isProActive);
  }
  
  /// Create gates from Play Billing manager  
  factory MindTrainerProGates.fromPlayBillingManager(dynamic manager) {
    return MindTrainerProGates(() => manager.isProActive);
  }
  
  /// Create gates with explicit status function
  factory MindTrainerProGates.fromStatusCheck(bool Function() isActive) {
    return MindTrainerProGates(isActive);
  }
  
  /// Create gates from our new EntitlementResolver (preferred approach)
  factory MindTrainerProGates.fromEntitlementResolver([EntitlementResolver? resolver]) {
    final actualResolver = resolver ?? EntitlementResolver.instance;
    return MindTrainerProGates(() => actualResolver.isPro);
  }
  
  /// Whether Pro features are currently active
  bool get isProActive => _isProActive();
  
  // === SESSION LIMITS ===
  
  /// Whether user can start unlimited daily focus sessions
  /// Free: 5 sessions per day, Pro: unlimited
  bool get unlimitedDailySessions => isProActive;
  
  /// Get daily session limit for current user
  int get dailySessionLimit => isProActive ? -1 : 5; // -1 = unlimited
  
  /// Check if user can start another session today
  bool canStartSession(int todaysSessionCount) {
    if (isProActive) return true;
    return todaysSessionCount < 5;
  }
  
  // === COACHING ACCESS ===
  
  /// Whether user can access extended ConversationalCoach phases
  /// Free: stabilize + open only, Pro: full reflect + reframe + plan + close
  bool get extendedCoachingPhases => isProActive;
  
  /// Whether specific coaching phase is available
  bool isCoachPhaseAvailable(dynamic phase) {
    // Convert phase to string for comparison
    final phaseName = phase.toString().split('.').last;
    
    // Free users get basic phases
    if (phaseName == 'stabilize' || phaseName == 'open') {
      return true;
    }
    // Pro users get advanced phases
    return isProActive;
  }
  
  // === ANALYTICS & INSIGHTS ===
  
  /// Whether user can access advanced analytics dashboard
  /// Free: basic stats, Pro: correlations, tag associations, keyword uplift
  bool get advancedAnalytics => isProActive;
  
  /// Whether user can view mood-focus correlations
  bool get moodFocusCorrelations => isProActive;
  
  /// Whether user can see tag performance associations  
  bool get tagAssociations => isProActive;
  
  /// Whether user can analyze keyword uplift in notes
  bool get keywordUplift => isProActive;
  
  /// Whether user can access extended insights history
  /// Free: last 30 days, Pro: unlimited historical data
  bool get extendedInsightsHistory => isProActive;
  
  /// Get insights history window for current user (in days)
  int get insightsHistoryDays => isProActive ? -1 : 30; // -1 = unlimited
  
  // === DATA MANAGEMENT ===
  
  /// Whether user can export session data to CSV/JSON
  bool get dataExport => isProActive;
  
  /// Whether user can import session data from external sources
  bool get dataImport => isProActive;
  
  /// Whether user can access data portability features
  bool get dataPortability => dataExport && dataImport;
  
  // === CUSTOM GOALS ===
  
  /// Whether user can create custom session goals beyond weekly target
  bool get customGoals => isProActive;
  
  /// Whether user can set multiple concurrent goals
  bool get multipleGoals => isProActive;
  
  /// Whether user can access advanced goal tracking features
  bool get advancedGoalTracking => isProActive;
  
  // === UI ENHANCEMENTS ===
  
  /// Whether user has ad-free experience
  bool get adFree => isProActive;
  
  /// Whether user can access premium themes and customization
  bool get premiumThemes => isProActive;
  
  /// Whether user can access priority customer support
  bool get prioritySupport => isProActive;
  
  // === ADDITIONAL PRO FEATURES ===
  
  /// Whether user can access AI-powered session scheduling optimization
  bool get smartSessionScheduling => isProActive;
  
  /// Whether user can record voice notes and get transcription insights
  bool get voiceJournalInsights => isProActive;
  
  /// Whether user can participate in Pro community challenges
  bool get communityChallengePro => isProActive;
  
  /// Whether user can access expert-designed goal templates
  bool get advancedGoalTemplates => isProActive;
  
  /// Whether user can save contextual environment presets
  bool get environmentPresets => isProActive;
  
  /// Whether user can sync with external health/biometric data
  bool get biometricIntegration => isProActive;
  
  /// Whether user can generate shareable progress reports
  bool get progressSharingExport => isProActive;
  
  /// Whether user can access secure cloud backup and sync
  bool get cloudBackupSync => isProActive;

  // === FEATURE COLLECTIONS ===
  
  /// Get all currently available Pro features for this user
  List<ProFeature> get availableFeatures {
    if (!isProActive) return [];
    
    return [
      ProFeature.unlimitedSessions,
      ProFeature.extendedCoaching, 
      ProFeature.advancedAnalytics,
      ProFeature.dataExport,
      ProFeature.customGoals,
      ProFeature.adFree,
      ProFeature.premiumThemes,
      ProFeature.smartScheduling,
      ProFeature.voiceJournal,
      ProFeature.communityChallenge,
      ProFeature.expertGoalTemplates,
      ProFeature.environmentPresets,
      ProFeature.biometricSync,
      ProFeature.progressReports,
      ProFeature.cloudBackup,
    ];
  }
  
  /// Get features that are locked for current user
  List<ProFeature> get lockedFeatures {
    if (isProActive) return [];
    
    return [
      ProFeature.unlimitedSessions,
      ProFeature.extendedCoaching,
      ProFeature.advancedAnalytics, 
      ProFeature.dataExport,
      ProFeature.customGoals,
      ProFeature.adFree,
      ProFeature.premiumThemes,
      ProFeature.smartScheduling,
      ProFeature.voiceJournal,
      ProFeature.communityChallenge,
      ProFeature.expertGoalTemplates,
      ProFeature.environmentPresets,
      ProFeature.biometricSync,
      ProFeature.progressReports,
      ProFeature.cloudBackup,
    ];
  }
}


/// MindTrainer-specific Pro features
enum ProFeature {
  unlimitedSessions,
  extendedCoaching,
  advancedAnalytics,
  dataExport,
  customGoals,
  adFree,
  premiumThemes,
  smartScheduling,
  voiceJournal,
  communityChallenge,
  expertGoalTemplates,
  environmentPresets,
  biometricSync,
  progressReports,
  cloudBackup,
}

extension ProFeatureExtension on ProFeature {
  /// Human-readable feature name
  String get displayName {
    switch (this) {
      case ProFeature.unlimitedSessions:
        return 'Unlimited Daily Sessions';
      case ProFeature.extendedCoaching:
        return 'Extended AI Coaching';
      case ProFeature.advancedAnalytics:
        return 'Advanced Analytics';
      case ProFeature.dataExport:
        return 'Data Export/Import';
      case ProFeature.customGoals:
        return 'Custom Goals';
      case ProFeature.adFree:
        return 'Ad-Free Experience';
      case ProFeature.premiumThemes:
        return 'Premium Themes';
      case ProFeature.smartScheduling:
        return 'Smart Session Scheduling';
      case ProFeature.voiceJournal:
        return 'Voice Journal Insights';
      case ProFeature.communityChallenge:
        return 'Community Challenges';
      case ProFeature.expertGoalTemplates:
        return 'Expert Goal Templates';
      case ProFeature.environmentPresets:
        return 'Environment Presets';
      case ProFeature.biometricSync:
        return 'Biometric Integration';
      case ProFeature.progressReports:
        return 'Progress Reports';
      case ProFeature.cloudBackup:
        return 'Cloud Backup & Sync';
    }
  }
  
  /// Feature description for UI
  String get description {
    switch (this) {
      case ProFeature.unlimitedSessions:
        return 'No daily limit on focus sessions';
      case ProFeature.extendedCoaching:
        return 'Full coaching flow with reflection and reframing';
      case ProFeature.advancedAnalytics:
        return 'Mood correlations, tag associations, and trend analysis';
      case ProFeature.dataExport:
        return 'Export/import sessions to CSV and JSON';
      case ProFeature.customGoals:
        return 'Set personalized goals and track multiple targets';
      case ProFeature.adFree:
        return 'Remove all advertisements';
      case ProFeature.premiumThemes:
        return 'Exclusive themes and customization options';
      case ProFeature.smartScheduling:
        return 'AI suggests optimal meditation times based on your patterns';
      case ProFeature.voiceJournal:
        return 'Record voice reflections with automatic insights';
      case ProFeature.communityChallenge:
        return 'Join themed challenges with anonymous progress sharing';
      case ProFeature.expertGoalTemplates:
        return 'Professionally designed goal programs for specific outcomes';
      case ProFeature.environmentPresets:
        return 'Save custom focus environments for different contexts';
      case ProFeature.biometricSync:
        return 'Connect with health apps for comprehensive wellness insights';
      case ProFeature.progressReports:
        return 'Generate beautiful shareable progress certificates';
      case ProFeature.cloudBackup:
        return 'Encrypted backup and cross-device synchronization';
    }
  }
  
  /// Icon or emoji for UI display
  String get icon {
    switch (this) {
      case ProFeature.unlimitedSessions:
        return '∞';
      case ProFeature.extendedCoaching:
        return '🧠';
      case ProFeature.advancedAnalytics:
        return '📊';
      case ProFeature.dataExport:
        return '📁';
      case ProFeature.customGoals:
        return '🎯';
      case ProFeature.adFree:
        return '🚫';
      case ProFeature.premiumThemes:
        return '🎨';
      case ProFeature.smartScheduling:
        return '🤖';
      case ProFeature.voiceJournal:
        return '🎙️';
      case ProFeature.communityChallenge:
        return '👥';
      case ProFeature.expertGoalTemplates:
        return '📋';
      case ProFeature.environmentPresets:
        return '⚙️';
      case ProFeature.biometricSync:
        return '❤️';
      case ProFeature.progressReports:
        return '📜';
      case ProFeature.cloudBackup:
        return '☁️';
    }
  }
}
/// Pro Feature Gate Integration Examples
/// 
/// This file demonstrates how to integrate the Pro feature gates
/// throughout the MindTrainer app for seamless Pro feature management.

import 'pro_feature_gates.dart';
import 'play_billing_pro_manager.dart';
import '../limits/session_limits.dart';
import '../coach/coach_feature_gates.dart';
import '../insights/insights_feature_gates.dart';
import '../coach/conversational_coach.dart' as coach;

/// Example: Session Start Flow with Limits
class SessionStartExample {
  final MindTrainerProGates _gates;
  final SessionLimitEnforcer _limiter;
  
  SessionStartExample(this._gates) : _limiter = SessionLimitEnforcer(_gates);
  
  /// Check if user can start a new session and provide appropriate feedback
  ({bool canStart, String message, bool showUpgrade}) checkSessionStart(
    List<dynamic> existingSessions,
  ) {
    final limitResult = _limiter.checkWithSessions(existingSessions);
    
    if (limitResult.canStart) {
      final warning = _limiter.getLimitWarning(limitResult.currentCount);
      return (
        canStart: true,
        message: warning ?? limitResult.displayMessage,
        showUpgrade: warning != null,
      );
    } else {
      return (
        canStart: false,
        message: _limiter.getUpgradePrompt(),
        showUpgrade: true,
      );
    }
  }
}

/// Example: Coaching Flow with Phase Gates
class CoachingFlowExample {
  final CoachingFeatureGates _coachGates;
  
  CoachingFlowExample(MindTrainerProGates gates) : _coachGates = CoachingFeatureGates(gates);
  
  /// Get next available coaching phase or upgrade prompt
  ({coach.CoachPhase? nextPhase, String? upgradeMessage}) getNextPhase(
    List<coach.CoachPhase> completedPhases,
  ) {
    // Check if user has reached free limits
    if (_coachGates.hasReachedFreeLimit(completedPhases)) {
      return (
        nextPhase: null,
        upgradeMessage: _coachGates.getCoachingUpgradePrompt(),
      );
    }
    
    // Find next available phase
    final availablePhases = _coachGates.getAvailablePhases();
    for (final phase in availablePhases) {
      if (!completedPhases.contains(phase)) {
        return (nextPhase: phase, upgradeMessage: null);
      }
    }
    
    return (nextPhase: null, upgradeMessage: null);
  }
  
  /// Check if specific phase transition is allowed
  bool canTransitionTo(coach.CoachPhase targetPhase) {
    return _coachGates.canProgressToPhase(targetPhase);
  }
}

/// Example: Analytics Dashboard with Pro Features
class AnalyticsDashboardExample {
  final InsightsFeatureGates _insightsGates;
  
  AnalyticsDashboardExample(MindTrainerProGates gates) : _insightsGates = InsightsFeatureGates(gates);
  
  /// Get available insights sections for current user
  List<AnalyticsSection> getAvailableSections() {
    final sections = <AnalyticsSection>[
      AnalyticsSection(
        title: 'Basic Statistics',
        available: true,
        description: 'Session counts, averages, and streaks',
      ),
      AnalyticsSection(
        title: 'Recent Trends',
        available: true,
        description: 'Last 7 and 30 day performance',
      ),
    ];
    
    // Pro-only sections
    final correlationsResult = _insightsGates.checkMoodFocusCorrelations();
    sections.add(AnalyticsSection(
      title: 'Mood-Focus Correlations',
      available: correlationsResult.allowed,
      description: correlationsResult.allowed 
        ? 'Statistical analysis of mood vs focus performance'
        : correlationsResult.upgradeMessage!,
    ));
    
    final tagsResult = _insightsGates.checkTagAssociations();
    sections.add(AnalyticsSection(
      title: 'Tag Performance',
      available: tagsResult.allowed,
      description: tagsResult.allowed
        ? 'Which tags predict your best focus days'
        : tagsResult.upgradeMessage!,
    ));
    
    return sections;
  }
  
  /// Get filtered date range for insights queries
  ({DateTime from, DateTime to}) getInsightsDateRange(DateTime requestedFrom, DateTime requestedTo) {
    return _insightsGates.getFilteredDateRange(requestedFrom, requestedTo);
  }
}

/// Example: Feature Gate Setup and Initialization
class ProGatesSetupExample {
  /// Initialize Pro gates with Play Billing manager
  static MindTrainerProGates setupWithPlayBilling(PlayBillingProManager playBillingManager) {
    return MindTrainerProGates.fromPlayBillingManager(playBillingManager);
  }
  
  /// Initialize all feature gate controllers
  static ProGateControllers setupAllGates(MindTrainerProGates gates) {
    return ProGateControllers(
      main: gates,
      sessions: SessionLimitEnforcer(gates),
      coaching: CoachingFeatureGates(gates),
      insights: InsightsFeatureGates(gates),
    );
  }
  
  /// Example: UI state based on Pro status
  static ProUIState getUIState(MindTrainerProGates gates) {
    return ProUIState(
      isProActive: gates.isProActive,
      dailySessionsRemaining: gates.isProActive ? null : (5 - 0), // Would use actual count
      availableProFeatures: gates.availableFeatures,
      lockedProFeatures: gates.lockedFeatures,
      upgradePrompt: gates.isProActive ? null : _getMainUpgradePrompt(gates),
    );
  }
  
  static String _getMainUpgradePrompt(MindTrainerProGates gates) {
    return 'Unlock the full MindTrainer experience with Pro! '
           'Get unlimited sessions, advanced coaching, detailed insights, '
           'and data export capabilities.';
  }
}

// Supporting data classes

class AnalyticsSection {
  final String title;
  final bool available;
  final String description;
  
  const AnalyticsSection({
    required this.title,
    required this.available,
    required this.description,
  });
}

class ProGateControllers {
  final MindTrainerProGates main;
  final SessionLimitEnforcer sessions;
  final CoachingFeatureGates coaching;
  final InsightsFeatureGates insights;
  
  const ProGateControllers({
    required this.main,
    required this.sessions,
    required this.coaching,
    required this.insights,
  });
}

class ProUIState {
  final bool isProActive;
  final int? dailySessionsRemaining; // null = unlimited
  final List<ProFeature> availableProFeatures;
  final List<ProFeature> lockedProFeatures;
  final String? upgradePrompt;
  
  const ProUIState({
    required this.isProActive,
    this.dailySessionsRemaining,
    required this.availableProFeatures,
    required this.lockedProFeatures,
    this.upgradePrompt,
  });
}
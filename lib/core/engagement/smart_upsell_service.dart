import '../analytics/conversion_analytics.dart';

/// Service for showing contextual upsell prompts at optimal moments
/// Uses behavioral triggers and timing optimization for maximum conversion
class SmartUpsellService {
  final ConversionAnalytics _analytics = ConversionAnalytics();
  static final SmartUpsellService _instance = SmartUpsellService._internal();
  
  factory SmartUpsellService() => _instance;
  SmartUpsellService._internal();

  /// Check if an upsell prompt should be shown based on current context
  UpsellPromptDecision shouldShowUpsellPrompt(UpsellTriggerContext context) {
    // Never interrupt user during active sessions
    if (context.isInActiveSession) {
      return UpsellPromptDecision.skip('user_in_active_session');
    }

    // Respect user's recent dismissal preferences
    if (context.hoursSinceLastPromptDismissal < 24) {
      return UpsellPromptDecision.skip('too_soon_after_dismissal');
    }

    // Don't be aggressive with new users
    if (context.daysSinceFirstUse < 3) {
      return UpsellPromptDecision.skip('user_too_new');
    }

    // Check for high-value moments
    final trigger = _identifyOptimalTrigger(context);
    if (trigger != null) {
      final prompt = _createContextualPrompt(trigger, context);
      
      _analytics.trackUpgradePromptShown(
        trigger.location, 
        trigger.type, 
        {
          'trigger_reason': trigger.reason,
          'user_session_count': context.totalSessions,
          'user_engagement_score': context.engagementScore,
        }
      );
      
      return UpsellPromptDecision.show(prompt);
    }

    return UpsellPromptDecision.skip('no_optimal_trigger_found');
  }

  /// Identify the best upsell trigger based on user behavior
  UpsellTrigger? _identifyOptimalTrigger(UpsellTriggerContext context) {
    // High engagement after good session
    if (context.lastSessionScore >= 8.0 && context.consecutiveGoodSessions >= 2) {
      return UpsellTrigger(
        type: UpsellTriggerType.postHighQualitySession,
        location: 'session_completion',
        reason: 'user_achieved_excellent_focus',
        priority: UpsellPriority.high,
      );
    }

    // User frequently uses analytics (shows data interest)
    if (context.analyticsViewsThisWeek >= 3) {
      return UpsellTrigger(
        type: UpsellTriggerType.analyticsEngagement,
        location: 'analytics_screen',
        reason: 'user_shows_data_interest',
        priority: UpsellPriority.high,
      );
    }

    // Consistent usage pattern (habit formation)
    if (context.currentStreak >= 7 && context.streakQuality == StreakQuality.high) {
      return UpsellTrigger(
        type: UpsellTriggerType.streakAchievement,
        location: 'home_screen',
        reason: 'user_formed_strong_habit',
        priority: UpsellPriority.high,
      );
    }

    // Goal achievement moment
    if (context.justCompletedWeeklyGoal && context.goalCompletionStreak >= 2) {
      return UpsellTrigger(
        type: UpsellTriggerType.goalCompletion,
        location: 'goal_completion',
        reason: 'user_consistently_meets_goals',
        priority: UpsellPriority.medium,
      );
    }

    // Discovery moment (user exploring features)
    if (context.featuresExploredThisSession >= 3) {
      return UpsellTrigger(
        type: UpsellTriggerType.featureExploration,
        location: 'feature_discovery',
        reason: 'user_actively_exploring',
        priority: UpsellPriority.medium,
      );
    }

    // Limitation hit (natural upsell moment)
    if (context.hitFeatureLimitThisSession) {
      return UpsellTrigger(
        type: UpsellTriggerType.featureLimit,
        location: 'feature_limit',
        reason: 'user_encountered_natural_limit',
        priority: UpsellPriority.high,
      );
    }

    // Comparison moment (seeing locked features)
    if (context.lockedFeatureInteractionsToday >= 2) {
      return UpsellTrigger(
        type: UpsellTriggerType.lockedFeatureInteraction,
        location: 'locked_feature',
        reason: 'user_repeatedly_interested_in_pro',
        priority: UpsellPriority.medium,
      );
    }

    return null; // No optimal trigger found
  }

  /// Create contextual prompt based on trigger
  UpsellPrompt _createContextualPrompt(UpsellTrigger trigger, UpsellTriggerContext context) {
    switch (trigger.type) {
      case UpsellTriggerType.postHighQualitySession:
        return UpsellPrompt(
          trigger: trigger,
          title: 'Amazing Focus Session! 🎯',
          message: 'You scored ${context.lastSessionScore.toStringAsFixed(1)}/10! See how your sessions compare and discover what drives your best performance with Pro analytics.',
          primaryAction: 'Unlock Insights',
          secondaryAction: 'Maybe Later',
          visualStyle: UpsellPromptStyle.celebratory,
          timing: UpsellTiming.immediate,
        );

      case UpsellTriggerType.analyticsEngagement:
        return UpsellPrompt(
          trigger: trigger,
          title: 'Love Data? You\'ll Love Pro! 📊',
          message: 'You check analytics often! Unlock mood correlations, tag insights, and keyword analysis to optimize your focus journey.',
          primaryAction: 'Get Pro Analytics',
          secondaryAction: 'Not Now',
          visualStyle: UpsellPromptStyle.dataFocused,
          timing: UpsellTiming.immediate,
        );

      case UpsellTriggerType.streakAchievement:
        return UpsellPrompt(
          trigger: trigger,
          title: '${context.currentStreak}-Day Streak! 🔥',
          message: 'Your consistency is incredible! Pro analytics can show you exactly what\'s driving your success and help maintain this momentum.',
          primaryAction: 'Optimize My Streak',
          secondaryAction: 'Keep Going Free',
          visualStyle: UpsellPromptStyle.achievement,
          timing: UpsellTiming.immediate,
        );

      case UpsellTriggerType.goalCompletion:
        return UpsellPrompt(
          trigger: trigger,
          title: 'Weekly Goal Crushed! 🎯',
          message: 'You\'re consistently hitting your targets! Pro insights can help you understand your patterns and set even better goals.',
          primaryAction: 'Level Up Goals',
          secondaryAction: 'Continue Free',
          visualStyle: UpsellPromptStyle.success,
          timing: UpsellTiming.immediate,
        );

      case UpsellTriggerType.featureExploration:
        return UpsellPrompt(
          trigger: trigger,
          title: 'Explorer Mindset! 🗺️',
          message: 'You love trying new features! Pro unlocks advanced analytics with mood correlations, tag performance, and keyword insights.',
          primaryAction: 'Explore Pro Features',
          secondaryAction: 'Stay Basic',
          visualStyle: UpsellPromptStyle.discovery,
          timing: UpsellTiming.immediate,
        );

      case UpsellTriggerType.featureLimit:
        return UpsellPrompt(
          trigger: trigger,
          title: 'You\'re Ready for More! ⚡',
          message: 'You\'ve hit your limit because you\'re actively using MindTrainer! Pro removes all limits and adds powerful analytics.',
          primaryAction: 'Remove Limits',
          secondaryAction: 'Stay Limited',
          visualStyle: UpsellPromptStyle.limitation,
          timing: UpsellTiming.immediate,
        );

      case UpsellTriggerType.lockedFeatureInteraction:
        return UpsellPrompt(
          trigger: trigger,
          title: 'Curious About Pro? 🌟',
          message: 'You keep exploring Pro features! Get unlimited access to advanced analytics that reveal your focus patterns and optimization opportunities.',
          primaryAction: 'Unlock Everything',
          secondaryAction: 'Browse More',
          visualStyle: UpsellPromptStyle.curiosity,
          timing: UpsellTiming.immediate,
        );
    }
  }

  /// Track user response to upsell prompt
  void trackUpsellResponse(UpsellPrompt prompt, UpsellResponse response) {
    _analytics.trackUpgradePromptInteraction(
      prompt.trigger.location,
      response.action,
      {
        'trigger_type': prompt.trigger.type.toString(),
        'trigger_reason': prompt.trigger.reason,
        'prompt_style': prompt.visualStyle.toString(),
        'response_time_seconds': response.responseTimeSeconds,
      },
    );

    if (response.action == 'dismissed' || response.action == 'maybe_later') {
      _analytics.trackFunnelDropOff(
        ConversionFunnelSteps.upgradePromptView,
        response.action == 'dismissed' ? DropOffReasons.userDismissed : DropOffReasons.timingNotRight,
        {
          'trigger_context': prompt.trigger.reason,
          'user_engagement_level': response.userEngagementContext,
        },
      );
    } else if (response.action == 'upgrade_tapped') {
      _analytics.trackFunnelStep(
        ConversionFunnelSteps.billingFlowStart,
        ConversionFunnelSteps.upgradePromptView,
        {
          'trigger_effectiveness': 'high', // User proceeded to billing
          'optimal_timing': 'confirmed',
        },
      );
    }
  }

  /// Get upsell prompt statistics for optimization
  Map<String, dynamic> getUpsellStatistics() {
    return {
      'prompts_shown_today': 'tracked_locally',
      'conversion_rate_by_trigger': 'calculated_from_logs',
      'optimal_timing_analysis': 'based_on_response_patterns',
      'user_segment_performance': 'engagement_vs_conversion',
    };
  }
}

/// Decision about whether to show an upsell prompt
class UpsellPromptDecision {
  final bool shouldShow;
  final String reason;
  final UpsellPrompt? prompt;

  UpsellPromptDecision.show(this.prompt) : shouldShow = true, reason = 'optimal_moment_detected';
  UpsellPromptDecision.skip(this.reason) : shouldShow = false, prompt = null;
}

/// Context for determining optimal upsell timing
class UpsellTriggerContext {
  final bool isInActiveSession;
  final int hoursSinceLastPromptDismissal;
  final int daysSinceFirstUse;
  final int totalSessions;
  final double engagementScore;
  final double lastSessionScore;
  final int consecutiveGoodSessions;
  final int analyticsViewsThisWeek;
  final int currentStreak;
  final StreakQuality streakQuality;
  final bool justCompletedWeeklyGoal;
  final int goalCompletionStreak;
  final int featuresExploredThisSession;
  final bool hitFeatureLimitThisSession;
  final int lockedFeatureInteractionsToday;

  UpsellTriggerContext({
    required this.isInActiveSession,
    required this.hoursSinceLastPromptDismissal,
    required this.daysSinceFirstUse,
    required this.totalSessions,
    required this.engagementScore,
    required this.lastSessionScore,
    required this.consecutiveGoodSessions,
    required this.analyticsViewsThisWeek,
    required this.currentStreak,
    required this.streakQuality,
    required this.justCompletedWeeklyGoal,
    required this.goalCompletionStreak,
    required this.featuresExploredThisSession,
    required this.hitFeatureLimitThisSession,
    required this.lockedFeatureInteractionsToday,
  });
}

/// Trigger that indicates optimal upsell timing
class UpsellTrigger {
  final UpsellTriggerType type;
  final String location;
  final String reason;
  final UpsellPriority priority;

  UpsellTrigger({
    required this.type,
    required this.location,
    required this.reason,
    required this.priority,
  });
}

/// Contextual upsell prompt
class UpsellPrompt {
  final UpsellTrigger trigger;
  final String title;
  final String message;
  final String primaryAction;
  final String secondaryAction;
  final UpsellPromptStyle visualStyle;
  final UpsellTiming timing;

  UpsellPrompt({
    required this.trigger,
    required this.title,
    required this.message,
    required this.primaryAction,
    required this.secondaryAction,
    required this.visualStyle,
    required this.timing,
  });
}

/// User response to upsell prompt
class UpsellResponse {
  final String action; // 'upgrade_tapped', 'maybe_later', 'dismissed'
  final int responseTimeSeconds;
  final String userEngagementContext;

  UpsellResponse({
    required this.action,
    required this.responseTimeSeconds,
    required this.userEngagementContext,
  });
}

enum UpsellTriggerType {
  postHighQualitySession,
  analyticsEngagement,
  streakAchievement,
  goalCompletion,
  featureExploration,
  featureLimit,
  lockedFeatureInteraction,
}

enum UpsellPriority {
  high,
  medium,
  low,
}

enum UpsellPromptStyle {
  celebratory,
  dataFocused,
  achievement,
  success,
  discovery,
  limitation,
  curiosity,
}

enum UpsellTiming {
  immediate,
  delayed,
  nextSession,
}

enum StreakQuality {
  high,    // Consistent high scores
  medium,  // Mixed scores but consistent usage
  low,     // Low scores but consistent usage
}
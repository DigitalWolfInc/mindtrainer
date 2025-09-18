import 'dart:convert';
import '../analytics/conversion_analytics.dart';

/// Service for generating contextual engagement cues to improve retention
/// Uses pure Dart logic with local data tracking for privacy compliance
class EngagementCueService {
  final ConversionAnalytics _analytics = ConversionAnalytics();
  static final EngagementCueService _instance = EngagementCueService._internal();
  
  factory EngagementCueService() => _instance;
  EngagementCueService._internal();

  /// Get engagement cues based on user activity patterns
  List<EngagementCue> getEngagementCues(UserActivityContext context) {
    final cues = <EngagementCue>[];
    
    // Check for streak opportunities
    if (context.daysSinceLastSession == 1 && context.currentStreak >= 3) {
      cues.add(_createStreakContinuationCue(context.currentStreak));
    }
    
    // Check for re-engagement after absence
    if (context.daysSinceLastSession > 2) {
      cues.add(_createReEngagementCue(context.daysSinceLastSession, context.hasProAccess));
    }
    
    // Check for Pro feature revisit opportunities
    if (context.hasProAccess && context.daysSinceProFeatureUse > 7) {
      cues.add(_createProFeatureReminderCue(context.unusedProFeatures));
    }
    
    // Check for goal completion opportunities
    if (context.sessionsThisWeek > 0 && context.weeklyGoal > 0) {
      final progress = context.sessionsThisWeek / context.weeklyGoal;
      if (progress >= 0.5 && progress < 1.0) {
        cues.add(_createGoalProgressCue(context.sessionsThisWeek, context.weeklyGoal));
      }
    }
    
    // Check for focus score improvement opportunities
    if (context.recentSessionsCount >= 3 && context.averageRecentFocusScore < context.personalBest * 0.8) {
      cues.add(_createFocusImprovementCue(context.averageRecentFocusScore, context.personalBest));
    }
    
    // Log engagement cue generation
    _analytics.trackEngagement('engagement_cues_generated', cues.length.toDouble(), {
      'user_type': context.hasProAccess ? 'pro' : 'free',
      'days_since_last_session': context.daysSinceLastSession,
      'current_streak': context.currentStreak,
      'cue_types': cues.map((c) => c.type.toString()).toList(),
    });
    
    return cues;
  }

  EngagementCue _createStreakContinuationCue(int currentStreak) {
    return EngagementCue(
      id: 'streak_continuation_${DateTime.now().millisecondsSinceEpoch}',
      type: EngagementCueType.streakContinuation,
      priority: EngagementPriority.high,
      title: 'Keep Your Streak Alive! 🔥',
      message: 'You\'re on a $currentStreak-day focus streak. One session today keeps it going!',
      actionText: 'Continue Streak',
      actionTarget: EngagementTarget.focusSession,
      expiryHours: 24,
      metadata: {'current_streak': currentStreak},
    );
  }

  EngagementCue _createReEngagementCue(int daysSinceLastSession, bool hasProAccess) {
    String message;
    String actionText;
    
    if (daysSinceLastSession <= 7) {
      message = 'We missed you! Your focus journey continues where you left off.';
      actionText = 'Resume Training';
    } else {
      message = 'Ready to refocus? Your mind training tools are waiting.';
      actionText = 'Start Fresh';
    }
    
    if (hasProAccess && daysSinceLastSession > 14) {
      message += ' Check out your Pro analytics to see your progress patterns.';
    }
    
    return EngagementCue(
      id: 'reengagement_${DateTime.now().millisecondsSinceEpoch}',
      type: EngagementCueType.reEngagement,
      priority: daysSinceLastSession > 7 ? EngagementPriority.high : EngagementPriority.medium,
      title: 'Welcome Back to MindTrainer',
      message: message,
      actionText: actionText,
      actionTarget: EngagementTarget.focusSession,
      expiryHours: 72,
      metadata: {
        'days_absent': daysSinceLastSession,
        'has_pro': hasProAccess,
      },
    );
  }

  EngagementCue _createProFeatureReminderCue(List<String> unusedFeatures) {
    if (unusedFeatures.isEmpty) return _createDefaultProCue();
    
    final feature = unusedFeatures.first;
    String message;
    EngagementTarget target;
    
    switch (feature) {
      case 'mood_correlations':
        message = 'Discover how your mood affects focus performance in Pro Analytics.';
        target = EngagementTarget.analytics;
        break;
      case 'tag_insights':
        message = 'See which session tags boost your performance most in Pro Analytics.';
        target = EngagementTarget.analytics;
        break;
      case 'keyword_analysis':
        message = 'Uncover power words that enhance your focus sessions.';
        target = EngagementTarget.analytics;
        break;
      default:
        message = 'Explore your Pro analytics for deeper focus insights.';
        target = EngagementTarget.analytics;
    }
    
    return EngagementCue(
      id: 'pro_reminder_${DateTime.now().millisecondsSinceEpoch}',
      type: EngagementCueType.proFeatureReminder,
      priority: EngagementPriority.medium,
      title: 'Unlock New Insights 📊',
      message: message,
      actionText: 'Explore Pro',
      actionTarget: target,
      expiryHours: 168, // 1 week
      metadata: {'unused_feature': feature},
    );
  }

  EngagementCue _createDefaultProCue() {
    return EngagementCue(
      id: 'pro_default_${DateTime.now().millisecondsSinceEpoch}',
      type: EngagementCueType.proFeatureReminder,
      priority: EngagementPriority.low,
      title: 'Pro Analytics Available',
      message: 'Your advanced analytics insights are ready to explore.',
      actionText: 'View Analytics',
      actionTarget: EngagementTarget.analytics,
      expiryHours: 168,
      metadata: {},
    );
  }

  EngagementCue _createGoalProgressCue(int currentSessions, int weeklyGoal) {
    final remaining = weeklyGoal - currentSessions;
    final progressPercent = (currentSessions / weeklyGoal * 100).round();
    
    return EngagementCue(
      id: 'goal_progress_${DateTime.now().millisecondsSinceEpoch}',
      type: EngagementCueType.goalProgress,
      priority: EngagementPriority.medium,
      title: 'You\'re ${progressPercent}% There! 🎯',
      message: 'Just $remaining more session${remaining == 1 ? '' : 's'} to reach your weekly goal.',
      actionText: 'Continue Progress',
      actionTarget: EngagementTarget.focusSession,
      expiryHours: 48,
      metadata: {
        'current_sessions': currentSessions,
        'weekly_goal': weeklyGoal,
        'progress_percent': progressPercent,
      },
    );
  }

  EngagementCue _createFocusImprovementCue(double recentAverage, double personalBest) {
    final improvementNeeded = (personalBest - recentAverage).toStringAsFixed(1);
    
    return EngagementCue(
      id: 'focus_improvement_${DateTime.now().millisecondsSinceEpoch}',
      type: EngagementCueType.focusImprovement,
      priority: EngagementPriority.medium,
      title: 'Reach Your Personal Best 🎯',
      message: 'Your recent focus scores averaged ${recentAverage.toStringAsFixed(1)}/10. Your best is ${personalBest.toStringAsFixed(1)}/10.',
      actionText: 'Improve Focus',
      actionTarget: EngagementTarget.focusSession,
      expiryHours: 96, // 4 days
      metadata: {
        'recent_average': recentAverage,
        'personal_best': personalBest,
        'improvement_gap': improvementNeeded,
      },
    );
  }

  /// Track when user interacts with an engagement cue
  void trackCueInteraction(EngagementCue cue, String action) {
    _analytics.trackEngagement('engagement_cue_interaction', 1.0, {
      'cue_id': cue.id,
      'cue_type': cue.type.toString(),
      'action': action, // 'tapped', 'dismissed', 'ignored'
      'priority': cue.priority.toString(),
      'target': cue.actionTarget.toString(),
    });
  }

  /// Mark cue as dismissed by user
  void dismissCue(String cueId) {
    _analytics.trackEngagement('engagement_cue_dismissed', 1.0, {
      'cue_id': cueId,
      'dismiss_reason': 'user_action',
    });
  }

  /// Get cues that should be shown based on timing and user preferences
  List<EngagementCue> getActiveCues(List<EngagementCue> allCues) {
    final now = DateTime.now();
    final activeCues = allCues.where((cue) {
      final expiryTime = cue.createdAt.add(Duration(hours: cue.expiryHours));
      return now.isBefore(expiryTime);
    }).toList();

    // Sort by priority (high first) then by creation time (newest first)
    activeCues.sort((a, b) {
      final priorityCompare = _priorityOrder(b.priority).compareTo(_priorityOrder(a.priority));
      if (priorityCompare != 0) return priorityCompare;
      return b.createdAt.compareTo(a.createdAt);
    });

    return activeCues;
  }

  int _priorityOrder(EngagementPriority priority) {
    switch (priority) {
      case EngagementPriority.high: return 3;
      case EngagementPriority.medium: return 2;
      case EngagementPriority.low: return 1;
    }
  }
}

/// Context for determining appropriate engagement cues
class UserActivityContext {
  final int daysSinceLastSession;
  final int currentStreak;
  final int sessionsThisWeek;
  final int weeklyGoal;
  final bool hasProAccess;
  final int daysSinceProFeatureUse;
  final List<String> unusedProFeatures;
  final int recentSessionsCount;
  final double averageRecentFocusScore;
  final double personalBest;

  UserActivityContext({
    required this.daysSinceLastSession,
    required this.currentStreak,
    required this.sessionsThisWeek,
    required this.weeklyGoal,
    required this.hasProAccess,
    required this.daysSinceProFeatureUse,
    required this.unusedProFeatures,
    required this.recentSessionsCount,
    required this.averageRecentFocusScore,
    required this.personalBest,
  });
}

/// Individual engagement cue to encourage user activity
class EngagementCue {
  final String id;
  final EngagementCueType type;
  final EngagementPriority priority;
  final String title;
  final String message;
  final String actionText;
  final EngagementTarget actionTarget;
  final int expiryHours;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  EngagementCue({
    required this.id,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.actionText,
    required this.actionTarget,
    required this.expiryHours,
    required this.metadata,
  }) : createdAt = DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toString(),
    'priority': priority.toString(),
    'title': title,
    'message': message,
    'action_text': actionText,
    'action_target': actionTarget.toString(),
    'expiry_hours': expiryHours,
    'metadata': metadata,
    'created_at': createdAt.toIso8601String(),
  };
}

enum EngagementCueType {
  streakContinuation,
  reEngagement,
  proFeatureReminder,
  goalProgress,
  focusImprovement,
}

enum EngagementPriority {
  high,
  medium,
  low,
}

enum EngagementTarget {
  focusSession,
  analytics,
  settings,
  history,
}
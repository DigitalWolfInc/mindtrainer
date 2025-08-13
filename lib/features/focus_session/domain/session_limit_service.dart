/// Session Limit Service for MindTrainer Pro
/// 
/// Integrates Pro feature gates with focus session management.
/// Enforces daily session limits for free users while providing seamless Pro experience.

import '../../../core/limits/session_limits.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/session_tags.dart';

/// Result of checking if a new session can be started
class SessionStartResult {
  final bool canStart;
  final String message;
  final bool requiresUpgrade;
  final int currentDailyCount;
  final int? remainingToday; // null = unlimited
  
  const SessionStartResult({
    required this.canStart,
    required this.message,
    required this.requiresUpgrade,
    required this.currentDailyCount,
    this.remainingToday,
  });
  
  /// User can start session - no restrictions
  const SessionStartResult.allowed({
    required int currentCount,
    int? remaining,
    String? message,
  }) : this(
    canStart: true,
    message: message ?? 'Ready to focus',
    requiresUpgrade: false,
    currentDailyCount: currentCount,
    remainingToday: remaining,
  );
  
  /// User is approaching daily limit - show warning
  const SessionStartResult.warning({
    required int currentCount,
    required int remaining,
    required String message,
  }) : this(
    canStart: true,
    message: message,
    requiresUpgrade: false,
    currentDailyCount: currentCount,
    remainingToday: remaining,
  );
  
  /// User has reached daily limit - show upgrade prompt
  const SessionStartResult.limitReached({
    required int currentCount,
    required String upgradeMessage,
  }) : this(
    canStart: false,
    message: upgradeMessage,
    requiresUpgrade: true,
    currentDailyCount: currentCount,
    remainingToday: 0,
  );
  
  /// Whether this is an unlimited Pro user
  bool get isUnlimited => remainingToday == null;
  
  /// Status message for UI display
  String get statusMessage {
    if (isUnlimited) {
      return 'Sessions today: $currentDailyCount • Pro Unlimited';
    } else if (canStart && remainingToday == 1) {
      return 'Last free session today • Upgrade for unlimited';
    } else if (canStart && remainingToday! > 0) {
      return 'Sessions today: $currentDailyCount/5 • $remainingToday remaining';
    } else {
      return message;
    }
  }
}

/// Service for managing session limits and Pro feature integration
class SessionLimitService {
  final MindTrainerProGates _proGates;
  final SessionLimitEnforcer _enforcer;
  
  SessionLimitService(this._proGates) : _enforcer = SessionLimitEnforcer(_proGates);
  
  /// Check if user can start a new session with appropriate messaging
  SessionStartResult checkCanStartSession(List<Session> existingSessions) {
    final limitResult = _enforcer.checkWithSessions(existingSessions);
    final todayCount = _enforcer.countTodaysSessions(existingSessions);
    
    if (limitResult.canStart) {
      if (_proGates.isProActive) {
        // Pro user - unlimited sessions
        return SessionStartResult.allowed(
          currentCount: todayCount,
          message: 'Ready to focus • Pro Unlimited',
        );
      } else {
        // Free user within limits
        final remaining = limitResult.remaining!;
        
        if (remaining == 1) {
          // Last free session warning
          return SessionStartResult.warning(
            currentCount: todayCount,
            remaining: remaining,
            message: 'This is your last free session today',
          );
        } else if (remaining == 2) {
          // Approaching limit
          return SessionStartResult.warning(
            currentCount: todayCount,
            remaining: remaining,
            message: 'You have $remaining free sessions left today',
          );
        } else {
          // Normal free usage
          return SessionStartResult.allowed(
            currentCount: todayCount,
            remaining: remaining,
            message: 'Ready to focus',
          );
        }
      }
    } else {
      // Free user at daily limit
      return SessionStartResult.limitReached(
        currentCount: todayCount,
        upgradeMessage: 'You\'ve reached your daily limit of 5 focus sessions. '
                       'Upgrade to Pro for unlimited sessions and advanced features.',
      );
    }
  }
  
  /// Get current session usage summary for dashboard/stats
  SessionUsageSummary getUsageSummary(List<Session> sessions) {
    final todayCount = _enforcer.countTodaysSessions(sessions);
    final weekSessions = _getWeekSessions(sessions);
    final thisWeekCount = weekSessions.length;
    
    if (_proGates.isProActive) {
      return SessionUsageSummary(
        todaySessions: todayCount,
        weekSessions: thisWeekCount,
        dailyLimit: null,
        weeklyAverage: thisWeekCount / 7,
        tier: 'Pro Unlimited',
        upgradeAvailable: false,
      );
    } else {
      return SessionUsageSummary(
        todaySessions: todayCount,
        weekSessions: thisWeekCount,
        dailyLimit: 5,
        weeklyAverage: thisWeekCount / 7,
        tier: 'Free',
        upgradeAvailable: true,
      );
    }
  }
  
  /// Get Pro upgrade benefits specific to session limits
  List<String> getSessionUpgradeBenefits() {
    return [
      'Unlimited daily focus sessions',
      'No interruptions from limit warnings',
      'Track long-term patterns without restrictions',
      'Perfect for intensive focus days',
    ];
  }
  
  /// Check if user should see upgrade prompts
  bool shouldShowUpgradeHint(List<Session> sessions) {
    if (_proGates.isProActive) return false;
    
    final todayCount = _enforcer.countTodaysSessions(sessions);
    
    // Show upgrade hints when user is active (3+ sessions today)
    // or has hit limits recently
    return todayCount >= 3 || _hasRecentLimitExperience(sessions);
  }
  
  /// Private helper to get this week's sessions
  List<Session> _getWeekSessions(List<Session> sessions) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    
    return sessions.where((session) {
      return session.dateTime.isAfter(weekStartDate) || 
             session.dateTime.isAtSameMomentAs(weekStartDate);
    }).toList();
  }
  
  /// Private helper to check if user has hit limits recently
  bool _hasRecentLimitExperience(List<Session> sessions) {
    // Check if user had 5+ sessions on any day in the past week
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    
    final recentSessions = sessions.where((s) => s.dateTime.isAfter(weekAgo)).toList();
    final sessionsByDay = <DateTime, int>{};
    
    for (final session in recentSessions) {
      final day = DateTime(session.dateTime.year, session.dateTime.month, session.dateTime.day);
      sessionsByDay[day] = (sessionsByDay[day] ?? 0) + 1;
    }
    
    return sessionsByDay.values.any((count) => count >= 5);
  }
}

/// Summary of session usage for dashboard display
class SessionUsageSummary {
  final int todaySessions;
  final int weekSessions;
  final int? dailyLimit; // null = unlimited
  final double weeklyAverage;
  final String tier;
  final bool upgradeAvailable;
  
  const SessionUsageSummary({
    required this.todaySessions,
    required this.weekSessions,
    this.dailyLimit,
    required this.weeklyAverage,
    required this.tier,
    required this.upgradeAvailable,
  });
  
  /// Whether user is on unlimited plan
  bool get isUnlimited => dailyLimit == null;
  
  /// Progress towards daily limit (0.0-1.0, or null if unlimited)
  double? get dailyProgress {
    if (dailyLimit == null) return null;
    return (todaySessions / dailyLimit!).clamp(0.0, 1.0);
  }
  
  /// Formatted daily usage string
  String get dailyUsageText {
    if (isUnlimited) {
      return '$todaySessions sessions today';
    } else {
      return '$todaySessions/$dailyLimit sessions today';
    }
  }
  
  /// Weekly average formatted to 1 decimal
  String get weeklyAverageText {
    return '${weeklyAverage.toStringAsFixed(1)} sessions/day this week';
  }
}
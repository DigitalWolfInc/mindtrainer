/// Session Limits for MindTrainer Free Tier
/// 
/// Enforces daily session limits for free users while allowing unlimited access for Pro.
/// Integrates with existing focus session tracking to provide transparent limit checking.

import '../payments/pro_feature_gates.dart';

/// Result of checking session limits
class SessionLimitResult {
  final bool canStart;
  final String? reason;
  final int currentCount;
  final int? limit; // null = unlimited
  final int? remaining; // null = unlimited
  
  const SessionLimitResult({
    required this.canStart,
    this.reason,
    required this.currentCount,
    this.limit,
    this.remaining,
  });
  
  /// User can start session (no limits apply)
  const SessionLimitResult.allowed({
    required int currentCount,
    int? limit,
    int? remaining,
  }) : this(
    canStart: true,
    reason: null,
    currentCount: currentCount,
    limit: limit,
    remaining: remaining,
  );
  
  /// User has reached their daily limit
  const SessionLimitResult.limitReached({
    required int currentCount,
    required int limit,
  }) : this(
    canStart: false,
    reason: 'Daily limit reached',
    currentCount: currentCount,
    limit: limit,
    remaining: 0,
  );
  
  /// Check result is for Pro user (unlimited)
  bool get isUnlimited => limit == null;
  
  /// Formatted message for UI display
  String get displayMessage {
    if (canStart) {
      if (isUnlimited) {
        return 'Sessions today: $currentCount';
      } else {
        return 'Sessions today: $currentCount/$limit';
      }
    } else {
      return reason ?? 'Cannot start session';
    }
  }
}

/// Session limit enforcement for free tier users
class SessionLimitEnforcer {
  final MindTrainerProGates _gates;
  
  const SessionLimitEnforcer(this._gates);
  
  /// Check if user can start a new focus session today
  SessionLimitResult checkSessionLimit(int todaysSessionCount) {
    final dailyLimit = _gates.dailySessionLimit;
    final canStart = _gates.canStartSession(todaysSessionCount);
    
    if (dailyLimit == -1) {
      // Pro user - unlimited sessions
      return SessionLimitResult.allowed(currentCount: todaysSessionCount);
    }
    
    if (canStart) {
      // Free user within limit
      final remaining = dailyLimit - todaysSessionCount;
      return SessionLimitResult.allowed(
        currentCount: todaysSessionCount,
        limit: dailyLimit,
        remaining: remaining,
      );
    } else {
      // Free user at limit
      return SessionLimitResult.limitReached(
        currentCount: todaysSessionCount,
        limit: dailyLimit,
      );
    }
  }
  
  /// Get session count for today from session list
  int countTodaysSessions(Iterable<dynamic> sessions) {
    final today = _toLocalDate(DateTime.now());
    
    return sessions.where((session) {
      // Assume session has dateTime field
      final sessionDate = _toLocalDate(_getSessionDateTime(session));
      return sessionDate.isAtSameMomentAs(today);
    }).length;
  }
  
  /// Check limits with automatic session counting
  SessionLimitResult checkWithSessions(Iterable<dynamic> sessions) {
    final todayCount = countTodaysSessions(sessions);
    return checkSessionLimit(todayCount);
  }
  
  /// Get upgrade prompt message for hitting limits
  String getUpgradePrompt() {
    return 'You\'ve reached your daily limit of 5 focus sessions. '
           'Upgrade to Pro for unlimited sessions and advanced features.';
  }
  
  /// Get limit warning message when approaching limit
  String? getLimitWarning(int todaysSessionCount) {
    if (_gates.isProActive) return null;
    
    final remaining = _gates.dailySessionLimit - todaysSessionCount;
    
    if (remaining == 1) {
      return 'This is your last free session today. '
             'Upgrade to Pro for unlimited access.';
    } else if (remaining == 2) {
      return 'You have $remaining free sessions left today.';
    }
    
    return null;
  }
  
  // Private helpers
  
  /// Convert DateTime to local date (ignoring time)
  DateTime _toLocalDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
  
  /// Extract DateTime from session object (handles different session types)
  DateTime _getSessionDateTime(dynamic session) {
    // Handle different session types that might have dateTime field
    if (session is Map<String, dynamic>) {
      final dateTimeStr = session['start'] ?? session['dateTime'];
      if (dateTimeStr is String) {
        return DateTime.parse(dateTimeStr);
      } else if (dateTimeStr is DateTime) {
        return dateTimeStr;
      }
    }
    
    // Try reflection-style access for objects
    try {
      // Assume session has a dateTime getter
      return (session as dynamic).dateTime as DateTime;
    } catch (e) {
      // Fallback to current time if we can't extract session time
      return DateTime.now();
    }
  }
}
/// Retention & Engagement System for MindTrainer
/// 
/// Provides intelligent cues to revisit Pro features, gentle reminders for streaks/goals,
/// and "what you missed" summaries to improve user engagement and retention.

import 'dart:async';
import 'dart:convert';
import '../storage/local_storage.dart';
import '../payments/pro_feature_gates.dart';

/// User engagement event types
enum EngagementEvent {
  sessionCompleted,
  streakAchieved,
  goalReached,
  proFeatureUsed,
  freeLimitReached,
  inactivityDetected,
  appReturned,
}

/// Engagement data point
class EngagementData {
  final EngagementEvent event;
  final DateTime timestamp;
  final Map<String, dynamic> properties;
  
  EngagementData({
    required this.event,
    required this.timestamp,
    this.properties = const {},
  });
  
  Map<String, dynamic> toJson() => {
    'event': event.name,
    'timestamp': timestamp.toIso8601String(),
    'properties': properties,
  };
  
  factory EngagementData.fromJson(Map<String, dynamic> json) {
    return EngagementData(
      event: EngagementEvent.values.firstWhere(
        (e) => e.name == json['event'],
        orElse: () => EngagementEvent.sessionCompleted,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
    );
  }
}

/// User activity streak information
class ActivityStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastActivity;
  final DateTime streakStartDate;
  
  const ActivityStreak({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastActivity,
    required this.streakStartDate,
  });
  
  bool get isActive => _daysSinceLastActivity == 0;
  bool get isAtRisk => _daysSinceLastActivity == 1;
  bool get isBroken => _daysSinceLastActivity > 1;
  
  int get _daysSinceLastActivity {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDay = DateTime(
      lastActivity.year, 
      lastActivity.month, 
      lastActivity.day
    );
    return today.difference(activityDay).inDays;
  }
  
  Map<String, dynamic> toJson() => {
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActivity': lastActivity.toIso8601String(),
    'streakStartDate': streakStartDate.toIso8601String(),
  };
  
  factory ActivityStreak.fromJson(Map<String, dynamic> json) {
    return ActivityStreak(
      currentStreak: json['currentStreak'] ?? 0,
      longestStreak: json['longestStreak'] ?? 0,
      lastActivity: DateTime.parse(json['lastActivity']),
      streakStartDate: DateTime.parse(json['streakStartDate']),
    );
  }
  
  /// Update streak based on new activity
  ActivityStreak updateWithActivity(DateTime activityTime) {
    final activityDay = DateTime(
      activityTime.year, 
      activityTime.month, 
      activityTime.day
    );
    final lastDay = DateTime(
      lastActivity.year, 
      lastActivity.month, 
      lastActivity.day
    );
    
    final daysDiff = activityDay.difference(lastDay).inDays;
    
    if (daysDiff == 0) {
      // Same day, no change to streak
      return copyWith(lastActivity: activityTime);
    } else if (daysDiff == 1) {
      // Next day, extend streak
      final newStreak = currentStreak + 1;
      return ActivityStreak(
        currentStreak: newStreak,
        longestStreak: newStreak > longestStreak ? newStreak : longestStreak,
        lastActivity: activityTime,
        streakStartDate: streakStartDate,
      );
    } else {
      // Gap in activity, reset streak
      return ActivityStreak(
        currentStreak: 1,
        longestStreak: longestStreak,
        lastActivity: activityTime,
        streakStartDate: activityTime,
      );
    }
  }
  
  ActivityStreak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActivity,
    DateTime? streakStartDate,
  }) {
    return ActivityStreak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActivity: lastActivity ?? this.lastActivity,
      streakStartDate: streakStartDate ?? this.streakStartDate,
    );
  }
}

/// Retention cue types
enum RetentionCueType {
  streakReminder,
  proFeatureHighlight,
  goalProgress,
  inactivitySummary,
  achievement,
}

/// Retention cue data
class RetentionCue {
  final RetentionCueType type;
  final String title;
  final String message;
  final String? actionText;
  final VoidCallback? onAction;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  
  RetentionCue({
    required this.type,
    required this.title,
    required this.message,
    this.actionText,
    this.onAction,
    DateTime? timestamp,
    this.data = const {},
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Main retention system
class RetentionSystem {
  final LocalStorage _storage;
  final MindTrainerProGates _proGates;
  
  static const String _engagementHistoryKey = 'engagement_history';
  static const String _streakDataKey = 'activity_streak';
  static const String _lastAppOpenKey = 'last_app_open';
  static const String _cueShownKey = 'retention_cues_shown';
  
  final StreamController<RetentionCue> _cueController = 
      StreamController<RetentionCue>.broadcast();
  
  ActivityStreak _currentStreak = ActivityStreak(
    currentStreak: 0,
    longestStreak: 0,
    lastActivity: DateTime.now(),
    streakStartDate: DateTime.now(),
  );
  
  RetentionSystem(this._storage, this._proGates);
  
  /// Stream of retention cues to show to user
  Stream<RetentionCue> get cueStream => _cueController.stream;
  
  /// Current activity streak
  ActivityStreak get currentStreak => _currentStreak;
  
  /// Initialize the system
  Future<void> initialize() async {
    await _loadStreakData();
    await _checkForReturnUser();
    await _scheduleRetentionChecks();
  }
  
  /// Record an engagement event
  Future<void> recordEvent(EngagementEvent event, {
    Map<String, dynamic>? properties,
  }) async {
    final data = EngagementData(
      event: event,
      timestamp: DateTime.now(),
      properties: properties ?? {},
    );
    
    await _saveEngagementEvent(data);
    
    // Update streak for session completion
    if (event == EngagementEvent.sessionCompleted) {
      await _updateStreak(data.timestamp);
    }
    
    // Check for cues based on event
    await _checkForEventBasedCues(event, properties ?? {});
  }
  
  /// Get engagement history for analytics
  Future<List<EngagementData>> getEngagementHistory({
    int? limitDays,
  }) async {
    final historyJson = await _storage.getString(_engagementHistoryKey);
    if (historyJson == null) return [];
    
    try {
      final List<dynamic> historyList = jsonDecode(historyJson);
      final history = historyList
          .map((json) => EngagementData.fromJson(json))
          .toList();
      
      if (limitDays != null) {
        final cutoff = DateTime.now().subtract(Duration(days: limitDays));
        return history.where((data) => data.timestamp.isAfter(cutoff)).toList();
      }
      
      return history;
    } catch (e) {
      return [];
    }
  }
  
  /// Generate "what you missed" summary for returning users
  Future<RetentionCue?> generateInactivitySummary() async {
    final lastOpen = await _getLastAppOpen();
    if (lastOpen == null) return null;
    
    final daysSince = DateTime.now().difference(lastOpen).inDays;
    if (daysSince < 2) return null; // Not inactive enough
    
    final history = await getEngagementHistory(limitDays: daysSince + 7);
    final beforeInactivity = history
        .where((event) => event.timestamp.isBefore(lastOpen))
        .toList();
    
    if (beforeInactivity.isEmpty) return null;
    
    // Analyze what they were doing before
    final sessionCount = beforeInactivity
        .where((e) => e.event == EngagementEvent.sessionCompleted)
        .length;
    
    final streakBefore = beforeInactivity
        .where((e) => e.event == EngagementEvent.streakAchieved)
        .length;
    
    String message;
    if (daysSince <= 7) {
      if (sessionCount > 0) {
        message = "Welcome back! You completed $sessionCount focus sessions before your break. "
                 "Ready to continue your mindfulness journey?";
      } else if (_proGates.isProActive) {
        message = "Your Pro features are waiting! Explore advanced focus modes and "
                 "breathing patterns you haven't tried yet.";
      } else {
        message = "Welcome back to MindTrainer! You have ${5 - _getTodaysSessionCount()} "
                 "free sessions remaining today.";
      }
    } else {
      message = "We missed you! Your mindfulness practice is ready to resume. "
               "Start with a short 5-minute session to ease back in.";
    }
    
    return RetentionCue(
      type: RetentionCueType.inactivitySummary,
      title: "Welcome back!",
      message: message,
      actionText: sessionCount > 0 ? "Continue Session" : "Start Fresh",
      data: {
        'days_away': daysSince,
        'previous_sessions': sessionCount,
        'previous_streaks': streakBefore,
      },
    );
  }
  
  /// Generate streak reminders
  Future<RetentionCue?> generateStreakReminder() async {
    if (_currentStreak.isAtRisk && !_proGates.isProActive) {
      return RetentionCue(
        type: RetentionCueType.streakReminder,
        title: "Don't break your streak!",
        message: "You're on a ${_currentStreak.currentStreak}-day streak. "
                "One quick session today keeps it going!",
        actionText: "Quick Session",
        data: {'streak': _currentStreak.currentStreak},
      );
    } else if (_currentStreak.currentStreak >= 7 && _currentStreak.isActive) {
      return RetentionCue(
        type: RetentionCueType.achievement,
        title: "Amazing streak!",
        message: "🔥 ${_currentStreak.currentStreak} days of consistent practice! "
                "${_proGates.isProActive ? 'Keep exploring Pro features to deepen your practice.' : 'Unlock Pro features to enhance your daily sessions.'}",
        actionText: _proGates.isProActive ? "Explore Pro" : "Try Pro",
        data: {'streak': _currentStreak.currentStreak},
      );
    }
    
    return null;
  }
  
  /// Generate Pro feature highlights for free users
  Future<RetentionCue?> generateProFeatureHighlight() async {
    if (_proGates.isProActive) return null;
    
    final todaysSessions = _getTodaysSessionCount();
    
    // Show after 3 sessions (engaged user)
    if (todaysSessions >= 3) {
      return RetentionCue(
        type: RetentionCueType.proFeatureHighlight,
        title: "You're on fire today!",
        message: "🎯 $todaysSessions sessions completed! Ready to unlock unlimited "
                "sessions and 9 premium focus environments?",
        actionText: "Explore Pro",
        data: {'sessions_today': todaysSessions},
      );
    }
    
    // Show if they've hit the session limit
    if (todaysSessions >= 5) {
      return RetentionCue(
        type: RetentionCueType.proFeatureHighlight,
        title: "You've reached today's limit",
        message: "Amazing dedication! Pro users get unlimited daily sessions "
                "plus advanced breathing guides and premium environments.",
        actionText: "Upgrade to Pro",
        data: {'sessions_today': todaysSessions, 'at_limit': true},
      );
    }
    
    return null;
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _cueController.close();
  }
  
  // Private methods
  
  Future<void> _loadStreakData() async {
    final streakJson = await _storage.getString(_streakDataKey);
    if (streakJson != null) {
      try {
        final streakData = jsonDecode(streakJson);
        _currentStreak = ActivityStreak.fromJson(streakData);
      } catch (e) {
        // Keep default streak if parsing fails
      }
    }
  }
  
  Future<void> _saveStreakData() async {
    final streakJson = jsonEncode(_currentStreak.toJson());
    await _storage.setString(_streakDataKey, streakJson);
  }
  
  Future<void> _updateStreak(DateTime activityTime) async {
    final oldStreak = _currentStreak.currentStreak;
    _currentStreak = _currentStreak.updateWithActivity(activityTime);
    await _saveStreakData();
    
    // Emit streak achievement if it increased
    if (_currentStreak.currentStreak > oldStreak) {
      await recordEvent(EngagementEvent.streakAchieved, properties: {
        'streak': _currentStreak.currentStreak,
        'longest_streak': _currentStreak.longestStreak,
      });
    }
  }
  
  Future<void> _saveEngagementEvent(EngagementData data) async {
    final history = await getEngagementHistory();
    history.add(data);
    
    // Keep only last 90 days
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final filtered = history
        .where((event) => event.timestamp.isAfter(cutoff))
        .toList();
    
    final historyJson = jsonEncode(
      filtered.map((data) => data.toJson()).toList()
    );
    await _storage.setString(_engagementHistoryKey, historyJson);
  }
  
  Future<void> _checkForReturnUser() async {
    final lastOpen = await _getLastAppOpen();
    final now = DateTime.now();
    
    if (lastOpen != null) {
      final daysSince = now.difference(lastOpen).inDays;
      
      if (daysSince >= 2) {
        await recordEvent(EngagementEvent.appReturned, properties: {
          'days_away': daysSince,
        });
        
        // Generate inactivity summary
        final summary = await generateInactivitySummary();
        if (summary != null && !_cueController.isClosed) {
          _cueController.add(summary);
        }
      }
    }
    
    await _storage.setString(_lastAppOpenKey, now.toIso8601String());
  }
  
  Future<DateTime?> _getLastAppOpen() async {
    final lastOpenStr = await _storage.getString(_lastAppOpenKey);
    if (lastOpenStr != null) {
      try {
        return DateTime.parse(lastOpenStr);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
  
  Future<void> _scheduleRetentionChecks() async {
    // Check for streak reminders
    final streakCue = await generateStreakReminder();
    if (streakCue != null && !_cueController.isClosed) {
      _cueController.add(streakCue);
    }
    
    // Check for Pro feature highlights
    final proCue = await generateProFeatureHighlight();
    if (proCue != null && !_cueController.isClosed) {
      _cueController.add(proCue);
    }
  }
  
  Future<void> _checkForEventBasedCues(
    EngagementEvent event, 
    Map<String, dynamic> properties
  ) async {
    if (event == EngagementEvent.freeLimitReached && !_proGates.isProActive) {
      final cue = RetentionCue(
        type: RetentionCueType.proFeatureHighlight,
        title: "Daily limit reached!",
        message: "You're committed to your practice! Upgrade to Pro for unlimited "
                "daily sessions and unlock your full potential.",
        actionText: "Upgrade Now",
        data: properties,
      );
      
      if (!_cueController.isClosed) {
        _cueController.add(cue);
      }
    }
  }
  
  int _getTodaysSessionCount() {
    // This would integrate with actual session counting service
    // For now, return a placeholder
    return 0;
  }
}
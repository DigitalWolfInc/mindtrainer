/// Engagement & Retention System for MindTrainer
/// 
/// Tracks user engagement patterns and provides intelligent cues
/// to increase retention and feature discovery.

import 'dart:math';
import '../storage/local_storage.dart';
import 'experiment_framework.dart';

/// User engagement event types
enum EngagementEvent {
  sessionStart,
  sessionComplete,
  coachInteraction,
  moodCheckin,
  insightsView,
  historyView,
  settingsView,
  proFeatureAttempt,
  proUpgrade,
  appLaunch,
  appBackground,
}

/// Engagement pattern analysis
class EngagementPattern {
  final int consecutiveDays;
  final int totalSessions;
  final int weeklyAverage;
  final DateTime lastActiveDate;
  final List<EngagementEvent> recentEvents;
  final Map<EngagementEvent, int> eventCounts;
  
  const EngagementPattern({
    required this.consecutiveDays,
    required this.totalSessions,
    required this.weeklyAverage,
    required this.lastActiveDate,
    required this.recentEvents,
    required this.eventCounts,
  });
  
  /// Check if user is highly engaged
  bool get isHighlyEngaged => 
      consecutiveDays >= 3 && weeklyAverage >= 5;
  
  /// Check if user is at risk of churning
  bool get isAtRisk => 
      daysSinceLastActive >= 3 && weeklyAverage < 3;
  
  /// Days since last activity
  int get daysSinceLastActive => 
      DateTime.now().difference(lastActiveDate).inDays;
  
  /// Get engagement level
  EngagementLevel get level {
    if (isHighlyEngaged) return EngagementLevel.high;
    if (isAtRisk) return EngagementLevel.low;
    return EngagementLevel.medium;
  }
}

/// Engagement levels
enum EngagementLevel { low, medium, high }

/// In-app cue types
enum CueType {
  streakReminder,
  proFeatureDiscovery,
  goalProgress,
  returnWelcome,
  achievementCelebration,
  inactivitySummary,
}

/// In-app cue for user engagement
class EngagementCue {
  final CueType type;
  final String title;
  final String message;
  final String? actionLabel;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int priority;
  
  const EngagementCue({
    required this.type,
    required this.title,
    required this.message,
    this.actionLabel,
    this.metadata = const {},
    required this.timestamp,
    this.priority = 1,
  });
  
  /// Create streak reminder cue
  factory EngagementCue.streakReminder(int streakDays, String tone) {
    final messages = {
      'supportive': 'You\'re on a $streakDays-day streak! Keep building your mindful routine.',
      'achievement': '$streakDays days strong! You\'re creating lasting change.',
      'curiosity': 'Day $streakDays - what insights will today bring?',
    };
    
    return EngagementCue(
      type: CueType.streakReminder,
      title: 'Streak Update',
      message: messages[tone] ?? messages['supportive']!,
      actionLabel: 'Continue',
      timestamp: DateTime.now(),
      priority: 2,
      metadata: {'streak_days': streakDays, 'tone': tone},
    );
  }
  
  /// Create pro feature discovery cue
  factory EngagementCue.proFeatureDiscovery(String feature, String benefit) {
    return EngagementCue(
      type: CueType.proFeatureDiscovery,
      title: 'Discover $feature',
      message: benefit,
      actionLabel: 'Explore Pro',
      timestamp: DateTime.now(),
      priority: 3,
      metadata: {'feature': feature},
    );
  }
  
  /// Create inactivity summary cue
  factory EngagementCue.inactivitySummary(int daysMissed, List<String> highlights) {
    return EngagementCue(
      type: CueType.inactivitySummary,
      title: 'Welcome back!',
      message: 'You\'ve missed $daysMissed days. Here\'s what happened: ${highlights.join(", ")}',
      actionLabel: 'Catch up',
      timestamp: DateTime.now(),
      priority: 4,
      metadata: {'days_missed': daysMissed, 'highlights': highlights},
    );
  }
}

/// Engagement tracking and cue system
class EngagementSystem {
  static const String _eventsKey = 'engagement_events';
  static const String _cueDismissalsKey = 'cue_dismissals';
  static const String _lastAnalysisKey = 'last_analysis';
  
  final LocalStorage _storage;
  final ExperimentFramework _experiments;
  final List<EngagementEvent> _sessionEvents = [];
  final Map<CueType, DateTime> _cueDismissals = {};
  
  EngagementSystem(this._storage, this._experiments);
  
  /// Initialize engagement system
  Future<void> initialize() async {
    await _loadCueDismissals();
  }
  
  /// Track engagement event
  Future<void> trackEvent(EngagementEvent event, {Map<String, dynamic>? metadata}) async {
    _sessionEvents.add(event);
    await _persistEvent(event, metadata ?? {});
  }
  
  /// Get current engagement pattern
  Future<EngagementPattern> getEngagementPattern() async {
    final events = await _loadRecentEvents(30); // Last 30 days
    final now = DateTime.now();
    
    // Calculate consecutive days
    int consecutiveDays = 0;
    final activeDays = <DateTime>{};
    
    for (final event in events) {
      activeDays.add(DateTime(event['date'].year, event['date'].month, event['date'].day));
    }
    
    final sortedDays = activeDays.toList()..sort((a, b) => b.compareTo(a));
    
    for (int i = 0; i < sortedDays.length; i++) {
      final dayDiff = now.difference(sortedDays[i]).inDays;
      if (dayDiff == i) {
        consecutiveDays++;
      } else {
        break;
      }
    }
    
    // Calculate weekly average
    final weeklyEvents = events.where((e) => 
        now.difference(e['date'] as DateTime).inDays <= 7).length;
    
    // Count event types
    final eventCounts = <EngagementEvent, int>{};
    final recentEventTypes = <EngagementEvent>[];
    
    for (final event in events.take(20)) {
      final type = EngagementEvent.values.firstWhere(
        (e) => e.toString() == event['type'],
        orElse: () => EngagementEvent.appLaunch,
      );
      
      eventCounts[type] = (eventCounts[type] ?? 0) + 1;
      recentEventTypes.add(type);
    }
    
    return EngagementPattern(
      consecutiveDays: consecutiveDays,
      totalSessions: events.length,
      weeklyAverage: weeklyEvents,
      lastActiveDate: events.isNotEmpty 
          ? events.first['date'] as DateTime
          : now.subtract(const Duration(days: 30)),
      recentEvents: recentEventTypes,
      eventCounts: eventCounts,
    );
  }
  
  /// Generate engagement cues based on current pattern
  Future<List<EngagementCue>> generateCues() async {
    final pattern = await getEngagementPattern();
    final cues = <EngagementCue>[];
    final now = DateTime.now();
    
    // Streak reminders for engaged users
    if (pattern.consecutiveDays >= 2 && !_wasCueDismissedToday(CueType.streakReminder)) {
      final tone = _experiments.getConfig<String>('upsell_message_style', 'tone', 'supportive');
      cues.add(EngagementCue.streakReminder(pattern.consecutiveDays, tone));
    }
    
    // Pro feature discovery for active users
    if (pattern.level == EngagementLevel.high && 
        pattern.eventCounts[EngagementEvent.proFeatureAttempt] != null &&
        !_wasCueDismissedRecently(CueType.proFeatureDiscovery, 3)) {
      
      final features = [
        {'name': 'Advanced Analytics', 'benefit': 'See deeper insights into your mindfulness patterns'},
        {'name': 'Unlimited Sessions', 'benefit': 'Practice as much as you want, whenever you want'},
        {'name': 'AI Coach+', 'benefit': 'Get personalized guidance tailored to your journey'},
      ];
      
      final feature = features[Random().nextInt(features.length)];
      cues.add(EngagementCue.proFeatureDiscovery(
        feature['name']!,
        feature['benefit']!,
      ));
    }
    
    // Inactivity summary for returning users
    if (pattern.daysSinceLastActive >= 2 && 
        !_wasCueDismissedToday(CueType.inactivitySummary)) {
      
      final highlights = _generateInactivityHighlights(pattern.daysSinceLastActive);
      cues.add(EngagementCue.inactivitySummary(
        pattern.daysSinceLastActive,
        highlights,
      ));
    }
    
    // Sort by priority
    cues.sort((a, b) => b.priority.compareTo(a.priority));
    
    return cues;
  }
  
  /// Dismiss a cue
  Future<void> dismissCue(CueType type) async {
    _cueDismissals[type] = DateTime.now();
    await _saveCueDismissals();
  }
  
  /// Check if cue was dismissed today
  bool _wasCueDismissedToday(CueType type) {
    final dismissal = _cueDismissals[type];
    if (dismissal == null) return false;
    
    final now = DateTime.now();
    final dismissalDate = DateTime(dismissal.year, dismissal.month, dismissal.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    
    return dismissalDate.isAtSameMomentAs(todayDate);
  }
  
  /// Check if cue was dismissed recently
  bool _wasCueDismissedRecently(CueType type, int days) {
    final dismissal = _cueDismissals[type];
    if (dismissal == null) return false;
    
    return DateTime.now().difference(dismissal).inDays < days;
  }
  
  /// Generate highlights for inactivity summary
  List<String> _generateInactivityHighlights(int daysMissed) {
    final highlights = <String>[];
    
    if (daysMissed <= 3) {
      highlights.add('Your streak is still recoverable');
    } else {
      highlights.add('New insights and features have been added');
    }
    
    highlights.add('Your focus goals are waiting');
    
    if (Random().nextBool()) {
      highlights.add('Other users found peace in similar situations');
    }
    
    return highlights.take(2).toList();
  }
  
  /// Persist engagement event
  Future<void> _persistEvent(EngagementEvent event, Map<String, dynamic> metadata) async {
    try {
      final events = await _loadRecentEvents(100); // Keep last 100 events
      
      final newEvent = {
        'type': event.toString(),
        'date': DateTime.now().toIso8601String(),
        'metadata': metadata,
      };
      
      events.insert(0, newEvent);
      if (events.length > 100) {
        events.removeLast();
      }
      
      await _storage.setString(_eventsKey, LocalStorage.encodeJson(events));
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Load recent events
  Future<List<Map<String, dynamic>>> _loadRecentEvents(int limit) async {
    try {
      final stored = await _storage.getString(_eventsKey);
      if (stored != null) {
        final List<dynamic> data = LocalStorage.parseJson(stored) ?? [];
        
        return data.take(limit).map((e) {
          final event = e as Map<String, dynamic>;
          return {
            ...event,
            'date': DateTime.parse(event['date'] as String),
          };
        }).toList();
      }
    } catch (e) {
      // Ignore errors
    }
    
    return [];
  }
  
  /// Load cue dismissals
  Future<void> _loadCueDismissals() async {
    try {
      final stored = await _storage.getString(_cueDismissalsKey);
      if (stored != null) {
        final Map<String, dynamic> data = LocalStorage.parseJson(stored) ?? {};
        
        _cueDismissals.clear();
        data.forEach((key, value) {
          final cueType = CueType.values.firstWhere(
            (t) => t.toString() == key,
            orElse: () => CueType.streakReminder,
          );
          _cueDismissals[cueType] = DateTime.parse(value as String);
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }
  
  /// Save cue dismissals
  Future<void> _saveCueDismissals() async {
    try {
      final data = <String, String>{};
      _cueDismissals.forEach((type, date) {
        data[type.toString()] = date.toIso8601String();
      });
      
      await _storage.setString(_cueDismissalsKey, LocalStorage.encodeJson(data));
    } catch (e) {
      // Ignore storage errors
    }
  }
}
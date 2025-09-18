import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/coach/coach_events.dart';
import '../features/focus_session/domain/focus_session_statistics.dart';
import '../features/focus_session/data/focus_session_statistics_storage.dart';
import '../foundation/clock.dart';
import '../settings/diagnostics.dart';
import 'badge.dart';
import 'badge_ids.dart';
import 'achievements_store.dart';
import 'snapshot.dart';

class AchievementsResolver extends ChangeNotifier {
  static const bool _diagEnabled = true;
  static AchievementsResolver? _instance;
  
  final AchievementsStore _store;
  final Clock _clock;
  Timer? _debounceTimer;
  bool _initialized = false;

  AchievementsResolver._(this._store, [Clock? clock]) : _clock = clock ?? const SystemClock();

  static AchievementsResolver get instance {
    _instance ??= AchievementsResolver._(AchievementsStore.instance);
    return _instance!;
  }

  /// Create instance with custom clock for testing
  static AchievementsResolver createWithClock(Clock clock) {
    return AchievementsResolver._(AchievementsStore.instance, clock);
  }

  AchievementsSnapshot get snapshot => _store.snapshot;

  Future<void> initialize() async {
    if (_initialized) return;
    
    await _store.init();
    _initialized = true;
  }

  // Session completion hook
  Future<void> onSessionCompleted({
    required DateTime completedAt,
    required int durationMinutes,
    List<String>? tags,
    String? note,
  }) async {
    _scheduleRecompute();
  }

  // Coach event hook
  Future<void> onCoachEvent(CoachEvent event) async {
    if (event.outcome == CoachOutcome.closed) {
      _scheduleRecompute();
    }
  }

  // Weekly goal completion hook
  Future<void> onWeeklyGoalCompleted() async {
    _scheduleRecompute();
  }

  // Animal check-in hook
  Future<void> resolveAnimalCheckin(String species) async {
    final count = await _store.incrementAnimal(species);
    final badges = <Badge>[];
    final now = _clock.now();

    // Check thresholds: 1, 7, 30, 100
    if (count == 1) badges.add(_createAnimalBadge(species, 1, now));
    if (count == 7) badges.add(_createAnimalBadge(species, 7, now));
    if (count == 30) badges.add(_createAnimalBadge(species, 30, now));
    if (count == 100) badges.add(_createAnimalBadge(species, 100, now));

    if (badges.isNotEmpty) {
      await _store.upsertMany(badges);
      notifyListeners();
    }
  }

  Badge _createAnimalBadge(String species, int threshold, DateTime unlockedAt) {
    final badgeId = 'animal.$species.$threshold';
    final info = _getAnimalBadgeInfo(species, threshold);
    return Badge.create(
      id: badgeId,
      title: info.title,
      description: info.description,
      category: 'animal',
      unlockedAt: unlockedAt,
      meta: {'species': species, 'threshold': threshold},
    );
  }

  void _scheduleRecompute() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 50), () {
      _recompute();
    });
  }

  Future<void> _recompute() async {
    if (_diagEnabled) {
      Diag.d('Badges', 'Recompute start');
    }

    try {
      final newBadges = await _computeNewlyEarnedBadges();
      
      if (newBadges.isNotEmpty) {
        await _store.upsertMany(newBadges);
        
        if (_diagEnabled) {
          for (final badge in newBadges) {
            Diag.d('Badges', 'Unlocked: ${badge.id}');
          }
        }
        
        notifyListeners();
      }

      if (_diagEnabled) {
        Diag.d('Badges', 'Recompute end: ${newBadges.length} new badges');
      }
    } catch (e) {
      if (_diagEnabled) {
        Diag.d('Badges', 'Recompute error: $e');
      }
    }
  }

  Future<List<Badge>> _computeNewlyEarnedBadges() async {
    final currentSnapshot = _store.snapshot;
    final allStats = await _loadAllStats();
    
    final newBadges = <Badge>[];
    final now = _clock.now();

    // Session count badges
    final sessionCount = allStats.completedSessionsCount;
    _checkSessionCountBadge(BadgeIds.firstSession, 1, sessionCount, currentSnapshot, newBadges, now);
    _checkSessionCountBadge(BadgeIds.fiveSessions, 5, sessionCount, currentSnapshot, newBadges, now);
    _checkSessionCountBadge(BadgeIds.twentySessions, 20, sessionCount, currentSnapshot, newBadges, now);
    _checkSessionCountBadge(BadgeIds.hundredSessions, 100, sessionCount, currentSnapshot, newBadges, now);

    // Total time badges
    final totalHours = allStats.totalFocusTimeMinutes / 60.0;
    _checkTimeBadge(BadgeIds.firstHourTotal, 1.0, totalHours, currentSnapshot, newBadges, now);
    _checkTimeBadge(BadgeIds.tenHoursTotal, 10.0, totalHours, currentSnapshot, newBadges, now);
    _checkTimeBadge(BadgeIds.hundredHoursTotal, 100.0, totalHours, currentSnapshot, newBadges, now);

    // Streak badges
    final maxStreak = await _computeMaxStreak();
    _checkStreakBadge(BadgeIds.firstStreak3, 3, maxStreak, currentSnapshot, newBadges, now);
    _checkStreakBadge(BadgeIds.streak7, 7, maxStreak, currentSnapshot, newBadges, now);
    _checkStreakBadge(BadgeIds.streak30, 30, maxStreak, currentSnapshot, newBadges, now);

    // Long session badges
    final longestSession = await _computeLongestSessionMinutes();
    _checkLongSessionBadge(BadgeIds.longSession25m, 25, longestSession, currentSnapshot, newBadges, now);
    _checkLongSessionBadge(BadgeIds.longSession60m, 60, longestSession, currentSnapshot, newBadges, now);
    _checkLongSessionBadge(BadgeIds.longSession120m, 120, longestSession, currentSnapshot, newBadges, now);

    // Tag mastery badge
    final maxTagUsage = await _computeMaxTagUsage();
    if (!currentSnapshot.has(BadgeIds.tagMastery10) && maxTagUsage >= 10) {
      newBadges.add(_createBadge(BadgeIds.tagMastery10, now, {'maxTagUsage': maxTagUsage}));
    }

    // Coach reflection badge
    final reflectionCount = await _computeReflectionCount();
    if (!currentSnapshot.has(BadgeIds.reflection10) && reflectionCount >= 10) {
      newBadges.add(_createBadge(BadgeIds.reflection10, now, {'reflectionCount': reflectionCount}));
    }

    // Weekly goal badge
    final weeklyGoalCount = await _computeWeeklyGoalCount();
    if (!currentSnapshot.has(BadgeIds.weekGoal3) && weeklyGoalCount >= 3) {
      newBadges.add(_createBadge(BadgeIds.weekGoal3, now, {'weeklyGoalCount': weeklyGoalCount}));
    }

    // Time-based badges
    final earlyRiserCount = await _computeEarlyRiserCount();
    if (!currentSnapshot.has(BadgeIds.earlyRiser) && earlyRiserCount >= 5) {
      newBadges.add(_createBadge(BadgeIds.earlyRiser, now, {'earlyRiserCount': earlyRiserCount}));
    }

    final nightOwlCount = await _computeNightOwlCount();
    if (!currentSnapshot.has(BadgeIds.nightOwl) && nightOwlCount >= 5) {
      newBadges.add(_createBadge(BadgeIds.nightOwl, now, {'nightOwlCount': nightOwlCount}));
    }

    final consistentWeeks = await _computeConsistentWeeks();
    if (!currentSnapshot.has(BadgeIds.consistentWeek) && consistentWeeks >= 1) {
      newBadges.add(_createBadge(BadgeIds.consistentWeek, now, {'consistentWeeks': consistentWeeks}));
    }

    final monthlyMilestones = await _computeMonthlyMilestones();
    if (!currentSnapshot.has(BadgeIds.monthlyMilestone) && monthlyMilestones >= 1) {
      newBadges.add(_createBadge(BadgeIds.monthlyMilestone, now, {'monthlyMilestones': monthlyMilestones}));
    }

    return newBadges;
  }

  void _checkSessionCountBadge(String badgeId, int threshold, int current, 
                              AchievementsSnapshot snapshot, List<Badge> newBadges, DateTime now) {
    if (!snapshot.has(badgeId) && current >= threshold) {
      newBadges.add(_createBadge(badgeId, now, {'sessionCount': current}));
    }
  }

  void _checkTimeBadge(String badgeId, double thresholdHours, double currentHours, 
                      AchievementsSnapshot snapshot, List<Badge> newBadges, DateTime now) {
    if (!snapshot.has(badgeId) && currentHours >= thresholdHours) {
      newBadges.add(_createBadge(badgeId, now, {'totalHours': currentHours}));
    }
  }

  void _checkStreakBadge(String badgeId, int threshold, int current, 
                        AchievementsSnapshot snapshot, List<Badge> newBadges, DateTime now) {
    if (!snapshot.has(badgeId) && current >= threshold) {
      newBadges.add(_createBadge(badgeId, now, {'maxStreak': current}));
    }
  }

  void _checkLongSessionBadge(String badgeId, int thresholdMinutes, int currentMinutes, 
                             AchievementsSnapshot snapshot, List<Badge> newBadges, DateTime now) {
    if (!snapshot.has(badgeId) && currentMinutes >= thresholdMinutes) {
      newBadges.add(_createBadge(badgeId, now, {'longestSession': currentMinutes}));
    }
  }

  Badge _createBadge(String id, DateTime unlockedAt, [Map<String, dynamic>? meta]) {
    final titleAndDesc = _getBadgeInfo(id);
    return Badge.create(
      id: id,
      title: titleAndDesc.title,
      description: titleAndDesc.description,
      unlockedAt: unlockedAt,
      meta: meta,
    );
  }

  // Data loading helpers

  Future<FocusSessionStatistics> _loadAllStats() async {
    return await FocusSessionStatisticsStorage.loadStatistics();
  }

  Future<List<Map<String, dynamic>>> _loadAllSessions() async {
    const sessionHistoryKey = 'session_history';
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(sessionHistoryKey) ?? [];
    
    return historyJson.asMap().entries.map((entry) {
      final jsonString = entry.value;
      final parts = jsonString.split('|');
      final dateTime = DateTime.parse(parts[0]);
      final durationMinutes = int.parse(parts[1]);
      final tags = parts.length > 2 ? parts[2] : '';
      final notes = parts.length > 3 ? parts[3] : '';
      
      return {
        'dateTime': dateTime,
        'durationMinutes': durationMinutes,
        'tags': tags,
        'notes': notes,
      };
    }).toList();
  }

  Future<List<CoachEvent>> _loadCoachEvents() async {
    // This would need to be implemented based on where coach events are stored
    // For now, return empty list as a placeholder
    return [];
  }

  // Computation helpers

  Future<int> _computeMaxStreak() async {
    final sessions = await _loadAllSessions();
    if (sessions.isEmpty) return 0;

    sessions.sort((a, b) => (a['dateTime'] as DateTime).compareTo(b['dateTime'] as DateTime));
    
    int maxStreak = 0;
    int currentStreak = 0;
    DateTime? lastDate;

    for (final session in sessions) {
      final sessionDate = session['dateTime'] as DateTime;
      final sessionDateOnly = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      
      if (lastDate == null) {
        currentStreak = 1;
      } else {
        final lastDateOnly = DateTime(lastDate.year, lastDate.month, lastDate.day);
        final daysDiff = sessionDateOnly.difference(lastDateOnly).inDays;
        
        if (daysDiff == 1) {
          currentStreak++;
        } else if (daysDiff > 1) {
          currentStreak = 1;
        }
        // If daysDiff == 0 (same day), keep current streak
      }
      
      maxStreak = maxStreak > currentStreak ? maxStreak : currentStreak;
      lastDate = sessionDate;
    }

    return maxStreak;
  }

  Future<int> _computeLongestSessionMinutes() async {
    final sessions = await _loadAllSessions();
    if (sessions.isEmpty) return 0;

    int longest = 0;
    for (final session in sessions) {
      final duration = session['durationMinutes'] as int;
      if (duration > longest) {
        longest = duration;
      }
    }

    return longest;
  }

  Future<int> _computeMaxTagUsage() async {
    final sessions = await _loadAllSessions();
    final tagCounts = <String, int>{};

    for (final session in sessions) {
      final tagsStr = session['tags'] as String;
      if (tagsStr.isNotEmpty) {
        final tags = tagsStr.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty);
        for (final tag in tags) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }
      }
    }

    return tagCounts.values.isEmpty ? 0 : tagCounts.values.reduce((a, b) => a > b ? a : b);
  }

  Future<int> _computeReflectionCount() async {
    final events = await _loadCoachEvents();
    return events.where((e) => e.outcome == CoachOutcome.closed).length;
  }

  Future<int> _computeWeeklyGoalCount() async {
    // This would need to be implemented based on where weekly goals are tracked
    // For now, return 0 as placeholder
    return 0;
  }

  Future<int> _computeEarlyRiserCount() async {
    final sessions = await _loadAllSessions();
    int earlyCount = 0;
    
    for (final session in sessions) {
      final sessionTime = session['dateTime'] as DateTime;
      if (sessionTime.hour < 8) {
        earlyCount++;
      }
    }
    
    return earlyCount;
  }

  Future<int> _computeNightOwlCount() async {
    final sessions = await _loadAllSessions();
    int nightCount = 0;
    
    for (final session in sessions) {
      final sessionTime = session['dateTime'] as DateTime;
      if (sessionTime.hour >= 22) {
        nightCount++;
      }
    }
    
    return nightCount;
  }

  Future<int> _computeConsistentWeeks() async {
    final sessions = await _loadAllSessions();
    if (sessions.isEmpty) return 0;

    // Group sessions by week
    final weeklySessionCounts = <String, int>{};
    
    for (final session in sessions) {
      final sessionTime = session['dateTime'] as DateTime;
      // Use Monday as week start
      final monday = sessionTime.subtract(Duration(days: sessionTime.weekday - 1));
      final weekKey = '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      
      weeklySessionCounts[weekKey] = (weeklySessionCounts[weekKey] ?? 0) + 1;
    }
    
    // Count weeks with 5+ sessions
    return weeklySessionCounts.values.where((count) => count >= 5).length;
  }

  Future<int> _computeMonthlyMilestones() async {
    final sessions = await _loadAllSessions();
    if (sessions.isEmpty) return 0;

    // Group sessions by month
    final monthlySessionCounts = <String, int>{};
    
    for (final session in sessions) {
      final sessionTime = session['dateTime'] as DateTime;
      final monthKey = '${sessionTime.year}-${sessionTime.month.toString().padLeft(2, '0')}';
      
      monthlySessionCounts[monthKey] = (monthlySessionCounts[monthKey] ?? 0) + 1;
    }
    
    // Count months with 30+ sessions
    return monthlySessionCounts.values.where((count) => count >= 30).length;
  }

  // Recently unlocked badges (for Coach congratulations)
  List<Badge> recentlyUnlocked({int withinMinutes = 10}) {
    final cutoff = DateTime.now().subtract(Duration(minutes: withinMinutes));
    return _store.snapshot.badges
        .where((badge) => badge.unlockedAt.isAfter(cutoff))
        .toList();
  }

  // Badge info mapping
  ({String title, String description}) _getBadgeInfo(String id) {
    switch (id) {
      case BadgeIds.firstSession:
        return (title: "First Step", description: "Completed your first focus session.");
      case BadgeIds.fiveSessions:
        return (title: "Getting Started", description: "Completed 5 focus sessions.");
      case BadgeIds.twentySessions:
        return (title: "Building Momentum", description: "Completed 20 focus sessions.");
      case BadgeIds.hundredSessions:
        return (title: "Centenarian", description: "Completed 100 focus sessions.");
      case BadgeIds.firstHourTotal:
        return (title: "First Hour", description: "Accumulated 1 hour of total focus time.");
      case BadgeIds.tenHoursTotal:
        return (title: "Deep Practitioner", description: "Accumulated 10 hours of total focus time.");
      case BadgeIds.hundredHoursTotal:
        return (title: "Master Focuser", description: "Accumulated 100 hours of total focus time.");
      case BadgeIds.firstStreak3:
        return (title: "Three in a Row", description: "Maintained a 3-day focus streak.");
      case BadgeIds.streak7:
        return (title: "Week Warrior", description: "Maintained a 7-day focus streak.");
      case BadgeIds.streak30:
        return (title: "Monthly Master", description: "Maintained a 30-day focus streak.");
      case BadgeIds.longSession25m:
        return (title: "Extended Focus", description: "Completed a 25-minute focus session.");
      case BadgeIds.longSession60m:
        return (title: "Deep Dive", description: "Completed a 60-minute focus session.");
      case BadgeIds.longSession120m:
        return (title: "Ultra Focus", description: "Completed a 2-hour focus session.");
      case BadgeIds.tagMastery10:
        return (title: "Tag Master", description: "Used the same tag on 10 different sessions.");
      case BadgeIds.reflection10:
        return (title: "Reflective Mind", description: "Completed 10 coach reflection sessions.");
      case BadgeIds.weekGoal3:
        return (title: "Goal Achiever", description: "Met your weekly goal 3 separate weeks.");
      case BadgeIds.earlyRiser:
        return (title: "Early Riser", description: "Completed 5 focus sessions before 8 AM.");
      case BadgeIds.nightOwl:
        return (title: "Night Owl", description: "Completed 5 focus sessions after 10 PM.");
      case BadgeIds.consistentWeek:
        return (title: "Consistent Week", description: "Completed 5+ sessions in a single week.");
      case BadgeIds.monthlyMilestone:
        return (title: "Monthly Milestone", description: "Completed 30+ sessions in a single month.");
      default:
        // Try animal badge patterns
        if (id.startsWith('animal.')) {
          final parts = id.split('.');
          if (parts.length >= 3) {
            final species = parts[1];
            final threshold = int.tryParse(parts[2]) ?? 0;
            return _getAnimalBadgeInfo(species, threshold);
          }
        }
        return (title: "Unknown Badge", description: "Description not available.");
    }
  }

  ({String title, String description}) _getAnimalBadgeInfo(String species, int threshold) {
    final titles = {
      1: "First Paws",
      7: "Weekly Pal", 
      30: "Loyal Companion",
      100: "Pack Leader",
    };

    final speciesEmoji = {
      'rabbit': '🐰',
      'turtle': '🐢', 
      'cat': '🐱',
      'owl': '🦉',
      'dolphin': '🐬',
      'deer': '🦌',
    };

    final emoji = speciesEmoji[species] ?? '🐾';
    final title = '${titles[threshold] ?? 'Animal Friend'} $emoji';
    final description = 'Checked in as a $species $threshold time${threshold > 1 ? 's' : ''}.';
    
    return (title: title, description: description);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Testing helpers
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  static void setTestInstance(AchievementsResolver resolver) {
    _instance = resolver;
  }

  // Force recompute for testing
  @visibleForTesting
  Future<void> forceRecompute() async {
    await _recompute();
  }
}
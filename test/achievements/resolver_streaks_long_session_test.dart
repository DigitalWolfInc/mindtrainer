import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_resolver.dart';
import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/badge_ids.dart';
import '../../lib/features/focus_session/data/focus_session_statistics_storage.dart';
import '../../lib/features/focus_session/domain/focus_session_statistics.dart';

void main() {
  group('AchievementsResolver Streaks & Long Session Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    tearDown(() {
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    group('Streak Computation', () {
      test('should award three_day_streak badge for 3+ sessions within 72 hours', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 30),  // Today
          (now.subtract(const Duration(hours: 25)), 20), // Yesterday 
          (now.subtract(const Duration(hours: 49)), 15), // Day before yesterday
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.threeDayStreak), true);
        
        final badge = snapshot.unlocked[BadgeIds.threeDayStreak]!;
        expect(badge.title, 'On a Roll');
        expect(badge.description, 'Completed sessions on 3 consecutive days.');
        expect(badge.meta?['streakDays'], 3);
      });

      test('should award seven_day_streak badge for 7+ sessions within week', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 30),   // Day 1
          (now.subtract(const Duration(hours: 25)), 20),  // Day 2
          (now.subtract(const Duration(hours: 49)), 15),  // Day 3
          (now.subtract(const Duration(hours: 73)), 25),  // Day 4
          (now.subtract(const Duration(hours: 97)), 30),  // Day 5
          (now.subtract(const Duration(hours: 121)), 20), // Day 6
          (now.subtract(const Duration(hours: 145)), 25), // Day 7
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.threeDayStreak), true);
        expect(snapshot.has(BadgeIds.sevenDayStreak), true);
        
        final badge = snapshot.unlocked[BadgeIds.sevenDayStreak]!;
        expect(badge.title, 'Week Warrior');
        expect(badge.meta?['streakDays'], 7);
      });

      test('should NOT award streak with gaps > 24 hours', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 30),   // Today
          (now.subtract(const Duration(hours: 25)), 20),  // Yesterday
          (now.subtract(const Duration(hours: 73)), 15),  // 3 days ago (gap too large)
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.threeDayStreak), false);
      });

      test('should handle single day multiple sessions correctly', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 30),  // Today - session 1
          (now.subtract(const Duration(hours: 2)), 20),  // Today - session 2 
          (now.subtract(const Duration(hours: 25)), 15), // Yesterday
          (now.subtract(const Duration(hours: 49)), 25), // Day before yesterday
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.threeDayStreak), true);
        
        // Should count as 3 days even though there are 4 sessions
        final badge = snapshot.unlocked[BadgeIds.threeDayStreak]!;
        expect(badge.meta?['streakDays'], 3);
      });
    });

    group('Long Session Awards', () {
      test('should award sixty_minute_session badge for 60+ minute session', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 60), // Exactly 60 minutes
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), true);
        
        final badge = snapshot.unlocked[BadgeIds.sixtyMinuteSession]!;
        expect(badge.title, 'Deep Dive');
        expect(badge.description, 'Completed a 60+ minute focus session.');
        expect(badge.meta?['sessionDuration'], 60);
      });

      test('should award two_hour_session badge for 120+ minute session', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 120), // Exactly 2 hours
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), true);
        expect(snapshot.has(BadgeIds.twoHourSession), true);
        
        final badge = snapshot.unlocked[BadgeIds.twoHourSession]!;
        expect(badge.title, 'Marathon Mind');
        expect(badge.meta?['sessionDuration'], 120);
      });

      test('should NOT award sixty_minute badge for 59 minute session', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 59), // Just under threshold
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), false);
      });

      test('should award badge for longest qualifying session only once', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 90),  // 90 minutes
          (now.subtract(const Duration(hours: 2)), 75),  // 75 minutes  
          (now.subtract(const Duration(hours: 3)), 120), // 120 minutes (longest)
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), true);
        expect(snapshot.has(BadgeIds.twoHourSession), true);
        
        // Should record the longest session (120 minutes)
        final longBadge = snapshot.unlocked[BadgeIds.twoHourSession]!;
        expect(longBadge.meta?['sessionDuration'], 120);
      });

      test('should handle very long sessions', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 480), // 8 hours
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), true);
        expect(snapshot.has(BadgeIds.twoHourSession), true);
        
        final badge = snapshot.unlocked[BadgeIds.twoHourSession]!;
        expect(badge.meta?['sessionDuration'], 480);
      });
    });

    group('Mixed Streak and Long Session Logic', () {
      test('should award both streak and long session badges together', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 90),  // Today - long session
          (now.subtract(const Duration(hours: 25)), 60), // Yesterday - long session
          (now.subtract(const Duration(hours: 49)), 75), // Day before - long session
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        // Should have streak badges
        expect(snapshot.has(BadgeIds.threeDayStreak), true);
        // Should have long session badges  
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), true);
      });

      test('should compute streaks correctly with mixed session lengths', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 15),   // Today - short
          (now.subtract(const Duration(hours: 25)), 120), // Yesterday - very long
          (now.subtract(const Duration(hours: 49)), 5),   // Day before - very short
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.threeDayStreak), true);
        expect(snapshot.has(BadgeIds.twoHourSession), true);
      });
    });

    group('Edge Cases and Robustness', () {
      test('should handle empty session history', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        await _setupSessionHistory([]);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.threeDayStreak), false);
        expect(snapshot.has(BadgeIds.sevenDayStreak), false);
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), false);
        expect(snapshot.has(BadgeIds.twoHourSession), false);
      });

      test('should handle single session', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 45),
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.threeDayStreak), false); // Need 3 days
        expect(snapshot.has(BadgeIds.sixtyMinuteSession), false); // Need 60+ minutes
      });

      test('should handle sessions with zero duration', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 0),   // Zero duration
          (now.subtract(const Duration(hours: 25)), 30), // Normal session
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        // Should not crash and should still process valid sessions
        expect(resolver.snapshot.has(BadgeIds.threeDayStreak), false);
      });
    });

    group('Idempotence', () {
      test('should not duplicate streak badges on recompute', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 30),
          (now.subtract(const Duration(hours: 25)), 20),
          (now.subtract(const Duration(hours: 49)), 15),
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();
        final initialCount = resolver.snapshot.count;

        // Multiple recomputes shouldn't change anything
        await resolver.forceRecompute();
        await resolver.forceRecompute();

        expect(resolver.snapshot.count, initialCount);
        expect(resolver.snapshot.has(BadgeIds.threeDayStreak), true);
      });

      test('should maintain consistent badge metadata', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          (now.subtract(const Duration(hours: 1)), 90),
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();
        final badge1 = resolver.snapshot.unlocked[BadgeIds.sixtyMinuteSession]!;

        await resolver.forceRecompute();
        final badge2 = resolver.snapshot.unlocked[BadgeIds.sixtyMinuteSession]!;

        expect(badge1.meta?['sessionDuration'], badge2.meta?['sessionDuration']);
        expect(badge1.unlockedAt, badge2.unlockedAt);
      });
    });
  });
}

// Helper function to setup session history in SharedPreferences
Future<void> _setupSessionHistory(List<(DateTime, int)> sessions) async {
  final prefs = await SharedPreferences.getInstance();
  
  final historyStrings = sessions.map((session) {
    final (dateTime, duration) = session;
    final dateStr = '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr|$duration';
  }).toList();
  
  await prefs.setStringList('session_history', historyStrings);
  
  // Also update statistics to maintain consistency
  final totalMinutes = sessions.fold<int>(0, (sum, session) => sum + session.$2);
  final sessionCount = sessions.length;
  final avgLength = sessionCount > 0 ? totalMinutes / sessionCount : 0.0;
  
  final stats = FocusSessionStatistics(
    totalFocusTimeMinutes: totalMinutes,
    averageSessionLength: avgLength,
    completedSessionsCount: sessionCount,
  );
  
  await FocusSessionStatisticsStorage.saveStatistics(stats);
}
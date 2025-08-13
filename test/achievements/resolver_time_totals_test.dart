import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_resolver.dart';
import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/badge_ids.dart';
import '../../lib/features/focus_session/data/focus_session_statistics_storage.dart';
import '../../lib/features/focus_session/domain/focus_session_statistics.dart';

void main() {
  group('AchievementsResolver Time Totals Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    tearDown(() {
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    group('Time Milestone Awards', () {
      test('should award first_hour_total badge at 1 hour (60 minutes)', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for exactly 1 hour
        await _setupTimeStats(totalTimeMinutes: 60);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstHourTotal), true);
        
        final badge = snapshot.unlocked[BadgeIds.firstHourTotal]!;
        expect(badge.title, 'First Hour');
        expect(badge.description, 'Accumulated 1 hour of total focus time.');
        expect(badge.meta?['totalHours'], 1.0);
      });

      test('should award ten_hours_total badge at 10 hours (600 minutes)', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for exactly 10 hours
        await _setupTimeStats(totalTimeMinutes: 600);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstHourTotal), true);
        expect(snapshot.has(BadgeIds.tenHoursTotal), true);
        
        final badge = snapshot.unlocked[BadgeIds.tenHoursTotal]!;
        expect(badge.title, 'Deep Practitioner');
        expect(badge.meta?['totalHours'], 10.0);
      });

      test('should award hundred_hours_total badge at 100 hours (6000 minutes)', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for exactly 100 hours
        await _setupTimeStats(totalTimeMinutes: 6000);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstHourTotal), true);
        expect(snapshot.has(BadgeIds.tenHoursTotal), true);
        expect(snapshot.has(BadgeIds.hundredHoursTotal), true);
        
        final badge = snapshot.unlocked[BadgeIds.hundredHoursTotal]!;
        expect(badge.title, 'Master Focuser');
        expect(badge.meta?['totalHours'], 100.0);
      });
    });

    group('Time Threshold Precision', () {
      test('should award badge at exact threshold (>=)', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Test each threshold exactly
        final testCases = [
          (60, BadgeIds.firstHourTotal),     // Exactly 1 hour
          (600, BadgeIds.tenHoursTotal),     // Exactly 10 hours  
          (6000, BadgeIds.hundredHoursTotal), // Exactly 100 hours
        ];

        for (final (minutes, badgeId) in testCases) {
          await _setupTimeStats(totalTimeMinutes: minutes);
          await resolver.forceRecompute();
          
          expect(resolver.snapshot.has(badgeId), true, 
                reason: 'Badge $badgeId should be awarded at exactly $minutes minutes');
        }
      });

      test('should NOT award badge just under threshold', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Test just under each threshold
        final testCases = [
          (59, BadgeIds.firstHourTotal),     // 59 minutes (< 1 hour)
          (599, BadgeIds.tenHoursTotal),     // 599 minutes (< 10 hours)
          (5999, BadgeIds.hundredHoursTotal), // 5999 minutes (< 100 hours)
        ];

        for (final (minutes, badgeId) in testCases) {
          AchievementsStore.resetInstance();
          AchievementsResolver.resetInstance();
          final newResolver = AchievementsResolver.instance;
          await newResolver.initialize();
          
          await _setupTimeStats(totalTimeMinutes: minutes);
          await newResolver.forceRecompute();
          
          expect(newResolver.snapshot.has(badgeId), false, 
                reason: 'Badge $badgeId should NOT be awarded at $minutes minutes');
        }
      });

      test('should award badge just over threshold', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Test just over each threshold
        final testCases = [
          (61, BadgeIds.firstHourTotal),     // 61 minutes (> 1 hour)
          (601, BadgeIds.tenHoursTotal),     // 601 minutes (> 10 hours)
          (6001, BadgeIds.hundredHoursTotal), // 6001 minutes (> 100 hours)
        ];

        for (final (minutes, badgeId) in testCases) {
          await _setupTimeStats(totalTimeMinutes: minutes);
          await resolver.forceRecompute();
          
          expect(resolver.snapshot.has(badgeId), true, 
                reason: 'Badge $badgeId should be awarded at $minutes minutes');
        }
      });
    });

    group('Fractional Hours', () {
      test('should handle fractional hours correctly', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // 1.5 hours = 90 minutes
        await _setupTimeStats(totalTimeMinutes: 90);
        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstHourTotal), true);
        expect(snapshot.has(BadgeIds.tenHoursTotal), false);
        
        final badge = snapshot.unlocked[BadgeIds.firstHourTotal]!;
        expect(badge.meta?['totalHours'], 1.5);
      });

      test('should store precise decimal values in metadata', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // 2 hours 15 minutes = 135 minutes = 2.25 hours
        await _setupTimeStats(totalTimeMinutes: 135);
        await resolver.forceRecompute();

        final badge = resolver.snapshot.unlocked[BadgeIds.firstHourTotal]!;
        expect(badge.meta?['totalHours'], 2.25);
      });
    });

    group('Progressive Time Awards', () {
      test('should award badges progressively as time increases', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Start with 30 minutes (no badges)
        await _setupTimeStats(totalTimeMinutes: 30);
        await resolver.forceRecompute();
        expect(resolver.snapshot.count, 0);

        // Reach 1 hour
        await _setupTimeStats(totalTimeMinutes: 60);
        await resolver.forceRecompute();
        expect(resolver.snapshot.count, 1);
        expect(resolver.snapshot.has(BadgeIds.firstHourTotal), true);

        // Reach 5 hours (no new badge yet)
        await _setupTimeStats(totalTimeMinutes: 300);
        await resolver.forceRecompute();
        expect(resolver.snapshot.count, 1);
        expect(resolver.snapshot.has(BadgeIds.tenHoursTotal), false);

        // Reach 10 hours
        await _setupTimeStats(totalTimeMinutes: 600);
        await resolver.forceRecompute();
        expect(resolver.snapshot.count, 2);
        expect(resolver.snapshot.has(BadgeIds.tenHoursTotal), true);

        // Reach 100 hours
        await _setupTimeStats(totalTimeMinutes: 6000);
        await resolver.forceRecompute();
        expect(resolver.snapshot.count, 3);
        expect(resolver.snapshot.has(BadgeIds.hundredHoursTotal), true);
      });
    });

    group('Large Time Values', () {
      test('should handle very large time totals', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // 1000 hours = 60000 minutes
        await _setupTimeStats(totalTimeMinutes: 60000);
        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstHourTotal), true);
        expect(snapshot.has(BadgeIds.tenHoursTotal), true);
        expect(snapshot.has(BadgeIds.hundredHoursTotal), true);
        
        final badge = snapshot.unlocked[BadgeIds.hundredHoursTotal]!;
        expect(badge.meta?['totalHours'], 1000.0);
      });

      test('should handle maximum integer time values', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Very large time value
        await _setupTimeStats(totalTimeMinutes: 999999);
        await resolver.forceRecompute();

        // Should award all time badges
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstHourTotal), true);
        expect(snapshot.has(BadgeIds.tenHoursTotal), true);
        expect(snapshot.has(BadgeIds.hundredHoursTotal), true);
      });
    });

    group('Zero and Edge Cases', () {
      test('should handle zero time gracefully', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        await _setupTimeStats(totalTimeMinutes: 0);
        await resolver.forceRecompute();

        expect(resolver.snapshot.count, 0);
        expect(resolver.snapshot.has(BadgeIds.firstHourTotal), false);
      });

      test('should handle negative time values gracefully', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // This shouldn't happen in real usage, but test robustness
        final stats = FocusSessionStatistics(
          totalFocusTimeMinutes: -10,
          averageSessionLength: 0.0,
          completedSessionsCount: 0,
        );
        await FocusSessionStatisticsStorage.saveStatistics(stats);

        await resolver.forceRecompute();

        expect(resolver.snapshot.count, 0);
        expect(resolver.snapshot.has(BadgeIds.firstHourTotal), false);
      });
    });

    group('Idempotence', () {
      test('should not duplicate time badges on recompute', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        await _setupTimeStats(totalTimeMinutes: 600); // 10 hours
        await resolver.forceRecompute();
        final initialCount = resolver.snapshot.count;

        // Multiple recomputes shouldn't change anything
        await resolver.forceRecompute();
        await resolver.forceRecompute();
        await resolver.forceRecompute();

        expect(resolver.snapshot.count, initialCount);
        expect(resolver.snapshot.has(BadgeIds.firstHourTotal), true);
        expect(resolver.snapshot.has(BadgeIds.tenHoursTotal), true);
      });

      test('should maintain badge metadata consistency', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        await _setupTimeStats(totalTimeMinutes: 150); // 2.5 hours
        await resolver.forceRecompute();
        
        final badge1 = resolver.snapshot.unlocked[BadgeIds.firstHourTotal]!;
        
        // Recompute shouldn't change the badge
        await resolver.forceRecompute();
        final badge2 = resolver.snapshot.unlocked[BadgeIds.firstHourTotal]!;
        
        expect(badge1.meta?['totalHours'], badge2.meta?['totalHours']);
        expect(badge1.unlockedAt, badge2.unlockedAt);
      });
    });
  });
}

// Helper function to setup time statistics
Future<void> _setupTimeStats({required int totalTimeMinutes}) async {
  final sessions = totalTimeMinutes > 0 ? (totalTimeMinutes / 30).ceil() : 0;
  final avgLength = sessions > 0 ? totalTimeMinutes / sessions : 0.0;
  
  final stats = FocusSessionStatistics(
    totalFocusTimeMinutes: totalTimeMinutes,
    averageSessionLength: avgLength,
    completedSessionsCount: sessions,
  );
  
  await FocusSessionStatisticsStorage.saveStatistics(stats);
}
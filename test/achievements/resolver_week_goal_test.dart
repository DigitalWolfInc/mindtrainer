import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_resolver.dart';
import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/badge_ids.dart';

void main() {
  group('AchievementsResolver Weekly Goals Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    tearDown(() {
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    group('Weekly Goal Achievement', () {
      test('should award weekly_warrior badge for meeting weekly goal', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Simulate meeting a weekly goal
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 5,
          actualValue: 5,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        
        final badge = snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.title, 'Weekly Warrior');
        expect(badge.description, 'Achieved a weekly practice goal.');
        expect(badge.meta?['goalType'], 'sessions');
        expect(badge.meta?['targetValue'], 5);
        expect(badge.meta?['actualValue'], 5);
      });

      test('should award badge for exceeding weekly goal', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Simulate exceeding a weekly goal
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'minutes',
          targetValue: 180,
          actualValue: 220,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        
        final badge = snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.meta?['goalType'], 'minutes');
        expect(badge.meta?['targetValue'], 180);
        expect(badge.meta?['actualValue'], 220);
      });

      test('should handle different goal types', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final testCases = [
          ('sessions', 7, 8),
          ('minutes', 300, 350),
          ('days', 5, 6),
          ('custom', 10, 12),
        ];

        for (final (goalType, target, actual) in testCases) {
          // Reset resolver for each test
          AchievementsStore.resetInstance();
          AchievementsResolver.resetInstance();
          final newResolver = AchievementsResolver.instance;
          await newResolver.initialize();

          await newResolver.onWeeklyGoalAchieved(
            weekStart: DateTime.now().subtract(const Duration(days: 7)),
            goalType: goalType,
            targetValue: target,
            actualValue: actual,
          );

          final snapshot = newResolver.snapshot;
          expect(snapshot.has(BadgeIds.weeklyWarrior), true,
              reason: 'Should award badge for $goalType goal');
          
          final badge = snapshot.unlocked[BadgeIds.weeklyWarrior]!;
          expect(badge.meta?['goalType'], goalType);
          expect(badge.meta?['targetValue'], target);
          expect(badge.meta?['actualValue'], actual);
        }
      });

      test('should record achievement timestamp correctly', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final beforeTime = DateTime.now();
        
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 3,
          actualValue: 4,
        );

        final afterTime = DateTime.now();

        final badge = resolver.snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.unlockedAt.isAfter(beforeTime.subtract(const Duration(seconds: 1))), true);
        expect(badge.unlockedAt.isBefore(afterTime.add(const Duration(seconds: 1))), true);
      });

      test('should persist weekly goal achievements', () async {
        // First instance
        final resolver1 = AchievementsResolver.instance;
        await resolver1.initialize();

        await resolver1.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 5,
          actualValue: 6,
        );

        expect(resolver1.snapshot.has(BadgeIds.weeklyWarrior), true);

        // Reset and create new instance
        AchievementsResolver.resetInstance();
        final resolver2 = AchievementsResolver.instance;
        await resolver2.initialize();

        // Should maintain the badge
        expect(resolver2.snapshot.has(BadgeIds.weeklyWarrior), true);
        
        final badge = resolver2.snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.meta?['goalType'], 'sessions');
        expect(badge.meta?['targetValue'], 5);
      });
    });

    group('Edge Cases and Robustness', () {
      test('should handle zero target values gracefully', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // This shouldn't happen in real usage, but test robustness
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 0,
          actualValue: 1,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        
        final badge = snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.meta?['targetValue'], 0);
        expect(badge.meta?['actualValue'], 1);
      });

      test('should handle negative values gracefully', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // This shouldn't happen in real usage, but test robustness
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: -5,
          actualValue: -3,
        );

        // Should not crash
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
      });

      test('should handle very large values', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'minutes',
          targetValue: 999999,
          actualValue: 1000000,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        
        final badge = snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.meta?['targetValue'], 999999);
        expect(badge.meta?['actualValue'], 1000000);
      });

      test('should handle empty goal type', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: '',
          targetValue: 5,
          actualValue: 6,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        
        final badge = snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.meta?['goalType'], '');
      });

      test('should handle future week start dates', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final futureDate = DateTime.now().add(const Duration(days: 7));
        
        await resolver.onWeeklyGoalAchieved(
          weekStart: futureDate,
          goalType: 'sessions',
          targetValue: 3,
          actualValue: 4,
        );

        // Should still award the badge
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
      });

      test('should handle very old week start dates', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final oldDate = DateTime.now().subtract(const Duration(days: 365));
        
        await resolver.onWeeklyGoalAchieved(
          weekStart: oldDate,
          goalType: 'sessions',
          targetValue: 2,
          actualValue: 3,
        );

        // Should still award the badge
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
      });
    });

    group('Multiple Achievements', () {
      test('should award multiple weekly warrior badges for different weeks', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // First week achievement
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 14)),
          goalType: 'sessions',
          targetValue: 5,
          actualValue: 6,
        );

        expect(resolver.snapshot.has(BadgeIds.weeklyWarrior), true);

        // Second week achievement (should update metadata to most recent)
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'minutes',
          targetValue: 180,
          actualValue: 200,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        expect(snapshot.count, 1); // Should still be just one badge
        
        // Should have metadata from the most recent achievement
        final badge = snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge.meta?['goalType'], 'minutes');
        expect(badge.meta?['targetValue'], 180);
        expect(badge.meta?['actualValue'], 200);
      });

      test('should combine with other achievements', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Trigger a session completion to potentially award other badges
        await resolver.onSessionCompleted(
          completedAt: DateTime.now(),
          durationMinutes: 30,
          tags: ['focus'],
          note: 'Good session',
        );

        // Trigger a weekly goal achievement
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 3,
          actualValue: 4,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        
        // Badge should exist alongside any others that might have been awarded
        expect(snapshot.count, greaterThanOrEqualTo(1));
      });
    });

    group('Idempotence and Consistency', () {
      test('should not duplicate weekly warrior badges on multiple calls', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Award the badge
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 5,
          actualValue: 6,
        );

        final initialCount = resolver.snapshot.count;
        final initialBadge = resolver.snapshot.unlocked[BadgeIds.weeklyWarrior]!;

        // Call again with same parameters
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 5,
          actualValue: 6,
        );

        expect(resolver.snapshot.count, initialCount);
        
        final finalBadge = resolver.snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(finalBadge.unlockedAt, initialBadge.unlockedAt); // Should not change
      });

      test('should maintain badge consistency across recomputes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'minutes',
          targetValue: 120,
          actualValue: 150,
        );

        final badge1 = resolver.snapshot.unlocked[BadgeIds.weeklyWarrior]!;

        // Force recompute shouldn't affect this badge
        await resolver.forceRecompute();

        final badge2 = resolver.snapshot.unlocked[BadgeIds.weeklyWarrior]!;
        expect(badge1.unlockedAt, badge2.unlockedAt);
        expect(badge1.meta?['goalType'], badge2.meta?['goalType']);
        expect(badge1.meta?['targetValue'], badge2.meta?['targetValue']);
      });
    });

    group('Integration with Coach System', () {
      test('should handle coach events alongside weekly goals', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Simulate coach event
        await resolver.onCoachEvent(
          eventType: 'streak_celebrated',
          metadata: {'streakLength': 7},
        );

        // Simulate weekly goal
        await resolver.onWeeklyGoalAchieved(
          weekStart: DateTime.now().subtract(const Duration(days: 7)),
          goalType: 'sessions',
          targetValue: 7,
          actualValue: 8,
        );

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.weeklyWarrior), true);
        
        // Should not interfere with each other
        expect(snapshot.count, greaterThanOrEqualTo(1));
      });
    });
  });
}
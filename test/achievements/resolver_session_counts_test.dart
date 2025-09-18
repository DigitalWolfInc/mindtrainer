import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_resolver.dart';
import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/badge_ids.dart';
import '../../lib/features/focus_session/data/focus_session_statistics_storage.dart';
import '../../lib/features/focus_session/domain/focus_session_statistics.dart';

void main() {
  group('AchievementsResolver Session Counts Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    tearDown(() {
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    group('Session Count Milestones', () {
      test('should award first_session badge after 1 session', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for 1 session
        await _setupSessionStats(completedSessions: 1, totalTimeMinutes: 30);

        // Trigger recompute
        await resolver.forceRecompute();

        // Check badge was awarded
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstSession), true);
        
        final badge = snapshot.unlocked[BadgeIds.firstSession]!;
        expect(badge.title, 'First Step');
        expect(badge.description, 'Completed your first focus session.');
        expect(badge.meta?['sessionCount'], 1);
      });

      test('should award five_sessions badge after 5 sessions', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for 5 sessions
        await _setupSessionStats(completedSessions: 5, totalTimeMinutes: 150);

        // Trigger recompute
        await resolver.forceRecompute();

        // Check both badges are awarded
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstSession), true);
        expect(snapshot.has(BadgeIds.fiveSessions), true);
        
        final badge = snapshot.unlocked[BadgeIds.fiveSessions]!;
        expect(badge.title, 'Getting Started');
        expect(badge.meta?['sessionCount'], 5);
      });

      test('should award twenty_sessions badge after 20 sessions', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for 20 sessions
        await _setupSessionStats(completedSessions: 20, totalTimeMinutes: 600);

        // Trigger recompute
        await resolver.forceRecompute();

        // Check all relevant badges are awarded
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstSession), true);
        expect(snapshot.has(BadgeIds.fiveSessions), true);
        expect(snapshot.has(BadgeIds.twentySessions), true);
        
        final badge = snapshot.unlocked[BadgeIds.twentySessions]!;
        expect(badge.title, 'Building Momentum');
        expect(badge.meta?['sessionCount'], 20);
      });

      test('should award hundred_sessions badge after 100 sessions', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for 100 sessions
        await _setupSessionStats(completedSessions: 100, totalTimeMinutes: 3000);

        // Trigger recompute
        await resolver.forceRecompute();

        // Check all badges are awarded
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstSession), true);
        expect(snapshot.has(BadgeIds.fiveSessions), true);
        expect(snapshot.has(BadgeIds.twentySessions), true);
        expect(snapshot.has(BadgeIds.hundredSessions), true);
        
        final badge = snapshot.unlocked[BadgeIds.hundredSessions]!;
        expect(badge.title, 'Centenarian');
        expect(badge.meta?['sessionCount'], 100);
      });
    });

    group('Threshold Boundaries', () {
      test('should not award five_sessions badge with only 4 sessions', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for 4 sessions (just under threshold)
        await _setupSessionStats(completedSessions: 4, totalTimeMinutes: 120);

        // Trigger recompute
        await resolver.forceRecompute();

        // Check only first_session badge is awarded
        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.firstSession), true);
        expect(snapshot.has(BadgeIds.fiveSessions), false);
      });

      test('should award badges at exact thresholds', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Test each threshold exactly
        final thresholds = [
          (1, BadgeIds.firstSession),
          (5, BadgeIds.fiveSessions),
          (20, BadgeIds.twentySessions),
          (100, BadgeIds.hundredSessions),
        ];

        for (final (count, badgeId) in thresholds) {
          await _setupSessionStats(completedSessions: count, totalTimeMinutes: count * 30);
          await resolver.forceRecompute();
          
          final snapshot = resolver.snapshot;
          expect(snapshot.has(badgeId), true, reason: 'Badge $badgeId should be awarded at exactly $count sessions');
        }
      });
    });

    group('Idempotent Awards', () {
      test('should not duplicate badges on multiple recomputes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup statistics for 5 sessions
        await _setupSessionStats(completedSessions: 5, totalTimeMinutes: 150);

        // Multiple recomputes
        await resolver.forceRecompute();
        final firstSnapshot = resolver.snapshot;
        
        await resolver.forceRecompute();
        await resolver.forceRecompute();
        final finalSnapshot = resolver.snapshot;

        // Should have same badges
        expect(finalSnapshot.count, firstSnapshot.count);
        expect(finalSnapshot.has(BadgeIds.firstSession), true);
        expect(finalSnapshot.has(BadgeIds.fiveSessions), true);
      });

      test('should award new badges when session count increases', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Start with 1 session
        await _setupSessionStats(completedSessions: 1, totalTimeMinutes: 30);
        await resolver.forceRecompute();
        
        expect(resolver.snapshot.count, 1);
        expect(resolver.snapshot.has(BadgeIds.firstSession), true);

        // Increase to 5 sessions
        await _setupSessionStats(completedSessions: 5, totalTimeMinutes: 150);
        await resolver.forceRecompute();
        
        expect(resolver.snapshot.count, 2);
        expect(resolver.snapshot.has(BadgeIds.firstSession), true);
        expect(resolver.snapshot.has(BadgeIds.fiveSessions), true);

        // Increase to 20 sessions
        await _setupSessionStats(completedSessions: 20, totalTimeMinutes: 600);
        await resolver.forceRecompute();
        
        expect(resolver.snapshot.count, 3);
        expect(resolver.snapshot.has(BadgeIds.twentySessions), true);
      });
    });

    group('Persistence', () {
      test('should maintain badges across resolver instances', () async {
        // First instance
        final resolver1 = AchievementsResolver.instance;
        await resolver1.initialize();

        await _setupSessionStats(completedSessions: 5, totalTimeMinutes: 150);
        await resolver1.forceRecompute();
        
        expect(resolver1.snapshot.count, 2);

        // Reset and create new instance
        AchievementsResolver.resetInstance();
        final resolver2 = AchievementsResolver.instance;
        await resolver2.initialize();

        // Should maintain same badges
        expect(resolver2.snapshot.count, 2);
        expect(resolver2.snapshot.has(BadgeIds.firstSession), true);
        expect(resolver2.snapshot.has(BadgeIds.fiveSessions), true);
      });
    });

    group('Edge Cases', () {
      test('should handle zero sessions gracefully', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // No sessions completed
        await _setupSessionStats(completedSessions: 0, totalTimeMinutes: 0);
        await resolver.forceRecompute();

        // Should have no badges
        expect(resolver.snapshot.count, 0);
        expect(resolver.snapshot.has(BadgeIds.firstSession), false);
      });

      test('should handle very large session counts', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Very large number of sessions
        await _setupSessionStats(completedSessions: 1000, totalTimeMinutes: 30000);
        await resolver.forceRecompute();

        // Should award all session count badges
        expect(resolver.snapshot.has(BadgeIds.firstSession), true);
        expect(resolver.snapshot.has(BadgeIds.fiveSessions), true);
        expect(resolver.snapshot.has(BadgeIds.twentySessions), true);
        expect(resolver.snapshot.has(BadgeIds.hundredSessions), true);
      });

      test('should handle statistics loading errors gracefully', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Don't setup any statistics (should default to empty)
        await resolver.forceRecompute();

        // Should not crash and have no badges
        expect(resolver.snapshot.count, 0);
      });
    });

    group('Session Completion Integration', () {
      test('should trigger recompute when session is completed', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        // Setup initial state with no sessions
        await _setupSessionStats(completedSessions: 0, totalTimeMinutes: 0);

        // Simulate session completion
        await resolver.onSessionCompleted(
          completedAt: DateTime.now(),
          durationMinutes: 30,
          tags: ['focus', 'work'],
          note: 'Good session',
        );

        // Update stats to reflect the completion
        await _setupSessionStats(completedSessions: 1, totalTimeMinutes: 30);

        // Wait a bit for debounced recompute (50ms + buffer)
        await Future.delayed(const Duration(milliseconds: 100));

        // Should have awarded first session badge
        expect(resolver.snapshot.has(BadgeIds.firstSession), true);
      });
    });
  });
}

// Helper function to setup session statistics
Future<void> _setupSessionStats({
  required int completedSessions,
  required int totalTimeMinutes,
}) async {
  final stats = FocusSessionStatistics(
    totalFocusTimeMinutes: totalTimeMinutes,
    averageSessionLength: completedSessions > 0 ? totalTimeMinutes / completedSessions : 0.0,
    completedSessionsCount: completedSessions,
  );
  
  await FocusSessionStatisticsStorage.saveStatistics(stats);
}
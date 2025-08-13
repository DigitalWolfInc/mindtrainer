import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_resolver.dart';
import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/badge_ids.dart';
import '../../lib/foundation/clock.dart';

void main() {
  group('Time-based Badges', () {
    late AchievementsResolver resolver;
    late FakeClock fakeClock;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      
      fakeClock = FakeClock(DateTime(2024, 1, 1, 12, 0));
      resolver = AchievementsResolver.createWithClock(fakeClock);
      await resolver.initialize();
    });

    tearDown(() {
      AchievementsResolver.resetInstance();
      AchievementsStore.resetInstance();
    });

    test('early riser badge unlocks after 5 morning sessions', () async {
      // Create 5 session records before 8 AM
      await _createSessionHistory([
        '2024-01-01T07:00:00.000Z|30|focus,morning|Great morning session',
        '2024-01-02T06:30:00.000Z|25|focus,early|Another early session',
        '2024-01-03T07:30:00.000Z|20|focus|Early again',
        '2024-01-04T07:15:00.000Z|35|focus,morning|Before 8 AM',
        '2024-01-05T07:45:00.000Z|15|focus|Fifth morning session',
      ]);

      await resolver.forceRecompute();

      expect(resolver.snapshot.has(BadgeIds.earlyRiser), isTrue);
    });

    test('night owl badge unlocks after 5 evening sessions', () async {
      // Create 5 session records after 10 PM
      await _createSessionHistory([
        '2024-01-01T22:00:00.000Z|30|focus,night|Late night session',
        '2024-01-02T23:30:00.000Z|25|focus,evening|Another late session',
        '2024-01-03T22:30:00.000Z|20|focus|Late again',
        '2024-01-04T23:15:00.000Z|35|focus,night|After 10 PM',
        '2024-01-05T22:45:00.000Z|15|focus|Fifth night session',
      ]);

      await resolver.forceRecompute();

      expect(resolver.snapshot.has(BadgeIds.nightOwl), isTrue);
    });

    test('consistent week badge unlocks after week with 5+ sessions', () async {
      // Create 5 sessions in the same week (Monday to Friday)
      await _createSessionHistory([
        '2024-01-01T12:00:00.000Z|30|focus|Monday session',
        '2024-01-02T12:00:00.000Z|25|focus|Tuesday session',
        '2024-01-03T12:00:00.000Z|20|focus|Wednesday session',
        '2024-01-04T12:00:00.000Z|35|focus|Thursday session',
        '2024-01-05T12:00:00.000Z|15|focus|Friday session',
      ]);

      await resolver.forceRecompute();

      expect(resolver.snapshot.has(BadgeIds.consistentWeek), isTrue);
    });

    test('monthly milestone badge unlocks after month with 30+ sessions', () async {
      // Create 30 sessions in January
      final sessions = <String>[];
      for (int day = 1; day <= 30; day++) {
        sessions.add('2024-01-${day.toString().padLeft(2, '0')}T12:00:00.000Z|20|focus|Session $day');
      }
      
      await _createSessionHistory(sessions);
      await resolver.forceRecompute();

      expect(resolver.snapshot.has(BadgeIds.monthlyMilestone), isTrue);
    });

    test('time badges do not unlock prematurely', () async {
      // Create sessions that should not trigger badges
      await _createSessionHistory([
        '2024-01-01T12:00:00.000Z|30|focus|Afternoon session', // Not early or late
        '2024-01-02T15:00:00.000Z|25|focus|Another afternoon', // Not early or late
      ]);

      await resolver.forceRecompute();

      expect(resolver.snapshot.has(BadgeIds.earlyRiser), isFalse);
      expect(resolver.snapshot.has(BadgeIds.nightOwl), isFalse);
      expect(resolver.snapshot.has(BadgeIds.consistentWeek), isFalse);
      expect(resolver.snapshot.has(BadgeIds.monthlyMilestone), isFalse);
    });
  });
}

Future<void> _createSessionHistory(List<String> sessionStrings) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('session_history', sessionStrings);
}
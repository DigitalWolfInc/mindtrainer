import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_resolver.dart';
import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/badge_ids.dart';
import '../../lib/features/focus_session/data/focus_session_statistics_storage.dart';
import '../../lib/features/focus_session/domain/focus_session_statistics.dart';

void main() {
  group('AchievementsResolver Tags & Reflections Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    tearDown(() {
      AchievementsStore.resetInstance();
      AchievementsResolver.resetInstance();
    });

    group('Tag Mastery Awards', () {
      test('should award focus_master badge for 10+ sessions with "focus" tag', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(10, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus', 'work'],
          note: 'Session ${i + 1}',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.focusMaster), true);
        
        final badge = snapshot.unlocked[BadgeIds.focusMaster]!;
        expect(badge.title, 'Focus Master');
        expect(badge.description, 'Completed 10+ sessions tagged with "focus".');
        expect(badge.meta?['tagName'], 'focus');
        expect(badge.meta?['tagCount'], 10);
      });

      test('should award meditation_master badge for 10+ sessions with "meditation" tag', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(12, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 25,
          tags: ['meditation', 'mindfulness'],
          note: 'Meditation session ${i + 1}',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.meditationMaster), true);
        
        final badge = snapshot.unlocked[BadgeIds.meditationMaster]!;
        expect(badge.title, 'Meditation Master');
        expect(badge.description, 'Completed 10+ sessions tagged with "meditation".');
        expect(badge.meta?['tagName'], 'meditation');
        expect(badge.meta?['tagCount'], 12);
      });

      test('should NOT award tag mastery with only 9 sessions', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(9, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus'],
          note: 'Session ${i + 1}',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.focusMaster), false);
      });

      test('should count case-insensitive tag matching', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          SessionData(
            dateTime: now.subtract(const Duration(hours: 1)),
            duration: 30,
            tags: ['Focus'], // Capital F
            note: 'Session 1',
          ),
          SessionData(
            dateTime: now.subtract(const Duration(hours: 2)),
            duration: 30,
            tags: ['FOCUS'], // All caps
            note: 'Session 2',
          ),
          SessionData(
            dateTime: now.subtract(const Duration(hours: 3)),
            duration: 30,
            tags: ['focus'], // Lowercase
            note: 'Session 3',
          ),
          ...List.generate(7, (i) => SessionData(
            dateTime: now.subtract(Duration(hours: i + 4)),
            duration: 30,
            tags: ['focus'],
            note: 'Session ${i + 4}',
          )),
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.focusMaster), true);
        
        final badge = snapshot.unlocked[BadgeIds.focusMaster]!;
        expect(badge.meta?['tagCount'], 10);
      });

      test('should handle sessions with multiple tags correctly', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(10, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus', 'meditation', 'work'],
          note: 'Session ${i + 1}',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        // Should award both badges since all sessions have both tags
        expect(snapshot.has(BadgeIds.focusMaster), true);
        expect(snapshot.has(BadgeIds.meditationMaster), true);
      });

      test('should handle empty and null tags gracefully', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          SessionData(
            dateTime: now.subtract(const Duration(hours: 1)),
            duration: 30,
            tags: [], // Empty tags
            note: 'Session 1',
          ),
          SessionData(
            dateTime: now.subtract(const Duration(hours: 2)),
            duration: 30,
            tags: null, // Null tags
            note: 'Session 2',
          ),
          ...List.generate(10, (i) => SessionData(
            dateTime: now.subtract(Duration(hours: i + 3)),
            duration: 30,
            tags: ['focus'],
            note: 'Session ${i + 3}',
          )),
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.focusMaster), true);
        
        final badge = snapshot.unlocked[BadgeIds.focusMaster]!;
        expect(badge.meta?['tagCount'], 10); // Should count only the tagged sessions
      });
    });

    group('Reflection Awards', () {
      test('should award reflection_writer badge for 5+ sessions with notes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(5, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus'],
          note: 'This is my reflection for session ${i + 1}. I learned something important today.',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.reflectionWriter), true);
        
        final badge = snapshot.unlocked[BadgeIds.reflectionWriter]!;
        expect(badge.title, 'Reflection Writer');
        expect(badge.description, 'Written thoughtful notes for 5+ sessions.');
        expect(badge.meta?['reflectionCount'], 5);
      });

      test('should award deep_thinker badge for 20+ sessions with notes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(22, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus'],
          note: 'Deep reflection ${i + 1}: Today I discovered new insights about mindfulness.',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.reflectionWriter), true);
        expect(snapshot.has(BadgeIds.deepThinker), true);
        
        final badge = snapshot.unlocked[BadgeIds.deepThinker]!;
        expect(badge.title, 'Deep Thinker');
        expect(badge.meta?['reflectionCount'], 22);
      });

      test('should NOT count empty or whitespace-only notes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          SessionData(
            dateTime: now.subtract(const Duration(hours: 1)),
            duration: 30,
            tags: ['focus'],
            note: '', // Empty note
          ),
          SessionData(
            dateTime: now.subtract(const Duration(hours: 2)),
            duration: 30,
            tags: ['focus'],
            note: '   ', // Whitespace only
          ),
          SessionData(
            dateTime: now.subtract(const Duration(hours: 3)),
            duration: 30,
            tags: ['focus'],
            note: null, // Null note
          ),
          ...List.generate(5, (i) => SessionData(
            dateTime: now.subtract(Duration(hours: i + 4)),
            duration: 30,
            tags: ['focus'],
            note: 'Good session ${i + 1}',
          )),
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.reflectionWriter), true);
        
        final badge = snapshot.unlocked[BadgeIds.reflectionWriter]!;
        expect(badge.meta?['reflectionCount'], 5); // Should count only non-empty notes
      });

      test('should count minimal meaningful notes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = [
          SessionData(
            dateTime: now.subtract(const Duration(hours: 1)),
            duration: 30,
            tags: ['focus'],
            note: 'ok', // Very short but meaningful
          ),
          SessionData(
            dateTime: now.subtract(const Duration(hours: 2)),
            duration: 30,
            tags: ['focus'],
            note: 'Good!', // Short but meaningful
          ),
          ...List.generate(3, (i) => SessionData(
            dateTime: now.subtract(Duration(hours: i + 3)),
            duration: 30,
            tags: ['focus'],
            note: 'Session ${i + 1}',
          )),
        ];

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.reflectionWriter), true);
        
        final badge = snapshot.unlocked[BadgeIds.reflectionWriter]!;
        expect(badge.meta?['reflectionCount'], 5);
      });
    });

    group('Mixed Tag and Reflection Logic', () {
      test('should award both tag mastery and reflection badges together', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(10, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus', 'meditation'],
          note: 'Reflection ${i + 1}: Great session with good focus.',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        // Should have tag mastery badges
        expect(snapshot.has(BadgeIds.focusMaster), true);
        expect(snapshot.has(BadgeIds.meditationMaster), true);
        // Should have reflection badges
        expect(snapshot.has(BadgeIds.reflectionWriter), true);
      });

      test('should handle sessions with tags but no notes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(10, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus'],
          note: null, // No notes
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.focusMaster), true);
        expect(snapshot.has(BadgeIds.reflectionWriter), false);
      });
    });

    group('Edge Cases', () {
      test('should handle sessions with duplicate tags', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(10, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus', 'focus', 'Focus'], // Duplicates with different cases
          note: 'Session ${i + 1}',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.focusMaster), true);
        
        final badge = snapshot.unlocked[BadgeIds.focusMaster]!;
        expect(badge.meta?['tagCount'], 10); // Should count each session once
      });

      test('should handle very long notes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final longNote = 'This is a very long note ' * 100; // Very long string
        
        final sessions = List.generate(5, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus'],
          note: longNote,
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        final snapshot = resolver.snapshot;
        expect(snapshot.has(BadgeIds.reflectionWriter), true);
      });

      test('should handle special characters in tags and notes', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(10, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus@work', 'deep-focus', 'focus_session'],
          note: 'Note with émojis 😊 and special chars: ñáéíóú!@#\$%',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();

        // Should not crash and should process normally
        expect(resolver.snapshot.has(BadgeIds.reflectionWriter), true);
      });
    });

    group('Idempotence', () {
      test('should not duplicate tag and reflection badges on recompute', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(10, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus'],
          note: 'Reflection ${i + 1}',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();
        final initialCount = resolver.snapshot.count;

        // Multiple recomputes shouldn't change anything
        await resolver.forceRecompute();
        await resolver.forceRecompute();

        expect(resolver.snapshot.count, initialCount);
        expect(resolver.snapshot.has(BadgeIds.focusMaster), true);
        expect(resolver.snapshot.has(BadgeIds.reflectionWriter), true);
      });

      test('should maintain badge metadata consistency', () async {
        final resolver = AchievementsResolver.instance;
        await resolver.initialize();

        final now = DateTime.now();
        final sessions = List.generate(12, (i) => SessionData(
          dateTime: now.subtract(Duration(hours: i + 1)),
          duration: 30,
          tags: ['focus'],
          note: 'Note ${i + 1}',
        ));

        await _setupSessionHistory(sessions);

        await resolver.forceRecompute();
        final badge1 = resolver.snapshot.unlocked[BadgeIds.focusMaster]!;

        await resolver.forceRecompute();
        final badge2 = resolver.snapshot.unlocked[BadgeIds.focusMaster]!;

        expect(badge1.meta?['tagCount'], badge2.meta?['tagCount']);
        expect(badge1.unlockedAt, badge2.unlockedAt);
      });
    });
  });
}

// Helper class for session data
class SessionData {
  final DateTime dateTime;
  final int duration;
  final List<String>? tags;
  final String? note;

  const SessionData({
    required this.dateTime,
    required this.duration,
    this.tags,
    this.note,
  });
}

// Helper function to setup session history in SharedPreferences
Future<void> _setupSessionHistory(List<SessionData> sessions) async {
  final prefs = await SharedPreferences.getInstance();
  
  final historyStrings = sessions.map((session) {
    final dateStr = '${session.dateTime.year.toString().padLeft(4, '0')}-${session.dateTime.month.toString().padLeft(2, '0')}-${session.dateTime.day.toString().padLeft(2, '0')} ${session.dateTime.hour.toString().padLeft(2, '0')}:${session.dateTime.minute.toString().padLeft(2, '0')}';
    
    final tags = session.tags?.join(',') ?? '';
    final note = session.note ?? '';
    
    if (tags.isEmpty && note.isEmpty) {
      return '$dateStr|${session.duration}';
    }
    
    return '$dateStr|${session.duration}|$tags|$note';
  }).toList();
  
  await prefs.setStringList('session_history', historyStrings);
  
  // Also update statistics to maintain consistency
  final totalMinutes = sessions.fold<int>(0, (sum, session) => sum + session.duration);
  final sessionCount = sessions.length;
  final avgLength = sessionCount > 0 ? totalMinutes / sessionCount : 0.0;
  
  final stats = FocusSessionStatistics(
    totalFocusTimeMinutes: totalMinutes,
    averageSessionLength: avgLength,
    completedSessionsCount: sessionCount,
  );
  
  await FocusSessionStatisticsStorage.saveStatistics(stats);
}
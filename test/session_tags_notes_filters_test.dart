import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindtrainer/core/session_tags.dart';

void main() {
  group('Session Tags, Notes & Filters', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    group('Add/Remove Tags', () {
      test('should add tag to session (idempotent)', () async {
        // Setup session data
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Add first tag
        final result1 = await SessionTagsService.addTag(sessionId, 'focus');
        expect(result1, true);

        // Verify tag was added
        final updatedSessions1 = await SessionTagsService.loadSessions();
        expect(updatedSessions1.first.tags, contains('focus'));

        // Add same tag again (idempotent)
        final result2 = await SessionTagsService.addTag(sessionId, 'focus');
        expect(result2, true);

        // Verify no duplicate
        final updatedSessions2 = await SessionTagsService.loadSessions();
        expect(updatedSessions2.first.tags, ['focus']);

        // Add second tag
        final result3 = await SessionTagsService.addTag(sessionId, 'deep-work');
        expect(result3, true);

        // Verify both tags exist
        final updatedSessions3 = await SessionTagsService.loadSessions();
        expect(updatedSessions3.first.tags, containsAll(['focus', 'deep-work']));
      });

      test('should remove tag from session (no-op for non-existent)', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45|focus,deep-work|Study session'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Remove existing tag
        final result1 = await SessionTagsService.removeTag(sessionId, 'focus');
        expect(result1, true);

        // Verify tag was removed
        final updatedSessions1 = await SessionTagsService.loadSessions();
        expect(updatedSessions1.first.tags, ['deep-work']);

        // Remove non-existent tag (no-op)
        final result2 = await SessionTagsService.removeTag(sessionId, 'nonexistent');
        expect(result2, true);

        // Verify no change
        final updatedSessions2 = await SessionTagsService.loadSessions();
        expect(updatedSessions2.first.tags, ['deep-work']);
      });

      test('should handle empty/whitespace tags gracefully', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Try to add empty tag
        final result1 = await SessionTagsService.addTag(sessionId, '');
        expect(result1, false);

        // Try to add whitespace-only tag
        final result2 = await SessionTagsService.addTag(sessionId, '   ');
        expect(result2, false);

        // Verify no tags were added
        final updatedSessions = await SessionTagsService.loadSessions();
        expect(updatedSessions.first.tags, isEmpty);
      });

      test('should set tags (replace all existing tags)', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45|old-tag,another-tag|'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Set new tags (replacing existing ones)
        final result = await SessionTagsService.setTags(sessionId, ['new-tag', 'focus', 'productivity']);
        expect(result, true);

        // Verify tags were replaced
        final updatedSessions = await SessionTagsService.loadSessions();
        expect(updatedSessions.first.tags, ['new-tag', 'focus', 'productivity']);
      });

      test('should clean and deduplicate tags when setting', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Set tags with duplicates and whitespace
        final result = await SessionTagsService.setTags(sessionId, [
          'focus',
          '  focus  ', // Duplicate with whitespace
          'deep-work',
          '', // Empty
          '   ', // Whitespace only
          'productivity'
        ]);
        expect(result, true);

        // Verify cleaned and deduplicated
        final updatedSessions = await SessionTagsService.loadSessions();
        expect(updatedSessions.first.tags, ['focus', 'deep-work', 'productivity']);
      });
    });

    group('Set/Clear Notes', () {
      test('should set note for session', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Set note
        final result = await SessionTagsService.setNote(sessionId, 'Working on algorithms');
        expect(result, true);

        // Verify note was set
        final updatedSessions = await SessionTagsService.loadSessions();
        expect(updatedSessions.first.note, 'Working on algorithms');
      });

      test('should clear note for session', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45||Existing note'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Verify note exists
        expect(sessions.first.note, 'Existing note');

        // Clear note
        final result = await SessionTagsService.clearNote(sessionId);
        expect(result, true);

        // Verify note was cleared
        final updatedSessions = await SessionTagsService.loadSessions();
        expect(updatedSessions.first.note, isNull);
      });

      test('should handle empty/whitespace notes', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45'],
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Set empty note (should clear)
        final result1 = await SessionTagsService.setNote(sessionId, '');
        expect(result1, true);

        final updatedSessions1 = await SessionTagsService.loadSessions();
        expect(updatedSessions1.first.note, isNull);

        // Set whitespace-only note (should clear)
        final result2 = await SessionTagsService.setNote(sessionId, '   ');
        expect(result2, true);

        final updatedSessions2 = await SessionTagsService.loadSessions();
        expect(updatedSessions2.first.note, isNull);
      });
    });

    group('Backward Compatibility', () {
      test('should load old format sessions without error', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45', // Old format (no tags/notes)
            '2024-01-14 14:15|60', // Old format
          ],
        });

        final sessions = await SessionTagsService.loadSessions();

        expect(sessions.length, 2);
        
        // First session
        expect(sessions[0].dateTime, DateTime(2024, 1, 15, 10, 30));
        expect(sessions[0].durationMinutes, 45);
        expect(sessions[0].tags, isEmpty);
        expect(sessions[0].note, isNull);
        expect(sessions[0].id, isNotEmpty);

        // Second session
        expect(sessions[1].dateTime, DateTime(2024, 1, 14, 14, 15));
        expect(sessions[1].durationMinutes, 60);
        expect(sessions[1].tags, isEmpty);
        expect(sessions[1].note, isNull);
        expect(sessions[1].id, isNotEmpty);
      });

      test('should load mixed format sessions correctly', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus,deep-work|Working on project', // New format
            '2024-01-14 14:15|60', // Old format
            '2024-01-13 16:00|30|study|', // New format, empty note
            '2024-01-12 09:15|25||Quick session', // New format, empty tags
          ],
        });

        final sessions = await SessionTagsService.loadSessions();

        expect(sessions.length, 4);
        
        // New format with both tags and note
        expect(sessions[0].tags, ['focus', 'deep-work']);
        expect(sessions[0].note, 'Working on project');

        // Old format
        expect(sessions[1].tags, isEmpty);
        expect(sessions[1].note, isNull);

        // New format with tags only
        expect(sessions[2].tags, ['study']);
        expect(sessions[2].note, isNull);

        // New format with note only
        expect(sessions[3].tags, isEmpty);
        expect(sessions[3].note, 'Quick session');
      });

      test('should operate on old format sessions without error', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|45'], // Old format
        });

        final sessions = await SessionTagsService.loadSessions();
        final sessionId = sessions.first.id;

        // Add tag to old format session
        final tagResult = await SessionTagsService.addTag(sessionId, 'retroactive-tag');
        expect(tagResult, true);

        // Set note on old format session
        final noteResult = await SessionTagsService.setNote(sessionId, 'Added later');
        expect(noteResult, true);

        // Verify updates
        final updatedSessions = await SessionTagsService.loadSessions();
        expect(updatedSessions.first.tags, ['retroactive-tag']);
        expect(updatedSessions.first.note, 'Added later');
      });
    });

    group('Filter Sessions', () {
      late List<Session> testSessions;

      setUp(() {
        testSessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 30),
            durationMinutes: 45,
            tags: ['focus', 'deep-work'],
            note: 'Working on algorithms project',
            id: 'session_1',
          ),
          Session(
            dateTime: DateTime(2024, 1, 14, 14, 15),
            durationMinutes: 60,
            tags: ['study', 'review'],
            note: 'Reviewing data structures',
            id: 'session_2',
          ),
          Session(
            dateTime: DateTime(2024, 1, 13, 16, 0),
            durationMinutes: 30,
            tags: ['focus'],
            note: 'Quick focus session',
            id: 'session_3',
          ),
          Session(
            dateTime: DateTime(2024, 1, 12, 9, 15),
            durationMinutes: 25,
            tags: [],
            note: null,
            id: 'session_4',
          ),
          Session(
            dateTime: DateTime(2024, 1, 16, 11, 45),
            durationMinutes: 90,
            tags: ['deep-work', 'project'],
            note: 'Final implementation phase',
            id: 'session_5',
          ),
        ];
      });

      test('should filter by tagsAny only', () async {
        // Filter by single tag
        final focusFilter = SessionFilter(tagsAny: ['focus']);
        final focusSessions = SessionTagsService.filterSessions(testSessions, focusFilter);
        
        expect(focusSessions.length, 2);
        expect(focusSessions.map((s) => s.id), containsAll(['session_1', 'session_3']));

        // Filter by multiple tags (any match)
        final multiTagFilter = SessionFilter(tagsAny: ['study', 'project']);
        final multiTagSessions = SessionTagsService.filterSessions(testSessions, multiTagFilter);
        
        expect(multiTagSessions.length, 2);
        expect(multiTagSessions.map((s) => s.id), containsAll(['session_2', 'session_5']));

        // Filter by non-existent tag
        final noMatchFilter = SessionFilter(tagsAny: ['nonexistent']);
        final noMatchSessions = SessionTagsService.filterSessions(testSessions, noMatchFilter);
        
        expect(noMatchSessions, isEmpty);
      });

      test('should filter by date range only', () async {
        // Filter from specific date
        final fromFilter = SessionFilter(from: DateTime(2024, 1, 14));
        final fromSessions = SessionTagsService.filterSessions(testSessions, fromFilter);
        
        expect(fromSessions.length, 3); // Sessions 1 (Jan 15), 2 (Jan 14), 5 (Jan 16)
        expect(fromSessions.map((s) => s.id), containsAll(['session_1', 'session_2', 'session_5']));
        expect(fromSessions.map((s) => s.id), isNot(contains('session_3'))); // Jan 13 is before Jan 14
        expect(fromSessions.map((s) => s.id), isNot(contains('session_4'))); // Jan 12 is before Jan 14

        // Filter to specific date
        final toFilter = SessionFilter(to: DateTime(2024, 1, 14));
        final toSessions = SessionTagsService.filterSessions(testSessions, toFilter);
        
        expect(toSessions.length, 3); // Sessions 2, 3, 4 (Jan 14, 13, 12)
        expect(toSessions.map((s) => s.id), containsAll(['session_2', 'session_3', 'session_4']));

        // Filter date range
        final rangeFilter = SessionFilter(
          from: DateTime(2024, 1, 13),
          to: DateTime(2024, 1, 15),
        );
        final rangeSessions = SessionTagsService.filterSessions(testSessions, rangeFilter);
        
        expect(rangeSessions.length, 3); // Sessions 1, 2, 3
        expect(rangeSessions.map((s) => s.id), containsAll(['session_1', 'session_2', 'session_3']));
      });

      test('should filter by noteQuery only', () async {
        // Case-insensitive substring search
        final algorithmFilter = SessionFilter(noteQuery: 'ALGORITHM');
        final algorithmSessions = SessionTagsService.filterSessions(testSessions, algorithmFilter);
        
        expect(algorithmSessions.length, 1);
        expect(algorithmSessions.first.id, 'session_1');

        // Multiple matches - sessions containing "session" in notes
        final sessionFilter = SessionFilter(noteQuery: 'session');
        final sessionSessions = SessionTagsService.filterSessions(testSessions, sessionFilter);
        
        expect(sessionSessions.length, 1);
        expect(sessionSessions.map((s) => s.id), contains('session_3'));

        // No matches
        final noMatchFilter = SessionFilter(noteQuery: 'nonexistent');
        final noMatchSessions = SessionTagsService.filterSessions(testSessions, noMatchFilter);
        
        expect(noMatchSessions, isEmpty);
      });

      test('should handle combined filters (tagsAny + date + note)', () async {
        // Combine all filter types
        final combinedFilter = SessionFilter(
          tagsAny: ['focus', 'deep-work'],
          from: DateTime(2024, 1, 14),
          noteQuery: 'working',
        );
        final combinedSessions = SessionTagsService.filterSessions(testSessions, combinedFilter);
        
        expect(combinedSessions.length, 1);
        expect(combinedSessions.first.id, 'session_1'); // Only session matching all criteria

        // Test another combination
        final partialFilter = SessionFilter(
          tagsAny: ['deep-work'],
          to: DateTime(2024, 1, 15),
        );
        final partialSessions = SessionTagsService.filterSessions(testSessions, partialFilter);
        
        expect(partialSessions.length, 1);
        expect(partialSessions.first.id, 'session_1'); // session_5 is after Jan 15
      });

      test('should treat empty tagsAny as no tag filter', () async {
        // Empty tagsAny list should return all sessions (no tag filtering)
        final emptyTagsFilter = SessionFilter(tagsAny: []);
        final allSessions = SessionTagsService.filterSessions(testSessions, emptyTagsFilter);
        
        expect(allSessions.length, testSessions.length);
      });

      test('should handle case-insensitive note search', () async {
        final upperCaseFilter = SessionFilter(noteQuery: 'WORKING');
        final lowerCaseFilter = SessionFilter(noteQuery: 'working');
        final mixedCaseFilter = SessionFilter(noteQuery: 'Working');

        final upperResults = SessionTagsService.filterSessions(testSessions, upperCaseFilter);
        final lowerResults = SessionTagsService.filterSessions(testSessions, lowerCaseFilter);
        final mixedResults = SessionTagsService.filterSessions(testSessions, mixedCaseFilter);

        // All should return the same results
        expect(upperResults.length, 1);
        expect(lowerResults.length, 1);
        expect(mixedResults.length, 1);
        expect(upperResults.first.id, 'session_1');
        expect(lowerResults.first.id, 'session_1');
        expect(mixedResults.first.id, 'session_1');
      });
    });

    group('Stability & Performance', () {
      test('should not modify original input list', () async {
        final originalSessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 30),
            durationMinutes: 45,
            tags: ['focus'],
            note: 'Test session',
            id: 'session_1',
          ),
          Session(
            dateTime: DateTime(2024, 1, 14, 14, 15),
            durationMinutes: 60,
            tags: ['study'],
            note: 'Another session',
            id: 'session_2',
          ),
        ];

        final originalLength = originalSessions.length;
        final originalFirstId = originalSessions.first.id;

        // Apply filter
        final filter = SessionFilter(tagsAny: ['focus']);
        final filteredSessions = SessionTagsService.filterSessions(originalSessions, filter);

        // Verify original list is unchanged
        expect(originalSessions.length, originalLength);
        expect(originalSessions.first.id, originalFirstId);
        expect(filteredSessions.length, 1);
        expect(filteredSessions.first.id, 'session_1');
      });

      test('should handle large session lists efficiently', () async {
        // Create 1000 test sessions
        final largeSessions = List.generate(1000, (index) {
          return Session(
            dateTime: DateTime(2024, 1, 1).add(Duration(hours: index)),
            durationMinutes: 30 + (index % 60),
            tags: index % 3 == 0 ? ['focus'] : (index % 3 == 1 ? ['study'] : []),
            note: index % 5 == 0 ? 'Note for session $index' : null,
            id: 'session_$index',
          );
        });

        // Measure filtering performance (should be O(n))
        final stopwatch = Stopwatch()..start();
        
        final filter = SessionFilter(
          tagsAny: ['focus'],
          from: DateTime(2024, 1, 10),
          noteQuery: 'Note',
        );
        
        final results = SessionTagsService.filterSessions(largeSessions, filter);
        
        stopwatch.stop();
        
        // Verify results are reasonable
        expect(results.length, greaterThan(0));
        expect(results.length, lessThan(largeSessions.length));
        
        // Performance should be reasonable (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(100)); // Should be fast
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindtrainer/features/focus_session/data/focus_session_repository_impl.dart';

void main() {
  group('Session Metadata', () {
    late FocusSessionRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = FocusSessionRepositoryImpl();
    });

    group('Save note/tags on completion', () {
      test('should save session with tags and note', () async {
        final completedAt = DateTime(2024, 1, 15, 10, 30);
        final tags = ['focus', 'deep-work', 'study'];
        const note = 'Worked on data structures course';

        await repository.saveCompletedSession(
          completedAt: completedAt,
          durationMinutes: 45,
          tags: tags,
          note: note,
        );

        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];

        expect(history.length, 1);
        expect(history[0], '2024-01-15 10:30|45|focus,deep-work,study|Worked on data structures course');
      });

      test('should save session with only tags', () async {
        final completedAt = DateTime(2024, 1, 15, 14, 15);
        final tags = ['focus', 'productivity'];

        await repository.saveCompletedSession(
          completedAt: completedAt,
          durationMinutes: 30,
          tags: tags,
          note: null,
        );

        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];

        expect(history.length, 1);
        expect(history[0], '2024-01-15 14:15|30|focus,productivity|');
      });

      test('should save session with only note', () async {
        final completedAt = DateTime(2024, 1, 15, 16, 45);
        const note = 'Quick focus session during lunch break';

        await repository.saveCompletedSession(
          completedAt: completedAt,
          durationMinutes: 25,
          tags: null,
          note: note,
        );

        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];

        expect(history.length, 1);
        expect(history[0], '2024-01-15 16:45|25||Quick focus session during lunch break');
      });

      test('should save session without tags or note (backward compatible)', () async {
        final completedAt = DateTime(2024, 1, 15, 11, 0);

        await repository.saveCompletedSession(
          completedAt: completedAt,
          durationMinutes: 60,
          tags: null,
          note: null,
        );

        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];

        expect(history.length, 1);
        expect(history[0], '2024-01-15 11:00|60'); // Old format
      });

      test('should handle empty/whitespace tags correctly', () async {
        final completedAt = DateTime(2024, 1, 15, 12, 30);
        final tags = ['focus', '', '  ', 'productivity', ' clean '];
        const note = '  Some notes with whitespace  ';

        await repository.saveCompletedSession(
          completedAt: completedAt,
          durationMinutes: 40,
          tags: tags,
          note: note,
        );

        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];

        expect(history.length, 1);
        expect(history[0], '2024-01-15 12:30|40|focus,productivity,clean|Some notes with whitespace');
      });

      test('should handle empty tags list and empty note', () async {
        final completedAt = DateTime(2024, 1, 15, 13, 15);
        final tags = <String>[];
        const note = '';

        await repository.saveCompletedSession(
          completedAt: completedAt,
          durationMinutes: 20,
          tags: tags,
          note: note,
        );

        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];

        expect(history.length, 1);
        expect(history[0], '2024-01-15 13:15|20'); // Should use old format when no metadata
      });
    });

    group('History filtering', () {
      test('should filter by single tag', () async {
        // Setup test data
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus,deep-work|Working on project A',
            '2024-01-14 14:15|30|productivity,meeting|Team standup',
            '2024-01-13 16:00|60|focus,study|Learning new framework',
            '2024-01-12 09:00|25||Quick morning session',
          ],
        });

        final sessions = await _loadSessionHistory();
        final focusSessions = _filterSessionsByTags(sessions, {'focus'});

        expect(focusSessions.length, 2);
        expect(focusSessions[0]['note'], 'Working on project A');
        expect(focusSessions[1]['note'], 'Learning new framework');
      });

      test('should filter by multiple tags (AND logic)', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus,deep-work,study|Working on project A',
            '2024-01-14 14:15|30|focus,productivity|Team standup',
            '2024-01-13 16:00|60|focus,study|Learning new framework',
            '2024-01-12 09:00|25|productivity|Quick morning session',
          ],
        });

        final sessions = await _loadSessionHistory();
        final filteredSessions = _filterSessionsByTags(sessions, {'focus', 'study'});

        expect(filteredSessions.length, 2); // Only sessions with BOTH tags
        expect(filteredSessions[0]['note'], 'Working on project A');
        expect(filteredSessions[1]['note'], 'Learning new framework');
      });

      test('should filter by note substring search', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus|Working on PROJECT Alpha',
            '2024-01-14 14:15|30|meeting|Team standup discussion',
            '2024-01-13 16:00|60|study|Learning new project management',
            '2024-01-12 09:00|25||Quick morning session',
          ],
        });

        final sessions = await _loadSessionHistory();
        final projectSessions = _filterSessionsByNote(sessions, 'project');

        expect(projectSessions.length, 2); // Case-insensitive search
        expect(projectSessions[0]['note'], 'Working on PROJECT Alpha');
        expect(projectSessions[1]['note'], 'Learning new project management');
      });

      test('should filter by both tags and note search', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus,project|Working on PROJECT Alpha',
            '2024-01-14 14:15|30|focus,meeting|Project planning session',
            '2024-01-13 16:00|60|study,project|Learning project management',
            '2024-01-12 09:00|25|focus|Quick focus session',
          ],
        });

        final sessions = await _loadSessionHistory();
        final filtered = _filterSessions(sessions, {'focus'}, 'project');

        expect(filtered.length, 2); // Must have 'focus' tag AND contain 'project' in note
        expect(filtered[0]['note'], 'Working on PROJECT Alpha');
        expect(filtered[1]['note'], 'Project planning session');
      });

      test('should return empty list when no sessions match filters', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus|Working on project A',
            '2024-01-14 14:15|30|productivity|Team meeting',
          ],
        });

        final sessions = await _loadSessionHistory();
        final filtered = _filterSessionsByTags(sessions, {'nonexistent'});

        expect(filtered, isEmpty);
      });

      test('should handle sessions without metadata in filtering', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus|Working on project A',
            '2024-01-14 14:15|30', // Old format without metadata
            '2024-01-13 16:00|60||', // New format but empty metadata
          ],
        });

        final sessions = await _loadSessionHistory();
        
        // Filter by tag should only return session with tags
        final tagFiltered = _filterSessionsByTags(sessions, {'focus'});
        expect(tagFiltered.length, 1);
        
        // Filter by note should only return session with notes
        final noteFiltered = _filterSessionsByNote(sessions, 'project');
        expect(noteFiltered.length, 1);
        
        // No filters should return all sessions
        final allSessions = _filterSessions(sessions, {}, '');
        expect(allSessions.length, 3);
      });

      test('should ignore empty/whitespace search queries', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|45|focus|Working on project A',
            '2024-01-14 14:15|30|productivity|Team meeting',
          ],
        });

        final sessions = await _loadSessionHistory();
        
        // Empty search should return all sessions
        final emptySearch = _filterSessionsByNote(sessions, '');
        expect(emptySearch.length, 2);
        
        // Whitespace-only search should return all sessions
        final whitespaceSearch = _filterSessionsByNote(sessions, '   ');
        expect(whitespaceSearch.length, 2);
      });
    });
  });
}

// Helper functions that mirror the history screen filtering logic
Future<List<Map<String, dynamic>>> _loadSessionHistory() async {
  final prefs = await SharedPreferences.getInstance();
  final historyJson = prefs.getStringList('session_history') ?? [];
  
  return historyJson.map((jsonString) {
    final parts = jsonString.split('|');
    
    // Handle backward compatibility: old format has 2 parts, new format has 4
    final tags = parts.length > 2 ? parts[2].split(',').where((tag) => tag.trim().isNotEmpty).toList() : <String>[];
    final note = parts.length > 3 ? parts[3] : '';
    
    return {
      'dateTime': DateTime.parse(parts[0]),
      'durationMinutes': int.parse(parts[1]),
      'tags': tags,
      'note': note,
    };
  }).toList();
}

List<Map<String, dynamic>> _filterSessionsByTags(List<Map<String, dynamic>> sessions, Set<String> selectedTags) {
  return sessions.where((session) {
    final tags = session['tags'] as List<String>? ?? [];
    
    // Session must have all selected tags
    if (selectedTags.isNotEmpty) {
      if (!selectedTags.every((tag) => tags.contains(tag))) {
        return false;
      }
    }
    
    return true;
  }).toList();
}

List<Map<String, dynamic>> _filterSessionsByNote(List<Map<String, dynamic>> sessions, String searchQuery) {
  final trimmedQuery = searchQuery.trim();
  if (trimmedQuery.isEmpty) return sessions;
  
  return sessions.where((session) {
    final note = session['note'] as String? ?? '';
    return note.toLowerCase().contains(trimmedQuery.toLowerCase());
  }).toList();
}

List<Map<String, dynamic>> _filterSessions(List<Map<String, dynamic>> sessions, Set<String> selectedTags, String searchQuery) {
  return sessions.where((session) {
    final tags = session['tags'] as List<String>? ?? [];
    final note = session['note'] as String? ?? '';
    
    // Filter by selected tags (session must have all selected tags)
    if (selectedTags.isNotEmpty) {
      if (!selectedTags.every((tag) => tags.contains(tag))) {
        return false;
      }
    }
    
    // Filter by search query in note
    final trimmedQuery = searchQuery.trim();
    if (trimmedQuery.isNotEmpty) {
      if (!note.toLowerCase().contains(trimmedQuery.toLowerCase())) {
        return false;
      }
    }
    
    return true;
  }).toList();
}
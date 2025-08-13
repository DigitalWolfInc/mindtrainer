import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/features/focus_session/data/focus_session_repository_impl.dart';
import '../../../lib/features/focus_session/domain/focus_session_statistics.dart';

void main() {
  group('FocusSessionRepositoryImpl Statistics Integration', () {
    late FocusSessionRepositoryImpl repository;
    
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = FocusSessionRepositoryImpl();
    });
    
    test('should update statistics when session is completed', () async {
      // Initial statistics should be empty
      final initialStats = await repository.loadStatistics();
      expect(initialStats.completedSessionsCount, equals(0));
      expect(initialStats.totalFocusTimeMinutes, equals(0));
      
      // Complete a 25-minute session
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 25,
      );
      
      // Statistics should be updated
      final updatedStats = await repository.loadStatistics();
      expect(updatedStats.completedSessionsCount, equals(1));
      expect(updatedStats.totalFocusTimeMinutes, equals(25));
      expect(updatedStats.averageSessionLength, equals(25.0));
    });
    
    test('should accumulate statistics across multiple sessions', () async {
      // Complete multiple sessions
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 20,
      );
      
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 30,
      );
      
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 10,
      );
      
      // Check accumulated statistics
      final stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, equals(3));
      expect(stats.totalFocusTimeMinutes, equals(60));
      expect(stats.averageSessionLength, equals(20.0));
    });
    
    test('should clear statistics correctly', () async {
      // Complete a session first
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 30,
      );
      
      // Verify statistics exist
      final beforeClear = await repository.loadStatistics();
      expect(beforeClear.completedSessionsCount, equals(1));
      
      // Clear statistics
      await repository.clearStatistics();
      
      // Verify statistics are cleared
      final afterClear = await repository.loadStatistics();
      expect(afterClear.completedSessionsCount, equals(0));
      expect(afterClear.totalFocusTimeMinutes, equals(0));
      expect(afterClear.averageSessionLength, equals(0.0));
    });
    
    test('should handle sessions with metadata correctly', () async {
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 35,
        tags: ['focus', 'morning'],
        note: 'Great session!',
      );
      
      final stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, equals(1));
      expect(stats.totalFocusTimeMinutes, equals(35));
      expect(stats.averageSessionLength, equals(35.0));
    });
    
    test('should maintain statistics accuracy with varying session lengths', () async {
      final sessionLengths = [5, 10, 15, 20, 25, 30, 45, 60];
      
      for (final length in sessionLengths) {
        await repository.saveCompletedSession(
          completedAt: DateTime.now(),
          durationMinutes: length,
        );
      }
      
      final stats = await repository.loadStatistics();
      final expectedTotal = sessionLengths.reduce((a, b) => a + b);
      final expectedAverage = expectedTotal / sessionLengths.length;
      
      expect(stats.completedSessionsCount, equals(sessionLengths.length));
      expect(stats.totalFocusTimeMinutes, equals(expectedTotal));
      expect(stats.averageSessionLength, equals(expectedAverage));
    });
  });
}
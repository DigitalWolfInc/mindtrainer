import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindtrainer/features/focus_session/domain/focus_session_state.dart';
import 'package:mindtrainer/features/focus_session/data/focus_session_repository_impl.dart';

void main() {
  group('FocusSessionRepositoryImpl', () {
    late FocusSessionRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = FocusSessionRepositoryImpl();
    });

    test('should return null when no active session exists', () async {
      final session = await repository.loadActiveSession();
      expect(session, isNull);
    });

    test('should save and load active session correctly', () async {
      final originalState = FocusSessionState(
        status: FocusSessionStatus.paused,
        startTime: null,
        elapsedMs: 5000,
        pausedMs: 1000,
        targetDurationMs: 10000,
      );

      await repository.saveActiveSession(originalState);
      final loadedState = await repository.loadActiveSession();

      expect(loadedState, isNotNull);
      expect(loadedState!.status, originalState.status);
      expect(loadedState.elapsedMs, originalState.elapsedMs);
      expect(loadedState.pausedMs, originalState.pausedMs);
      expect(loadedState.targetDurationMs, originalState.targetDurationMs);
    });

    test('should clear active session', () async {
      final state = FocusSessionState.idle(10000);
      
      await repository.saveActiveSession(state);
      expect(await repository.loadActiveSession(), isNotNull);
      
      await repository.clearActiveSession();
      expect(await repository.loadActiveSession(), isNull);
    });

    test('should save completed session to history', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await repository.saveCompletedSession(
        completedAt: DateTime(2024, 1, 15, 14, 30),
        durationMinutes: 25,
      );
      
      final history = prefs.getStringList('session_history') ?? [];
      expect(history.length, 1);
      expect(history.first, '2024-01-15 14:30|25');
    });

    test('should maintain history order with multiple completed sessions', () async {
      final prefs = await SharedPreferences.getInstance();
      
      await repository.saveCompletedSession(
        completedAt: DateTime(2024, 1, 15, 14, 30),
        durationMinutes: 25,
      );
      
      await repository.saveCompletedSession(
        completedAt: DateTime(2024, 1, 15, 15, 30),
        durationMinutes: 30,
      );
      
      final history = prefs.getStringList('session_history') ?? [];
      expect(history.length, 2);
      expect(history[0], '2024-01-15 15:30|30'); // Most recent first
      expect(history[1], '2024-01-15 14:30|25');
    });

    test('should handle corrupted session data gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_focus_session', 'invalid_json_data');
      
      final session = await repository.loadActiveSession();
      expect(session, isNull);
    });

    test('should restore running session with correct remaining time', () async {
      // Simulate a session that started 3 seconds ago with 10 second target
      final startTime = DateTime.now().subtract(const Duration(seconds: 3));
      final runningState = FocusSessionState(
        status: FocusSessionStatus.running,
        startTime: startTime,
        elapsedMs: 0,
        pausedMs: 0,
        targetDurationMs: 10000,
      );

      await repository.saveActiveSession(runningState);
      final restoredState = await repository.loadActiveSession();

      expect(restoredState, isNotNull);
      expect(restoredState!.status, FocusSessionStatus.running);
      expect(restoredState.startTime, isNotNull);
      
      // The remaining time should be approximately 7 seconds
      final remainingMs = restoredState.currentRemainingMs;
      expect(remainingMs, greaterThan(6000));
      expect(remainingMs, lessThan(8000));
    });

    test('should restore paused session with accumulated elapsed time', () async {
      final pausedState = FocusSessionState(
        status: FocusSessionStatus.paused,
        startTime: null,
        elapsedMs: 3000, // 3 seconds already elapsed
        pausedMs: 0,
        targetDurationMs: 10000,
      );

      await repository.saveActiveSession(pausedState);
      final restoredState = await repository.loadActiveSession();

      expect(restoredState, isNotNull);
      expect(restoredState!.status, FocusSessionStatus.paused);
      expect(restoredState.elapsedMs, 3000);
      expect(restoredState.remainingMs, 7000);
    });

    test('should update statistics when completing session', () async {
      // First session
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 25,
      );
      
      var stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, 1);
      expect(stats.totalFocusTimeMinutes, 25);
      expect(stats.averageSessionLength, 25.0);

      // Second session
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 35,
      );
      
      stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, 2);
      expect(stats.totalFocusTimeMinutes, 60);
      expect(stats.averageSessionLength, 30.0);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindtrainer/features/focus_session/domain/focus_session_state.dart';
import 'package:mindtrainer/features/focus_session/domain/focus_session_statistics.dart';
import 'package:mindtrainer/features/focus_session/data/focus_session_repository_impl.dart';

void main() {
  group('Focus Session Integration Tests', () {
    late FocusSessionRepositoryImpl repository;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repository = FocusSessionRepositoryImpl();
    });

    test('should complete full session lifecycle with history tracking', () async {
      const targetDurationMs = 5000; // 5 seconds for testing
      
      // Start session
      var sessionState = FocusSessionState.idle(targetDurationMs);
      sessionState = sessionState.start();
      await repository.saveActiveSession(sessionState);
      
      // Simulate some progress
      await Future.delayed(const Duration(milliseconds: 100));
      sessionState = sessionState.pause();
      await repository.saveActiveSession(sessionState);
      
      // Resume and run to completion
      sessionState = sessionState.start();
      await repository.saveActiveSession(sessionState);
      
      // Complete manually (simulating user completion or auto-completion)
      sessionState = sessionState.complete();
      
      // Save to history
      final durationMinutes = (sessionState.elapsedMs / 60000).round();
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: durationMinutes.clamp(1, 60), // At least 1 minute for history
      );
      
      // Clear active session
      await repository.clearActiveSession();
      
      // Verify history was written
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('session_history') ?? [];
      expect(history.length, 1);
      expect(history.first, contains('|1')); // Should contain 1 minute duration
      
      // Verify statistics were updated
      final stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, 1);
      expect(stats.totalFocusTimeMinutes, 1);
      expect(stats.averageSessionLength, 1.0);
      
      // Verify active session was cleared
      final activeSession = await repository.loadActiveSession();
      expect(activeSession, isNull);
    });

    test('should handle app restart scenario with running session', () async {
      const targetDurationMs = 10000; // 10 seconds
      
      // Simulate a session that was running when app was killed
      final startTime = DateTime.now().subtract(const Duration(seconds: 3));
      var sessionState = FocusSessionState(
        status: FocusSessionStatus.running,
        startTime: startTime,
        elapsedMs: 0,
        pausedMs: 0,
        targetDurationMs: targetDurationMs,
      );
      
      await repository.saveActiveSession(sessionState);
      
      // Simulate app restart - create new repository instance
      final newRepository = FocusSessionRepositoryImpl();
      final restoredState = await newRepository.loadActiveSession();
      
      expect(restoredState, isNotNull);
      expect(restoredState!.status, FocusSessionStatus.running);
      
      // The session should have the correct remaining time
      final remainingMs = restoredState.currentRemainingMs;
      expect(remainingMs, greaterThan(6000)); // Should be around 7 seconds left
      expect(remainingMs, lessThan(8000));
      
      // Should still be able to complete normally
      final completedState = restoredState.complete();
      expect(completedState.status, FocusSessionStatus.completed);
    });

    test('should handle app restart scenario with paused session', () async {
      const targetDurationMs = 10000; // 10 seconds
      
      // Simulate a session that was paused when app was killed
      var sessionState = FocusSessionState(
        status: FocusSessionStatus.paused,
        startTime: null,
        elapsedMs: 4000, // 4 seconds already elapsed
        pausedMs: 0,
        targetDurationMs: targetDurationMs,
      );
      
      await repository.saveActiveSession(sessionState);
      
      // Simulate app restart
      final newRepository = FocusSessionRepositoryImpl();
      final restoredState = await newRepository.loadActiveSession();
      
      expect(restoredState, isNotNull);
      expect(restoredState!.status, FocusSessionStatus.paused);
      expect(restoredState.elapsedMs, 4000);
      expect(restoredState.remainingMs, 6000);
      
      // Should be able to resume
      final resumedState = restoredState.start();
      expect(resumedState.status, FocusSessionStatus.running);
      expect(resumedState.elapsedMs, 4000); // Previous elapsed time preserved
    });

    test('should handle session that completed while app was closed', () async {
      const targetDurationMs = 1000; // 1 second for fast completion
      
      // Simulate a session that should have completed while app was closed
      final startTime = DateTime.now().subtract(const Duration(seconds: 5));
      var sessionState = FocusSessionState(
        status: FocusSessionStatus.running,
        startTime: startTime,
        elapsedMs: 0,
        pausedMs: 0,
        targetDurationMs: targetDurationMs,
      );
      
      await repository.saveActiveSession(sessionState);
      
      // Simulate app restart after session should have completed
      final newRepository = FocusSessionRepositoryImpl();
      var restoredState = await newRepository.loadActiveSession();
      
      expect(restoredState, isNotNull);
      
      // Tick should auto-complete the session
      restoredState = restoredState!.tick();
      expect(restoredState.status, FocusSessionStatus.completed);
      
      // The elapsed time should be at least the target duration
      expect(restoredState.currentElapsedMs, greaterThanOrEqualTo(targetDurationMs));
    });

    test('should maintain multiple completed sessions in correct order', () async {
      const durationMinutes1 = 25;
      const durationMinutes2 = 30;
      const durationMinutes3 = 20;
      
      final time1 = DateTime(2024, 1, 15, 9, 0);  // Oldest
      final time2 = DateTime(2024, 1, 15, 10, 0);
      final time3 = DateTime(2024, 1, 15, 11, 0); // Most recent
      
      await repository.saveCompletedSession(
        completedAt: time1,
        durationMinutes: durationMinutes1,
      );
      
      await repository.saveCompletedSession(
        completedAt: time2,
        durationMinutes: durationMinutes2,
      );
      
      await repository.saveCompletedSession(
        completedAt: time3,
        durationMinutes: durationMinutes3,
      );
      
      // Verify history order (most recent first)
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList('session_history') ?? [];
      
      expect(history.length, 3);
      expect(history[0], '2024-01-15 11:00|20'); // Most recent first
      expect(history[1], '2024-01-15 10:00|30');
      expect(history[2], '2024-01-15 09:00|25'); // Oldest last
      
      // Verify statistics are cumulative
      final stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, 3);
      expect(stats.totalFocusTimeMinutes, 75); // 25 + 30 + 20
      expect(stats.averageSessionLength, 25.0); // 75 / 3
    });

    test('should clear all data when requested', () async {
      // Setup some data
      final sessionState = FocusSessionState.idle(10000);
      await repository.saveActiveSession(sessionState);
      
      await repository.saveCompletedSession(
        completedAt: DateTime.now(),
        durationMinutes: 25,
      );
      
      // Verify data exists
      expect(await repository.loadActiveSession(), isNotNull);
      var stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, 1);
      
      // Clear everything
      await repository.clearActiveSession();
      await repository.clearStatistics();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_history');
      
      // Verify everything is cleared
      expect(await repository.loadActiveSession(), isNull);
      stats = await repository.loadStatistics();
      expect(stats.completedSessionsCount, 0);
      
      final history = prefs.getStringList('session_history') ?? [];
      expect(history.length, 0);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/focus_session/domain/focus_session_state.dart';

void main() {
  group('FocusSessionState', () {
    const targetDurationMs = 10000; // 10 seconds for testing

    test('should start in idle state', () {
      final state = FocusSessionState.idle(targetDurationMs);
      
      expect(state.status, FocusSessionStatus.idle);
      expect(state.elapsedMs, 0);
      expect(state.pausedMs, 0);
      expect(state.targetDurationMs, targetDurationMs);
      expect(state.remainingMs, targetDurationMs);
    });

    test('should transition from idle to running', () {
      final idleState = FocusSessionState.idle(targetDurationMs);
      final runningState = idleState.start();
      
      expect(runningState.status, FocusSessionStatus.running);
      expect(runningState.startTime, isNotNull);
      expect(runningState.elapsedMs, 0);
      expect(runningState.targetDurationMs, targetDurationMs);
    });

    test('should transition from running to paused', () async {
      final idleState = FocusSessionState.idle(targetDurationMs);
      final runningState = idleState.start();
      
      // Wait a bit to accumulate some elapsed time
      await Future.delayed(const Duration(milliseconds: 100));
      
      final pausedState = runningState.pause();
      
      expect(pausedState.status, FocusSessionStatus.paused);
      expect(pausedState.startTime, isNull);
      expect(pausedState.elapsedMs, greaterThan(0));
      expect(pausedState.elapsedMs, lessThan(targetDurationMs));
    });

    test('should transition from paused to running', () async {
      final idleState = FocusSessionState.idle(targetDurationMs);
      final runningState = idleState.start();
      
      await Future.delayed(const Duration(milliseconds: 50));
      final pausedState = runningState.pause();
      final elapsedBeforeResume = pausedState.elapsedMs;
      
      final resumedState = pausedState.start();
      
      expect(resumedState.status, FocusSessionStatus.running);
      expect(resumedState.startTime, isNotNull);
      expect(resumedState.elapsedMs, elapsedBeforeResume);
    });

    test('should transition to completed manually', () async {
      final idleState = FocusSessionState.idle(targetDurationMs);
      final runningState = idleState.start();
      
      await Future.delayed(const Duration(milliseconds: 50));
      
      final completedState = runningState.complete();
      
      expect(completedState.status, FocusSessionStatus.completed);
      expect(completedState.startTime, isNull);
      expect(completedState.elapsedMs, greaterThan(0));
    });

    test('should auto-complete when target duration reached', () {
      final idleState = FocusSessionState.idle(100); // 100ms for fast test
      final runningState = idleState.start();
      
      // Simulate time passing by creating a state with elapsed time >= target
      final almostCompleteState = FocusSessionState(
        status: FocusSessionStatus.running,
        startTime: DateTime.now().subtract(const Duration(milliseconds: 150)),
        elapsedMs: 0,
        pausedMs: 0,
        targetDurationMs: 100,
      );
      
      final tickedState = almostCompleteState.tick();
      
      expect(tickedState.status, FocusSessionStatus.completed);
    });

    test('should cancel from any non-idle state', () async {
      final idleState = FocusSessionState.idle(targetDurationMs);
      final runningState = idleState.start();
      
      await Future.delayed(const Duration(milliseconds: 50));
      final pausedState = runningState.pause();
      
      final cancelledFromRunning = runningState.cancel();
      final cancelledFromPaused = pausedState.cancel();
      
      expect(cancelledFromRunning.status, FocusSessionStatus.idle);
      expect(cancelledFromRunning.elapsedMs, 0);
      
      expect(cancelledFromPaused.status, FocusSessionStatus.idle);
      expect(cancelledFromPaused.elapsedMs, 0);
    });

    test('should calculate currentRemainingMs correctly while running', () {
      final state = FocusSessionState(
        status: FocusSessionStatus.running,
        startTime: DateTime.now().subtract(const Duration(milliseconds: 3000)),
        elapsedMs: 2000, // 2 seconds previous elapsed
        pausedMs: 0,
        targetDurationMs: 10000, // 10 second target
      );
      
      final remaining = state.currentRemainingMs;
      
      // Should be approximately 5000ms remaining (10000 - 2000 - 3000)
      expect(remaining, greaterThan(4000));
      expect(remaining, lessThan(6000));
    });

    test('should serialize and deserialize correctly', () {
      final originalState = FocusSessionState(
        status: FocusSessionStatus.paused,
        startTime: null,
        elapsedMs: 5000,
        pausedMs: 1000,
        targetDurationMs: 10000,
      );
      
      final json = originalState.toJson();
      final deserializedState = FocusSessionState.fromJson(json);
      
      expect(deserializedState.status, originalState.status);
      expect(deserializedState.startTime, originalState.startTime);
      expect(deserializedState.elapsedMs, originalState.elapsedMs);
      expect(deserializedState.pausedMs, originalState.pausedMs);
      expect(deserializedState.targetDurationMs, originalState.targetDurationMs);
    });
  });
}
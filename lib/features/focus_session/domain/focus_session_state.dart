enum FocusSessionStatus {
  idle,
  running,
  paused,
  completed,
}

class FocusSessionState {
  final FocusSessionStatus status;
  final DateTime? startTime;
  final int elapsedMs;
  final int pausedMs;
  final int targetDurationMs;

  const FocusSessionState({
    required this.status,
    this.startTime,
    required this.elapsedMs,
    required this.pausedMs,
    required this.targetDurationMs,
  });

  factory FocusSessionState.idle(int targetDurationMs) {
    return FocusSessionState(
      status: FocusSessionStatus.idle,
      elapsedMs: 0,
      pausedMs: 0,
      targetDurationMs: targetDurationMs,
    );
  }

  factory FocusSessionState.fromJson(Map<String, dynamic> json) {
    return FocusSessionState(
      status: FocusSessionStatus.values[json['status'] ?? 0],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      elapsedMs: json['elapsedMs'] ?? 0,
      pausedMs: json['pausedMs'] ?? 0,
      targetDurationMs: json['targetDurationMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.index,
      'startTime': startTime?.toIso8601String(),
      'elapsedMs': elapsedMs,
      'pausedMs': pausedMs,
      'targetDurationMs': targetDurationMs,
    };
  }

  int get remainingMs {
    return (targetDurationMs - elapsedMs).clamp(0, targetDurationMs);
  }

  int get currentElapsedMs {
    if (status == FocusSessionStatus.running && startTime != null) {
      final now = DateTime.now();
      final sessionRunTime = now.difference(startTime!).inMilliseconds;
      return elapsedMs + sessionRunTime;
    }
    return elapsedMs;
  }

  int get currentRemainingMs {
    return (targetDurationMs - currentElapsedMs).clamp(0, targetDurationMs);
  }

  FocusSessionState start() {
    if (status != FocusSessionStatus.idle && status != FocusSessionStatus.paused) {
      return this;
    }
    
    return FocusSessionState(
      status: FocusSessionStatus.running,
      startTime: DateTime.now(),
      elapsedMs: elapsedMs,
      pausedMs: pausedMs,
      targetDurationMs: targetDurationMs,
    );
  }

  FocusSessionState pause() {
    if (status != FocusSessionStatus.running || startTime == null) {
      return this;
    }

    final now = DateTime.now();
    final sessionRunTime = now.difference(startTime!).inMilliseconds;
    final newElapsed = elapsedMs + sessionRunTime;

    return FocusSessionState(
      status: FocusSessionStatus.paused,
      startTime: null,
      elapsedMs: newElapsed,
      pausedMs: pausedMs,
      targetDurationMs: targetDurationMs,
    );
  }

  FocusSessionState complete() {
    if (status == FocusSessionStatus.completed) {
      return this;
    }

    final finalElapsed = status == FocusSessionStatus.running ? currentElapsedMs : elapsedMs;

    return FocusSessionState(
      status: FocusSessionStatus.completed,
      startTime: null,
      elapsedMs: finalElapsed,
      pausedMs: pausedMs,
      targetDurationMs: targetDurationMs,
    );
  }

  FocusSessionState cancel() {
    return FocusSessionState.idle(targetDurationMs);
  }

  FocusSessionState tick() {
    if (status == FocusSessionStatus.running) {
      final currentElapsed = currentElapsedMs;
      if (currentElapsed >= targetDurationMs) {
        return complete();
      }
    }
    return this;
  }
}
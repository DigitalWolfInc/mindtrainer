/// Enhanced clock abstraction for testable time and delays
/// 
/// This module extends the basic Clock interface to support delays and timers,
/// making all timeout behavior deterministic and testable.

import 'dart:async';

/// Clock abstraction for testable time and delays  
abstract class Clock {
  /// Get the current time
  DateTime now();
  
  /// Create a delay for the specified duration
  Future<void> delay(Duration duration);
  
  /// Create a timer that calls the callback after the duration
  Timer timer(Duration duration, void Function() callback);
}

/// System clock using real time and real delays
class SystemClock implements Clock {
  const SystemClock();
  
  @override
  DateTime now() => DateTime.now();
  
  @override
  Future<void> delay(Duration duration) => Future.delayed(duration);
  
  @override
  Timer timer(Duration duration, void Function() callback) {
    return Timer(duration, callback);
  }
}

/// Fake clock for deterministic testing
class FakeClock implements Clock {
  DateTime _currentTime;
  final List<_ScheduledTimer> _scheduledTimers = [];
  int _nextTimerId = 0;
  
  FakeClock(DateTime initialTime) : _currentTime = initialTime;
  
  @override
  DateTime now() => _currentTime;
  
  /// Advance the fake clock by the specified duration
  /// This will trigger any scheduled timers and complete any delays
  void advance(Duration duration) {
    final newTime = _currentTime.add(duration);
    
    // Find all timers that should trigger in this time window (and are still active)
    final timersToTrigger = _scheduledTimers
        .where((timer) => 
            timer.isActive && 
            (timer.triggerTime.isBefore(newTime) || timer.triggerTime.isAtSameMomentAs(newTime)))
        .toList();
    
    // Sort by trigger time to ensure proper ordering
    timersToTrigger.sort((a, b) => a.triggerTime.compareTo(b.triggerTime));
    
    // Trigger each timer at its scheduled time
    for (final timer in timersToTrigger) {
      _currentTime = timer.triggerTime;
      timer.isActive = false; // Mark as inactive before triggering
      timer.trigger();
      _scheduledTimers.remove(timer);
    }
    
    // Update to final time
    _currentTime = newTime;
  }
  
  @override
  Future<void> delay(Duration duration) {
    final completer = Completer<void>();
    final triggerTime = _currentTime.add(duration);
    
    _scheduledTimers.add(_ScheduledTimer(
      id: _nextTimerId++,
      triggerTime: triggerTime,
      callback: () => completer.complete(),
    ));
    
    return completer.future;
  }
  
  @override
  Timer timer(Duration duration, void Function() callback) {
    final triggerTime = _currentTime.add(duration);
    final timerId = _nextTimerId++;
    
    final scheduledTimer = _ScheduledTimer(
      id: timerId,
      triggerTime: triggerTime,
      callback: () {
        callback();
      },
    );
    
    final fakeTimer = _FakeTimer(timerId, scheduledTimer);
    _scheduledTimers.add(scheduledTimer);
    
    return fakeTimer;
  }
  
  /// Get count of pending timers (for testing)
  int get pendingTimersCount => _scheduledTimers.length;
}

/// Internal scheduled timer data
class _ScheduledTimer {
  final int id;
  final DateTime triggerTime;
  final void Function() callback;
  bool isActive = true;
  
  _ScheduledTimer({
    required this.id,
    required this.triggerTime,
    required this.callback,
  });
  
  void trigger() => callback();
  
  void cancel() {
    isActive = false;
  }
}

/// Fake timer implementation
class _FakeTimer implements Timer {
  final int id;
  final _ScheduledTimer _scheduledTimer;
  
  _FakeTimer(this.id, this._scheduledTimer);
  
  @override
  bool get isActive => _scheduledTimer.isActive;
  
  @override
  int get tick => 0; // Not implemented for fake timer
  
  @override
  void cancel() {
    _scheduledTimer.cancel();
  }
}
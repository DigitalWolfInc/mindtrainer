/// Internal diagnostics ring buffer logger for MindTrainer
/// 
/// Provides safe, minimal logging focused on payments/billing events.
/// Uses fixed-capacity ring buffer to prevent memory bloat.

import 'dart:collection';

/// Ring buffer logger with fixed capacity
class _RingLog {
  final Queue<String> _buffer = Queue<String>();
  final int capacity;
  
  _RingLog(this.capacity);
  
  /// Add a new log line, trimming oldest entries if at capacity
  void add(String line) {
    _buffer.addLast(line);
    
    // Trim to capacity
    while (_buffer.length > capacity) {
      _buffer.removeFirst();
    }
  }
  
  /// Get snapshot of all log lines, newest to oldest
  List<String> snapshot() {
    return _buffer.toList().reversed.toList();
  }
  
  /// Clear all log entries
  void clear() {
    _buffer.clear();
  }
  
  /// Current number of entries
  int get length => _buffer.length;
}

/// Static diagnostics singleton for safe, payments-focused logging
class Diag {
  static final _RingLog _log = _RingLog(200);
  
  /// Log a diagnostic message with timestamp and tag
  /// Format: "HH:mm:ss [tag] msg"
  static void d(String tag, String msg) {
    final now = DateTime.now();
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:'
                   '${now.minute.toString().padLeft(2, '0')}:'
                   '${now.second.toString().padLeft(2, '0')}';
    
    final logLine = '$timeStr [$tag] $msg';
    _log.add(logLine);
  }
  
  /// Get snapshot of all diagnostic lines (newest to oldest)
  static List<String> dump() {
    return _log.snapshot();
  }
  
  /// Clear all diagnostic entries
  static void clear() {
    _log.clear();
  }
  
  /// Get current number of diagnostic entries
  static int get count => _log.length;
}
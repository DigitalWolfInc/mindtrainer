/// Lightweight Logger for MindTrainer
/// 
/// Provides in-memory ring buffer logging with optional file persistence.
/// All file operations require explicit user consent.

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart' if (dart.library.html) 'package:flutter/foundation.dart';

/// Log levels for filtering and categorization
enum LogLevel {
  debug(0, 'DEBUG'),
  info(1, 'INFO'),
  warn(2, 'WARN'),
  error(3, 'ERROR');
  
  const LogLevel(this.priority, this.name);
  
  final int priority;
  final String name;
}

/// Individual log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Map<String, dynamic>? extra;
  
  const LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.extra,
  });
  
  /// Format log entry for display
  String format() {
    final timeStr = timestamp.toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';
    final extraStr = extra != null ? ' ${extra.toString()}' : '';
    return '$timeStr [${level.name}] $tagStr$message$extraStr';
  }
  
  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      if (tag != null) 'tag': tag,
      if (extra != null) 'extra': extra,
    };
  }
  
  /// Create from JSON
  static LogEntry fromJson(Map<String, dynamic> json) {
    return LogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      level: LogLevel.values.firstWhere((l) => l.name == json['level']),
      message: json['message'],
      tag: json['tag'],
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }
}

/// Ring buffer implementation for efficient log storage
class RingBuffer<T> {
  final List<T?> _buffer;
  final int capacity;
  int _head = 0;
  int _size = 0;
  
  RingBuffer(this.capacity) : _buffer = List.filled(capacity, null);
  
  /// Add item to buffer
  void add(T item) {
    _buffer[_head] = item;
    _head = (_head + 1) % capacity;
    if (_size < capacity) {
      _size++;
    }
  }
  
  /// Get all items in chronological order
  List<T> getAll() {
    if (_size == 0) return [];
    
    final result = <T>[];
    final start = _size < capacity ? 0 : _head;
    
    for (int i = 0; i < _size; i++) {
      final index = (start + i) % capacity;
      final item = _buffer[index];
      if (item != null) {
        result.add(item);
      }
    }
    
    return result;
  }
  
  /// Clear buffer
  void clear() {
    _buffer.fillRange(0, capacity, null);
    _head = 0;
    _size = 0;
  }
  
  /// Current number of items
  int get length => _size;
  
  /// Check if buffer is empty
  bool get isEmpty => _size == 0;
  
  /// Check if buffer is full
  bool get isFull => _size == capacity;
}

/// Main logger class with ring buffer and optional file persistence
class MindTrainerLogger {
  static const int defaultBufferSize = 1000;
  static const String logFileName = 'app_logs.txt';
  
  final RingBuffer<LogEntry> _buffer;
  final LogLevel minimumLevel;
  final StreamController<LogEntry> _streamController = StreamController<LogEntry>.broadcast();
  
  // File persistence state
  bool _fileLoggingEnabled = false;
  bool _hasFileConsent = false;
  String? _logFilePath;
  
  MindTrainerLogger._({
    int bufferSize = defaultBufferSize,
    this.minimumLevel = LogLevel.info,
  }) : _buffer = RingBuffer<LogEntry>(bufferSize);
  
  /// Singleton instance
  static MindTrainerLogger? _instance;
  static MindTrainerLogger get instance {
    return _instance ??= MindTrainerLogger._();
  }
  
  /// Initialize logger with custom settings
  static void initialize({
    int bufferSize = defaultBufferSize,
    LogLevel minimumLevel = LogLevel.info,
  }) {
    // Only initialize in debug mode
    if (kReleaseMode) return;
    
    _instance = MindTrainerLogger._(
      bufferSize: bufferSize,
      minimumLevel: minimumLevel,
    );
  }
  
  /// Stream of log entries for real-time monitoring
  Stream<LogEntry> get logStream => _streamController.stream;
  
  /// Log a message
  void log(LogLevel level, String message, {
    String? tag,
    Map<String, dynamic>? extra,
  }) {
    // Guard all logging in release mode
    if (kReleaseMode) return;
    
    if (level.priority < minimumLevel.priority) return;
    
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      extra: extra,
    );
    
    // Add to ring buffer
    _buffer.add(entry);
    
    // Notify stream listeners
    _streamController.add(entry);
    
    // Debug print in development
    if (kDebugMode) {
      debugPrint(entry.format());
    }
    
    // Write to file if enabled and consented
    if (_fileLoggingEnabled && _hasFileConsent) {
      _writeToFile(entry);
    }
  }
  
  /// Convenience methods for different log levels
  void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    log(LogLevel.debug, message, tag: tag, extra: extra);
  }
  
  void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    log(LogLevel.info, message, tag: tag, extra: extra);
  }
  
  void warn(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    log(LogLevel.warn, message, tag: tag, extra: extra);
  }
  
  void error(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    log(LogLevel.error, message, tag: tag, extra: extra);
  }
  
  /// Get all log entries from ring buffer
  List<LogEntry> getAllLogs() {
    return _buffer.getAll();
  }
  
  /// Get logs filtered by level
  List<LogEntry> getLogsByLevel(LogLevel level) {
    return getAllLogs().where((entry) => entry.level == level).toList();
  }
  
  /// Get logs filtered by time range
  List<LogEntry> getLogsByTimeRange(DateTime start, DateTime end) {
    return getAllLogs().where((entry) => 
      entry.timestamp.isAfter(start) && entry.timestamp.isBefore(end)
    ).toList();
  }
  
  /// Get logs filtered by tag
  List<LogEntry> getLogsByTag(String tag) {
    return getAllLogs().where((entry) => entry.tag == tag).toList();
  }
  
  /// Clear all logs
  void clearLogs() {
    _buffer.clear();
  }
  
  /// Enable file logging with user consent
  Future<bool> enableFileLogging({required bool userConsent}) async {
    if (!userConsent) {
      _hasFileConsent = false;
      _fileLoggingEnabled = false;
      return false;
    }
    
    try {
      // Platform check for file system support
      if (kIsWeb) {
        // Web platform - no file system access
        return false;
      }
      
      final documentsDir = await getApplicationDocumentsDirectory();
      _logFilePath = '${documentsDir.path}/$logFileName';
      _hasFileConsent = true;
      _fileLoggingEnabled = true;
      
      info('File logging enabled', tag: 'Logger');
      return true;
    } catch (e) {
      error('Failed to enable file logging: $e', tag: 'Logger');
      return false;
    }
  }
  
  /// Disable file logging
  void disableFileLogging() {
    _fileLoggingEnabled = false;
    _hasFileConsent = false;
    info('File logging disabled', tag: 'Logger');
  }
  
  /// Get file path for logs (if file logging is enabled)
  String? get logFilePath => _fileLoggingEnabled ? _logFilePath : null;
  
  /// Check if file logging is available on this platform
  bool get canUseFileLogging => !kIsWeb;
  
  /// Export logs as JSON string
  String exportLogsAsJson() {
    final logs = getAllLogs().map((entry) => entry.toJson()).toList();
    return jsonEncode({
      'exported_at': DateTime.now().toIso8601String(),
      'total_entries': logs.length,
      'logs': logs,
    });
  }
  
  /// Export logs as plain text
  String exportLogsAsText() {
    final logs = getAllLogs();
    final buffer = StringBuffer();
    
    buffer.writeln('MindTrainer Logs Export');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total entries: ${logs.length}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    for (final entry in logs) {
      buffer.writeln(entry.format());
    }
    
    return buffer.toString();
  }
  
  /// Write log entry to file (private method)
  Future<void> _writeToFile(LogEntry entry) async {
    if (_logFilePath == null) return;
    
    try {
      final file = File(_logFilePath!);
      await file.writeAsString(
        '${entry.format()}\n',
        mode: FileMode.append,
      );
    } catch (e) {
      // Silently fail to avoid logging loops
      if (kDebugMode) {
        debugPrint('Failed to write log to file: $e');
      }
    }
  }
  
  /// Get current buffer statistics
  Map<String, dynamic> getBufferStats() {
    final logs = getAllLogs();
    final levelCounts = <String, int>{};
    
    for (final level in LogLevel.values) {
      levelCounts[level.name] = logs.where((log) => log.level == level).length;
    }
    
    return {
      'buffer_size': _buffer.capacity,
      'current_entries': _buffer.length,
      'is_full': _buffer.isFull,
      'file_logging_enabled': _fileLoggingEnabled,
      'file_path': _logFilePath,
      'level_counts': levelCounts,
    };
  }
  
  /// Dispose resources
  void dispose() {
    _streamController.close();
  }
}

/// Convenience functions for global logging
class Log {
  static MindTrainerLogger get _logger => MindTrainerLogger.instance;
  
  static void debug(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    _logger.debug(message, tag: tag, extra: extra);
  }
  
  static void info(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    _logger.info(message, tag: tag, extra: extra);
  }
  
  static void warn(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    _logger.warn(message, tag: tag, extra: extra);
  }
  
  static void error(String message, {String? tag, Map<String, dynamic>? extra}) {
    if (kReleaseMode) return;
    _logger.error(message, tag: tag, extra: extra);
  }
}
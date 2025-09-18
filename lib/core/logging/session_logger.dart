import 'dart:convert';
import 'dart:io';

/// Persistent session logger for tracking user prompts
/// Appends entries to claude_log.txt in the project root
class SessionLogger {
  static const String _logFileName = 'claude_log.txt';
  static String? _cachedLogPath;
  static DateTime? _lastPrompt;
  static String? _lastPromptText;
  static DateTime? _lastSessionStart;
  
  /// Get the log file path relative to project root
  static String get _logFilePath {
    if (_cachedLogPath != null) return _cachedLogPath!;
    
    // Get current directory and work backwards to find project root
    var currentDir = Directory.current;
    
    // Look for pubspec.yaml to identify project root
    while (!File('${currentDir.path}/pubspec.yaml').existsSync()) {
      final parent = currentDir.parent;
      if (parent.path == currentDir.path) {
        // Reached filesystem root, fallback to current directory
        break;
      }
      currentDir = parent;
    }
    
    _cachedLogPath = '${currentDir.path}/$_logFileName';
    return _cachedLogPath!;
  }
  
  /// Log a session start marker
  static Future<void> logSessionStart() async {
    final now = DateTime.now();
    
    // Check for idempotence - don't add if already added within 1 minute
    if (_lastSessionStart != null && 
        now.difference(_lastSessionStart!).inSeconds < 60) {
      return;
    }
    
    try {
      final timestamp = _formatDateTime(now);
      final entry = '---- SESSION START [$timestamp] ----\n';
      
      final logFile = File(_logFilePath);
      await logFile.writeAsString(entry, mode: FileMode.append, encoding: utf8);
      
      _lastSessionStart = now;
    } catch (e) {
      // Silently ignore logging errors to not interfere with main functionality
    }
  }
  
  /// Log a user prompt
  static Future<void> logPrompt(String promptText) async {
    final now = DateTime.now();
    
    // Check for deduplication within 60 seconds
    bool isDuplicate = false;
    if (_lastPrompt != null && 
        _lastPromptText == promptText &&
        now.difference(_lastPrompt!).inSeconds < 60) {
      isDuplicate = true;
    }
    
    try {
      final timestamp = _formatDateTime(now);
      String entry;
      
      if (isDuplicate) {
        entry = '[$timestamp] — $promptText (dedup)\n';
      } else {
        if (promptText.contains('\n')) {
          // Multiline prompt
          entry = '[$timestamp] — PROMPT\n<<<\n$promptText\n>>>\n';
        } else {
          // Single line prompt
          entry = '[$timestamp] — $promptText\n';
        }
      }
      
      final logFile = File(_logFilePath);
      await logFile.writeAsString(entry, mode: FileMode.append, encoding: utf8);
      
      if (!isDuplicate) {
        _lastPrompt = now;
        _lastPromptText = promptText;
      }
    } catch (e) {
      // Silently ignore logging errors
    }
  }
  
  /// Format datetime in YYYY-MM-DD HH:MM format
  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-'
           '${dateTime.month.toString().padLeft(2, '0')}-'
           '${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  /// Read the last N lines from the log file
  static Future<List<String>> readLastLines(int count) async {
    try {
      final logFile = File(_logFilePath);
      if (!await logFile.exists()) {
        return [];
      }
      
      final content = await logFile.readAsString(encoding: utf8);
      final lines = content.split('\n');
      
      // Remove empty trailing line if present
      if (lines.isNotEmpty && lines.last.isEmpty) {
        lines.removeLast();
      }
      
      // Return last N lines
      if (lines.length <= count) {
        return lines;
      } else {
        return lines.sublist(lines.length - count);
      }
    } catch (e) {
      return [];
    }
  }
  
  /// Check if log file exists
  static Future<bool> logExists() async {
    try {
      final logFile = File(_logFilePath);
      return await logFile.exists();
    } catch (e) {
      return false;
    }
  }
}
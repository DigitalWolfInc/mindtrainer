import 'dart:io';
import 'dart:convert';

/// Simple persistent logging for Claude prompts
/// Appends entries to claude_log.txt in the project root
class ClaudeLog {
  static const String _logFileName = 'claude_log.txt';
  
  /// Get the log file path relative to project root
  static String get _logFilePath {
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
    
    return '${currentDir.path}/$_logFileName';
  }
  
  /// Append a new log entry with timestamp
  static Future<void> logPrompt(String promptText) async {
    try {
      final timestamp = DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ');
      final entry = '[$timestamp] — $promptText\n';
      
      final logFile = File(_logFilePath);
      await logFile.writeAsString(entry, mode: FileMode.append, encoding: utf8);
    } catch (e) {
      // Silently ignore logging errors to not interfere with main functionality
    }
  }
  
  /// Append a test entry (for verification)
  static Future<void> logTest(String testMessage) async {
    try {
      final entry = '[TEST] $testMessage\n';
      
      final logFile = File(_logFilePath);
      await logFile.writeAsString(entry, mode: FileMode.append, encoding: utf8);
    } catch (e) {
      // Silently ignore logging errors
    }
  }
  
  /// Read the entire log file contents
  static Future<String> readLog() async {
    try {
      final logFile = File(_logFilePath);
      if (await logFile.exists()) {
        return await logFile.readAsString(encoding: utf8);
      }
      return '';
    } catch (e) {
      return '';
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
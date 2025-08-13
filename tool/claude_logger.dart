#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Claude Logger - Dev-only tool for logging prompts to claude_log.txt
/// 
/// Usage:
/// dart run tool/claude_logger.dart --session-start
/// dart run tool/claude_logger.dart --append "exact prompt text"
/// dart run tool/claude_logger.dart --append-file ./prompt.txt

void main(List<String> args) async {
  final logger = ClaudeLogger();
  
  try {
    if (args.isEmpty) {
      _printUsage();
      return;
    }
    
    final command = args[0];
    
    switch (command) {
      case '--session-start':
        await logger.sessionStart();
        print('Session start logged');
        break;
        
      case '--append':
        if (args.length < 2) {
          print('Error: --append requires prompt text');
          _printUsage();
          exit(1);
        }
        final prompt = args[1];
        await logger.appendPrompt(prompt);
        print('Prompt logged');
        break;
        
      case '--append-file':
        if (args.length < 2) {
          print('Error: --append-file requires file path');
          _printUsage();
          exit(1);
        }
        final filePath = args[1];
        try {
          final file = File(filePath);
          if (!await file.exists()) {
            print('Error: File not found: $filePath');
            exit(1);
          }
          final content = await file.readAsString();
          await logger.appendPrompt(content);
          print('File content logged');
        } catch (e) {
          print('Error reading file: $e');
          exit(1);
        }
        break;
        
      default:
        print('Error: Unknown command: $command');
        _printUsage();
        exit(1);
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}

void _printUsage() {
  print('Usage:');
  print('  dart run tool/claude_logger.dart --session-start');
  print('  dart run tool/claude_logger.dart --append "exact prompt text"');
  print('  dart run tool/claude_logger.dart --append-file ./prompt.txt');
}

/// Claude Logger implementation
class ClaudeLogger {
  static const String _logFileName = 'claude_log.txt';
  static const int _dedupWindowSeconds = 60;
  
  late final File _logFile;
  
  ClaudeLogger() {
    _logFile = File(_logFileName);
  }
  
  /// Add session start marker
  Future<void> sessionStart() async {
    final timestamp = _formatTimestamp(DateTime.now());
    final marker = '---- SESSION START [$timestamp] ----\n';
    
    // Check if we already added session start in the last minute (dedup)
    if (await _shouldDedup(marker.trim(), skipDedupCheck: true)) {
      return; // Don't add duplicate session start within 1 minute
    }
    
    await _appendToFile(marker);
  }
  
  /// Append a prompt with deduplication
  Future<void> appendPrompt(String prompt) async {
    final timestamp = _formatTimestamp(DateTime.now());
    
    // Check for deduplication
    if (await _shouldDedup(prompt)) {
      // Add dedup marker instead
      final dedupEntry = '[$timestamp] — $prompt (dedup)\n';
      await _appendToFile(dedupEntry);
      return;
    }
    
    String entry;
    if (prompt.contains('\n')) {
      // Multiline format
      entry = '[$timestamp] — PROMPT\n<<<\n$prompt\n>>>\n';
    } else {
      // Single line format
      entry = '[$timestamp] — $prompt\n';
    }
    
    await _appendToFile(entry);
  }
  
  /// Check if prompt should be deduplicated
  Future<bool> _shouldDedup(String prompt, {bool skipDedupCheck = false}) async {
    if (skipDedupCheck) {
      // For session start, check if the exact same marker was added recently
      if (!await _logFile.exists()) return false;
      
      try {
        final content = await _logFile.readAsString();
        final lines = content.split('\n');
        final cutoff = DateTime.now().subtract(const Duration(seconds: _dedupWindowSeconds));
        
        // Look for recent session start markers
        for (final line in lines.reversed) {
          if (line.startsWith('---- SESSION START [')) {
            final timestampMatch = RegExp(r'\[(.*?)\]').firstMatch(line);
            if (timestampMatch != null) {
              final timestampStr = timestampMatch.group(1)!;
              try {
                final timestamp = _parseTimestamp(timestampStr);
                if (timestamp.isAfter(cutoff)) {
                  return true; // Found recent session start
                }
              } catch (e) {
                // Ignore parse errors, continue checking
              }
            }
          }
        }
      } catch (e) {
        // Ignore read errors
      }
      return false;
    }
    
    if (!await _logFile.exists()) return false;
    
    try {
      final content = await _logFile.readAsString();
      final lines = content.split('\n');
      final cutoff = DateTime.now().subtract(const Duration(seconds: _dedupWindowSeconds));
      
      // Look for identical prompts in recent entries
      for (final line in lines.reversed) {
        if (line.isEmpty) continue;
        
        // Parse timestamp from line
        final timestampMatch = RegExp(r'^\[(.*?)\] — (.*)$').firstMatch(line);
        if (timestampMatch != null) {
          final timestampStr = timestampMatch.group(1)!;
          final promptPart = timestampMatch.group(2)!;
          
          try {
            final timestamp = _parseTimestamp(timestampStr);
            if (timestamp.isAfter(cutoff)) {
              // Remove (dedup) suffix for comparison
              final cleanPrompt = promptPart.replaceAll(' (dedup)', '');
              if (cleanPrompt == prompt || cleanPrompt == 'PROMPT') {
                // For multiline, need to check the actual content between <<< >>>
                if (cleanPrompt == 'PROMPT') {
                  // This is potentially a multiline match, would need more complex parsing
                  // For now, just check if this is the same type
                  return prompt.contains('\n');
                }
                return true;
              }
            } else {
              // Timestamps are getting older, can break early
              break;
            }
          } catch (e) {
            // Ignore timestamp parse errors, continue
          }
        }
      }
    } catch (e) {
      // Ignore read errors
    }
    
    return false;
  }
  
  /// Append content to file atomically where possible
  Future<void> _appendToFile(String content) async {
    try {
      // Ensure file exists
      if (!await _logFile.exists()) {
        await _logFile.create(recursive: true);
      }
      
      // For atomic append, we'll use a simple append operation
      // In case of concurrent access, this is the safest approach
      await _logFile.writeAsString(content, mode: FileMode.append, encoding: utf8);
    } catch (e) {
      // If atomic append fails, try recovery
      try {
        // Read existing content
        String existing = '';
        if (await _logFile.exists()) {
          try {
            existing = await _logFile.readAsString();
          } catch (e) {
            // File might be corrupted, truncate at last complete line
            existing = await _recoverCorruptedFile();
          }
        }
        
        // Write existing + new content
        await _logFile.writeAsString(existing + content, encoding: utf8);
      } catch (e) {
        rethrow;
      }
    }
  }
  
  /// Recover from corrupted file by truncating at last complete line
  Future<String> _recoverCorruptedFile() async {
    try {
      final bytes = await _logFile.readAsBytes();
      // Find last complete line (ending with \n)
      int lastNewline = -1;
      for (int i = bytes.length - 1; i >= 0; i--) {
        if (bytes[i] == 10) { // \n
          lastNewline = i;
          break;
        }
      }
      
      if (lastNewline >= 0) {
        final recoveredBytes = bytes.sublist(0, lastNewline + 1);
        return utf8.decode(recoveredBytes);
      }
    } catch (e) {
      // If recovery fails, start fresh
    }
    return '';
  }
  
  /// Format timestamp as YYYY-MM-DD HH:MM
  String _formatTimestamp(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
  
  /// Parse timestamp from YYYY-MM-DD HH:MM format
  DateTime _parseTimestamp(String timestamp) {
    final parts = timestamp.split(' ');
    if (parts.length != 2) throw FormatException('Invalid timestamp format');
    
    final dateParts = parts[0].split('-');
    final timeParts = parts[1].split(':');
    
    if (dateParts.length != 3 || timeParts.length != 2) {
      throw FormatException('Invalid timestamp format');
    }
    
    final year = int.parse(dateParts[0]);
    final month = int.parse(dateParts[1]);
    final day = int.parse(dateParts[2]);
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    return DateTime(year, month, day, hour, minute);
  }
}
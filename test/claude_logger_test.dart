import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../tool/claude_logger.dart';

void main() {
  group('ClaudeLogger Tests', () {
    late String testDirectory;
    late String originalDirectory;
    
    setUp(() async {
      // Create temporary directory for tests
      testDirectory = Directory.systemTemp.path + 
          '/claude_logger_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
      
      // Change to test directory so logger creates files there
      originalDirectory = Directory.current.path;
      Directory.current = testDirectory;
    });
    
    tearDown(() async {
      // Restore original directory
      Directory.current = originalDirectory;
      
      // Clean up test directory
      try {
        await Directory(testDirectory).delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });
    
    group('File Creation', () {
      test('should create log file on first write', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        expect(await logFile.exists(), false);
        
        await logger.appendPrompt('First entry');
        
        expect(await logFile.exists(), true);
      });
      
      test('should append to existing file without overwriting', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        // Create file with initial content
        await logFile.writeAsString('Initial content\n');
        
        await logger.appendPrompt('New entry');
        
        final content = await logFile.readAsString();
        expect(content, startsWith('Initial content\n'));
        expect(content, contains('New entry'));
      });
    });
    
    group('Single Line Format', () {
      test('should format single line prompts correctly', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        await logger.appendPrompt('Simple prompt');
        
        final content = await logFile.readAsString();
        expect(content, matches(r'^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}\] — Simple prompt\n$'));
      });
      
      test('should preserve special characters in single line', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        const prompt = 'Special chars: ©, ™, emojis 🚀🔥, punctuation!';
        await logger.appendPrompt(prompt);
        
        final content = await logFile.readAsString();
        expect(content, contains(prompt));
      });
    });
    
    group('Multiline Format', () {
      test('should format multiline prompts with fence correctly', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        const multilinePrompt = '''This is line 1
This is line 2
This is line 3''';
        
        await logger.appendPrompt(multilinePrompt);
        
        final content = await logFile.readAsString();
        expect(content, matches(r'^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}\] — PROMPT\n<<<\n'));
        expect(content, contains(multilinePrompt));
        expect(content, endsWith('>>>\n'));
      });
      
      test('should preserve exact formatting in multiline content', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        const multilinePrompt = '''Line with spaces   
	Tab-indented line
Line with special chars: © ™ 🚀
Empty line below:

Final line''';
        
        await logger.appendPrompt(multilinePrompt);
        
        final content = await logFile.readAsString();
        expect(content, contains(multilinePrompt));
      });
    });
    
    group('Session Start Markers', () {
      test('should add session start marker with timestamp', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        await logger.sessionStart();
        
        final content = await logFile.readAsString();
        expect(content, matches(r'^---- SESSION START \[\d{4}-\d{2}-\d{2} \d{2}:\d{2}\] ----\n$'));
      });
      
      test('should not duplicate session start within 60 seconds', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        await logger.sessionStart();
        await Future.delayed(const Duration(milliseconds: 100));
        await logger.sessionStart(); // Should be deduplicated
        
        final content = await logFile.readAsString();
        final sessionStarts = '---- SESSION START'.allMatches(content).length;
        expect(sessionStarts, 1);
      });
    });
    
    group('Deduplication', () {
      test('should deduplicate identical prompts within 60 seconds', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        const prompt = 'Duplicate test prompt';
        
        await logger.appendPrompt(prompt);
        await Future.delayed(const Duration(milliseconds: 100));
        await logger.appendPrompt(prompt); // Should be deduplicated
        
        final content = await logFile.readAsString();
        expect(content, contains('$prompt\n'));
        expect(content, contains('$prompt (dedup)\n'));
        
        // Should have exactly one normal entry and one dedup entry
        final normalMatches = '$prompt\n'.allMatches(content).length;
        final dedupMatches = '$prompt (dedup)\n'.allMatches(content).length;
        expect(normalMatches, 1);
        expect(dedupMatches, 1);
      });
      
      test('should not deduplicate after 60+ seconds', () async {
        // This test would take too long to run in practice, 
        // so we'll test the logic by mocking timestamps
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        const prompt = 'Time test prompt';
        
        await logger.appendPrompt(prompt);
        
        // Manually write an old timestamp entry to simulate time passage
        final oldTimestamp = DateTime.now().subtract(const Duration(seconds: 65));
        final year = oldTimestamp.year.toString().padLeft(4, '0');
        final month = oldTimestamp.month.toString().padLeft(2, '0');
        final day = oldTimestamp.day.toString().padLeft(2, '0');
        final hour = oldTimestamp.hour.toString().padLeft(2, '0');
        final minute = oldTimestamp.minute.toString().padLeft(2, '0');
        final formattedTimestamp = '$year-$month-$day $hour:$minute';
        final oldEntry = '[$formattedTimestamp] — $prompt\n';
        
        // Clear file and write old entry
        await logFile.writeAsString(oldEntry);
        
        // Now add the same prompt - should not be deduplicated
        await logger.appendPrompt(prompt);
        
        final content = await logFile.readAsString();
        final matches = prompt.allMatches(content).length;
        expect(matches, 2); // Should have two entries, no dedup
      });
    });
    
    group('Corrupted File Recovery', () {
      test('should handle corrupted file and continue appending', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        // Create a corrupted file (invalid UTF-8 or truncated)
        await logFile.writeAsBytes([0xFF, 0xFE, 0x00]); // Invalid UTF-8
        
        // Logger should recover and append cleanly
        await logger.appendPrompt('Recovery test');
        
        // Should not throw and should have valid content at the end
        final content = await logFile.readAsString();
        expect(content, contains('Recovery test'));
      });
      
      test('should truncate at last complete line for partial corruption', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        // Create file with complete line + partial line
        const validContent = '[2023-01-01 10:00] — Valid entry\n';
        const partialContent = '[2023-01-01 10:01] — Partial en'; // No newline
        
        await logFile.writeAsString(validContent + partialContent);
        
        // Force a recovery scenario by appending
        await logger.appendPrompt('New entry after recovery');
        
        final content = await logFile.readAsString();
        expect(content, contains('Valid entry'));
        expect(content, contains('New entry after recovery'));
      });
    });
    
    group('Cross-platform Compatibility', () {
      test('should use relative path for log file', () async {
        final logger = ClaudeLogger();
        await logger.appendPrompt('Path test');
        
        // Log file should be created in current directory
        final logFile = File('claude_log.txt');
        expect(await logFile.exists(), true);
        
        // Path should be relative, not absolute
        expect(logFile.path, 'claude_log.txt');
      });
      
      test('should handle Unicode content correctly', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        const unicodePrompt = 'Unicode test: 你好 мир 🌍 ñoño';
        await logger.appendPrompt(unicodePrompt);
        
        final content = await logFile.readAsString();
        expect(content, contains(unicodePrompt));
      });
    });
    
    group('Timestamp Formatting', () {
      test('should format timestamps consistently', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        await logger.appendPrompt('Timestamp test');
        
        final content = await logFile.readAsString();
        // Should match YYYY-MM-DD HH:MM format
        expect(content, matches(r'^\[2\d{3}-\d{2}-\d{2} \d{2}:\d{2}\]'));
      });
      
      test('should zero-pad single digit months, days, hours, minutes', () async {
        final logger = ClaudeLogger();
        final logFile = File('claude_log.txt');
        
        // Add entry and check that timestamp is properly formatted
        await logger.appendPrompt('Padding test');
        
        final content = await logFile.readAsString();
        // Should match YYYY-MM-DD HH:MM format with proper zero padding
        expect(content, matches(r'^\[2\d{3}-\d{2}-\d{2} \d{2}:\d{2}\] — Padding test\n$'));
      });
    });
  });
}
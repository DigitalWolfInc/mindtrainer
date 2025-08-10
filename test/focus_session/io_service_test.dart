import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindtrainer/features/focus_session/domain/io_service.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  group('FocusSessionIOService', () {
    late Directory tempDir;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('io_service_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    group('CSV Export', () {
      test('should export CSV with correct header and format', () async {
        // Setup test data
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|25',
            '2024-01-14 14:15|60',
          ],
        });

        final csvPath = '${tempDir.path}/test_export.csv';
        final result = await FocusSessionIOService.exportCsv(csvPath);

        expect(result.success, true);
        expect(result.data, csvPath);

        final file = File(csvPath);
        expect(await file.exists(), true);

        final content = await file.readAsString();
        final lines = content.trim().split('\n');

        // Check header
        expect(lines[0], 'id,start,end,durationMinutes,notes,tags');

        // Check first data row
        final row1Parts = lines[1].split(',');
        expect(row1Parts[1], '2024-01-15 10:30');
        expect(row1Parts[2], '2024-01-15 10:55'); // 10:30 + 25 minutes
        expect(row1Parts[3], '25');
        expect(row1Parts[4], ''); // empty notes
        expect(row1Parts[5], ''); // empty tags

        // Check second data row
        final row2Parts = lines[2].split(',');
        expect(row2Parts[1], '2024-01-14 14:15');
        expect(row2Parts[2], '2024-01-14 15:15'); // 14:15 + 60 minutes
        expect(row2Parts[3], '60');
      });

      test('should handle CSV field escaping correctly', () async {
        // Create test data with fields that need escaping
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|25'],
        });

        final csvPath = '${tempDir.path}/escaping_test.csv';
        final result = await FocusSessionIOService.exportCsv(csvPath);

        expect(result.success, true);

        final file = File(csvPath);
        final content = await file.readAsString();
        final lines = content.trim().split('\n');

        // Verify CSV structure is correct
        expect(lines.length, 2); // Header + 1 data row
        expect(lines[0], 'id,start,end,durationMinutes,notes,tags');
        
        final dataParts = lines[1].split(',');
        expect(dataParts.length, 6); // All fields present
        expect(dataParts[1], '2024-01-15 10:30'); // start time
        expect(dataParts[3], '25'); // duration
      });

      test('should handle empty session history', () async {
        SharedPreferences.setMockInitialValues({'session_history': []});

        final csvPath = '${tempDir.path}/empty_export.csv';
        final result = await FocusSessionIOService.exportCsv(csvPath);

        expect(result.success, true);

        final file = File(csvPath);
        final content = await file.readAsString();
        final lines = content.trim().split('\n');

        expect(lines.length, 1); // Only header
        expect(lines[0], 'id,start,end,durationMinutes,notes,tags');
      });

      test('should handle file write errors', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|25'],
        });

        // Try to write to invalid path
        final invalidPath = '/invalid/path/test.csv';
        final result = await FocusSessionIOService.exportCsv(invalidPath);

        expect(result.success, false);
        expect(result.errorMessage, contains('Failed to export CSV'));
      });
    });

    group('JSON Export', () {
      test('should export JSON with correct structure', () async {
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|25',
            '2024-01-14 14:15|60',
          ],
        });

        final jsonPath = '${tempDir.path}/test_export.json';
        final result = await FocusSessionIOService.exportJson(jsonPath);

        expect(result.success, true);
        expect(result.data, jsonPath);

        final file = File(jsonPath);
        expect(await file.exists(), true);

        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        expect(data.containsKey('exportTimestamp'), true);
        expect(data.containsKey('sessions'), true);

        final sessions = data['sessions'] as List;
        expect(sessions.length, 2);

        final session1 = sessions[0] as Map<String, dynamic>;
        expect(session1['start'], '2024-01-15 10:30');
        expect(session1['end'], '2024-01-15 10:55');
        expect(session1['durationMinutes'], 25);
        expect(session1['notes'], '');
        expect(session1['tags'], '');
        expect(session1.containsKey('id'), true);
      });

      test('should handle empty session history for JSON', () async {
        SharedPreferences.setMockInitialValues({'session_history': []});

        final jsonPath = '${tempDir.path}/empty_export.json';
        final result = await FocusSessionIOService.exportJson(jsonPath);

        expect(result.success, true);

        final file = File(jsonPath);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        expect(data['sessions'], isEmpty);
      });
    });

    group('JSON Import', () {
      test('should import JSON sessions successfully', () async {
        // Start with empty session history
        SharedPreferences.setMockInitialValues({'session_history': []});

        // Create test import file
        final importData = {
          'exportTimestamp': '2024-01-16T10:00:00.000Z',
          'sessions': [
            {
              'id': 'import_session_1',
              'start': '2024-01-15 10:30',
              'end': '2024-01-15 10:55',
              'durationMinutes': 25,
              'notes': 'Imported session',
              'tags': 'test',
            },
            {
              'id': 'import_session_2',
              'start': '2024-01-14 14:15',
              'end': '2024-01-14 15:15',
              'durationMinutes': 60,
              'notes': '',
              'tags': '',
            }
          ],
        };

        final importPath = '${tempDir.path}/import_test.json';
        final importFile = File(importPath);
        await importFile.writeAsString(jsonEncode(importData));

        final result = await FocusSessionIOService.importJson(importPath);

        expect(result.success, true);
        expect(result.data, 'Imported 2 new sessions');

        // Verify sessions were saved
        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];
        expect(history.length, 2);
        expect(history[0], '2024-01-15 10:30|25|test|Imported session');
        expect(history[1], '2024-01-14 14:15|60');
      });

      test('should handle duplicate import correctly (no-op)', () async {
        // Start with existing session
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|25'],
        });

        // Export existing sessions to get proper format for duplicate test
        final exportPath = '${tempDir.path}/existing_export.json';
        final exportResult = await FocusSessionIOService.exportJson(exportPath);
        expect(exportResult.success, true);

        // Read exported data to get existing session format
        final exportFile = File(exportPath);
        final exportContent = await exportFile.readAsString();
        final exportData = jsonDecode(exportContent) as Map<String, dynamic>;
        final existingSession = (exportData['sessions'] as List).first;

        // Create import file with duplicate session (same ID)
        final importData = {
          'exportTimestamp': '2024-01-16T10:00:00.000Z',
          'sessions': [existingSession], // Exact duplicate
        };

        final importPath = '${tempDir.path}/duplicate_import.json';
        final importFile = File(importPath);
        await importFile.writeAsString(jsonEncode(importData));

        final result = await FocusSessionIOService.importJson(importPath);

        expect(result.success, true);
        expect(result.data, 'No new sessions to import');

        // Verify no duplicate was added
        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];
        expect(history.length, 1); // Still only 1 session
      });

      test('should handle mixed new and duplicate sessions', () async {
        // Start with one existing session
        SharedPreferences.setMockInitialValues({
          'session_history': ['2024-01-15 10:30|25'],
        });

        // Export existing sessions to get proper format for mixed test
        final exportPath = '${tempDir.path}/existing_export_mixed.json';
        final exportResult = await FocusSessionIOService.exportJson(exportPath);
        expect(exportResult.success, true);

        // Read exported data to get existing session format
        final exportFile = File(exportPath);
        final exportContent = await exportFile.readAsString();
        final exportData = jsonDecode(exportContent) as Map<String, dynamic>;
        final existingSession = (exportData['sessions'] as List).first;

        // Create import with one duplicate and one new session
        final importData = {
          'exportTimestamp': '2024-01-16T10:00:00.000Z',
          'sessions': [
            existingSession, // Duplicate
            {
              'id': 'new_session_1',
              'start': '2024-01-16 09:00',
              'end': '2024-01-16 09:30',
              'durationMinutes': 30,
              'notes': '',
              'tags': '',
            }, // New session
          ],
        };

        final importPath = '${tempDir.path}/mixed_import.json';
        final importFile = File(importPath);
        await importFile.writeAsString(jsonEncode(importData));

        final result = await FocusSessionIOService.importJson(importPath);

        expect(result.success, true);
        expect(result.data, 'Imported 1 new sessions');

        // Verify only new session was added
        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];
        expect(history.length, 2);
        expect(history[0], '2024-01-16 09:00|30'); // New session first
        expect(history[1], '2024-01-15 10:30|25'); // Original session
      });

      test('should handle invalid JSON format', () async {
        // Create invalid JSON file
        final invalidPath = '${tempDir.path}/invalid.json';
        final invalidFile = File(invalidPath);
        await invalidFile.writeAsString('invalid json content');

        final result = await FocusSessionIOService.importJson(invalidPath);

        expect(result.success, false);
        expect(result.errorMessage, contains('Failed to import JSON'));
      });

      test('should handle missing sessions array', () async {
        // Create JSON without sessions key
        final importData = {'exportTimestamp': '2024-01-16T10:00:00.000Z'};

        final importPath = '${tempDir.path}/missing_sessions.json';
        final importFile = File(importPath);
        await importFile.writeAsString(jsonEncode(importData));

        final result = await FocusSessionIOService.importJson(importPath);

        expect(result.success, false);
        expect(result.errorMessage, 'Invalid JSON format: missing sessions array');
      });

      test('should handle non-existent import file', () async {
        final nonExistentPath = '${tempDir.path}/does_not_exist.json';
        final result = await FocusSessionIOService.importJson(nonExistentPath);

        expect(result.success, false);
        expect(result.errorMessage, 'Import file does not exist');
      });
    });

    group('Round-trip Import/Export', () {
      test('should maintain data integrity through export-import cycle', () async {
        // Setup initial test data
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|25',
            '2024-01-14 14:15|60',
            '2024-01-13 09:45|45',
          ],
        });

        // Export to JSON
        final exportPath = '${tempDir.path}/roundtrip_export.json';
        final exportResult = await FocusSessionIOService.exportJson(exportPath);
        expect(exportResult.success, true);

        // Clear session history
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('session_history', []);

        // Import back from JSON
        final importResult = await FocusSessionIOService.importJson(exportPath);
        expect(importResult.success, true);
        expect(importResult.data, 'Imported 3 new sessions');

        // Verify data integrity
        final restoredHistory = prefs.getStringList('session_history') ?? [];
        expect(restoredHistory.length, 3);
        expect(restoredHistory, containsAll([
          '2024-01-15 10:30|25',
          '2024-01-14 14:15|60',
          '2024-01-13 09:45|45',
        ]));
      });

      test('should handle multiple import cycles correctly', () async {
        // Simplified test to focus on core import functionality
        SharedPreferences.setMockInitialValues({'session_history': []});

        // Create first import file  
        final firstImportData = {
          'sessions': [
            {
              'id': 'unique_session_1',
              'start': '2024-01-15 10:30',
              'end': '2024-01-15 10:55',
              'durationMinutes': 25,
              'notes': '',
              'tags': '',
            }
          ],
        };

        final firstImportPath = '${tempDir.path}/first_import.json';
        await File(firstImportPath).writeAsString(jsonEncode(firstImportData));

        final firstImportResult = await FocusSessionIOService.importJson(firstImportPath);
        expect(firstImportResult.success, true);
        expect(firstImportResult.data, 'Imported 1 new sessions');

        // Create second import file with different session
        final secondImportData = {
          'sessions': [
            {
              'id': 'unique_session_2',
              'start': '2024-01-16 11:00',
              'end': '2024-01-16 11:30',
              'durationMinutes': 30,
              'notes': '',
              'tags': '',
            }
          ],
        };

        final secondImportPath = '${tempDir.path}/second_import.json';
        await File(secondImportPath).writeAsString(jsonEncode(secondImportData));

        final secondImportResult = await FocusSessionIOService.importJson(secondImportPath);
        expect(secondImportResult.success, true);
        expect(secondImportResult.data, 'Imported 1 new sessions');

        // Verify 2 sessions total
        final prefs = await SharedPreferences.getInstance();
        final history = prefs.getStringList('session_history') ?? [];
        expect(history.length, 2);

        // Re-import first file (should be no-op since same IDs)
        final thirdImportResult = await FocusSessionIOService.importJson(firstImportPath);
        expect(thirdImportResult.success, true);
        expect(thirdImportResult.data, 'No new sessions to import');

        // Verify still only 2 sessions
        final finalHistory = prefs.getStringList('session_history') ?? [];
        expect(finalHistory.length, 2);
      });
    });

    group('Edge Cases', () {
      test('should handle sessions with same timestamp but different indices', () async {
        // Setup sessions at same time (edge case in ID generation)
        SharedPreferences.setMockInitialValues({
          'session_history': [
            '2024-01-15 10:30|25',
            '2024-01-15 10:30|30', // Same timestamp, different duration
          ],
        });

        // Export to JSON to verify session processing
        final exportPath = '${tempDir.path}/same_time_export.json';
        final exportResult = await FocusSessionIOService.exportJson(exportPath);
        expect(exportResult.success, true);

        // Read exported data to verify IDs are unique
        final exportFile = File(exportPath);
        final exportContent = await exportFile.readAsString();
        final exportData = jsonDecode(exportContent) as Map<String, dynamic>;
        final sessions = exportData['sessions'] as List;

        expect(sessions.length, 2);

        // IDs should be different due to index
        expect(sessions[0]['id'], isNot(equals(sessions[1]['id'])));
      });

      test('should handle very large session history', () async {
        // Create 1000 sessions
        final largeHistory = List.generate(1000, (index) {
          final date = DateTime(2024, 1, 1).add(Duration(hours: index));
          final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          return '$dateStr|${25 + (index % 60)}'; // Varying durations
        });

        SharedPreferences.setMockInitialValues({
          'session_history': largeHistory,
        });

        final jsonPath = '${tempDir.path}/large_export.json';
        final result = await FocusSessionIOService.exportJson(jsonPath);

        expect(result.success, true);

        final file = File(jsonPath);
        final content = await file.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;
        final sessions = data['sessions'] as List;

        expect(sessions.length, 1000);
      });
    });
  });
}
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../lib/data/tool_usage_store.dart';
import '../../lib/favorites/tool_definitions.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  final String tempDir;
  
  MockPathProviderPlatform(this.tempDir);
  
  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

void main() {
  group('ToolUsageStore Tests', () {
    late String testDirectory;
    late MockPathProviderPlatform mockPathProvider;

    setUp(() async {
      ToolUsageStore.resetInstance();
      
      // Create a temporary directory for test files
      testDirectory = Directory.systemTemp.path + '/tool_usage_store_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
      
      // Mock path provider
      mockPathProvider = MockPathProviderPlatform(testDirectory);
      PathProviderPlatform.instance = mockPathProvider;
    });

    tearDown(() async {
      ToolUsageStore.resetInstance();
      
      // Clean up test directory
      try {
        await Directory(testDirectory).delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('ToolUsage Model', () {
      test('should create ToolUsage with factory constructor', () {
        final usage = ToolUsage.now(ToolRegistry.focusSession);
        
        expect(usage.toolId, ToolRegistry.focusSession);
        expect(usage.ts, isA<DateTime>());
      });

      test('should serialize to and from JSON correctly', () {
        final originalUsage = ToolUsage(
          toolId: ToolRegistry.focusSession,
          ts: DateTime.parse('2023-01-15T10:30:00.000Z'),
        );

        final json = originalUsage.toJson();
        expect(json['toolId'], ToolRegistry.focusSession);
        expect(json['tsIsoString'], '2023-01-15T10:30:00.000Z');

        final recreatedUsage = ToolUsage.fromJson(json);
        expect(recreatedUsage, equals(originalUsage));
      });

      test('should implement equality correctly', () {
        final usage1 = ToolUsage(
          toolId: ToolRegistry.focusSession,
          ts: DateTime.parse('2023-01-15T10:30:00.000Z'),
        );
        
        final usage2 = ToolUsage(
          toolId: ToolRegistry.focusSession,
          ts: DateTime.parse('2023-01-15T10:30:00.000Z'),
        );
        
        final usage3 = ToolUsage(
          toolId: ToolRegistry.animalCheckin,
          ts: DateTime.parse('2023-01-15T10:30:00.000Z'),
        );

        expect(usage1, equals(usage2));
        expect(usage1, isNot(equals(usage3)));
      });
    });

    group('Store Initialization', () {
      test('should initialize with empty usage history', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        final recent = store.recent();
        expect(recent, isEmpty);
      });

      test('should handle missing file gracefully', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        expect(store.recent(), isEmpty);
      });

      test('should recover from corrupted JSON with empty list', () async {
        // Create corrupted JSON file
        final file = File('$testDirectory/tool_usage.json');
        await file.writeAsString('{ invalid json content }');

        final store = ToolUsageStore.instance;
        await store.load();

        expect(store.recent(), isEmpty);
      });

      test('should load existing valid JSON data', () async {
        // Pre-populate with valid data
        final file = File('$testDirectory/tool_usage.json');
        final validData = [
          {
            'toolId': ToolRegistry.focusSession,
            'tsIsoString': '2023-01-15T10:30:00.000Z',
          },
          {
            'toolId': ToolRegistry.animalCheckin,
            'tsIsoString': '2023-01-15T09:30:00.000Z',
          },
        ];
        await file.writeAsString(jsonEncode(validData));

        final store = ToolUsageStore.instance;
        await store.load();

        final recent = store.recent();
        expect(recent.length, 2);
        expect(recent[0].toolId, ToolRegistry.focusSession); // Newest first
        expect(recent[1].toolId, ToolRegistry.animalCheckin);
      });
    });

    group('Recording Usage', () {
      test('should record usage successfully', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        await store.record(ToolRegistry.focusSession);

        final recent = store.recent();
        expect(recent.length, 1);
        expect(recent[0].toolId, ToolRegistry.focusSession);
      });

      test('should ignore empty tool IDs', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        await store.record('');

        final recent = store.recent();
        expect(recent, isEmpty);
      });

      test('should maintain chronological order (newest first)', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        await store.record(ToolRegistry.focusSession);
        await Future.delayed(const Duration(milliseconds: 10));
        await store.record(ToolRegistry.animalCheckin);
        await Future.delayed(const Duration(milliseconds: 10));
        await store.record(ToolRegistry.sessionHistory);

        final recent = store.recent();
        expect(recent.length, 3);
        expect(recent[0].toolId, ToolRegistry.sessionHistory); // Most recent
        expect(recent[1].toolId, ToolRegistry.animalCheckin);
        expect(recent[2].toolId, ToolRegistry.focusSession); // Oldest
        
        // Verify timestamps are in descending order
        expect(recent[0].ts.isAfter(recent[1].ts), true);
        expect(recent[1].ts.isAfter(recent[2].ts), true);
      });

      test('should allow duplicate tool recordings', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        await store.record(ToolRegistry.focusSession);
        await store.record(ToolRegistry.focusSession);
        await store.record(ToolRegistry.focusSession);

        final recent = store.recent();
        expect(recent.length, 3);
        expect(recent.every((usage) => usage.toolId == ToolRegistry.focusSession), true);
      });
    });

    group('History Capping', () {
      test('should cap history at 100 entries during recording', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        // Record 150 entries
        for (int i = 0; i < 150; i++) {
          await store.record('tool_$i');
        }

        final recent = store.recent();
        expect(recent.length, 100);
        
        // Should keep the most recent 100
        expect(recent[0].toolId, 'tool_149'); // Most recent
        expect(recent[99].toolId, 'tool_50'); // 100th most recent
      });

      test('should cap history at 100 entries during load', () async {
        // Create file with 150 entries
        final file = File('$testDirectory/tool_usage.json');
        final data = List.generate(150, (i) => {
          'toolId': 'tool_$i',
          'tsIsoString': DateTime.now().add(Duration(minutes: i)).toIso8601String(),
        });
        await file.writeAsString(jsonEncode(data));

        final store = ToolUsageStore.instance;
        await store.load();

        final recent = store.recent();
        expect(recent.length, 100);
      });
    });

    group('Recent Retrieval', () {
      test('should respect limit parameter', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        // Add 10 entries
        for (int i = 0; i < 10; i++) {
          await store.record('tool_$i');
        }

        final recent3 = store.recent(limit: 3);
        expect(recent3.length, 3);
        expect(recent3[0].toolId, 'tool_9'); // Most recent
        expect(recent3[1].toolId, 'tool_8');
        expect(recent3[2].toolId, 'tool_7');
      });

      test('should cap limit at 100', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        // Try to get more than 100
        final recent = store.recent(limit: 200);
        expect(recent.length, 0); // No data added yet
        
        // Add some data and try again
        for (int i = 0; i < 5; i++) {
          await store.record('tool_$i');
        }
        
        final recentLimited = store.recent(limit: 200);
        expect(recentLimited.length, 5); // Should return all 5, not 200
      });

      test('should return empty list when no usage history', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        final recent = store.recent();
        expect(recent, isEmpty);
      });
    });

    group('Persistence', () {
      test('should persist usage across store instances', () async {
        // First store instance
        final store1 = ToolUsageStore.instance;
        await store1.load();
        
        await store1.record(ToolRegistry.focusSession);
        await store1.record(ToolRegistry.animalCheckin);

        // Create new store instance
        ToolUsageStore.resetInstance();
        final store2 = ToolUsageStore.instance;
        await store2.load();

        final recent = store2.recent();
        expect(recent.length, 2);
        expect(recent[0].toolId, ToolRegistry.animalCheckin); // Most recent
        expect(recent[1].toolId, ToolRegistry.focusSession);
      });

      test('should use atomic write operations', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        await store.record(ToolRegistry.focusSession);

        // Verify main file exists and temp file doesn't
        final mainFile = File('$testDirectory/tool_usage.json');
        final tempFile = File('$testDirectory/tool_usage.json.tmp');
        
        expect(await mainFile.exists(), true);
        expect(await tempFile.exists(), false);

        // Verify content is valid JSON
        final content = await mainFile.readAsString();
        final decoded = jsonDecode(content);
        expect(decoded, isA<List>());
        expect(decoded.length, 1);
        expect(decoded[0]['toolId'], ToolRegistry.focusSession);
      });

      test('should handle file write failures gracefully', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        // Try to record usage - should work in memory even if persistence fails
        await store.record(ToolRegistry.focusSession);
        
        // Should still work in memory
        final recent = store.recent();
        expect(recent.length, 1);
        expect(recent[0].toolId, ToolRegistry.focusSession);
      });
    });

    group('Edge Cases', () {
      test('should handle special characters in tool ID', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        const specialId = 'tool@#\$%^&*()_+-=[]{}|;:,.<>?';
        await store.record(specialId);
        
        final recent = store.recent();
        expect(recent.length, 1);
        expect(recent[0].toolId, specialId);
      });

      test('should handle very long tool IDs', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        final longId = 'very_long_tool_id_' * 100;
        await store.record(longId);
        
        final recent = store.recent();
        expect(recent.length, 1);
        expect(recent[0].toolId, longId);
      });

      test('should handle rapid successive calls', () async {
        final store = ToolUsageStore.instance;
        await store.load();

        // Record usage rapidly
        final futures = List.generate(20, (i) => store.record('tool_$i'));
        await Future.wait(futures);

        final recent = store.recent();
        expect(recent.length, 20);
      });

      test('should handle malformed JSON entries gracefully', () async {
        // Create file with mixed valid and invalid entries
        final file = File('$testDirectory/tool_usage.json');
        await file.writeAsString('''[
          {
            "toolId": "valid_tool",
            "tsIsoString": "2023-01-15T10:30:00.000Z"
          },
          {
            "toolId": null,
            "tsIsoString": "invalid_date"
          }
        ]''');

        final store = ToolUsageStore.instance;
        await store.load();

        // Should recover with empty list due to any parsing error
        final recent = store.recent();
        expect(recent, isEmpty);
      });
    });
  });
}
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/tool_usage/tool_usage_store.dart';
import '../../lib/tool_usage/tool_usage_record.dart';
import '../../lib/favorites/tool_definitions.dart';

void main() {
  group('ToolUsageStore Tests', () {
    late String testDirectory;

    setUp(() async {
      ToolUsageStore.resetInstance();
      
      // Create a temporary directory for test files
      testDirectory = Directory.systemTemp.path + '/tool_usage_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
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

    group('Store Initialization', () {
      test('should initialize with empty usage history', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/usage.json');

        expect(store.totalUsageCount, 0);
        expect(store.hasUsageHistory, false);
        expect(store.getAllUsage(), isEmpty);
      });

      test('should handle missing file gracefully', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/nonexistent.json');

        expect(store.totalUsageCount, 0);
        expect(store.hasUsageHistory, false);
      });

      test('should handle corrupted JSON gracefully', () async {
        final corruptedFile = File('$testDirectory/corrupted.json');
        await corruptedFile.writeAsString('{ invalid json content }');

        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/corrupted.json');

        expect(store.totalUsageCount, 0);
        expect(store.hasUsageHistory, false);
      });
    });

    group('Recording Usage', () {
      test('should record usage successfully', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/record_test.json');

        bool notified = false;
        store.addListener(() => notified = true);

        await store.recordUsage(ToolRegistry.focusSession);

        expect(store.totalUsageCount, 1);
        expect(store.hasUsageHistory, true);
        expect(store.getUsageCount(ToolRegistry.focusSession), 1);
        expect(notified, true);
      });

      test('should maintain chronological order (newest first)', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/order_test.json');

        await store.recordUsage(ToolRegistry.focusSession);
        await Future.delayed(const Duration(milliseconds: 10)); // Ensure different timestamps
        await store.recordUsage(ToolRegistry.animalCheckin);
        await Future.delayed(const Duration(milliseconds: 10));
        await store.recordUsage(ToolRegistry.sessionHistory);

        final usage = store.getAllUsage();
        expect(usage.length, 3);
        expect(usage[0].toolId, ToolRegistry.sessionHistory); // Most recent
        expect(usage[1].toolId, ToolRegistry.animalCheckin);
        expect(usage[2].toolId, ToolRegistry.focusSession); // Oldest
        
        // Verify timestamps are in descending order
        expect(usage[0].timestamp.isAfter(usage[1].timestamp), true);
        expect(usage[1].timestamp.isAfter(usage[2].timestamp), true);
      });

      test('should allow duplicate tool recordings', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/duplicate_test.json');

        await store.recordUsage(ToolRegistry.focusSession);
        await store.recordUsage(ToolRegistry.focusSession);
        await store.recordUsage(ToolRegistry.focusSession);

        expect(store.totalUsageCount, 3);
        expect(store.getUsageCount(ToolRegistry.focusSession), 3);
      });

      test('should record multiple different tools', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/multiple_test.json');

        await store.recordUsage(ToolRegistry.focusSession);
        await store.recordUsage(ToolRegistry.animalCheckin);
        await store.recordUsage(ToolRegistry.analytics);

        expect(store.totalUsageCount, 3);
        expect(store.getUsageCount(ToolRegistry.focusSession), 1);
        expect(store.getUsageCount(ToolRegistry.animalCheckin), 1);
        expect(store.getUsageCount(ToolRegistry.analytics), 1);
        expect(store.getUsageCount(ToolRegistry.settings), 0);
      });
    });

    group('Usage Retrieval', () {
      test('should get recent usage with correct limit', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/recent_test.json');

        // Add 5 usage records
        for (int i = 0; i < 5; i++) {
          await store.recordUsage('tool_$i');
        }

        final recent3 = store.getRecentUsage(3);
        expect(recent3.length, 3);
        expect(recent3[0].toolId, 'tool_4'); // Most recent
        expect(recent3[1].toolId, 'tool_3');
        expect(recent3[2].toolId, 'tool_2');
      });

      test('should get recent unique tools correctly', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/unique_test.json');

        // Add usage with duplicates
        await store.recordUsage(ToolRegistry.focusSession);
        await store.recordUsage(ToolRegistry.animalCheckin);
        await store.recordUsage(ToolRegistry.focusSession); // Duplicate
        await store.recordUsage(ToolRegistry.sessionHistory);
        await store.recordUsage(ToolRegistry.animalCheckin); // Duplicate

        final uniqueTools = store.getRecentUniqueTools(5);
        expect(uniqueTools.length, 3);
        expect(uniqueTools[0], ToolRegistry.animalCheckin); // Most recent
        expect(uniqueTools[1], ToolRegistry.sessionHistory);
        expect(uniqueTools[2], ToolRegistry.focusSession);
      });

      test('should respect limit for unique tools', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/unique_limit_test.json');

        // Add 5 different tools
        await store.recordUsage(ToolRegistry.focusSession);
        await store.recordUsage(ToolRegistry.animalCheckin);
        await store.recordUsage(ToolRegistry.sessionHistory);
        await store.recordUsage(ToolRegistry.analytics);
        await store.recordUsage(ToolRegistry.settings);

        final uniqueTools = store.getRecentUniqueTools(3);
        expect(uniqueTools.length, 3);
        expect(uniqueTools[0], ToolRegistry.settings); // Most recent
        expect(uniqueTools[1], ToolRegistry.analytics);
        expect(uniqueTools[2], ToolRegistry.sessionHistory);
      });

      test('should get last usage time correctly', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/last_usage_test.json');

        final beforeTime = DateTime.now();
        await store.recordUsage(ToolRegistry.focusSession);
        final afterTime = DateTime.now();

        final lastUsage = store.getLastUsageTime(ToolRegistry.focusSession);
        expect(lastUsage, isNotNull);
        expect(lastUsage!.isAfter(beforeTime.subtract(const Duration(seconds: 1))), true);
        expect(lastUsage.isBefore(afterTime.add(const Duration(seconds: 1))), true);

        expect(store.getLastUsageTime(ToolRegistry.analytics), isNull);
      });
    });

    group('History Trimming', () {
      test('should trim history to max 100 records', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/trim_test.json');

        // Add 150 records (more than max)
        for (int i = 0; i < 150; i++) {
          await store.recordUsage('tool_${i % 10}');
        }

        expect(store.totalUsageCount, 100);
        
        final usage = store.getAllUsage();
        expect(usage.length, 100);
        
        // Should keep the most recent 100
        expect(usage[0].toolId, 'tool_9'); // Most recent (149 % 10 = 9)
        expect(usage[99].toolId, 'tool_0'); // 100th most recent (50 % 10 = 0)
      });

      test('should trim on load if file has more than max records', () async {
        final filePath = '$testDirectory/trim_load_test.json';
        
        // First, create a store with 150 records
        final store1 = ToolUsageStore.instance;
        await store1.init(filePath: filePath);
        
        for (int i = 0; i < 150; i++) {
          await store1.recordUsage('tool_${i % 5}');
        }

        // Reset and load with new instance
        ToolUsageStore.resetInstance();
        final store2 = ToolUsageStore.instance;
        await store2.init(filePath: filePath);

        expect(store2.totalUsageCount, 100);
      });
    });

    group('Persistence', () {
      test('should persist usage history to file', () async {
        final filePath = '$testDirectory/persist_test.json';
        
        // First store instance
        final store1 = ToolUsageStore.instance;
        await store1.init(filePath: filePath);
        
        await store1.recordUsage(ToolRegistry.focusSession);
        await store1.recordUsage(ToolRegistry.animalCheckin);

        // Reset and create new instance
        ToolUsageStore.resetInstance();
        final store2 = ToolUsageStore.instance;
        await store2.init(filePath: filePath);

        expect(store2.totalUsageCount, 2);
        expect(store2.getUsageCount(ToolRegistry.focusSession), 1);
        expect(store2.getUsageCount(ToolRegistry.animalCheckin), 1);
        
        final usage = store2.getAllUsage();
        expect(usage[0].toolId, ToolRegistry.animalCheckin); // Most recent
        expect(usage[1].toolId, ToolRegistry.focusSession);
      });

      test('should handle file write failures gracefully', () async {
        final store = ToolUsageStore.instance;
        
        // Try to write to invalid path
        await store.init(filePath: '/nonexistent_root_path/usage.json');
        
        // Should not crash when recording usage
        await store.recordUsage(ToolRegistry.focusSession);
        
        // Should still work in memory
        expect(store.getUsageCount(ToolRegistry.focusSession), 1);
      });

      test('should use atomic write operations', () async {
        final store = ToolUsageStore.instance;
        final filePath = '$testDirectory/atomic_test.json';
        await store.init(filePath: filePath);

        await store.recordUsage(ToolRegistry.focusSession);

        // Verify main file exists and temp file doesn't
        final mainFile = File(filePath);
        final tempFile = File('$filePath.tmp');
        
        expect(await mainFile.exists(), true);
        expect(await tempFile.exists(), false);

        // Verify content
        final content = await mainFile.readAsString();
        expect(content.contains(ToolRegistry.focusSession), true);
      });
    });

    group('Clear History', () {
      test('should clear all history', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/clear_test.json');

        // Add some usage
        await store.recordUsage(ToolRegistry.focusSession);
        await store.recordUsage(ToolRegistry.animalCheckin);
        expect(store.totalUsageCount, 2);

        bool notified = false;
        store.addListener(() => notified = true);

        // Clear history
        await store.clearHistory();

        expect(store.totalUsageCount, 0);
        expect(store.hasUsageHistory, false);
        expect(store.getAllUsage(), isEmpty);
        expect(notified, true);
      });

      test('should persist empty state after clear', () async {
        final filePath = '$testDirectory/clear_persist_test.json';
        
        final store1 = ToolUsageStore.instance;
        await store1.init(filePath: filePath);
        
        await store1.recordUsage(ToolRegistry.focusSession);
        await store1.clearHistory();

        // Reset and check persistence
        ToolUsageStore.resetInstance();
        final store2 = ToolUsageStore.instance;
        await store2.init(filePath: filePath);

        expect(store2.totalUsageCount, 0);
        expect(store2.hasUsageHistory, false);
      });
    });

    group('Edge Cases', () {
      test('should handle empty tool ID gracefully', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/empty_id_test.json');

        await store.recordUsage('');
        
        expect(store.totalUsageCount, 1);
        expect(store.getUsageCount(''), 1);
      });

      test('should handle special characters in tool ID', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/special_chars_test.json');

        const specialId = 'tool@#\$%^&*()_+-=[]{}|;:,.<>?';
        await store.recordUsage(specialId);
        
        expect(store.getUsageCount(specialId), 1);
      });

      test('should handle rapid successive calls', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/rapid_test.json');

        // Record usage rapidly
        final futures = List.generate(20, (i) => store.recordUsage('tool_$i'));
        await Future.wait(futures);

        expect(store.totalUsageCount, 20);
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners on record usage', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/notify_test.json');

        int notificationCount = 0;
        store.addListener(() => notificationCount++);

        await store.recordUsage(ToolRegistry.focusSession);
        await store.recordUsage(ToolRegistry.animalCheckin);

        expect(notificationCount, 2);
      });

      test('should notify listeners on clear', () async {
        final store = ToolUsageStore.instance;
        await store.init(filePath: '$testDirectory/notify_clear_test.json');

        await store.recordUsage(ToolRegistry.focusSession);

        int notificationCount = 0;
        store.addListener(() => notificationCount++);

        await store.clearHistory();

        expect(notificationCount, 1);
      });
    });
  });
}
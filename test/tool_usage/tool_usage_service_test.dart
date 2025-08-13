import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/tool_usage/tool_usage_service.dart';
import '../../lib/tool_usage/tool_usage_store.dart';
import '../../lib/favorites/tool_definitions.dart';

void main() {
  group('ToolUsageService Tests', () {
    late String testDirectory;

    setUp(() async {
      ToolUsageService.resetInstance();
      
      // Create a temporary directory for test files
      testDirectory = Directory.systemTemp.path + '/tool_usage_service_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
    });

    tearDown(() async {
      ToolUsageService.resetInstance();
      
      // Clean up test directory
      try {
        await Directory(testDirectory).delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Service Initialization', () {
      test('should initialize service and store', () async {
        final service = ToolUsageService.instance;
        await service.init();

        expect(service.hasUsageHistory, false);
      });

      test('should provide access to store', () async {
        final service = ToolUsageService.instance;
        await service.init();

        expect(service.store, isA<ToolUsageStore>());
      });
    });

    group('Recording Usage', () {
      test('should record usage through service', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_record_test.json');

        await service.recordUsage(ToolRegistry.focusSession);

        expect(service.hasUsageHistory, true);
        expect(store.getUsageCount(ToolRegistry.focusSession), 1);
      });

      test('should ignore empty tool IDs', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_empty_test.json');

        await service.recordUsage('');

        expect(service.hasUsageHistory, false);
        expect(store.totalUsageCount, 0);
      });

      test('should record multiple usages', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_multiple_test.json');

        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);
        await service.recordUsage(ToolRegistry.analytics);

        expect(store.totalUsageCount, 3);
      });
    });

    group('Usage Retrieval', () {
      test('should get recent usage with timestamps', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_recent_test.json');

        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);

        final recentUsage = service.getRecentUsage(5);
        expect(recentUsage.length, 2);
        expect(recentUsage[0].toolId, ToolRegistry.animalCheckin); // Most recent
        expect(recentUsage[1].toolId, ToolRegistry.focusSession);
        
        // Check timestamps are present
        expect(recentUsage[0].timestamp, isNotNull);
        expect(recentUsage[1].timestamp, isNotNull);
      });

      test('should get recent unique tools', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_unique_test.json');

        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);
        await service.recordUsage(ToolRegistry.focusSession); // Duplicate
        await service.recordUsage(ToolRegistry.sessionHistory);

        final uniqueTools = service.getRecentUniqueTools(5);
        expect(uniqueTools.length, 3);
        expect(uniqueTools[0], ToolRegistry.sessionHistory); // Most recent
        expect(uniqueTools[1], ToolRegistry.focusSession); // Latest non-duplicate focus session
        expect(uniqueTools[2], ToolRegistry.animalCheckin);
      });

      test('should respect limit for recent usage', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_limit_test.json');

        // Add 10 usages
        for (int i = 0; i < 10; i++) {
          await service.recordUsage('tool_$i');
        }

        final recent3 = service.getRecentUsage(3);
        expect(recent3.length, 3);
        expect(recent3[0].toolId, 'tool_9'); // Most recent
        expect(recent3[1].toolId, 'tool_8');
        expect(recent3[2].toolId, 'tool_7');
      });
    });

    group('Tool Statistics', () {
      test('should get tool usage statistics', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_stats_test.json');

        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);

        final focusStats = service.getToolStats(ToolRegistry.focusSession);
        expect(focusStats.toolId, ToolRegistry.focusSession);
        expect(focusStats.usageCount, 2);
        expect(focusStats.lastUsed, isNotNull);

        final checkinStats = service.getToolStats(ToolRegistry.animalCheckin);
        expect(checkinStats.toolId, ToolRegistry.animalCheckin);
        expect(checkinStats.usageCount, 1);
        expect(checkinStats.lastUsed, isNotNull);

        final settingsStats = service.getToolStats(ToolRegistry.settings);
        expect(settingsStats.toolId, ToolRegistry.settings);
        expect(settingsStats.usageCount, 0);
        expect(settingsStats.lastUsed, isNull);
      });

      test('should get overall usage statistics', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_overall_test.json');

        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);
        await service.recordUsage(ToolRegistry.focusSession); // Duplicate tool
        await service.recordUsage(ToolRegistry.sessionHistory);

        final overallStats = service.getOverallStats();
        expect(overallStats.totalUsageCount, 4);
        expect(overallStats.uniqueToolsUsed, 3); // 3 unique tools
        expect(overallStats.lastActivity, isNotNull);
      });

      test('should handle empty statistics correctly', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_empty_stats_test.json');

        final focusStats = service.getToolStats(ToolRegistry.focusSession);
        expect(focusStats.usageCount, 0);
        expect(focusStats.lastUsed, isNull);

        final overallStats = service.getOverallStats();
        expect(overallStats.totalUsageCount, 0);
        expect(overallStats.uniqueToolsUsed, 0);
        expect(overallStats.lastActivity, isNull);
      });
    });

    group('Clear History', () {
      test('should clear history through service', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_clear_test.json');

        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);
        
        expect(service.hasUsageHistory, true);

        await service.clearHistory();

        expect(service.hasUsageHistory, false);
        expect(store.totalUsageCount, 0);
      });
    });

    group('Integration with Store', () {
      test('should maintain consistency with store', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_consistency_test.json');

        // Record through service
        await service.recordUsage(ToolRegistry.focusSession);
        
        // Verify through store
        expect(store.getUsageCount(ToolRegistry.focusSession), 1);
        expect(store.hasUsageHistory, true);

        // Record through store
        await store.recordUsage(ToolRegistry.animalCheckin);
        
        // Verify through service
        expect(service.hasUsageHistory, true);
        final uniqueTools = service.getRecentUniqueTools(5);
        expect(uniqueTools.contains(ToolRegistry.animalCheckin), true);
      });

      test('should notify listeners through store', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_notify_test.json');

        int notificationCount = 0;
        store.addListener(() => notificationCount++);

        await service.recordUsage(ToolRegistry.focusSession);
        await service.clearHistory();

        expect(notificationCount, 2); // One for record, one for clear
      });
    });

    group('Edge Cases', () {
      test('should handle rapid successive service calls', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_rapid_test.json');

        // Record usage rapidly through service
        final futures = List.generate(20, (i) => service.recordUsage('tool_$i'));
        await Future.wait(futures);

        expect(store.totalUsageCount, 20);
        
        final uniqueTools = service.getRecentUniqueTools(25);
        expect(uniqueTools.length, 20);
      });

      test('should handle null and invalid inputs gracefully', () async {
        final service = ToolUsageService.instance;
        final store = service.store;
        await store.init(filePath: '$testDirectory/service_invalid_test.json');

        // These should not crash
        await service.recordUsage('');
        final stats = service.getToolStats('nonexistent_tool');
        final recentUsage = service.getRecentUsage(0);
        final uniqueTools = service.getRecentUniqueTools(-1);

        expect(stats.usageCount, 0);
        expect(recentUsage, isEmpty);
        expect(uniqueTools, isEmpty);
      });
    });
  });
}
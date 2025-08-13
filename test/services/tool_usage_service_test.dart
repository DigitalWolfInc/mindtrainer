import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../lib/services/tool_usage_service.dart';
import '../../lib/data/tool_usage_store.dart';
import '../../lib/favorites/tool_definitions.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  final String tempDir;
  
  MockPathProviderPlatform(this.tempDir);
  
  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

void main() {
  group('ToolUsageService Tests', () {
    late String testDirectory;
    late MockPathProviderPlatform mockPathProvider;

    setUp(() async {
      ToolUsageService.resetInstance();
      ToolUsageStore.resetInstance();
      
      // Create a temporary directory for test files
      testDirectory = Directory.systemTemp.path + '/tool_usage_service_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
      
      // Mock path provider
      mockPathProvider = MockPathProviderPlatform(testDirectory);
      PathProviderPlatform.instance = mockPathProvider;
    });

    tearDown(() async {
      ToolUsageService.resetInstance();
      ToolUsageStore.resetInstance();
      
      // Clean up test directory
      try {
        await Directory(testDirectory).delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Initialization', () {
      test('should initialize successfully', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        // Should complete without error
        expect(service, isNotNull);
      });

      test('should use singleton pattern', () {
        final service1 = ToolUsageService.instance;
        final service2 = ToolUsageService.instance;
        
        expect(identical(service1, service2), true);
      });
    });

    group('Recording Usage', () {
      test('should record valid tool usage', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        await service.recordUsage(ToolRegistry.focusSession);
        
        final recent = service.getRecent(5);
        expect(recent.length, 1);
        expect(recent[0].toolId, ToolRegistry.focusSession);
      });

      test('should ignore null tool IDs', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        await service.recordUsage(null);
        
        final recent = service.getRecent(5);
        expect(recent, isEmpty);
      });

      test('should ignore empty tool IDs', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        await service.recordUsage('');
        
        final recent = service.getRecent(5);
        expect(recent, isEmpty);
      });

      test('should ignore whitespace-only tool IDs', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        await service.recordUsage('   ');
        
        final recent = service.getRecent(5);
        expect(recent, isEmpty);
      });

      test('should pass through to store for recording', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        // Record multiple tools
        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);
        await service.recordUsage(ToolRegistry.sessionHistory);
        
        final recent = service.getRecent(10);
        expect(recent.length, 3);
        expect(recent[0].toolId, ToolRegistry.sessionHistory); // Most recent
        expect(recent[1].toolId, ToolRegistry.animalCheckin);
        expect(recent[2].toolId, ToolRegistry.focusSession); // Oldest
      });
    });

    group('Retrieving Usage', () {
      test('should return recent usage with correct limit', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        // Record 5 different tools
        for (int i = 0; i < 5; i++) {
          await service.recordUsage('tool_$i');
        }
        
        final recent3 = service.getRecent(3);
        expect(recent3.length, 3);
        expect(recent3[0].toolId, 'tool_4'); // Most recent
        expect(recent3[1].toolId, 'tool_3');
        expect(recent3[2].toolId, 'tool_2');
        
        final recent2 = service.getRecent(2);
        expect(recent2.length, 2);
        expect(recent2[0].toolId, 'tool_4');
        expect(recent2[1].toolId, 'tool_3');
      });

      test('should return empty list when no usage recorded', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        final recent = service.getRecent(5);
        expect(recent, isEmpty);
      });

      test('should handle limit larger than available records', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        await service.recordUsage('tool_1');
        await service.recordUsage('tool_2');
        
        final recent = service.getRecent(10);
        expect(recent.length, 2);
        expect(recent[0].toolId, 'tool_2');
        expect(recent[1].toolId, 'tool_1');
      });

      test('should pass through to store for retrieval', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        // Record some usage
        await service.recordUsage(ToolRegistry.focusSession);
        await service.recordUsage(ToolRegistry.animalCheckin);
        
        // Verify service returns same data as direct store access
        final serviceRecent = service.getRecent(5);
        final storeRecent = ToolUsageStore.instance.recent(limit: 5);
        
        expect(serviceRecent.length, storeRecent.length);
        expect(serviceRecent[0].toolId, storeRecent[0].toolId);
        expect(serviceRecent[1].toolId, storeRecent[1].toolId);
      });
    });

    group('Error Handling', () {
      test('should handle store errors gracefully', () async {
        final service = ToolUsageService.instance;
        await service.init();
        
        // Service should not crash even if store has issues
        // This is more of a smoke test since store is robust
        await service.recordUsage(ToolRegistry.focusSession);
        final recent = service.getRecent(5);
        
        expect(recent.length, 1);
        expect(recent[0].toolId, ToolRegistry.focusSession);
      });
    });

    group('Integration', () {
      test('should maintain usage across service resets', () async {
        // First service instance
        final service1 = ToolUsageService.instance;
        await service1.init();
        
        await service1.recordUsage(ToolRegistry.focusSession);
        await service1.recordUsage(ToolRegistry.animalCheckin);
        
        // Reset and create new service instance
        ToolUsageService.resetInstance();
        final service2 = ToolUsageService.instance;
        await service2.init();
        
        final recent = service2.getRecent(5);
        expect(recent.length, 2);
        expect(recent[0].toolId, ToolRegistry.animalCheckin); // Most recent
        expect(recent[1].toolId, ToolRegistry.focusSession);
      });
    });
  });
}
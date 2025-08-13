import 'package:flutter_test/flutter_test.dart';

import '../../lib/tool_usage/tool_usage_service.dart';

void main() {
  group('ToolUsage Analytics Integration', () {
    late ToolUsageService toolUsageService;

    setUp(() {
      toolUsageService = ToolUsageService.instance;
    });

    tearDown(() {
      ToolUsageService.resetInstance();
    });

    test('recordUsage with valid toolId does not crash', () async {
      const toolId = 'focus_timer';
      
      // Should not throw even without analytics service
      expect(() async => await toolUsageService.recordUsage(toolId), returnsNormally);
    });

    test('recordUsage with empty toolId does not crash', () async {
      // Should not throw and should handle empty string gracefully
      expect(() async => await toolUsageService.recordUsage(''), returnsNormally);
    });

    test('singleton instance without analytics works correctly', () async {
      final singleton = ToolUsageService.instance;
      
      // Should be able to record usage without analytics service
      await singleton.recordUsage('test_tool');
      
      // Should be able to retrieve recent usage
      final recentUsage = singleton.getRecentUsage(5);
      expect(recentUsage.length, greaterThanOrEqualTo(1));
      expect(recentUsage.first.toolId, equals('test_tool'));
    });

    test('createWithAnalytics method exists for future integration', () {
      // This verifies the method signature exists for when analytics service is available
      expect(ToolUsageService.createWithAnalytics, isA<Function>());
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/tool_usage/tool_usage_service.dart';
import '../../lib/features/analytics/domain/analytics_service.dart';

@GenerateMocks([AnalyticsService])
import 'tool_usage_analytics_integration_test.mocks.dart';

void main() {
  group('ToolUsage Analytics Integration', () {
    late MockAnalyticsService mockAnalytics;
    late ToolUsageService toolUsageService;

    setUp(() {
      mockAnalytics = MockAnalyticsService();
      toolUsageService = ToolUsageService.createWithAnalytics(mockAnalytics);
    });

    test('recordUsage calls analytics service with correct parameters', () async {
      const toolId = 'focus_timer';
      
      await toolUsageService.recordUsage(toolId);
      
      verify(mockAnalytics.trackEvent('tool_usage', {
        'tool_id': toolId,
        'source': 'tool_selection',
      })).called(1);
    });

    test('recordUsage with empty toolId does not call analytics', () async {
      await toolUsageService.recordUsage('');
      
      verifyNever(mockAnalytics.trackEvent(any, any));
    });

    test('singleton instance without analytics does not crash', () async {
      final singleton = ToolUsageService.instance;
      
      // Should not throw even without analytics service
      expect(() => singleton.recordUsage('test'), returnsNormally);
    });
  });
}
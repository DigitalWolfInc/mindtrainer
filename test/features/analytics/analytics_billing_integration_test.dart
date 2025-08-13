/// Integration tests for analytics with both fake and real billing modes
/// Tests Pro feature gating across different billing configurations

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/analytics/domain/analytics_service.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/billing/billing_adapter.dart';
import 'package:mindtrainer/core/billing/pro_catalog.dart';

void main() {
  group('Analytics Billing Integration', () {
    
    group('Fake Billing Mode', () {
      late FakeBillingAdapter fakeAdapter;
      late MindTrainerProGates proGates;
      late AdvancedAnalyticsService analyticsService;
      
      setUp(() {
        fakeAdapter = BillingAdapterFactory.createFake();
        proGates = MindTrainerProGates(() => fakeAdapter.isProActive);
        analyticsService = AdvancedAnalyticsService(proGates);
      });
      
      tearDown(() {
        fakeAdapter.dispose();
      });
      
      test('should provide free analytics when Pro inactive', () {
        expect(fakeAdapter.isProActive, false);
        
        final basicAnalytics = analyticsService.getBasicAnalytics();
        final moodCorrelations = analyticsService.getMoodFocusCorrelations();
        final tagInsights = analyticsService.getTagPerformanceInsights();
        final keywordAnalysis = analyticsService.getKeywordUpliftAnalysis();
        
        // Basic analytics should work
        expect(basicAnalytics.totalSessions, greaterThan(0));
        expect(basicAnalytics.averageFocusScore, greaterThan(0));
        
        // Pro features should be empty
        expect(moodCorrelations, isEmpty);
        expect(tagInsights, isEmpty);
        expect(keywordAnalysis, isEmpty);
        
        // History should be limited
        expect(analyticsService.historyWindowDays, 30);
        expect(analyticsService.hasExtendedHistory, false);
      });
      
      test('should provide Pro analytics when activated', () {
        // Activate Pro
        fakeAdapter.simulateProActivation(ProCatalog.monthlyProductId);
        expect(fakeAdapter.isProActive, true);
        
        final basicAnalytics = analyticsService.getBasicAnalytics();
        final moodCorrelations = analyticsService.getMoodFocusCorrelations();
        final tagInsights = analyticsService.getTagPerformanceInsights();
        final keywordAnalysis = analyticsService.getKeywordUpliftAnalysis();
        
        // Basic analytics should still work
        expect(basicAnalytics.totalSessions, greaterThan(0));
        
        // Pro features should now be available
        expect(moodCorrelations, isNotEmpty);
        expect(moodCorrelations.length, 5);
        expect(tagInsights, isNotEmpty);
        expect(tagInsights.length, 6);
        expect(keywordAnalysis, isNotEmpty);
        expect(keywordAnalysis.length, 5);
        
        // History should be unlimited
        expect(analyticsService.historyWindowDays, -1);
        expect(analyticsService.hasExtendedHistory, true);
      });
      
      test('should handle Pro expiration correctly', () {
        // Start with Pro active
        fakeAdapter.simulateProActivation(ProCatalog.yearlyProductId);
        expect(fakeAdapter.isProActive, true);
        expect(analyticsService.getMoodFocusCorrelations(), isNotEmpty);
        
        // Expire Pro
        fakeAdapter.simulateProExpiration();
        expect(fakeAdapter.isProActive, false);
        
        // Pro features should be locked again
        expect(analyticsService.getMoodFocusCorrelations(), isEmpty);
        expect(analyticsService.getTagPerformanceInsights(), isEmpty);
        expect(analyticsService.getKeywordUpliftAnalysis(), isEmpty);
        expect(analyticsService.hasExtendedHistory, false);
      });
      
      test('should show correct Pro summary states', () {
        // Free user summary
        final freeSummary = analyticsService.getProAnalyticsSummary();
        expect(freeSummary['available'], false);
        expect(freeSummary['lockedFeatures'], isNotEmpty);
        expect(freeSummary['lockedFeatures'], contains('Mood-Focus Correlations'));
        
        // Pro user summary
        fakeAdapter.simulateProActivation(ProCatalog.monthlyProductId);
        final proSummary = analyticsService.getProAnalyticsSummary();
        expect(proSummary['available'], true);
        expect(proSummary['moodCorrelationCount'], 5);
        expect(proSummary['tagInsightCount'], 6);
        expect(proSummary['keywordAnalysisCount'], 5);
        expect(proSummary['topMoodForFocus'], isNotNull);
        expect(proSummary['bestPerformingTag'], isNotNull);
        expect(proSummary['topKeywordUplift'], isNotNull);
      });
    });
    
    group('Real Billing Mode', () {
      late GooglePlayBillingAdapter realAdapter;
      late MindTrainerProGates proGates;
      late AdvancedAnalyticsService analyticsService;
      
      setUp(() {
        realAdapter = BillingAdapterFactory.createReal();
        proGates = MindTrainerProGates(() => realAdapter.isProActive);
        analyticsService = AdvancedAnalyticsService(proGates);
      });
      
      tearDown(() {
        realAdapter.dispose();
      });
      
      test('should provide free analytics when Pro not active', () {
        expect(realAdapter.isProActive, false);
        
        final basicAnalytics = analyticsService.getBasicAnalytics();
        final moodCorrelations = analyticsService.getMoodFocusCorrelations();
        final tagInsights = analyticsService.getTagPerformanceInsights();
        final keywordAnalysis = analyticsService.getKeywordUpliftAnalysis();
        
        // Basic analytics should work
        expect(basicAnalytics.totalSessions, greaterThan(0));
        expect(basicAnalytics.averageFocusScore, greaterThan(0));
        
        // Pro features should be empty (no active subscription)
        expect(moodCorrelations, isEmpty);
        expect(tagInsights, isEmpty);
        expect(keywordAnalysis, isEmpty);
        
        // History should be limited
        expect(analyticsService.historyWindowDays, 30);
        expect(analyticsService.hasExtendedHistory, false);
      });
      
      test('should handle billing initialization gracefully', () async {
        // Real adapter should not throw when trying to connect
        expect(() async {
          await realAdapter.startConnection();
          await realAdapter.queryProductDetails([
            ProCatalog.monthlyProductId,
            ProCatalog.yearlyProductId,
          ]);
          await realAdapter.queryPurchases();
        }, returnsNormally);
      });
      
      test('should maintain Pro state consistency', () {
        // Real adapter starts with no Pro
        expect(realAdapter.isProActive, false);
        expect(analyticsService.getMoodFocusCorrelations(), isEmpty);
        
        // If Pro were active (simulated), analytics should respond
        expect(proGates.advancedAnalytics, false);
        expect(proGates.moodFocusCorrelations, false);
        expect(proGates.tagAssociations, false);
        expect(proGates.keywordUplift, false);
      });
    });
    
    group('Mode Switching', () {
      test('should handle switching from fake to real billing', () {
        // Start with fake adapter (Pro active)
        final fakeAdapter = BillingAdapterFactory.createFake();
        fakeAdapter.simulateProActivation(ProCatalog.monthlyProductId);
        
        final fakeGates = MindTrainerProGates(() => fakeAdapter.isProActive);
        final fakeService = AdvancedAnalyticsService(fakeGates);
        
        expect(fakeAdapter.isProActive, true);
        expect(fakeService.getMoodFocusCorrelations(), isNotEmpty);
        
        // Switch to real adapter (no Pro active)
        final realAdapter = BillingAdapterFactory.createReal();
        final realGates = MindTrainerProGates(() => realAdapter.isProActive);
        final realService = AdvancedAnalyticsService(realGates);
        
        expect(realAdapter.isProActive, false);
        expect(realService.getMoodFocusCorrelations(), isEmpty);
        
        // Both services should provide basic analytics
        final fakeBasic = fakeService.getBasicAnalytics();
        final realBasic = realService.getBasicAnalytics();
        
        expect(fakeBasic.totalSessions, greaterThan(0));
        expect(realBasic.totalSessions, greaterThan(0));
        
        fakeAdapter.dispose();
        realAdapter.dispose();
      });
    });
    
    group('Upgrade/Downgrade Scenarios', () {
      late FakeBillingAdapter adapter;
      late MindTrainerProGates proGates;
      late AdvancedAnalyticsService analyticsService;
      
      setUp(() {
        adapter = BillingAdapterFactory.createFake();
        proGates = MindTrainerProGates(() => adapter.isProActive);
        analyticsService = AdvancedAnalyticsService(proGates);
      });
      
      tearDown(() {
        adapter.dispose();
      });
      
      test('should handle monthly to yearly upgrade', () {
        // Start with monthly Pro
        adapter.simulateProActivation(ProCatalog.monthlyProductId);
        expect(adapter.isProActive, true);
        expect(adapter.activeProPurchase!.productId, ProCatalog.monthlyProductId);
        expect(analyticsService.getMoodFocusCorrelations(), isNotEmpty);
        
        // Upgrade to yearly (cancel monthly, purchase yearly)
        adapter.simulateProExpiration();
        adapter.simulateProActivation(ProCatalog.yearlyProductId);
        
        expect(adapter.isProActive, true);
        expect(adapter.activeProPurchase!.productId, ProCatalog.yearlyProductId);
        expect(analyticsService.getMoodFocusCorrelations(), isNotEmpty);
        
        // Analytics should remain available throughout
        final summary = analyticsService.getProAnalyticsSummary();
        expect(summary['available'], true);
      });
      
      test('should handle yearly to monthly downgrade', () {
        // Start with yearly Pro
        adapter.simulateProActivation(ProCatalog.yearlyProductId);
        expect(adapter.isProActive, true);
        expect(analyticsService.hasExtendedHistory, true);
        
        // Downgrade to monthly (cancel yearly, purchase monthly)
        adapter.simulateProExpiration();
        adapter.simulateProActivation(ProCatalog.monthlyProductId);
        
        expect(adapter.isProActive, true);
        expect(adapter.activeProPurchase!.productId, ProCatalog.monthlyProductId);
        expect(analyticsService.hasExtendedHistory, true); // Still Pro, so still unlimited
        
        // Analytics should remain available
        expect(analyticsService.getMoodFocusCorrelations(), isNotEmpty);
        expect(analyticsService.getTagPerformanceInsights(), isNotEmpty);
      });
      
      test('should handle subscription expiration gracefully', () {
        // Active Pro subscription
        adapter.simulateProActivation(ProCatalog.monthlyProductId);
        expect(analyticsService.getMoodFocusCorrelations(), isNotEmpty);
        
        // Subscription expires
        adapter.simulateProExpiration();
        
        // Pro features should be locked
        expect(analyticsService.getMoodFocusCorrelations(), isEmpty);
        expect(analyticsService.hasExtendedHistory, false);
        
        // But basic analytics should still work
        final basicAnalytics = analyticsService.getBasicAnalytics();
        expect(basicAnalytics.totalSessions, greaterThan(0));
      });
    });
    
    group('Compliance Validation', () {
      test('should ensure no essential features are locked', () {
        final adapter = BillingAdapterFactory.createFake();
        final proGates = MindTrainerProGates(() => adapter.isProActive);
        final analyticsService = AdvancedAnalyticsService(proGates);
        
        expect(adapter.isProActive, false);
        
        // Essential analytics should work without Pro
        final basicAnalytics = analyticsService.getBasicAnalytics();
        expect(basicAnalytics.totalSessions, greaterThan(0));
        expect(basicAnalytics.averageFocusScore, greaterThan(0));
        expect(basicAnalytics.totalFocusTime, greaterThan(Duration.zero));
        expect(basicAnalytics.topTags, isNotEmpty);
        
        // User should be able to see what Pro offers
        final summary = analyticsService.getProAnalyticsSummary();
        expect(summary['lockedFeatures'], isNotEmpty);
        expect(summary['lockedFeatures'], contains('Mood-Focus Correlations'));
        
        adapter.dispose();
      });
      
      test('should provide genuine additional value in Pro features', () {
        final adapter = BillingAdapterFactory.createFake();
        final proGates = MindTrainerProGates(() => adapter.isProActive);
        final analyticsService = AdvancedAnalyticsService(proGates);
        
        // Free features
        final freeBasic = analyticsService.getBasicAnalytics();
        
        // Activate Pro
        adapter.simulateProActivation(ProCatalog.monthlyProductId);
        
        // Pro features
        final proBasic = analyticsService.getBasicAnalytics();
        final moodCorrelations = analyticsService.getMoodFocusCorrelations();
        final tagInsights = analyticsService.getTagPerformanceInsights();
        final keywordAnalysis = analyticsService.getKeywordUpliftAnalysis();
        
        // Basic features should be the same
        expect(proBasic.totalSessions, freeBasic.totalSessions);
        
        // Pro should add substantial additional value
        expect(moodCorrelations.length, 5);
        expect(tagInsights.length, 6);
        expect(keywordAnalysis.length, 5);
        
        // Each Pro feature should provide meaningful data
        for (final correlation in moodCorrelations) {
          expect(correlation.mood, isNotEmpty);
          expect(correlation.sessionCount, greaterThan(0));
          expect(correlation.trend, isNotEmpty);
        }
        
        for (final insight in tagInsights) {
          expect(insight.tag, isNotEmpty);
          expect(insight.usageCount, greaterThan(0));
          expect(insight.averageFocusScore, greaterThan(0));
        }
        
        for (final keyword in keywordAnalysis) {
          expect(keyword.keyword, isNotEmpty);
          expect(keyword.sessionCount, greaterThan(0));
          expect(keyword.context, isNotEmpty);
        }
        
        adapter.dispose();
      });
    });
  });
}
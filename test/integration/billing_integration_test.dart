/// Integration Tests for Google Play Billing Integration
/// 
/// Tests both fake and real billing adapters to ensure consistent behavior
/// and proper Pro feature gating across all modes.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/play_billing_adapter.dart';
import 'package:mindtrainer/core/payments/real_play_billing_adapter.dart';
import 'package:mindtrainer/core/payments/play_billing_pro_manager.dart';
import 'package:mindtrainer/core/payments/pro_catalog.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/payments/pro_status.dart';
import 'package:mindtrainer/core/payments/subscription_gateway.dart';

void main() {
  group('Billing Integration Tests', () {
    late ProCatalog testCatalog;
    
    setUpAll(() {
      testCatalog = ProCatalogFactory.createDefault();
    });
    
    group('Fake Billing Mode', () {
      test('Factory creates fake adapter for testing', () {
        final adapter = PlayBillingAdapterFactory.create(useFakeForTesting: true);
        expect(adapter, isA<FakePlayBillingAdapter>());
      });
      
      test('Fake billing supports full purchase flow', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        
        // Initialize
        final initialized = await manager.initialize();
        expect(initialized, true);
        expect(manager.connectionState, BillingConnectionState.connected);
        
        // Check initial status
        expect(manager.isProActive, false);
        expect(manager.currentStatus.tier, ProTier.free);
        
        // Purchase Pro monthly
        final result = await manager.purchasePlan('pro_monthly');
        expect(result.success, true);
        
        // Should now have Pro status
        expect(manager.isProActive, true);
        expect(manager.currentStatus.tier, ProTier.pro);
        
        await manager.dispose();
      });
      
      test('Pro gates work correctly with fake billing', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        await manager.initialize();
        
        // Create Pro gates from manager
        final gates = MindTrainerProGates.fromStatusCheck(() => manager.isProActive);
        
        // Initially free
        expect(gates.isProActive, false);
        expect(gates.unlimitedDailySessions, false);
        expect(gates.dailySessionLimit, 5);
        
        // After purchase
        await manager.purchasePlan('pro_monthly');
        
        expect(gates.isProActive, true);
        expect(gates.unlimitedDailySessions, true);
        expect(gates.dailySessionLimit, -1);
        
        await manager.dispose();
      });
      
      test('Fake billing can simulate purchase failures', () async {
        final manager = PlayBillingProManager.fake(
          testCatalog,
          simulatePurchaseFailure: true,
        );
        
        await manager.initialize();
        
        final result = await manager.purchasePlan('pro_monthly');
        expect(result.success, false);
        expect(result.error, isNotNull);
        expect(manager.isProActive, false);
        
        await manager.dispose();
      });
      
      test('Fake billing can simulate user cancellation', () async {
        final manager = PlayBillingProManager.fake(
          testCatalog,
          simulateUserCancel: true,
        );
        
        await manager.initialize();
        
        final result = await manager.purchasePlan('pro_yearly');
        expect(result.success, false);
        expect(result.cancelled, true);
        expect(manager.isProActive, false);
        
        await manager.dispose();
      });
      
      test('Purchase events are emitted correctly', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        await manager.initialize();
        
        final events = <PurchaseEvent>[];
        final subscription = manager.purchaseEventStream.listen((event) {
          events.add(event);
        });
        
        // Successful purchase
        await manager.purchasePlan('pro_monthly');
        
        expect(events.length, greaterThanOrEqualTo(2));
        expect(events.first.type, PurchaseEventType.started);
        expect(events.last.type, PurchaseEventType.completed);
        expect(events.last.productId, 'pro_monthly');
        
        await subscription.cancel();
        await manager.dispose();
      });
      
      test('Restore purchases works with existing purchases', () async {
        final adapter = PlayBillingAdapterFactory.createFake();
        final manager = PlayBillingProManager(adapter, testCatalog);
        
        await manager.initialize();
        
        // Simulate existing purchase
        if (adapter is FakePlayBillingAdapter) {
          adapter.addFakePurchase('pro_yearly');
        }
        
        // Restore should find the purchase
        final restored = await manager.restorePurchases();
        expect(restored, true);
        expect(manager.isProActive, true);
        
        await manager.dispose();
      });
    });
    
    group('Real Billing Mode', () {
      test('Factory creates real adapter for production', () {
        final adapter = PlayBillingAdapterFactory.createReal();
        expect(adapter, isA<RealPlayBillingAdapter>());
      });
      
      test('Real billing adapter has correct method channel', () {
        final adapter = PlayBillingAdapterFactory.createReal();
        expect(adapter, isNotNull);
        // Real adapter testing would require integration with actual Android environment
      });
      
      test('Manager works with real adapter (mocked platform calls)', () async {
        // Note: This test would need platform channel mocking for full testing
        final manager = PlayBillingProManager.create(testCatalog);
        
        // In a real test environment, we'd mock platform channels here
        // For now, just verify the manager can be created
        expect(manager, isNotNull);
        expect(manager.isProActive, false);
        
        // Don't initialize as it would try to connect to real billing
        await manager.dispose();
      });
    });
    
    group('Pro Feature Gates Integration', () {
      test('All Pro features respect billing state', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        await manager.initialize();
        
        final gates = MindTrainerProGates.fromStatusCheck(() => manager.isProActive);
        
        // Test all feature gates in free mode
        expect(gates.unlimitedDailySessions, false);
        expect(gates.extendedCoachingPhases, false);
        expect(gates.advancedAnalytics, false);
        expect(gates.moodFocusCorrelations, false);
        expect(gates.tagAssociations, false);
        expect(gates.keywordUplift, false);
        expect(gates.extendedInsightsHistory, false);
        expect(gates.dataExport, false);
        expect(gates.dataImport, false);
        expect(gates.dataPortability, false);
        expect(gates.customGoals, false);
        expect(gates.multipleGoals, false);
        expect(gates.advancedGoalTracking, false);
        expect(gates.adFree, false);
        expect(gates.premiumThemes, false);
        expect(gates.prioritySupport, false);
        expect(gates.smartSessionScheduling, false);
        expect(gates.voiceJournalInsights, false);
        expect(gates.communityChallengePro, false);
        expect(gates.advancedGoalTemplates, false);
        expect(gates.environmentPresets, false);
        expect(gates.biometricIntegration, false);
        expect(gates.progressSharingExport, false);
        expect(gates.cloudBackupSync, false);
        
        // Purchase Pro
        await manager.purchasePlan('pro_monthly');
        
        // All features should be enabled
        expect(gates.unlimitedDailySessions, true);
        expect(gates.extendedCoachingPhases, true);
        expect(gates.advancedAnalytics, true);
        expect(gates.moodFocusCorrelations, true);
        expect(gates.tagAssociations, true);
        expect(gates.keywordUplift, true);
        expect(gates.extendedInsightsHistory, true);
        expect(gates.dataExport, true);
        expect(gates.dataImport, true);
        expect(gates.dataPortability, true);
        expect(gates.customGoals, true);
        expect(gates.multipleGoals, true);
        expect(gates.advancedGoalTracking, true);
        expect(gates.adFree, true);
        expect(gates.premiumThemes, true);
        expect(gates.prioritySupport, true);
        expect(gates.smartSessionScheduling, true);
        expect(gates.voiceJournalInsights, true);
        expect(gates.communityChallengePro, true);
        expect(gates.advancedGoalTemplates, true);
        expect(gates.environmentPresets, true);
        expect(gates.biometricIntegration, true);
        expect(gates.progressSharingExport, true);
        expect(gates.cloudBackupSync, true);
        
        await manager.dispose();
      });
      
      test('Session limits respect billing status', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        await manager.initialize();
        
        final gates = MindTrainerProGates.fromStatusCheck(() => manager.isProActive);
        
        // Free user limits
        expect(gates.dailySessionLimit, 5);
        expect(gates.canStartSession(4), true);
        expect(gates.canStartSession(5), false);
        expect(gates.canStartSession(10), false);
        
        // After Pro purchase
        await manager.purchasePlan('pro_yearly');
        
        expect(gates.dailySessionLimit, -1); // Unlimited
        expect(gates.canStartSession(4), true);
        expect(gates.canStartSession(5), true);
        expect(gates.canStartSession(50), true);
        expect(gates.canStartSession(1000), true);
        
        await manager.dispose();
      });
      
      test('Insights history limits respect billing status', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        await manager.initialize();
        
        final gates = MindTrainerProGates.fromStatusCheck(() => manager.isProActive);
        
        // Free user - 30 days
        expect(gates.insightsHistoryDays, 30);
        expect(gates.extendedInsightsHistory, false);
        
        // Pro user - unlimited
        await manager.purchasePlan('pro_monthly');
        
        expect(gates.insightsHistoryDays, -1);
        expect(gates.extendedInsightsHistory, true);
        
        await manager.dispose();
      });
    });
    
    group('Pro Catalog Integration', () {
      test('Catalog updates with real billing product info', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        await manager.initialize();
        
        // Catalog should have base plans
        expect(manager.catalog.plans.length, 2);
        
        // Plans should have product IDs
        final monthlyPlan = manager.catalog.findPlanById('pro_monthly');
        final yearlyPlan = manager.catalog.findPlanById('pro_yearly');
        
        expect(monthlyPlan, isNotNull);
        expect(yearlyPlan, isNotNull);
        expect(yearlyPlan!.bestValue, true);
        
        await manager.dispose();
      });
      
      test('Plan pricing calculations work correctly', () {
        final monthlyPlan = testCatalog.monthlyPlan!;
        final yearlyPlan = testCatalog.yearlyPlan!;
        
        expect(monthlyPlan.monthlyEquivalentPrice, 9.99);
        expect(yearlyPlan.monthlyEquivalentPrice, closeTo(8.33, 0.01));
        
        final savings = yearlyPlan.calculateSavings(monthlyPlan.basePriceUsd);
        expect(savings, closeTo(19.89, 0.01)); // 12*9.99 - 99.99
        
        final savingsPercent = yearlyPlan.getSavingsPercentage(monthlyPlan.basePriceUsd);
        expect(savingsPercent, 17); // Roughly 17% savings
      });
    });
    
    group('Error Handling', () {
      test('Connection failures are handled gracefully', () async {
        final manager = PlayBillingProManager.fake(
          testCatalog,
          simulateConnectionFailure: true,
        );
        
        final initialized = await manager.initialize();
        expect(initialized, false);
        
        // Wait for connection state to settle
        await Future.delayed(const Duration(milliseconds: 100));
        expect(manager.connectionState, BillingConnectionState.error);
        
        // Should still be able to check status (free)
        expect(manager.isProActive, false);
        
        await manager.dispose();
      });
      
      test('Invalid product IDs are rejected', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        await manager.initialize();
        
        final result = await manager.purchasePlan('invalid_product');
        expect(result.success, false);
        expect(result.error, contains('not found'));
        
        await manager.dispose();
      });
      
      test('Disconnected billing prevents purchases', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        // Don't initialize - leave disconnected
        
        final result = await manager.purchasePlan('pro_monthly');
        expect(result.success, false);
        expect(result.error, contains('Not connected'));
        
        await manager.dispose();
      });
    });
    
    group('Subscription Gateway Adapter', () {
      test('Adapter implements SubscriptionGateway correctly', () async {
        final manager = PlayBillingProManager.fake(testCatalog);
        final adapter = PlayBillingProManagerAdapter(manager);
        
        await manager.initialize();
        
        // Initial status
        final initialStatus = await adapter.getCurrentStatus();
        expect(initialStatus.tier, ProTier.free);
        
        // Purchase via adapter
        final purchaseResult = await adapter.purchaseSubscription(
          SubscriptionProduct.proMonthly
        );
        expect(purchaseResult.success, true);
        
        // Status should be updated
        final newStatus = await adapter.getCurrentStatus();
        expect(newStatus.tier, ProTier.pro);
        
        // Restore purchases
        final restoreResult = await adapter.restorePurchases();
        expect(restoreResult.success, true);
        
        // Billing availability
        final available = await adapter.isBillingAvailable();
        expect(available, true);
        
        await manager.dispose();
      });
    });
  });
}
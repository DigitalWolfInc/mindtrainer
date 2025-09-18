import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/play_billing_adapter.dart';
import 'package:mindtrainer/core/payments/platform_billing_adapter.dart';
import 'package:mindtrainer/core/payments/pro_catalog.dart';
import 'package:mindtrainer/core/payments/play_billing_pro_manager.dart';
import 'package:mindtrainer/core/payments/pro_status.dart';

void main() {
  group('Play Billing Adapter', () {
    test('FakePlayBillingAdapter should start in disconnected state', () {
      final adapter = BillingAdapterFactory.createFake();
      expect(adapter.connectionState, BillingConnectionState.disconnected);
    });
    
    test('should successfully connect to billing service', () async {
      final adapter = BillingAdapterFactory.createFake();
      final result = await adapter.startConnection();
      
      expect(result.success, true);
      expect(adapter.connectionState, BillingConnectionState.connected);
    });
    
    test('should simulate connection failure when configured', () async {
      final adapter = BillingAdapterFactory.createFake(simulateConnectionFailure: true);
      final result = await adapter.startConnection();
      
      expect(result.success, false);
      expect(adapter.connectionState, BillingConnectionState.error);
      expect(result.responseCode, 6); // SERVICE_UNAVAILABLE
    });
    
    test('should query subscription products', () async {
      final adapter = BillingAdapterFactory.createFake();
      await adapter.startConnection();
      
      final products = await adapter.querySubscriptionProducts(['pro_monthly', 'pro_yearly']);
      
      expect(products.length, 2);
      expect(products.any((p) => p.productId == 'pro_monthly'), true);
      expect(products.any((p) => p.productId == 'pro_yearly'), true);
      
      final monthlyProduct = products.firstWhere((p) => p.productId == 'pro_monthly');
      expect(monthlyProduct.price, '\$9.99');
      expect(monthlyProduct.priceAmountMicros, 9990000);
      expect(monthlyProduct.priceCurrencyCode, 'USD');
    });
    
    test('should handle successful purchase flow', () async {
      final adapter = BillingAdapterFactory.createFake();
      await adapter.startConnection();
      
      final purchaseUpdates = <List<BillingPurchase>>[];
      adapter.purchaseUpdateStream.listen(purchaseUpdates.add);
      
      final result = await adapter.launchSubscriptionPurchaseFlow('pro_monthly');
      
      // Wait a bit for stream to propagate
      await Future.delayed(const Duration(milliseconds: 10));
      
      expect(result.success, true);
      expect(purchaseUpdates.length, 1);
      expect(purchaseUpdates.first.length, 1);
      
      final purchase = purchaseUpdates.first.first;
      expect(purchase.productId, 'pro_monthly');
      expect(purchase.state, PurchaseState.purchased);
      expect(purchase.autoRenewing, true);
    });
    
    test('should handle user cancellation', () async {
      final adapter = BillingAdapterFactory.createFake(simulateUserCancel: true);
      await adapter.startConnection();
      
      final result = await adapter.launchSubscriptionPurchaseFlow('pro_monthly');
      
      expect(result.success, false);
      expect(result.responseCode, 1); // USER_CANCELED
    });
    
    test('should handle purchase failure', () async {
      final adapter = BillingAdapterFactory.createFake(simulatePurchaseFailure: true);
      await adapter.startConnection();
      
      final result = await adapter.launchSubscriptionPurchaseFlow('pro_monthly');
      
      expect(result.success, false);
      expect(result.responseCode, 7);
      expect(result.debugMessage, 'Purchase failed');
    });
    
    test('should acknowledge purchases', () async {
      final adapter = BillingAdapterFactory.createFake();
      await adapter.startConnection();
      
      // Make a purchase first
      await adapter.launchSubscriptionPurchaseFlow('pro_monthly');
      final purchases = await adapter.queryPurchases();
      final purchase = purchases.first;
      
      expect(purchase.acknowledged, false);
      
      // Acknowledge the purchase
      final result = await adapter.acknowledgePurchase(purchase.purchaseToken);
      expect(result.success, true);
      
      // Verify acknowledgment
      final updatedPurchases = await adapter.queryPurchases();
      expect(updatedPurchases.first.acknowledged, true);
    });
    
    test('should support test helpers for simulation', () async {
      final adapter = BillingAdapterFactory.createFake();
      await adapter.startConnection();
      
      final purchaseUpdates = <List<BillingPurchase>>[];
      adapter.purchaseUpdateStream.listen(purchaseUpdates.add);
      
      // For fake mode, we'll simulate a purchase and verify the stream
      final result = await adapter.launchSubscriptionPurchaseFlow('pro_yearly');
      expect(result.success, true);
      
      // Wait for purchase stream updates
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(purchaseUpdates.length, 1);
      expect(purchaseUpdates.first.first.productId, 'pro_yearly');
    });
  });
  
  group('Pro Catalog', () {
    late ProCatalog catalog;
    
    setUp(() {
      catalog = ProCatalogFactory.createDefault();
    });
    
    test('should have monthly and yearly plans', () {
      expect(catalog.plans.length, 2);
      expect(catalog.monthlyPlan, isNotNull);
      expect(catalog.yearlyPlan, isNotNull);
      
      final monthly = catalog.monthlyPlan!;
      expect(monthly.productId, 'pro_monthly');
      expect(monthly.period, ProPlanPeriod.monthly);
      expect(monthly.basePriceUsd, 9.99);
      
      final yearly = catalog.yearlyPlan!;
      expect(yearly.productId, 'pro_yearly');
      expect(yearly.period, ProPlanPeriod.yearly);
      expect(yearly.basePriceUsd, 99.99);
      expect(yearly.bestValue, true);
    });
    
    test('should calculate monthly equivalent pricing', () {
      final yearly = catalog.yearlyPlan!;
      final monthlyEquivalent = yearly.monthlyEquivalentPrice;
      
      expect(monthlyEquivalent, closeTo(8.33, 0.01)); // 99.99 / 12
    });
    
    test('should calculate savings for yearly plan', () {
      final monthly = catalog.monthlyPlan!;
      final yearly = catalog.yearlyPlan!;
      
      final savings = yearly.calculateSavings(monthly.basePriceUsd);
      expect(savings, closeTo(19.89, 0.01)); // (9.99 * 12) - 99.99
      
      final savingsPercent = yearly.getSavingsPercentage(monthly.basePriceUsd);
      expect(savingsPercent, 17); // ~17% savings
    });
    
    test('should find plans by ID and period', () {
      final monthlyById = catalog.findPlanById('pro_monthly');
      expect(monthlyById, isNotNull);
      expect(monthlyById!.period, ProPlanPeriod.monthly);
      
      final monthlyPlans = catalog.getPlansByPeriod(ProPlanPeriod.monthly);
      expect(monthlyPlans.length, 1);
      expect(monthlyPlans.first.productId, 'pro_monthly');
      
      final yearlyPlans = catalog.getPlansByPeriod(ProPlanPeriod.yearly);
      expect(yearlyPlans.length, 1);
      expect(yearlyPlans.first.productId, 'pro_yearly');
    });
    
    test('should integrate billing products', () {
      final billingProducts = [
        const BillingProduct(
          productId: 'pro_monthly',
          type: 'subs',
          title: 'MindTrainer Pro Monthly',
          description: 'Monthly subscription',
          price: '\$10.99', // Different from base price
          priceAmountMicros: 10990000,
          priceCurrencyCode: 'USD',
        ),
      ];
      
      final updatedCatalog = catalog.withBillingProducts(billingProducts);
      final monthlyPlan = updatedCatalog.monthlyPlan!;
      
      expect(monthlyPlan.formattedPrice, '\$10.99'); // Uses billing product price
      expect(monthlyPlan.billingProduct, isNotNull);
      expect(monthlyPlan.billingProduct!.title, 'MindTrainer Pro Monthly');
    });
    
    test('should sort plans by value', () {
      final sortedPlans = catalog.plansByValue;
      
      // Best value should be first
      expect(sortedPlans.first.bestValue, true);
      expect(sortedPlans.first.productId, 'pro_yearly');
    });
  });
  
  group('Pro Plan Formatter', () {
    late ProCatalog catalog;
    
    setUp(() {
      catalog = ProCatalogFactory.createDefault();
    });
    
    test('should format plan prices with periods', () {
      final monthly = catalog.monthlyPlan!;
      final yearly = catalog.yearlyPlan!;
      
      expect(ProPlanFormatter.formatPlanPrice(monthly), '\$9.99/month');
      expect(ProPlanFormatter.formatPlanPrice(yearly), '\$99.99/year');
    });
    
    test('should format savings messages for yearly plans', () {
      final monthly = catalog.monthlyPlan!;
      final yearly = catalog.yearlyPlan!;
      
      final monthlySavings = ProPlanFormatter.formatSavingsMessage(monthly, catalog);
      expect(monthlySavings, isNull); // No savings for monthly
      
      final yearlySavings = ProPlanFormatter.formatSavingsMessage(yearly, catalog);
      expect(yearlySavings, 'Save 17% vs monthly');
    });
    
    test('should format monthly equivalents', () {
      final monthly = catalog.monthlyPlan!;
      final yearly = catalog.yearlyPlan!;
      
      expect(ProPlanFormatter.formatMonthlyEquivalent(monthly), 'Billed monthly');
      expect(ProPlanFormatter.formatMonthlyEquivalent(yearly), 'Only \$8.33/month');
    });
    
    test('should format comparison summaries', () {
      final yearly = catalog.yearlyPlan!;
      final summary = ProPlanFormatter.formatComparisonSummary(yearly, catalog);
      
      expect(summary, 'Only \$8.33/month • Save 17% vs monthly');
    });
  });
  
  group('Play Billing Pro Manager', () {
    late PlayBillingAdapter adapter;
    late ProCatalog catalog;
    late PlayBillingProManager manager;
    
    setUp(() {
      adapter = BillingAdapterFactory.createFake();
      catalog = ProCatalogFactory.createDefault();
      manager = PlayBillingProManager(adapter, catalog);
    });
    
    tearDown(() async {
      await manager.dispose();
    });
    
    test('should initialize and connect', () async {
      final success = await manager.initialize();
      
      expect(success, true);
      expect(manager.connectionState, BillingConnectionState.connected);
      expect(manager.currentStatus.tier, ProTier.free);
    });
    
    test('should handle successful purchase flow', () async {
      await manager.initialize();
      
      final purchaseEvents = <PurchaseEvent>[];
      manager.purchaseEventStream.listen(purchaseEvents.add);
      
      final result = await manager.purchasePlan('pro_monthly');
      
      // Wait for purchase processing to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(result.success, true);
      expect(manager.isProActive, true);
      expect(manager.currentStatus.tier, ProTier.pro);
      
      // Verify purchase events were emitted
      expect(purchaseEvents.length, 2);
      expect(purchaseEvents.first.type, PurchaseEventType.started);
      expect(purchaseEvents.last.type, PurchaseEventType.completed);
    });
    
    test('should handle purchase cancellation', () async {
      adapter = BillingAdapterFactory.createFake(simulateUserCancel: true);
      manager = PlayBillingProManager(adapter, catalog);
      await manager.initialize();
      
      final purchaseEvents = <PurchaseEvent>[];
      manager.purchaseEventStream.listen(purchaseEvents.add);
      
      final result = await manager.purchasePlan('pro_monthly');
      
      // Wait for event processing
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(result.success, false);
      expect(result.cancelled, true);
      expect(manager.isProActive, false);
      
      // Verify cancellation event
      final cancelEvents = purchaseEvents.where((e) => e.type == PurchaseEventType.cancelled);
      expect(cancelEvents.length, 1);
    });
    
    test('should handle purchase failure', () async {
      adapter = BillingAdapterFactory.createFake(simulatePurchaseFailure: true);
      manager = PlayBillingProManager(adapter, catalog);
      await manager.initialize();
      
      final purchaseEvents = <PurchaseEvent>[];
      manager.purchaseEventStream.listen(purchaseEvents.add);
      
      final result = await manager.purchasePlan('pro_monthly');
      
      // Wait for event processing
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(result.success, false);
      expect(result.error, isNotNull);
      expect(manager.isProActive, false);
      
      // Verify failure event
      final failEvents = purchaseEvents.where((e) => e.type == PurchaseEventType.failed);
      expect(failEvents.length, 1);
      expect(failEvents.first.error, 'Purchase failed');
    });
    
    test('should restore existing purchases', () async {
      await manager.initialize();
      
      // For fake adapter, simulate a purchase first
      await adapter.launchSubscriptionPurchaseFlow('pro_yearly');
      
      final success = await manager.restorePurchases();
      
      expect(success, true);
      expect(manager.isProActive, true);
      expect(manager.currentStatus.tier, ProTier.pro);
    });
    
    test('should update catalog with billing products on connection', () async {
      await manager.initialize();
      
      // Catalog should be updated with billing product details
      final monthlyPlan = manager.catalog.monthlyPlan;
      expect(monthlyPlan?.billingProduct, isNotNull);
      expect(monthlyPlan?.billingProduct?.title, 'MindTrainer Pro Monthly');
    });
    
    test('should handle connection failure gracefully', () async {
      adapter = BillingAdapterFactory.createFake(simulateConnectionFailure: true);
      manager = PlayBillingProManager(adapter, catalog);
      
      final success = await manager.initialize();
      
      // Wait for connection state to update
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(success, false);
      expect(manager.connectionState, BillingConnectionState.error);
      
      // Should not be able to purchase when disconnected
      final result = await manager.purchasePlan('pro_monthly');
      expect(result.success, false);
      expect(result.error, contains('Not connected'));
    });
    
    test('should reject purchase for unknown product ID', () async {
      await manager.initialize();
      
      // Wait for connection to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      final result = await manager.purchasePlan('unknown_product');
      
      expect(result.success, false);
      expect(result.error, 'Plan not found');
    });
  });
  
  group('Purchase Flow Integration', () {
    test('should handle complete purchase-to-Pro-activation flow', () async {
      final adapter = BillingAdapterFactory.createFake();
      final catalog = ProCatalogFactory.createDefault();
      final manager = PlayBillingProManager(adapter, catalog);
      
      try {
        // Start as free user
        await manager.initialize();
        
        // Wait for connection to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(manager.isProActive, false);
        
        // Track all events
        final events = <PurchaseEvent>[];
        manager.purchaseEventStream.listen(events.add);
        
        // Purchase Pro monthly
        final result = await manager.purchasePlan('pro_monthly');
        
        // Wait for purchase processing
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify successful purchase
        expect(result.success, true);
        expect(manager.isProActive, true);
        expect(manager.currentStatus.tier, ProTier.pro);
        expect(manager.currentStatus.expiresAt, isNotNull);
        expect(manager.currentStatus.autoRenewing, true);
        
        // Verify event sequence
        expect(events.length, 2);
        expect(events[0].type, PurchaseEventType.started);
        expect(events[1].type, PurchaseEventType.completed);
        expect(events[1].productId, 'pro_monthly');
        expect(events[1].purchaseToken, isNotNull);
        
        // Verify yearly purchase works too
        final yearlyResult = await manager.purchasePlan('pro_yearly');
        expect(yearlyResult.success, true);
        
      } finally {
        await manager.dispose();
      }
    });
  });
  
  group('State Reflection for UI', () {
    test('should provide UI-ready catalog and status information', () async {
      final adapter = BillingAdapterFactory.createFake();
      final catalog = ProCatalogFactory.createDefault();
      final manager = PlayBillingProManager(adapter, catalog);
      
      try {
        await manager.initialize();
        
        // Wait for connection and catalog loading
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify catalog is UI-ready
        expect(manager.catalog.plans.length, 2);
        expect(manager.catalog.bestValuePlan?.bestValue, true);
        expect(manager.catalog.productIds, ['pro_monthly', 'pro_yearly']);
        
        // Plans should have UI-friendly formatting
        final monthlyPlan = manager.catalog.monthlyPlan!;
        expect(ProPlanFormatter.formatPlanPrice(monthlyPlan), '\$9.99/month');
        
        // Status should be UI-ready
        expect(manager.isProActive, false); // Starts as free
        expect(manager.currentStatus.tier, ProTier.free);
        
        // After purchase, status should update
        await manager.purchasePlan('pro_monthly');
        
        // Wait for purchase processing
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(manager.isProActive, true);
        expect(manager.currentStatus.tier, ProTier.pro);
        
      } finally {
        await manager.dispose();
      }
    });
    
    test('should handle billing product price updates in UI', () async {
      final adapter = BillingAdapterFactory.createFake();
      final catalog = ProCatalogFactory.createDefault();
      final manager = PlayBillingProManager(adapter, catalog);
      
      try {
        await manager.initialize();
        
        // Wait for connection and catalog loading
        await Future.delayed(const Duration(milliseconds: 100));
        
        // After connection, catalog should have billing products loaded
        final monthlyPlan = manager.catalog.monthlyPlan!;
        expect(monthlyPlan.billingProduct, isNotNull);
        expect(monthlyPlan.billingProduct!.price, '\$9.99');
        expect(monthlyPlan.formattedPrice, '\$9.99');
        
      } finally {
        await manager.dispose();
      }
    });
  });
}
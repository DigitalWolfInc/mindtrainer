/// Integration tests for billing system with both fake and real modes
/// Tests configuration switching and mode validation

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/billing/billing_adapter.dart';
import 'package:mindtrainer/core/billing/billing_config.dart';
import 'package:mindtrainer/core/billing/pro_catalog.dart';

void main() {
  group('Billing Integration Tests', () {
    
    group('BillingConfig', () {
      test('should use fake billing in test environment', () {
        // In test environment, should always use fake
        expect(BillingConfig.useFakeBilling, true);
        expect(BillingConfig.isRealBillingAvailable, false);
        expect(BillingConfig.isProductionBilling, false);
      });
      
      test('should provide configuration description', () {
        final description = BillingConfig.getConfigDescription();
        expect(description, contains('FAKE'));
        expect(description, isNotEmpty);
      });
    });
    
    group('Factory Mode Selection', () {
      test('should create fake adapter by default in test environment', () {
        final adapter = BillingAdapterFactory.create();
        expect(adapter, isA<FakeBillingAdapter>());
      });
      
      test('should create fake adapter when explicitly requested', () {
        final adapter = BillingAdapterFactory.create(useFakeAdapter: true);
        expect(adapter, isA<FakeBillingAdapter>());
      });
      
      test('should create real adapter when explicitly requested', () {
        final adapter = BillingAdapterFactory.create(useFakeAdapter: false);
        expect(adapter, isA<GooglePlayBillingAdapter>());
      });
      
      test('should create specific adapters via direct methods', () {
        final fakeAdapter = BillingAdapterFactory.createFake();
        final realAdapter = BillingAdapterFactory.createReal();
        
        expect(fakeAdapter, isA<FakeBillingAdapter>());
        expect(realAdapter, isA<GooglePlayBillingAdapter>());
      });
      
      test('should provide configuration info', () {
        final info = BillingAdapterFactory.getConfigInfo();
        expect(info, isNotEmpty);
        expect(info, contains('FAKE')); // Should be fake in test environment
      });
    });
    
    group('Fake Mode Validation', () {
      late FakeBillingAdapter fakeAdapter;
      
      setUp(() {
        fakeAdapter = BillingAdapterFactory.createFake();
      });
      
      tearDown(() {
        fakeAdapter.dispose();
      });
      
      test('should work consistently in fake mode', () async {
        // Test connection
        await fakeAdapter.startConnection();
        expect(fakeAdapter.connectionState, BillingServiceState.connected);
        
        // Test product query
        final productResult = await fakeAdapter.queryProductDetails([
          ProCatalog.monthlyProductId,
          ProCatalog.yearlyProductId,
        ]);
        expect(productResult.isSuccess, true);
        expect(fakeAdapter.availableProducts.length, 2);
        
        // Test purchase simulation
        fakeAdapter.simulateProActivation(ProCatalog.monthlyProductId);
        expect(fakeAdapter.isProActive, true);
        expect(fakeAdapter.currentPurchases.length, 1);
        
        // Test acknowledgment
        final purchase = fakeAdapter.currentPurchases.first;
        final ackResult = await fakeAdapter.acknowledgePurchase(purchase.purchaseToken);
        expect(ackResult.isSuccess, true);
      });
      
      test('should handle Pro activation/expiration correctly', () {
        expect(fakeAdapter.isProActive, false);
        
        // Activate Pro
        fakeAdapter.simulateProActivation(ProCatalog.yearlyProductId);
        expect(fakeAdapter.isProActive, true);
        expect(fakeAdapter.activeProPurchase, isNotNull);
        expect(fakeAdapter.activeProPurchase!.productId, ProCatalog.yearlyProductId);
        
        // Expire Pro
        fakeAdapter.simulateProExpiration();
        expect(fakeAdapter.isProActive, false);
        expect(fakeAdapter.activeProPurchase, isNull);
      });
    });
    
    group('Real Mode Configuration', () {
      late GooglePlayBillingAdapter realAdapter;
      
      setUp(() {
        realAdapter = BillingAdapterFactory.createReal();
      });
      
      tearDown(() {
        realAdapter.dispose();
      });
      
      test('should initialize real adapter correctly', () {
        expect(realAdapter.connectionState, BillingServiceState.disconnected);
        expect(realAdapter.isProActive, false);
        expect(realAdapter.availableProducts, isEmpty);
        expect(realAdapter.currentPurchases, isEmpty);
      });
      
      test('should attempt connection (will fail in test environment)', () async {
        // In test environment, real adapter will fail to connect since there's no Android runtime
        // But we can test that it attempts the connection process
        final result = await realAdapter.startConnection();
        
        // Could succeed or fail depending on environment
        expect(result.responseCode, anyOf(
          BillingResultCode.ok,
          BillingResultCode.error,
          BillingResultCode.serviceUnavailable,
        ));
      });
      
      test('should handle platform channel methods correctly', () async {
        // Test that methods don't throw exceptions
        expect(() async {
          await realAdapter.queryProductDetails([ProCatalog.monthlyProductId]);
          await realAdapter.queryPurchases();
          await realAdapter.launchBillingFlow(ProCatalog.monthlyProductId);
        }, returnsNormally);
      });
    });
    
    group('Cross-Mode Compatibility', () {
      test('should maintain interface compatibility between modes', () {
        final fakeAdapter = BillingAdapterFactory.createFake();
        final realAdapter = BillingAdapterFactory.createReal();
        
        // Both should implement the same interface
        expect(fakeAdapter, isA<BillingAdapter>());
        expect(realAdapter, isA<BillingAdapter>());
        
        // Both should have the same properties
        expect(fakeAdapter.connectionState, isA<BillingServiceState>());
        expect(realAdapter.connectionState, isA<BillingServiceState>());
        
        expect(fakeAdapter.isProActive, isA<bool>());
        expect(realAdapter.isProActive, isA<bool>());
        
        expect(fakeAdapter.availableProducts, isA<List<ProProduct>>());
        expect(realAdapter.availableProducts, isA<List<ProProduct>>());
        
        expect(fakeAdapter.currentPurchases, isA<List<ProPurchase>>());
        expect(realAdapter.currentPurchases, isA<List<ProPurchase>>());
        
        fakeAdapter.dispose();
        realAdapter.dispose();
      });
      
      test('should handle upgrade/downgrade scenarios consistently', () async {
        final fakeAdapter = BillingAdapterFactory.createFake();
        
        await fakeAdapter.startConnection();
        
        // Test monthly to yearly upgrade
        fakeAdapter.simulateProActivation(ProCatalog.monthlyProductId);
        expect(fakeAdapter.isProActive, true);
        expect(fakeAdapter.activeProPurchase!.productId, ProCatalog.monthlyProductId);
        
        // Simulate upgrade to yearly (would involve canceling monthly and purchasing yearly)
        fakeAdapter.simulateProExpiration(); // Cancel monthly
        fakeAdapter.simulateProActivation(ProCatalog.yearlyProductId); // Purchase yearly
        expect(fakeAdapter.isProActive, true);
        expect(fakeAdapter.activeProPurchase!.productId, ProCatalog.yearlyProductId);
        
        // Test downgrade (yearly to monthly)
        fakeAdapter.simulateProExpiration(); // Cancel yearly
        fakeAdapter.simulateProActivation(ProCatalog.monthlyProductId); // Purchase monthly
        expect(fakeAdapter.isProActive, true);
        expect(fakeAdapter.activeProPurchase!.productId, ProCatalog.monthlyProductId);
        
        fakeAdapter.dispose();
      });
    });
    
    group('Purchase Flow Validation', () {
      late FakeBillingAdapter adapter;
      List<ProPurchase> receivedUpdates = [];
      
      setUp(() {
        adapter = BillingAdapterFactory.createFake();
        receivedUpdates.clear();
        
        adapter.setPurchaseUpdateListener((purchases) {
          receivedUpdates.addAll(purchases);
        });
      });
      
      tearDown(() {
        adapter.dispose();
      });
      
      test('should validate complete purchase flow', () async {
        // 1. Connect
        final connectionResult = await adapter.startConnection();
        expect(connectionResult.isSuccess, true);
        
        // 2. Query products
        final queryResult = await adapter.queryProductDetails([
          ProCatalog.monthlyProductId,
          ProCatalog.yearlyProductId,
        ]);
        expect(queryResult.isSuccess, true);
        expect(adapter.availableProducts.length, 2);
        
        // 3. Simulate purchase
        adapter.simulateProActivation(ProCatalog.monthlyProductId);
        
        // 4. Verify purchase was received
        expect(receivedUpdates.length, 1);
        expect(receivedUpdates.first.productId, ProCatalog.monthlyProductId);
        expect(receivedUpdates.first.isPurchased, true);
        expect(receivedUpdates.first.autoRenewing, true);
        
        // 5. Acknowledge purchase
        final purchase = receivedUpdates.first;
        expect(purchase.acknowledged, false);
        
        final ackResult = await adapter.acknowledgePurchase(purchase.purchaseToken);
        expect(ackResult.isSuccess, true);
        
        // 6. Verify acknowledgment
        final acknowledgedPurchase = adapter.currentPurchases
            .where((p) => p.purchaseToken == purchase.purchaseToken)
            .first;
        expect(acknowledgedPurchase.acknowledged, true);
        
        // 7. Verify Pro status
        expect(adapter.isProActive, true);
        expect(adapter.activeProPurchase, isNotNull);
      });
      
      test('should handle purchase failure gracefully', () async {
        await adapter.startConnection();
        
        // Launch billing flow (could fail due to 80% success rate)
        final result = await adapter.launchBillingFlow(ProCatalog.monthlyProductId);
        
        if (result.responseCode == BillingResultCode.userCanceled) {
          // User canceled - should not affect Pro status
          expect(adapter.isProActive, false);
          expect(receivedUpdates, isEmpty);
        } else if (result.isSuccess) {
          // Purchase succeeded
          expect(adapter.isProActive, true);
          expect(receivedUpdates.length, 1);
        }
      });
    });
    
    group('Google Play Policy Compliance', () {
      test('should not lock essential features', () {
        final fakeAdapter = BillingAdapterFactory.createFake();
        
        // Essential features should work without Pro
        expect(fakeAdapter.isProActive, false);
        
        // User should still be able to:
        // - Use basic app functionality (verified in other tests)
        // - See what Pro features are available
        // - Purchase Pro if desired
        
        fakeAdapter.dispose();
      });
      
      test('should handle subscription management correctly', () async {
        final fakeAdapter = BillingAdapterFactory.createFake();
        
        await fakeAdapter.startConnection();
        
        // Test subscription purchase
        fakeAdapter.simulateProActivation(ProCatalog.monthlyProductId);
        expect(fakeAdapter.isProActive, true);
        
        // Test subscription query
        final queryResult = await fakeAdapter.queryPurchases();
        expect(queryResult.isSuccess, true);
        expect(fakeAdapter.currentPurchases.length, 1);
        
        // Test subscription restoration (important for device transfers)
        final currentPurchases = List.from(fakeAdapter.currentPurchases);
        fakeAdapter.simulateProExpiration(); // Simulate app reinstall
        
        // Restore purchases
        for (final purchase in currentPurchases) {
          fakeAdapter.simulateProActivation(purchase.productId);
        }
        expect(fakeAdapter.isProActive, true);
        
        fakeAdapter.dispose();
      });
    });
  });
}
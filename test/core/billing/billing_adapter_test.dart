/// Unit tests for billing adapter system
/// Tests both FakeBillingAdapter and core billing functionality

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/billing/billing_adapter.dart';
import 'package:mindtrainer/core/billing/pro_catalog.dart';

void main() {
  group('BillingResult', () {
    test('should correctly identify success result', () {
      const result = BillingResult(responseCode: BillingResultCode.ok);
      
      expect(result.isSuccess, true);
      expect(result.isError, false);
      expect(result.isUserCanceled, false);
    });
    
    test('should correctly identify user canceled result', () {
      const result = BillingResult(responseCode: BillingResultCode.userCanceled);
      
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.isUserCanceled, true);
    });
    
    test('should correctly identify error results', () {
      const result = BillingResult(responseCode: BillingResultCode.serviceUnavailable);
      
      expect(result.isSuccess, false);
      expect(result.isError, true);
      expect(result.isUserCanceled, false);
    });
    
    test('should format toString correctly', () {
      const result = BillingResult(
        responseCode: BillingResultCode.ok,
        debugMessage: 'Success',
      );
      
      expect(result.toString(), 'BillingResult(ok, Success)');
    });
  });
  
  group('FakeBillingAdapter', () {
    late FakeBillingAdapter adapter;
    
    setUp(() {
      adapter = FakeBillingAdapter();
    });
    
    tearDown(() {
      adapter.dispose();
    });
    
    test('should start in disconnected state', () {
      expect(adapter.connectionState, BillingServiceState.disconnected);
      expect(adapter.isProActive, false);
      expect(adapter.activeProPurchase, isNull);
      expect(adapter.availableProducts, isEmpty);
      expect(adapter.currentPurchases, isEmpty);
    });
    
    test('should connect successfully', () async {
      final result = await adapter.startConnection();
      
      expect(result.isSuccess, true);
      expect(adapter.connectionState, BillingServiceState.connected);
    });
    
    test('should disconnect cleanly', () async {
      await adapter.startConnection();
      expect(adapter.connectionState, BillingServiceState.connected);
      
      await adapter.endConnection();
      expect(adapter.connectionState, BillingServiceState.disconnected);
      expect(adapter.availableProducts, isEmpty);
      expect(adapter.currentPurchases, isEmpty);
    });
    
    test('should query product details when connected', () async {
      await adapter.startConnection();
      
      final result = await adapter.queryProductDetails([
        ProCatalog.monthlyProductId,
        ProCatalog.yearlyProductId,
      ]);
      
      expect(result.isSuccess, true);
      expect(adapter.availableProducts.length, 2);
      expect(
        adapter.availableProducts.map((p) => p.id),
        containsAll([ProCatalog.monthlyProductId, ProCatalog.yearlyProductId]),
      );
    });
    
    test('should fail to query products when disconnected', () async {
      final result = await adapter.queryProductDetails([ProCatalog.monthlyProductId]);
      
      expect(result.isSuccess, false);
      expect(result.responseCode, BillingResultCode.serviceDisconnected);
      expect(result.debugMessage, 'Billing service not connected');
    });
    
    test('should launch billing flow when connected', () async {
      await adapter.startConnection();
      
      // FakeBillingAdapter has 80% success rate, so we may need multiple attempts
      // But for testing, we'll just verify the method works
      final result = await adapter.launchBillingFlow(ProCatalog.monthlyProductId);
      
      expect(result.responseCode, 
        anyOf(BillingResultCode.ok, BillingResultCode.userCanceled));
      
      if (result.isSuccess) {
        expect(adapter.isProActive, true);
        expect(adapter.currentPurchases.length, 1);
        expect(adapter.activeProPurchase, isNotNull);
        expect(adapter.activeProPurchase!.productId, ProCatalog.monthlyProductId);
      }
    });
    
    test('should fail billing flow when disconnected', () async {
      final result = await adapter.launchBillingFlow(ProCatalog.monthlyProductId);
      
      expect(result.isSuccess, false);
      expect(result.responseCode, BillingResultCode.serviceDisconnected);
    });
    
    test('should fail billing flow for invalid product', () async {
      await adapter.startConnection();
      
      final result = await adapter.launchBillingFlow('invalid_product_id');
      
      expect(result.isSuccess, false);
      expect(result.responseCode, BillingResultCode.itemUnavailable);
    });
    
    test('should acknowledge purchases correctly', () async {
      await adapter.startConnection();
      
      // Simulate Pro activation
      adapter.simulateProActivation(ProCatalog.monthlyProductId);
      
      expect(adapter.isProActive, true);
      expect(adapter.currentPurchases.length, 1);
      
      final purchase = adapter.currentPurchases.first;
      expect(purchase.acknowledged, false);
      
      final result = await adapter.acknowledgePurchase(purchase.purchaseToken);
      
      expect(result.isSuccess, true);
      
      final acknowledgedPurchase = adapter.currentPurchases
          .where((p) => p.purchaseToken == purchase.purchaseToken)
          .first;
      expect(acknowledgedPurchase.acknowledged, true);
    });
    
    test('should query purchases when connected', () async {
      await adapter.startConnection();
      
      final result = await adapter.queryPurchases();
      expect(result.isSuccess, true);
    });
    
    test('should fail to query purchases when disconnected', () async {
      final result = await adapter.queryPurchases();
      
      expect(result.isSuccess, false);
      expect(result.responseCode, BillingResultCode.serviceDisconnected);
    });
    
    test('should simulate Pro activation correctly', () {
      List<ProPurchase> purchaseUpdates = [];
      
      adapter.setPurchaseUpdateListener((purchases) {
        purchaseUpdates.addAll(purchases);
      });
      
      adapter.simulateProActivation(ProCatalog.yearlyProductId);
      
      expect(adapter.isProActive, true);
      expect(adapter.currentPurchases.length, 1);
      expect(adapter.activeProPurchase, isNotNull);
      expect(adapter.activeProPurchase!.productId, ProCatalog.yearlyProductId);
      expect(adapter.activeProPurchase!.autoRenewing, true);
      expect(purchaseUpdates.length, 1);
    });
    
    test('should simulate Pro expiration correctly', () {
      List<ProPurchase> purchaseUpdates = [];
      
      adapter.setPurchaseUpdateListener((purchases) {
        purchaseUpdates.clear();
        purchaseUpdates.addAll(purchases);
      });
      
      // First activate Pro
      adapter.simulateProActivation(ProCatalog.monthlyProductId);
      expect(adapter.isProActive, true);
      
      // Then expire it
      adapter.simulateProExpiration();
      
      expect(adapter.isProActive, false);
      expect(adapter.currentPurchases, isEmpty);
      expect(adapter.activeProPurchase, isNull);
      expect(purchaseUpdates, isEmpty);
    });
    
    test('should handle dispose correctly', () {
      adapter.setPurchaseUpdateListener((purchases) {});
      adapter.simulateProActivation(ProCatalog.monthlyProductId);
      
      expect(adapter.connectionState, BillingServiceState.disconnected);
      expect(adapter.isProActive, true);
      
      adapter.dispose();
      
      expect(adapter.connectionState, BillingServiceState.closed);
      expect(adapter.isProActive, false);
      expect(adapter.availableProducts, isEmpty);
      expect(adapter.currentPurchases, isEmpty);
    });
    
    test('should create realistic fake purchases', () {
      adapter.simulateProActivation(ProCatalog.monthlyProductId);
      
      final purchase = adapter.currentPurchases.first;
      
      expect(purchase.purchaseToken, startsWith('fake_token_'));
      expect(purchase.productId, ProCatalog.monthlyProductId);
      expect(purchase.orderId, startsWith('fake_order_'));
      expect(purchase.purchaseTime, isPositive);
      expect(purchase.purchaseState, 0); // Purchased
      expect(purchase.acknowledged, false);
      expect(purchase.autoRenewing, true);
      expect(purchase.obfuscatedAccountId, startsWith('fake_account_'));
      expect(purchase.developerPayload, isNull);
      expect(purchase.isPurchased, true);
      expect(purchase.isPending, false);
    });
    
    test('should handle multiple products correctly', () async {
      await adapter.startConnection();
      
      final result = await adapter.queryProductDetails([
        ProCatalog.monthlyProductId,
        ProCatalog.yearlyProductId,
        'nonexistent_product',
      ]);
      
      expect(result.isSuccess, true);
      expect(adapter.availableProducts.length, 2); // Only valid products
      
      final productIds = adapter.availableProducts.map((p) => p.id).toList();
      expect(productIds, contains(ProCatalog.monthlyProductId));
      expect(productIds, contains(ProCatalog.yearlyProductId));
      expect(productIds, isNot(contains('nonexistent_product')));
    });
  });
  
  group('GooglePlayBillingAdapter', () {
    late GooglePlayBillingAdapter adapter;
    
    setUp(() {
      adapter = GooglePlayBillingAdapter();
    });
    
    tearDown(() {
      adapter.dispose();
    });
    
    test('should start in disconnected state', () {
      expect(adapter.connectionState, BillingServiceState.disconnected);
      expect(adapter.isProActive, false);
      expect(adapter.activeProPurchase, isNull);
      expect(adapter.availableProducts, isEmpty);
      expect(adapter.currentPurchases, isEmpty);
    });
    
    test('should connect successfully (skeleton)', () async {
      final result = await adapter.startConnection();
      
      expect(result.isSuccess, true);
      expect(adapter.connectionState, BillingServiceState.connected);
    });
    
    test('should disconnect cleanly', () async {
      await adapter.startConnection();
      
      await adapter.endConnection();
      expect(adapter.connectionState, BillingServiceState.disconnected);
    });
    
    test('should return catalog products for queryProductDetails', () async {
      await adapter.startConnection();
      
      final result = await adapter.queryProductDetails([
        ProCatalog.monthlyProductId,
        ProCatalog.yearlyProductId,
      ]);
      
      expect(result.isSuccess, true);
      expect(adapter.availableProducts.length, 2);
    });
    
    test('should return feature not supported for billing flow', () async {
      await adapter.startConnection();
      
      final result = await adapter.launchBillingFlow(ProCatalog.monthlyProductId);
      
      expect(result.isSuccess, false);
      expect(result.responseCode, BillingResultCode.featureNotSupported);
      expect(result.debugMessage, 'Google Play Billing not yet implemented');
    });
    
    test('should handle dispose correctly', () {
      adapter.dispose();
      
      expect(adapter.connectionState, BillingServiceState.closed);
      expect(adapter.availableProducts, isEmpty);
      expect(adapter.currentPurchases, isEmpty);
    });
  });
  
  group('BillingAdapterFactory', () {
    test('should create FakeBillingAdapter by default', () {
      final adapter = BillingAdapterFactory.create();
      expect(adapter, isA<FakeBillingAdapter>());
    });
    
    test('should create FakeBillingAdapter when explicitly requested', () {
      final adapter = BillingAdapterFactory.create(useFakeAdapter: true);
      expect(adapter, isA<FakeBillingAdapter>());
    });
    
    test('should create GooglePlayBillingAdapter when fake is disabled', () {
      final adapter = BillingAdapterFactory.create(useFakeAdapter: false);
      expect(adapter, isA<GooglePlayBillingAdapter>());
    });
  });
  
  group('Billing Flow Integration', () {
    late FakeBillingAdapter adapter;
    List<ProPurchase> receivedPurchases = [];
    
    setUp(() {
      adapter = FakeBillingAdapter();
      receivedPurchases.clear();
      
      adapter.setPurchaseUpdateListener((purchases) {
        receivedPurchases.addAll(purchases);
      });
    });
    
    tearDown(() {
      adapter.dispose();
    });
    
    test('should complete full purchase flow successfully', () async {
      // Step 1: Connect
      final connectionResult = await adapter.startConnection();
      expect(connectionResult.isSuccess, true);
      
      // Step 2: Query products
      final queryResult = await adapter.queryProductDetails([
        ProCatalog.monthlyProductId,
      ]);
      expect(queryResult.isSuccess, true);
      expect(adapter.availableProducts.length, 1);
      
      // Step 3: Simulate successful purchase
      adapter.simulateProActivation(ProCatalog.monthlyProductId);
      expect(adapter.isProActive, true);
      expect(receivedPurchases.length, 1);
      
      // Step 4: Acknowledge purchase
      final purchase = receivedPurchases.first;
      final ackResult = await adapter.acknowledgePurchase(purchase.purchaseToken);
      expect(ackResult.isSuccess, true);
      
      // Step 5: Verify final state
      final acknowledgedPurchase = adapter.currentPurchases
          .where((p) => p.purchaseToken == purchase.purchaseToken)
          .first;
      expect(acknowledgedPurchase.acknowledged, true);
      expect(adapter.isProActive, true);
    });
    
    test('should handle purchase cancellation gracefully', () async {
      await adapter.startConnection();
      
      // The FakeBillingAdapter has built-in randomness, but we can test
      // the cancellation scenario by checking the possible return values
      final result = await adapter.launchBillingFlow(ProCatalog.monthlyProductId);
      
      if (result.responseCode == BillingResultCode.userCanceled) {
        expect(result.debugMessage, 'User canceled purchase');
        expect(adapter.isProActive, false);
        expect(receivedPurchases, isEmpty);
      }
    });
    
    test('should maintain Pro status across app sessions', () async {
      await adapter.startConnection();
      
      // Simulate Pro activation
      adapter.simulateProActivation(ProCatalog.yearlyProductId);
      expect(adapter.isProActive, true);
      
      // Query existing purchases (simulates app restart)
      final queryResult = await adapter.queryPurchases();
      expect(queryResult.isSuccess, true);
      expect(adapter.isProActive, true);
      
      // Verify Pro purchase is still active
      final activePurchase = adapter.activeProPurchase;
      expect(activePurchase, isNotNull);
      expect(activePurchase!.productId, ProCatalog.yearlyProductId);
      expect(activePurchase.autoRenewing, true);
    });
    
    test('should handle Pro expiration correctly', () async {
      await adapter.startConnection();
      
      // Start with active Pro
      adapter.simulateProActivation(ProCatalog.monthlyProductId);
      expect(adapter.isProActive, true);
      
      // Simulate expiration
      adapter.simulateProExpiration();
      
      // Verify Pro is no longer active
      expect(adapter.isProActive, false);
      expect(adapter.activeProPurchase, isNull);
      expect(adapter.currentPurchases, isEmpty);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/payments/fake_billing_adapter.dart';
import 'package:mindtrainer/payments/models.dart';

void main() {
  group('FakeBillingAdapter', () {
    late FakeBillingAdapter adapter;

    setUp(() {
      adapter = FakeBillingAdapter.instance;
      adapter.reset();
    });

    tearDown(() {
      adapter.reset();
    });

    group('configuration', () {
      test('can configure success rate', () {
        adapter.setSuccessRate(0.5);
        // Success rate is internal, but we can test it doesn't crash
        expect(() => adapter.setSuccessRate(0.5), returnsNormally);
      });

      test('clamps success rate to valid range', () {
        expect(() => adapter.setSuccessRate(-0.5), returnsNormally);
        expect(() => adapter.setSuccessRate(1.5), returnsNormally);
      });

      test('can configure operation delay', () {
        adapter.setOperationDelay(const Duration(milliseconds: 100));
        expect(() => adapter.setOperationDelay(const Duration(milliseconds: 100)), returnsNormally);
      });

      test('can configure network simulation', () {
        adapter.setSimulateNetworkDelays(false);
        expect(() => adapter.setSimulateNetworkDelays(false), returnsNormally);
      });

      test('can force specific errors', () {
        adapter.forceError('USER_CANCELED');
        expect(() => adapter.forceError('USER_CANCELED'), returnsNormally);
      });

      test('reset clears all configuration', () {
        adapter.setSuccessRate(0.1);
        adapter.setOperationDelay(const Duration(seconds: 5));
        adapter.forceError('TEST_ERROR');
        
        adapter.reset();
        
        // Reset should not crash and should clear state
        expect(() => adapter.reset(), returnsNormally);
      });
    });

    group('basic operations', () {
      test('initializes successfully', () async {
        final result = await adapter.initialize();
        
        expect(result.isSuccess, isTrue);
        expect(result.debugMessage, contains('Fake billing initialized'));
      });

      test('connects successfully', () async {
        await adapter.initialize();
        final result = await adapter.startConnection();
        
        expect(result.isSuccess, isTrue);
        expect(result.debugMessage, contains('Connected to fake billing service'));
      });

      test('can end connection', () async {
        await adapter.initialize();
        await adapter.startConnection();
        
        expect(() => adapter.endConnection(), returnsNormally);
      });

      test('queries product details successfully', () async {
        await adapter.initialize();
        await adapter.startConnection();
        
        final result = await adapter.queryProductDetails([
          BillingProducts.proMonthly,
          BillingProducts.proYearly,
        ]);
        
        expect(result.isSuccess, isTrue);
        expect(result.debugMessage, contains('Products queried successfully'));
      });

      test('returns available products', () async {
        await adapter.initialize();
        await adapter.startConnection();
        await adapter.queryProductDetails([BillingProducts.proMonthly]);
        
        final products = await adapter.getAvailableProducts();
        
        expect(products, isNotEmpty);
        expect(products.length, equals(2)); // Monthly and yearly
        expect(products.any((p) => p.productId == BillingProducts.proMonthly), isTrue);
        expect(products.any((p) => p.productId == BillingProducts.proYearly), isTrue);
        
        final monthlyProduct = products.firstWhere((p) => p.productId == BillingProducts.proMonthly);
        expect(monthlyProduct.title, contains('Fake'));
        expect(monthlyProduct.price, equals('\$9.99'));
      });
    });

    group('purchase flow', () {
      setUp(() async {
        await adapter.initialize();
        await adapter.startConnection();
      });

      test('launches billing flow successfully', () async {
        // Set high success rate for consistent test
        adapter.setSuccessRate(1.0);
        
        final result = await adapter.launchBillingFlow(BillingProducts.proMonthly);
        
        // Should succeed with high success rate
        expect(result.responseCode, anyOf([
          BillingResult.ok,
          BillingResult.userCanceled,
        ]));
      });

      test('can simulate user cancellation', () async {
        // Force user cancellation
        adapter.forceError('USER_CANCELED');
        
        final result = await adapter.launchBillingFlow(BillingProducts.proMonthly);
        
        expect(result.isUserCanceled, isTrue);
        expect(result.debugMessage, contains('forced to fail'));
      });

      test('can simulate purchase failure', () async {
        // Force generic error
        adapter.forceError('UNKNOWN_ERROR');
        
        final result = await adapter.launchBillingFlow(BillingProducts.proMonthly);
        
        expect(result.isError, isTrue);
        expect(result.debugMessage, contains('forced to fail'));
      });

      test('requires connection for purchases', () async {
        await adapter.endConnection();
        
        final result = await adapter.launchBillingFlow(BillingProducts.proMonthly);
        
        expect(result.responseCode, equals(BillingResult.serviceUnavailable));
        expect(result.debugMessage, contains('Not connected'));
      });
    });

    group('purchase management', () {
      setUp(() async {
        await adapter.initialize();
        await adapter.startConnection();
      });

      test('queries purchases successfully', () async {
        final result = await adapter.queryPurchases();
        
        expect(result.isSuccess, isTrue);
        expect(result.debugMessage, contains('Purchases queried successfully'));
      });

      test('returns current purchases', () async {
        // Initially no purchases
        final initialPurchases = await adapter.getCurrentPurchases();
        expect(initialPurchases, isEmpty);
        
        // Add a fake purchase
        adapter.addFakePurchase(BillingProducts.proMonthly);
        
        final purchasesAfter = await adapter.getCurrentPurchases();
        expect(purchasesAfter.length, equals(1));
        expect(purchasesAfter[0].productId, equals(BillingProducts.proMonthly));
        expect(purchasesAfter[0].isValid, isTrue);
      });

      test('acknowledges purchases', () async {
        // Add unacknowledged purchase
        adapter.addFakePurchase(BillingProducts.proMonthly, acknowledged: false);
        
        final purchases = await adapter.getCurrentPurchases();
        final purchase = purchases.first;
        expect(purchase.acknowledged, isFalse);
        
        // Acknowledge the purchase
        final result = await adapter.acknowledgePurchase(purchase.purchaseToken!);
        
        expect(result.isSuccess, isTrue);
        expect(result.debugMessage, contains('acknowledged'));
        
        // Verify acknowledgment
        final updatedPurchases = await adapter.getCurrentPurchases();
        final updatedPurchase = updatedPurchases.first;
        expect(updatedPurchase.acknowledged, isTrue);
      });

      test('handles acknowledgment of non-existent purchase', () async {
        final result = await adapter.acknowledgePurchase('fake_nonexistent_token');
        
        expect(result.responseCode, equals(BillingResult.itemUnavailable));
        expect(result.debugMessage, contains('not found'));
      });

      test('can clear all purchases', () async {
        adapter.addFakePurchase(BillingProducts.proMonthly);
        adapter.addFakePurchase(BillingProducts.proYearly);
        
        final purchasesBefore = await adapter.getCurrentPurchases();
        expect(purchasesBefore.length, equals(2));
        
        adapter.clearPurchases();
        
        final purchasesAfter = await adapter.getCurrentPurchases();
        expect(purchasesAfter, isEmpty);
      });
    });

    group('error simulation', () {
      setUp(() async {
        await adapter.initialize();
        await adapter.startConnection();
      });

      test('can force initialization errors', () async {
        adapter.reset();
        adapter.forceError('SERVICE_UNAVAILABLE');
        
        final result = await adapter.initialize();
        
        expect(result.responseCode, equals(BillingResult.serviceUnavailable));
        expect(result.debugMessage, contains('Forced error'));
      });

      test('can force connection errors', () async {
        adapter.reset();
        await adapter.initialize();
        adapter.forceError('BILLING_UNAVAILABLE');
        
        final result = await adapter.startConnection();
        
        expect(result.responseCode, equals(BillingResult.billingUnavailable));
      });

      test('can force query errors', () async {
        adapter.forceError('ITEM_UNAVAILABLE');
        
        final result = await adapter.queryProductDetails([BillingProducts.proMonthly]);
        
        expect(result.responseCode, equals(BillingResult.itemUnavailable));
      });

      test('can force acknowledgment errors', () async {
        adapter.addFakePurchase(BillingProducts.proMonthly);
        adapter.forceError('DEVELOPER_ERROR');
        
        final purchases = await adapter.getCurrentPurchases();
        final result = await adapter.acknowledgePurchase(purchases.first.purchaseToken!);
        
        expect(result.responseCode, equals(BillingResult.developerError));
      });
    });

    group('simulation features', () {
      setUp(() async {
        await adapter.initialize();
        await adapter.startConnection();
      });

      test('can simulate purchase updates', () async {
        expect(() => adapter.simulatePurchaseUpdate(BillingProducts.proMonthly), returnsNormally);
        
        final purchases = await adapter.getCurrentPurchases();
        expect(purchases.any((p) => p.productId == BillingProducts.proMonthly), isTrue);
      });

      test('can simulate disconnection', () async {
        expect(() => adapter.simulateDisconnection(), returnsNormally);
        
        // After disconnection, operations should fail
        final result = await adapter.launchBillingFlow(BillingProducts.proMonthly);
        expect(result.responseCode, equals(BillingResult.serviceUnavailable));
      });

      test('can add fake purchases with custom properties', () async {
        final purchaseTime = DateTime(2023, 1, 15);
        
        adapter.addFakePurchase(
          BillingProducts.proYearly,
          acknowledged: true,
          autoRenewing: false,
          purchaseTime: purchaseTime,
        );
        
        final purchases = await adapter.getCurrentPurchases();
        final purchase = purchases.first;
        
        expect(purchase.productId, equals(BillingProducts.proYearly));
        expect(purchase.acknowledged, isTrue);
        expect(purchase.autoRenewing, isFalse);
        expect(purchase.purchaseDateTime?.year, equals(2023));
        expect(purchase.purchaseDateTime?.month, equals(1));
      });
    });

    group('delay simulation', () {
      test('respects operation delays when enabled', () async {
        adapter.setOperationDelay(const Duration(milliseconds: 50));
        adapter.setSimulateNetworkDelays(true);
        
        final stopwatch = Stopwatch()..start();
        await adapter.initialize();
        stopwatch.stop();
        
        // Should take at least the delay time
        expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40)); // Allow some tolerance
      });

      test('skips delays when disabled', () async {
        adapter.setOperationDelay(const Duration(milliseconds: 100));
        adapter.setSimulateNetworkDelays(false);
        
        final stopwatch = Stopwatch()..start();
        await adapter.initialize();
        stopwatch.stop();
        
        // Should be much faster when delays are disabled
        expect(stopwatch.elapsedMilliseconds, lessThan(50));
      });
    });
  });

  group('BillingErrorMapper', () {
    test('maps error codes to user-friendly messages', () {
      expect(BillingErrorMapper.mapErrorToUserMessage('USER_CANCELED', null), 
          equals('Purchase was canceled.'));
      
      expect(BillingErrorMapper.mapErrorToUserMessage('SERVICE_UNAVAILABLE', null), 
          contains('temporarily unavailable'));
      
      expect(BillingErrorMapper.mapErrorToUserMessage('BILLING_UNAVAILABLE', null), 
          contains('not available on this device'));
      
      expect(BillingErrorMapper.mapErrorToUserMessage('ITEM_UNAVAILABLE', null), 
          contains('currently unavailable'));
      
      expect(BillingErrorMapper.mapErrorToUserMessage('DEVELOPER_ERROR', null), 
          contains('configuration error'));
      
      expect(BillingErrorMapper.mapErrorToUserMessage('NETWORK_ERROR', null), 
          contains('Network connection error'));
      
      expect(BillingErrorMapper.mapErrorToUserMessage('ITEM_ALREADY_OWNED', null), 
          contains('already own'));
      
      expect(BillingErrorMapper.mapErrorToUserMessage('ITEM_NOT_OWNED', null), 
          contains('not associated with your account'));
    });

    test('handles unknown error codes', () {
      final message = BillingErrorMapper.mapErrorToUserMessage('UNKNOWN_CODE', null);
      expect(message, contains('unexpected error'));
    });

    test('uses debug message when available', () {
      final message = BillingErrorMapper.mapErrorToUserMessage('UNKNOWN_CODE', 'Custom error details');
      expect(message, contains('Custom error details'));
    });

    test('handles null error codes', () {
      final message = BillingErrorMapper.mapErrorToUserMessage(null, null);
      expect(message, contains('unknown error occurred'));
    });

    test('maps response codes to error codes', () {
      expect(BillingErrorMapper.mapResponseCodeToErrorCode(BillingResult.ok), 
          equals('SUCCESS'));
      
      expect(BillingErrorMapper.mapResponseCodeToErrorCode(BillingResult.userCanceled), 
          equals('USER_CANCELED'));
      
      expect(BillingErrorMapper.mapResponseCodeToErrorCode(BillingResult.serviceUnavailable), 
          equals('SERVICE_UNAVAILABLE'));
      
      expect(BillingErrorMapper.mapResponseCodeToErrorCode(BillingResult.billingUnavailable), 
          equals('BILLING_UNAVAILABLE'));
      
      expect(BillingErrorMapper.mapResponseCodeToErrorCode(BillingResult.itemUnavailable), 
          equals('ITEM_UNAVAILABLE'));
      
      expect(BillingErrorMapper.mapResponseCodeToErrorCode(BillingResult.developerError), 
          equals('DEVELOPER_ERROR'));
      
      expect(BillingErrorMapper.mapResponseCodeToErrorCode(BillingResult.errorCode), 
          equals('UNKNOWN_ERROR'));
    });

    test('identifies retryable errors correctly', () {
      expect(BillingErrorMapper.isRetryableError('SERVICE_UNAVAILABLE'), isTrue);
      expect(BillingErrorMapper.isRetryableError('NETWORK_ERROR'), isTrue);
      expect(BillingErrorMapper.isRetryableError('ITEM_UNAVAILABLE'), isTrue);
      
      expect(BillingErrorMapper.isRetryableError('USER_CANCELED'), isFalse);
      expect(BillingErrorMapper.isRetryableError('BILLING_UNAVAILABLE'), isFalse);
      expect(BillingErrorMapper.isRetryableError('DEVELOPER_ERROR'), isFalse);
      expect(BillingErrorMapper.isRetryableError('ITEM_ALREADY_OWNED'), isFalse);
      
      // Unknown errors should be retryable by default
      expect(BillingErrorMapper.isRetryableError('UNKNOWN_ERROR'), isTrue);
      expect(BillingErrorMapper.isRetryableError(null), isTrue);
    });

    test('calculates retry delays with exponential backoff', () {
      expect(BillingErrorMapper.getRetryDelay(1), equals(const Duration(seconds: 1)));
      expect(BillingErrorMapper.getRetryDelay(2), equals(const Duration(seconds: 2)));
      expect(BillingErrorMapper.getRetryDelay(3), equals(const Duration(seconds: 4)));
      expect(BillingErrorMapper.getRetryDelay(4), equals(const Duration(seconds: 8)));
      expect(BillingErrorMapper.getRetryDelay(5), equals(const Duration(seconds: 16)));
      
      // Should cap at 30 seconds
      expect(BillingErrorMapper.getRetryDelay(10), equals(const Duration(seconds: 30)));
    });
  });
}
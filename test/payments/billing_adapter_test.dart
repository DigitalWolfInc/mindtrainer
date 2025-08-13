import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/payments/billing_adapter.dart';
import '../../lib/core/payments/play_billing_adapter.dart';

import 'billing_adapter_test.mocks.dart';

@GenerateMocks([PlayBillingAdapter])
void main() {
  group('BillingAdapter Tests', () {
    late MockPlayBillingAdapter mockPlayBillingAdapter;
    late BillingAdapter billingAdapter;

    setUp(() {
      mockPlayBillingAdapter = MockPlayBillingAdapter();
      
      // Reset singleton
      BillingAdapter.resetInstance();
    });

    tearDown(() {
      BillingAdapter.resetInstance();
    });

    BillingAdapter createBillingAdapter() {
      return BillingAdapter._(mockPlayBillingAdapter);
    }

    group('Initialization', () {
      test('should initialize underlying adapter', () async {
        when(mockPlayBillingAdapter.startConnection())
            .thenAnswer((_) async => BillingResult.ok());

        billingAdapter = createBillingAdapter();
        
        await billingAdapter.initialize();

        verify(mockPlayBillingAdapter.startConnection()).called(1);
      });
    });

    group('Purchase Operations', () {
      test('should call underlying adapter for purchase', () async {
        when(mockPlayBillingAdapter.launchSubscriptionPurchaseFlow(any))
            .thenAnswer((_) async => BillingResult.ok());

        billingAdapter = createBillingAdapter();
        
        await billingAdapter.purchase('mindtrainer_pro_monthly');

        verify(mockPlayBillingAdapter.launchSubscriptionPurchaseFlow('mindtrainer_pro_monthly'))
            .called(1);
      });

      test('should throw BillingException on purchase failure', () async {
        when(mockPlayBillingAdapter.launchSubscriptionPurchaseFlow(any))
            .thenAnswer((_) async => BillingResult.error('Payment failed', 7));

        billingAdapter = createBillingAdapter();

        expect(
          () async => await billingAdapter.purchase('mindtrainer_pro_monthly'),
          throwsA(isA<BillingException>()),
        );
      });

      test('should handle user cancellation correctly', () async {
        when(mockPlayBillingAdapter.launchSubscriptionPurchaseFlow(any))
            .thenAnswer((_) async => BillingResult.cancelled());

        billingAdapter = createBillingAdapter();

        expect(
          () async => await billingAdapter.purchase('mindtrainer_pro_monthly'),
          throwsA(predicate((e) => 
            e is BillingException && e.code == 'purchase_canceled'
          )),
        );
      });
    });

    group('Query Operations', () {
      test('should call underlying adapter for queryPurchases', () async {
        when(mockPlayBillingAdapter.queryPurchases())
            .thenAnswer((_) async => []);

        billingAdapter = createBillingAdapter();
        
        await billingAdapter.queryPurchases();

        verify(mockPlayBillingAdapter.queryPurchases()).called(1);
      });

      test('should call underlying adapter for queryProductDetails', () async {
        final mockProducts = [
          BillingProduct(
            productId: 'mindtrainer_pro_monthly',
            type: 'subs',
            title: 'Pro Monthly',
            description: 'Monthly subscription',
            price: '\$9.99',
            priceAmountMicros: 9990000,
            priceCurrencyCode: 'USD',
          ),
        ];
        
        when(mockPlayBillingAdapter.querySubscriptionProducts(any))
            .thenAnswer((_) async => mockProducts);

        billingAdapter = createBillingAdapter();
        
        await billingAdapter.queryProductDetails(['mindtrainer_pro_monthly']);

        verify(mockPlayBillingAdapter.querySubscriptionProducts(['mindtrainer_pro_monthly']))
            .called(1);
      });
    });

    group('Connection Management', () {
      test('should return connection state from underlying adapter', () {
        when(mockPlayBillingAdapter.connectionState)
            .thenReturn(BillingConnectionState.connected);

        billingAdapter = createBillingAdapter();
        
        expect(billingAdapter.connectionState, BillingConnectionState.connected);
      });

      test('should forward connection state stream', () async {
        final stateController = StreamController<BillingConnectionState>();
        when(mockPlayBillingAdapter.connectionStateStream)
            .thenAnswer((_) => stateController.stream);

        billingAdapter = createBillingAdapter();
        
        final stream = billingAdapter.connectionStateStream;
        
        stateController.add(BillingConnectionState.connected);
        
        expect(await stream.first, BillingConnectionState.connected);
        
        await stateController.close();
      });

      test('should forward purchase update stream', () async {
        final purchaseController = StreamController<List<BillingPurchase>>();
        when(mockPlayBillingAdapter.purchaseUpdateStream)
            .thenAnswer((_) => purchaseController.stream);

        billingAdapter = createBillingAdapter();
        
        final stream = billingAdapter.purchaseUpdateStream;
        
        final mockPurchases = [
          BillingPurchase(
            purchaseToken: 'token123',
            productId: 'mindtrainer_pro_monthly',
            state: PurchaseState.purchased,
            purchaseTime: DateTime.now().millisecondsSinceEpoch,
            acknowledged: true,
            autoRenewing: true,
          ),
        ];
        
        purchaseController.add(mockPurchases);
        
        final receivedPurchases = await stream.first;
        expect(receivedPurchases.length, 1);
        expect(receivedPurchases.first.productId, 'mindtrainer_pro_monthly');
        
        await purchaseController.close();
      });
    });

    group('Billing Features', () {
      test('should check billing availability', () async {
        when(mockPlayBillingAdapter.isSubscriptionSupported())
            .thenAnswer((_) async => true);

        billingAdapter = createBillingAdapter();
        
        final available = await billingAdapter.isBillingAvailable();
        
        expect(available, true);
        verify(mockPlayBillingAdapter.isSubscriptionSupported()).called(1);
      });

      test('should handle manage subscriptions not available', () async {
        billingAdapter = createBillingAdapter();

        expect(
          () async => await billingAdapter.manageSubscriptions(),
          throwsA(predicate((e) => 
            e is BillingException && e.code == 'manage_subscriptions_not_available'
          )),
        );
      });
    });

    group('Error Mapping', () {
      test('should map response codes to billing exceptions correctly', () {
        // Test cancellation
        final cancelResult = BillingResult.cancelled();
        final cancelException = BillingException._fromResult(cancelResult);
        expect(cancelException.code, 'purchase_canceled');

        // Test offline
        final offlineResult = BillingResult.error('Service unavailable', 6);
        final offlineException = BillingException._fromResult(offlineResult);
        expect(offlineException.code, 'offline');

        // Test already owned
        final ownedResult = BillingResult.error('Already owned', 7);
        final ownedException = BillingException._fromResult(ownedResult);
        expect(ownedException.code, 'already_owned');

        // Test unknown error
        final unknownResult = BillingResult.error('Unknown error', 999);
        final unknownException = BillingException._fromResult(unknownResult);
        expect(unknownException.code, 'unknown');
      });

      test('should preserve error messages', () {
        final result = BillingResult.error('Custom error message', 999);
        final exception = BillingException._fromResult(result);
        expect(exception.message, 'Custom error message');
      });
    });

    group('Resource Management', () {
      test('should dispose underlying adapter', () async {
        when(mockPlayBillingAdapter.endConnection()).thenAnswer((_) async {});

        billingAdapter = createBillingAdapter();
        
        await billingAdapter.dispose();

        verify(mockPlayBillingAdapter.endConnection()).called(1);
      });
    });

    group('Product Details Callback', () {
      test('should handle product details callback', () async {
        final mockProducts = [
          BillingProduct(
            productId: 'mindtrainer_pro_monthly',
            type: 'subs',
            title: 'Pro Monthly',
            description: 'Monthly subscription',
            price: '\$9.99',
            priceAmountMicros: 9990000,
            priceCurrencyCode: 'USD',
          ),
        ];
        
        when(mockPlayBillingAdapter.querySubscriptionProducts(any))
            .thenAnswer((_) async => mockProducts);

        billingAdapter = createBillingAdapter();
        
        List<BillingProduct>? receivedProducts;
        billingAdapter._setOnProductDetailsCallback((products) {
          receivedProducts = products;
        });
        
        await billingAdapter.queryProductDetails(['mindtrainer_pro_monthly']);

        expect(receivedProducts, isNotNull);
        expect(receivedProducts!.length, 1);
        expect(receivedProducts!.first.productId, 'mindtrainer_pro_monthly');
      });

      test('should handle product query errors gracefully', () async {
        when(mockPlayBillingAdapter.querySubscriptionProducts(any))
            .thenThrow(Exception('Network error'));

        billingAdapter = createBillingAdapter();
        
        List<BillingProduct>? receivedProducts;
        billingAdapter._setOnProductDetailsCallback((products) {
          receivedProducts = products;
        });
        
        // Should not throw, should handle error gracefully
        await billingAdapter.queryProductDetails(['mindtrainer_pro_monthly']);

        // Callback should not have been called due to error
        expect(receivedProducts, isNull);
      });
    });
  });
}
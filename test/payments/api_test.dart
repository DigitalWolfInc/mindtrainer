import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/foundation/clock.dart';
import 'package:mindtrainer/foundation/timeouts.dart';
import 'package:mindtrainer/payments/api.dart';
import 'package:mindtrainer/payments/billing_constants.dart';
import 'package:mindtrainer/payments/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PurchaseAPI', () {
    late List<MethodCall> methodCalls;

    setUp(() {
      methodCalls = [];

      // Mock the platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('mindtrainer/billing'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          switch (methodCall.method) {
            case 'startPurchase':
              return {
                'responseCode': 0,
                'debugMessage': 'Purchase started successfully',
              };

            case 'warmProducts':
              return {
                'responseCode': 0,
                'debugMessage': 'Products warmed successfully',
              };

            case 'changeSubscription':
              // Return unimplemented for now
              return {
                'responseCode': 7, // DEVELOPER_ERROR
                'debugMessage': 'UNIMPLEMENTED: Subscription changes require Play Console base plan configuration',
              };

            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('mindtrainer/billing'),
        null,
      );
    });

    group('startPurchase', () {
      test('calls platform method with correct parameters', () async {
        final result = await PurchaseAPI.startPurchase('mindtrainer_pro_monthly');

        expect(result.isSuccess, isTrue);
        expect(result.debugMessage, equals('Purchase started successfully'));
        
        expect(methodCalls.length, equals(1));
        expect(methodCalls[0].method, equals('startPurchase'));
        expect(methodCalls[0].arguments['productId'], equals('mindtrainer_pro_monthly'));
      });

      test('handles platform exceptions gracefully', () async {
        // Replace handler to throw exception
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          const MethodChannel('mindtrainer/billing'),
          (MethodCall methodCall) async {
            throw PlatformException(code: 'TEST_ERROR', message: 'Test error');
          },
        );

        final result = await PurchaseAPI.startPurchase('mindtrainer_pro_monthly');

        expect(result.isError, isTrue);
        expect(result.debugMessage, contains('Test error'));
      });
    });

    group('warmProducts', () {
      test('calls platform method with default product IDs', () async {
        final result = await PurchaseAPI.warmProducts();

        expect(result.isSuccess, isTrue);
        expect(result.debugMessage, equals('Products warmed successfully'));
        
        expect(methodCalls.length, equals(1));
        expect(methodCalls[0].method, equals('warmProducts'));
        expect(methodCalls[0].arguments['productIds'], equals(ProductIds.allSubscriptions));
      });

      test('calls platform method with custom product IDs', () async {
        final customIds = ['custom_product_1', 'custom_product_2'];
        final result = await PurchaseAPI.warmProducts(customIds);

        expect(result.isSuccess, isTrue);
        
        expect(methodCalls.length, equals(1));
        expect(methodCalls[0].method, equals('warmProducts'));
        expect(methodCalls[0].arguments['productIds'], equals(customIds));
      });
    });

    group('changeSubscription', () {
      test('returns unimplemented status', () async {
        final result = await PurchaseAPI.changeSubscription(
          fromProductId: 'mindtrainer_pro_monthly',
          toProductId: 'mindtrainer_pro_yearly',
        );

        expect(result.responseCode, equals(BillingResponseCodes.developerError));
        expect(result.debugMessage, contains('UNIMPLEMENTED'));
      });

      test('calls platform method with correct parameters when implemented', () async {
        // This test verifies the parameter structure is correct
        // In the future when changeSubscription is implemented, the platform will handle it
        
        await PurchaseAPI.changeSubscription(
          fromProductId: 'mindtrainer_pro_monthly',
          toProductId: 'mindtrainer_pro_yearly',
          prorationMode: 'IMMEDIATE_WITH_TIME_PRORATION',
        );

        // Even though it returns unimplemented, it should still call the platform method
        expect(methodCalls.length, equals(1));
        expect(methodCalls[0].method, equals('changeSubscription'));
        expect(methodCalls[0].arguments['fromProductId'], equals('mindtrainer_pro_monthly'));
        expect(methodCalls[0].arguments['toProductId'], equals('mindtrainer_pro_yearly'));
        expect(methodCalls[0].arguments['prorationMode'], equals('IMMEDIATE_WITH_TIME_PRORATION'));
      });
    });
  });

  group('PurchaseFlowResult', () {
    test('creates success result with cleanup', () {
      var cleanupCalled = false;
      final billingResult = BillingResult(responseCode: 0, debugMessage: 'Success');
      final result = PurchaseFlowResult.success(billingResult, () {
        cleanupCalled = true;
      });

      expect(result.isSuccess, isTrue);
      expect(result.billingResult, equals(billingResult));

      result.dispose();
      expect(cleanupCalled, isTrue);
    });

    test('creates error result without cleanup', () {
      final billingResult = BillingResult(responseCode: 1, debugMessage: 'Error');
      final result = PurchaseFlowResult.error(billingResult);

      expect(result.isSuccess, isFalse);
      expect(result.billingResult, equals(billingResult));

      // Should not throw when disposing error result
      result.dispose();
    });
  });

  group('Guarded Purchase Flow', () {
    late FakeClock fakeClock;

    setUp(() {
      fakeClock = FakeClock(DateTime(2024, 1, 1));
      PurchaseAPI.setClock(fakeClock);
    });

    tearDown(() {
      PurchaseAPI.setClock(const SystemClock());
    });

    test('triggers timeout callback when purchase takes too long', () async {
      var timeoutTriggered = false;
      
      final result = await PurchaseAPI.startPurchaseWithGuard(
        'mindtrainer_pro_monthly',
        timeout: const Duration(seconds: 5),
        onTimeout: () {
          timeoutTriggered = true;
        },
      );

      expect(result.isSuccess, isTrue);
      expect(timeoutTriggered, isFalse);

      // Advance clock past timeout
      fakeClock.advance(const Duration(seconds: 6));

      expect(timeoutTriggered, isTrue);

      result.dispose();
    });

    test('cancels timeout if disposed before triggering', () async {
      var timeoutTriggered = false;
      
      final result = await PurchaseAPI.startPurchaseWithGuard(
        'mindtrainer_pro_monthly',
        timeout: const Duration(seconds: 5),
        onTimeout: () {
          timeoutTriggered = true;
        },
      );

      // Dispose before timeout
      result.dispose();
      
      // Advance clock past timeout
      fakeClock.advance(const Duration(seconds: 6));

      expect(timeoutTriggered, isFalse);
    });
  });

  group('PurchaseOrigins', () {
    test('defines correct origin constants', () {
      expect(PurchaseOrigins.purchase, equals('purchase'));
      expect(PurchaseOrigins.restore, equals('restore'));
      expect(PurchaseOrigins.unknown, equals('unknown'));
    });
  });
}
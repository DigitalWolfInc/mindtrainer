import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/payments/channel.dart';
import 'package:mindtrainer/payments/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BillingChannel', () {
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
            case 'initialize':
              return {
                'responseCode': 0,
                'debugMessage': 'Billing initialized (test)',
              };
              
            case 'startConnection':
              return {
                'responseCode': 0,
                'debugMessage': 'Connected to billing service (test)',
              };
              
            case 'getAvailableProducts':
              return [
                {
                  'productId': 'mindtrainer_pro_monthly',
                  'title': 'MindTrainer Pro Monthly',
                  'price': '\$9.99',
                  'priceAmountMicros': 9990000,
                  'priceCurrencyCode': 'USD',
                  'subscriptionPeriod': 'P1M',
                },
              ];
              
            case 'getCurrentPurchases':
              return [
                {
                  'productId': 'mindtrainer_pro_monthly',
                  'purchaseToken': 'test_token_123',
                  'acknowledged': true,
                  'autoRenewing': true,
                  'purchaseState': 1,
                  'purchaseTime': 1640995200000,
                },
              ];
              
            case 'queryProductDetails':
              return {
                'responseCode': 0,
                'debugMessage': 'Products queried successfully',
              };
              
            case 'launchBillingFlow':
              return {
                'responseCode': 0,
                'debugMessage': 'Purchase successful (test)',
              };
              
            case 'acknowledgePurchase':
              return {
                'responseCode': 0,
                'debugMessage': 'Purchase acknowledged (test)',
              };
              
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      // Clean up
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('mindtrainer/billing'),
        null,
      );
    });

    test('initialize calls platform method and returns result', () async {
      await BillingChannel.initialize();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls[0].method, equals('initialize'));
    });

    test('startConnection calls platform method and returns BillingResult', () async {
      final result = await BillingChannel.startConnection();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls[0].method, equals('startConnection'));
      expect(result.isSuccess, isTrue);
      expect(result.debugMessage, equals('Connected to billing service (test)'));
    });

    test('queryProductDetails passes product IDs to platform', () async {
      const productIds = ['mindtrainer_pro_monthly', 'mindtrainer_pro_yearly'];
      final result = await BillingChannel.queryProductDetails(productIds);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls[0].method, equals('queryProductDetails'));
      expect(methodCalls[0].arguments, equals({'productIds': productIds}));
      expect(result.isSuccess, isTrue);
    });

    test('getAvailableProducts returns list of ProductInfo', () async {
      final products = await BillingChannel.getAvailableProducts();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls[0].method, equals('getAvailableProducts'));
      expect(products.length, equals(1));
      expect(products[0].productId, equals('mindtrainer_pro_monthly'));
      expect(products[0].title, equals('MindTrainer Pro Monthly'));
      expect(products[0].price, equals('\$9.99'));
      expect(products[0].priceAmountMicros, equals(9990000));
    });

    test('launchBillingFlow passes product ID to platform', () async {
      const productId = 'mindtrainer_pro_monthly';
      final result = await BillingChannel.launchBillingFlow(productId);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls[0].method, equals('launchBillingFlow'));
      expect(methodCalls[0].arguments, equals({'productId': productId}));
      expect(result.isSuccess, isTrue);
    });

    test('getCurrentPurchases returns list of PurchaseInfo', () async {
      final purchases = await BillingChannel.getCurrentPurchases();
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls[0].method, equals('getCurrentPurchases'));
      expect(purchases.length, equals(1));
      expect(purchases[0].productId, equals('mindtrainer_pro_monthly'));
      expect(purchases[0].purchaseToken, equals('test_token_123'));
      expect(purchases[0].acknowledged, isTrue);
      expect(purchases[0].isPurchased, isTrue);
    });

    test('acknowledgePurchase passes purchase token to platform', () async {
      const purchaseToken = 'test_token_123';
      final result = await BillingChannel.acknowledgePurchase(purchaseToken);
      
      expect(methodCalls.length, equals(1));
      expect(methodCalls[0].method, equals('acknowledgePurchase'));
      expect(methodCalls[0].arguments, equals({'purchaseToken': purchaseToken}));
      expect(result.isSuccess, isTrue);
    });

    test('handles platform exceptions gracefully', () async {
      // Mock platform to throw exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('mindtrainer/billing'),
        (MethodCall methodCall) async {
          throw PlatformException(code: 'TEST_ERROR', message: 'Test error');
        },
      );
      
      final result = await BillingChannel.startConnection();
      expect(result.isError, isTrue);
      expect(result.debugMessage, contains('Test error'));
    });

    group('method call handling', () {
      test('handles onPurchasesUpdated', () async {
        final purchasesList = [
          {
            'productId': 'mindtrainer_pro_monthly',
            'purchaseToken': 'new_token_456',
            'acknowledged': false,
            'autoRenewing': true,
            'purchaseState': 1,
          },
        ];

        List<PurchaseInfo>? receivedPurchases;
        final subscription = BillingChannel.purchaseUpdates.listen((purchases) {
          receivedPurchases = purchases;
        });

        // Initialize the channel to set up the method call handler
        await BillingChannel.initialize();

        // Simulate platform calling the method directly on the handler
        const MethodChannel channel = MethodChannel('mindtrainer/billing');
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onPurchasesUpdated', purchasesList),
          ),
          (data) {},
        );

        // Give time for stream processing
        await Future.delayed(const Duration(milliseconds: 10));

        expect(receivedPurchases, isNotNull);
        expect(receivedPurchases!.length, equals(1));
        expect(receivedPurchases![0].productId, equals('mindtrainer_pro_monthly'));
        expect(receivedPurchases![0].purchaseToken, equals('new_token_456'));

        subscription.cancel();
      });

      test('handles onBillingServiceDisconnected', () async {
        BillingResult? receivedResult;
        final subscription = BillingChannel.connectionUpdates.listen((result) {
          receivedResult = result;
        });

        // Initialize the channel to set up the method call handler
        await BillingChannel.initialize();

        // Simulate platform calling the method directly on the handler
        const MethodChannel channel = MethodChannel('mindtrainer/billing');
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          channel.name,
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onBillingServiceDisconnected'),
          ),
          (data) {},
        );

        // Give time for stream processing
        await Future.delayed(const Duration(milliseconds: 10));

        expect(receivedResult, isNotNull);
        expect(receivedResult!.isError, isTrue);
        expect(receivedResult!.debugMessage, contains('disconnected'));

        subscription.cancel();
      });
    });
  });
}
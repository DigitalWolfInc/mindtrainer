import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/payments/models.dart';

void main() {
  group('BillingResult', () {
    test('creates from successful response map', () {
      final map = {
        'responseCode': 0,
        'debugMessage': 'Success',
      };

      final result = BillingResult.fromMap(map);

      expect(result.responseCode, equals(0));
      expect(result.debugMessage, equals('Success'));
      expect(result.isSuccess, isTrue);
      expect(result.isError, isFalse);
    });

    test('creates from error response map', () {
      final map = {
        'responseCode': 8,
        'debugMessage': 'Network error',
      };

      final result = BillingResult.fromMap(map);

      expect(result.responseCode, equals(8));
      expect(result.debugMessage, equals('Network error'));
      expect(result.isSuccess, isFalse);
      expect(result.isError, isTrue);
    });

    test('creates error result from code and message', () {
      final result = BillingResult.error('TEST_ERROR', 'Test message');

      expect(result.responseCode, equals(BillingResult.errorCode));
      expect(result.debugMessage, equals('TEST_ERROR: Test message'));
      expect(result.isError, isTrue);
    });

    test('handles missing fields gracefully', () {
      final map = <String, Object?>{};
      final result = BillingResult.fromMap(map);

      expect(result.responseCode, equals(BillingResult.errorCode));
      expect(result.debugMessage, isNull);
    });

    test('detects user cancellation', () {
      final result = BillingResult.fromMap({'responseCode': 1});
      expect(result.isUserCanceled, isTrue);
    });

    test('equality and hashCode work correctly', () {
      final result1 = BillingResult(responseCode: 0, debugMessage: 'OK');
      final result2 = BillingResult(responseCode: 0, debugMessage: 'OK');
      final result3 = BillingResult(responseCode: 1, debugMessage: 'Canceled');

      expect(result1, equals(result2));
      expect(result1.hashCode, equals(result2.hashCode));
      expect(result1, isNot(equals(result3)));
    });

    test('converts to map correctly', () {
      final result = BillingResult(responseCode: 0, debugMessage: 'Success');
      final map = result.toMap();

      expect(map['responseCode'], equals(0));
      expect(map['debugMessage'], equals('Success'));
    });
  });

  group('ProductInfo', () {
    test('creates from complete product map', () {
      final map = {
        'productId': 'mindtrainer_pro_monthly',
        'title': 'MindTrainer Pro Monthly',
        'description': 'Unlock premium features',
        'price': '\$9.99',
        'priceAmountMicros': 9990000,
        'priceCurrencyCode': 'USD',
        'subscriptionPeriod': 'P1M',
        'introductoryPrice': '\$4.99',
        'introductoryPricePeriod': 'P1W',
      };

      final product = ProductInfo.fromMap(map);

      expect(product.productId, equals('mindtrainer_pro_monthly'));
      expect(product.title, equals('MindTrainer Pro Monthly'));
      expect(product.description, equals('Unlock premium features'));
      expect(product.price, equals('\$9.99'));
      expect(product.priceAmountMicros, equals(9990000));
      expect(product.priceCurrencyCode, equals('USD'));
      expect(product.subscriptionPeriod, equals('P1M'));
      expect(product.introductoryPrice, equals('\$4.99'));
      expect(product.introductoryPricePeriod, equals('P1W'));
      expect(product.isSubscription, isTrue);
      expect(product.hasIntroductoryOffer, isTrue);
    });

    test('creates from minimal product map', () {
      final map = {
        'productId': 'test_product',
      };

      final product = ProductInfo.fromMap(map);

      expect(product.productId, equals('test_product'));
      expect(product.title, isNull);
      expect(product.price, isNull);
      expect(product.isSubscription, isFalse);
      expect(product.hasIntroductoryOffer, isFalse);
    });

    test('handles missing productId gracefully', () {
      final map = <String, Object?>{};
      final product = ProductInfo.fromMap(map);

      expect(product.productId, equals(''));
    });

    test('equality and hashCode work correctly', () {
      final product1 = ProductInfo(
        productId: 'test_product',
        title: 'Test',
        price: '\$9.99',
      );
      final product2 = ProductInfo(
        productId: 'test_product',
        title: 'Test',
        price: '\$9.99',
      );
      final product3 = ProductInfo(
        productId: 'different_product',
        title: 'Test',
        price: '\$9.99',
      );

      expect(product1, equals(product2));
      expect(product1.hashCode, equals(product2.hashCode));
      expect(product1, isNot(equals(product3)));
    });

    test('converts to map correctly', () {
      final product = ProductInfo(
        productId: 'test_product',
        title: 'Test Product',
        price: '\$9.99',
        priceAmountMicros: 9990000,
      );
      final map = product.toMap();

      expect(map['productId'], equals('test_product'));
      expect(map['title'], equals('Test Product'));
      expect(map['price'], equals('\$9.99'));
      expect(map['priceAmountMicros'], equals(9990000));
    });
  });

  group('PurchaseInfo', () {
    test('creates from complete purchase map', () {
      final map = {
        'productId': 'mindtrainer_pro_monthly',
        'purchaseToken': 'test_token_123',
        'acknowledged': true,
        'autoRenewing': true,
        'priceMicros': 9990000,
        'price': '\$9.99',
        'originalJson': '{"test": "data"}',
        'orderId': 'order_123',
        'purchaseTime': 1640995200000,
        'purchaseState': 1,
        'obfuscatedAccountId': 'account_456',
        'developerPayload': 'payload_data',
      };

      final purchase = PurchaseInfo.fromMap(map);

      expect(purchase.productId, equals('mindtrainer_pro_monthly'));
      expect(purchase.purchaseToken, equals('test_token_123'));
      expect(purchase.acknowledged, isTrue);
      expect(purchase.autoRenewing, isTrue);
      expect(purchase.priceMicros, equals(9990000));
      expect(purchase.price, equals('\$9.99'));
      expect(purchase.originalJson, equals('{"test": "data"}'));
      expect(purchase.orderId, equals('order_123'));
      expect(purchase.purchaseTime, equals(1640995200000));
      expect(purchase.purchaseState, equals(1));
      expect(purchase.obfuscatedAccountId, equals('account_456'));
      expect(purchase.developerPayload, equals('payload_data'));
      expect(purchase.isPurchased, isTrue);
      expect(purchase.isValid, isTrue);
    });

    test('creates from minimal purchase map', () {
      final map = <String, Object?>{};
      final purchase = PurchaseInfo.fromMap(map);

      expect(purchase.productId, isNull);
      expect(purchase.purchaseToken, isNull);
      expect(purchase.acknowledged, isFalse);
      expect(purchase.autoRenewing, isFalse);
      expect(purchase.isValid, isFalse);
    });

    test('detects different purchase states', () {
      final pending = PurchaseInfo.fromMap({'purchaseState': 0});
      final purchased = PurchaseInfo.fromMap({'purchaseState': 1});
      final canceled = PurchaseInfo.fromMap({'purchaseState': 2});

      expect(pending.isPending, isTrue);
      expect(purchased.isPurchased, isTrue);
      expect(canceled.isCanceled, isTrue);
    });

    test('converts purchase time to DateTime', () {
      final timestamp = 1640995200000; // 2022-01-01T00:00:00.000Z
      final purchase = PurchaseInfo.fromMap({'purchaseTime': timestamp});

      final dateTime = purchase.purchaseDateTime;
      expect(dateTime, isNotNull);
      expect(dateTime!.millisecondsSinceEpoch, equals(timestamp));
    });

    test('handles null purchase time', () {
      final purchase = PurchaseInfo.fromMap(<String, Object?>{});
      expect(purchase.purchaseDateTime, isNull);
    });

    test('equality and hashCode work correctly', () {
      final purchase1 = PurchaseInfo(
        productId: 'test_product',
        purchaseToken: 'token_123',
        orderId: 'order_123',
      );
      final purchase2 = PurchaseInfo(
        productId: 'test_product',
        purchaseToken: 'token_123',
        orderId: 'order_123',
      );
      final purchase3 = PurchaseInfo(
        productId: 'test_product',
        purchaseToken: 'different_token',
        orderId: 'order_123',
      );

      expect(purchase1, equals(purchase2));
      expect(purchase1.hashCode, equals(purchase2.hashCode));
      expect(purchase1, isNot(equals(purchase3)));
    });

    test('converts to map correctly', () {
      final purchase = PurchaseInfo(
        productId: 'test_product',
        purchaseToken: 'token_123',
        acknowledged: true,
        purchaseState: 1,
      );
      final map = purchase.toMap();

      expect(map['productId'], equals('test_product'));
      expect(map['purchaseToken'], equals('token_123'));
      expect(map['acknowledged'], isTrue);
      expect(map['purchaseState'], equals(1));
    });

    test('detects purchase origins correctly', () {
      final purchaseOrigin = PurchaseInfo.fromMap({'origin': 'purchase'});
      final restoreOrigin = PurchaseInfo.fromMap({'origin': 'restore'});
      final unknownOrigin = PurchaseInfo.fromMap({'origin': 'unknown'});
      final noOrigin = PurchaseInfo.fromMap(<String, Object?>{});

      expect(purchaseOrigin.isFromPurchase, isTrue);
      expect(purchaseOrigin.isFromRestore, isFalse);
      
      expect(restoreOrigin.isFromRestore, isTrue);
      expect(restoreOrigin.isFromPurchase, isFalse);
      
      expect(unknownOrigin.isFromPurchase, isFalse);
      expect(unknownOrigin.isFromRestore, isFalse);
      
      expect(noOrigin.isFromPurchase, isFalse);
      expect(noOrigin.isFromRestore, isFalse);
    });

    test('provides readable purchase state strings', () {
      final pending = PurchaseInfo.fromMap({'purchaseState': 0});
      final purchased = PurchaseInfo.fromMap({'purchaseState': 1});
      final canceled = PurchaseInfo.fromMap({'purchaseState': 2});
      final unknown = PurchaseInfo.fromMap({'purchaseState': 99});

      expect(pending.purchaseStateString, equals('PENDING'));
      expect(purchased.purchaseStateString, equals('PURCHASED'));
      expect(canceled.purchaseStateString, equals('CANCELED'));
      expect(unknown.purchaseStateString, equals('UNSPECIFIED'));
    });
  });

  group('BillingProducts', () {
    test('contains correct product IDs', () {
      expect(BillingProducts.proMonthly, equals('mindtrainer_pro_monthly'));
      expect(BillingProducts.proYearly, equals('mindtrainer_pro_yearly'));
      expect(BillingProducts.allSubscriptions.length, equals(2));
      expect(BillingProducts.allSubscriptions, contains(BillingProducts.proMonthly));
      expect(BillingProducts.allSubscriptions, contains(BillingProducts.proYearly));
    });

    test('identifies Pro products correctly', () {
      expect(BillingProducts.isProProduct('mindtrainer_pro_monthly'), isTrue);
      expect(BillingProducts.isProProduct('mindtrainer_pro_yearly'), isTrue);
      expect(BillingProducts.isProProduct('unknown_product'), isFalse);
      expect(BillingProducts.isProProduct(null), isFalse);
    });

    test('provides display names for products', () {
      expect(BillingProducts.getProductDisplayName('mindtrainer_pro_monthly'), 
          equals('Pro Monthly'));
      expect(BillingProducts.getProductDisplayName('mindtrainer_pro_yearly'), 
          equals('Pro Yearly'));
      expect(BillingProducts.getProductDisplayName('unknown_product'), 
          equals('Unknown Subscription'));
    });
  });

  group('_asInt helper function', () {
    test('converts various numeric types', () {
      // Note: We can't directly test the private function, 
      // but we can test through BillingResult.fromMap
      final testCases = [
        {'responseCode': 42}, // int
        {'responseCode': 42.0}, // double
        {'responseCode': '42'}, // string
      ];

      for (final testCase in testCases) {
        final result = BillingResult.fromMap(testCase);
        expect(result.responseCode, equals(42));
      }
    });

    test('handles null and invalid values', () {
      final testCases = [
        <String, Object?>{}, // missing key
        {'responseCode': null}, // null value
        {'responseCode': 'invalid'}, // invalid string
      ];

      for (final testCase in testCases) {
        final result = BillingResult.fromMap(testCase);
        // Should default to error code
        expect(result.responseCode, equals(BillingResult.errorCode));
      }
    });
  });
}
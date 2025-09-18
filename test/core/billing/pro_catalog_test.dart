/// Unit tests for Pro subscription catalog
/// Tests product definitions, pricing, and catalog functionality

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/billing/pro_catalog.dart';

void main() {
  group('ProProduct', () {
    test('should identify monthly product correctly', () {
      const product = ProProduct(
        id: 'test_monthly',
        title: 'Test Monthly',
        description: 'Test description',
        price: '\$9.99',
        priceAmountMicros: 9990000.0,
        priceCurrencyCode: 'USD',
        subscriptionPeriod: 'P1M',
      );
      
      expect(product.isMonthly, true);
      expect(product.isYearly, false);
    });
    
    test('should identify yearly product correctly', () {
      const product = ProProduct(
        id: 'test_yearly',
        title: 'Test Yearly',
        description: 'Test description',
        price: '\$95.99',
        priceAmountMicros: 95990000.0,
        priceCurrencyCode: 'USD',
        subscriptionPeriod: 'P1Y',
      );
      
      expect(product.isMonthly, false);
      expect(product.isYearly, true);
    });
    
    test('should calculate monthly equivalent price for monthly product', () {
      const product = ProProduct(
        id: 'test_monthly',
        title: 'Test Monthly',
        description: 'Test description',
        price: '\$9.99',
        priceAmountMicros: 9990000.0,
        priceCurrencyCode: 'USD',
        subscriptionPeriod: 'P1M',
      );
      
      expect(product.monthlyEquivalentPrice, closeTo(9.99, 0.01));
    });
    
    test('should calculate monthly equivalent price for yearly product', () {
      const product = ProProduct(
        id: 'test_yearly',
        title: 'Test Yearly',
        description: 'Test description',
        price: '\$95.99',
        priceAmountMicros: 95990000.0,
        priceCurrencyCode: 'USD',
        subscriptionPeriod: 'P1Y',
      );
      
      expect(product.monthlyEquivalentPrice, closeTo(7.99, 0.01)); // ~$95.99 / 12
    });
    
    test('should calculate savings percentage for yearly product', () {
      const product = ProProduct(
        id: 'test_yearly',
        title: 'Test Yearly',
        description: 'Test description',
        price: '\$95.99',
        priceAmountMicros: 95990000.0,
        priceCurrencyCode: 'USD',
        subscriptionPeriod: 'P1Y',
      );
      
      final savings = product.savingsPercent;
      expect(savings, greaterThan(0));
      expect(savings, closeTo(20.0, 1.0)); // Approximately 20% savings
    });
    
    test('should return zero savings for monthly product', () {
      const product = ProProduct(
        id: 'test_monthly',
        title: 'Test Monthly',
        description: 'Test description',
        price: '\$9.99',
        priceAmountMicros: 9990000.0,
        priceCurrencyCode: 'USD',
        subscriptionPeriod: 'P1M',
      );
      
      expect(product.savingsPercent, 0.0);
    });
    
    test('should serialize to JSON correctly', () {
      const product = ProProduct(
        id: 'test_product',
        title: 'Test Product',
        description: 'Test description',
        price: '\$9.99',
        priceAmountMicros: 9990000.0,
        priceCurrencyCode: 'USD',
        subscriptionPeriod: 'P1M',
        introductoryPrice: '\$4.99',
        introductoryPricePeriod: 'P1W',
      );
      
      final json = product.toJson();
      
      expect(json['productId'], 'test_product');
      expect(json['title'], 'Test Product');
      expect(json['description'], 'Test description');
      expect(json['price'], '\$9.99');
      expect(json['priceAmountMicros'], 9990000.0);
      expect(json['priceCurrencyCode'], 'USD');
      expect(json['subscriptionPeriod'], 'P1M');
      expect(json['introductoryPrice'], '\$4.99');
      expect(json['introductoryPricePeriod'], 'P1W');
    });
    
    test('should deserialize from JSON correctly', () {
      final json = {
        'productId': 'test_product',
        'title': 'Test Product',
        'description': 'Test description',
        'price': '\$9.99',
        'priceAmountMicros': 9990000.0,
        'priceCurrencyCode': 'USD',
        'subscriptionPeriod': 'P1M',
        'introductoryPrice': '\$4.99',
        'introductoryPricePeriod': 'P1W',
      };
      
      final product = ProProduct.fromJson(json);
      
      expect(product.id, 'test_product');
      expect(product.title, 'Test Product');
      expect(product.description, 'Test description');
      expect(product.price, '\$9.99');
      expect(product.priceAmountMicros, 9990000.0);
      expect(product.priceCurrencyCode, 'USD');
      expect(product.subscriptionPeriod, 'P1M');
      expect(product.introductoryPrice, '\$4.99');
      expect(product.introductoryPricePeriod, 'P1W');
    });
  });
  
  group('ProPurchase', () {
    test('should identify purchased state correctly', () {
      const purchase = ProPurchase(
        purchaseToken: 'token123',
        productId: 'product123',
        orderId: 'order123',
        purchaseTime: 1234567890,
        purchaseState: 0, // Purchased
        acknowledged: false,
        autoRenewing: true,
      );
      
      expect(purchase.isPurchased, true);
      expect(purchase.isPending, false);
    });
    
    test('should identify pending state correctly', () {
      const purchase = ProPurchase(
        purchaseToken: 'token123',
        productId: 'product123',
        orderId: 'order123',
        purchaseTime: 1234567890,
        purchaseState: 1, // Pending
        acknowledged: false,
        autoRenewing: true,
      );
      
      expect(purchase.isPurchased, false);
      expect(purchase.isPending, true);
    });
    
    test('should convert purchase time to DateTime', () {
      const purchaseTime = 1640995200000; // January 1, 2022 00:00:00 UTC
      const purchase = ProPurchase(
        purchaseToken: 'token123',
        productId: 'product123',
        orderId: 'order123',
        purchaseTime: purchaseTime,
        purchaseState: 0,
        acknowledged: false,
        autoRenewing: true,
      );
      
      final dateTime = purchase.purchaseDateTime;
      expect(dateTime.millisecondsSinceEpoch, purchaseTime);
    });
    
    test('should serialize to JSON correctly', () {
      const purchase = ProPurchase(
        purchaseToken: 'token123',
        productId: 'product123',
        orderId: 'order123',
        purchaseTime: 1234567890,
        purchaseState: 0,
        acknowledged: true,
        autoRenewing: true,
        obfuscatedAccountId: 'account123',
        developerPayload: 'payload123',
      );
      
      final json = purchase.toJson();
      
      expect(json['purchaseToken'], 'token123');
      expect(json['productId'], 'product123');
      expect(json['orderId'], 'order123');
      expect(json['purchaseTime'], 1234567890);
      expect(json['purchaseState'], 0);
      expect(json['acknowledged'], true);
      expect(json['autoRenewing'], true);
      expect(json['obfuscatedAccountId'], 'account123');
      expect(json['developerPayload'], 'payload123');
    });
    
    test('should deserialize from JSON correctly', () {
      final json = {
        'purchaseToken': 'token123',
        'productId': 'product123',
        'orderId': 'order123',
        'purchaseTime': 1234567890,
        'purchaseState': 0,
        'acknowledged': true,
        'autoRenewing': true,
        'obfuscatedAccountId': 'account123',
        'developerPayload': 'payload123',
      };
      
      final purchase = ProPurchase.fromJson(json);
      
      expect(purchase.purchaseToken, 'token123');
      expect(purchase.productId, 'product123');
      expect(purchase.orderId, 'order123');
      expect(purchase.purchaseTime, 1234567890);
      expect(purchase.purchaseState, 0);
      expect(purchase.acknowledged, true);
      expect(purchase.autoRenewing, true);
      expect(purchase.obfuscatedAccountId, 'account123');
      expect(purchase.developerPayload, 'payload123');
    });
  });
  
  group('ProCatalog', () {
    test('should have correct product IDs', () {
      expect(ProCatalog.monthlyProductId, 'mindtrainer_pro_monthly');
      expect(ProCatalog.yearlyProductId, 'mindtrainer_pro_yearly');
    });
    
    test('should have valid monthly product', () {
      final monthly = ProCatalog.monthly;
      
      expect(monthly.id, ProCatalog.monthlyProductId);
      expect(monthly.title, 'MindTrainer Pro Monthly');
      expect(monthly.price, '\$9.99');
      expect(monthly.priceAmountMicros, 9990000.0);
      expect(monthly.priceCurrencyCode, 'USD');
      expect(monthly.subscriptionPeriod, 'P1M');
      expect(monthly.isMonthly, true);
      expect(monthly.isYearly, false);
    });
    
    test('should have valid yearly product with savings', () {
      final yearly = ProCatalog.yearly;
      
      expect(yearly.id, ProCatalog.yearlyProductId);
      expect(yearly.title, 'MindTrainer Pro Yearly');
      expect(yearly.price, '\$95.99');
      expect(yearly.priceAmountMicros, 95990000.0);
      expect(yearly.priceCurrencyCode, 'USD');
      expect(yearly.subscriptionPeriod, 'P1Y');
      expect(yearly.isMonthly, false);
      expect(yearly.isYearly, true);
      expect(yearly.savingsPercent, greaterThan(0));
      expect(yearly.introductoryPrice, '\$47.99');
      expect(yearly.introductoryPricePeriod, 'P1M');
    });
    
    test('should return all products', () {
      final products = ProCatalog.allProducts;
      
      expect(products.length, 2);
      expect(products, contains(ProCatalog.monthly));
      expect(products, contains(ProCatalog.yearly));
    });
    
    test('should get product by ID', () {
      final monthly = ProCatalog.getProductById(ProCatalog.monthlyProductId);
      final yearly = ProCatalog.getProductById(ProCatalog.yearlyProductId);
      final invalid = ProCatalog.getProductById('invalid_id');
      
      expect(monthly, equals(ProCatalog.monthly));
      expect(yearly, equals(ProCatalog.yearly));
      expect(invalid, isNull);
    });
    
    test('should get monthly and yearly products directly', () {
      expect(ProCatalog.monthlyProduct, equals(ProCatalog.monthly));
      expect(ProCatalog.yearlyProduct, equals(ProCatalog.yearly));
    });
    
    test('should validate product IDs', () {
      expect(ProCatalog.isValidProductId(ProCatalog.monthlyProductId), true);
      expect(ProCatalog.isValidProductId(ProCatalog.yearlyProductId), true);
      expect(ProCatalog.isValidProductId('invalid_id'), false);
    });
    
    test('should get display names', () {
      expect(ProCatalog.getDisplayName(ProCatalog.monthlyProductId), 'Monthly');
      expect(ProCatalog.getDisplayName(ProCatalog.yearlyProductId), 'Yearly');
      expect(ProCatalog.getDisplayName('invalid_id'), 'Unknown');
    });
    
    test('should generate yearly savings message', () {
      final message = ProCatalog.yearlySavingsMessage;
      
      expect(message, contains('Save'));
      expect(message, contains('%'));
      expect(message, contains('yearly plan'));
    });
    
    test('should have comprehensive Pro features list', () {
      final features = ProCatalog.proFeatures;
      
      expect(features, isNotEmpty);
      expect(features, contains('Unlimited daily focus sessions'));
      expect(features, contains('Premium meditation environments'));
      expect(features, contains('Advanced progress tracking'));
      expect(features, contains('Detailed focus analytics'));
      expect(features, contains('Custom session lengths'));
      expect(features, contains('Offline mode access'));
      expect(features, contains('Priority customer support'));
      expect(features, contains('Early access to new features'));
    });
    
    test('should have feature benefits mapping', () {
      final benefits = ProCatalog.featureBenefits;
      
      expect(benefits, isNotEmpty);
      expect(benefits['Unlimited Sessions'], contains('No daily limits'));
      expect(benefits['Premium Environments'], contains('Exclusive soundscapes'));
      expect(benefits['Advanced Analytics'], contains('Deep insights'));
      expect(benefits['Custom Lengths'], contains('5 minutes to 2 hours'));
      expect(benefits['Offline Mode'], contains('without internet'));
      expect(benefits['Priority Support'], contains('Get help'));
    });
    
    test('should have realistic pricing with savings', () {
      final monthly = ProCatalog.monthly;
      final yearly = ProCatalog.yearly;
      
      // Monthly price should be reasonable
      expect(monthly.monthlyEquivalentPrice, closeTo(9.99, 0.01));
      
      // Yearly should offer significant savings
      final yearlyMonthlyEquivalent = yearly.monthlyEquivalentPrice;
      expect(yearlyMonthlyEquivalent, lessThan(monthly.monthlyEquivalentPrice));
      
      // Savings should be meaningful (at least 10%)
      expect(yearly.savingsPercent, greaterThanOrEqualTo(10.0));
      expect(yearly.savingsPercent, lessThanOrEqualTo(30.0)); // But not unrealistic
    });
    
    test('should have introductory pricing for yearly plan', () {
      final yearly = ProCatalog.yearly;
      
      expect(yearly.introductoryPrice, isNotNull);
      expect(yearly.introductoryPricePeriod, isNotNull);
      expect(yearly.introductoryPrice, contains('\$'));
      expect(yearly.introductoryPricePeriod, 'P1M'); // One month intro period
    });
  });
  
  group('Catalog Business Logic', () {
    test('should provide clear value proposition differentiation', () {
      final monthly = ProCatalog.monthly;
      final yearly = ProCatalog.yearly;
      
      // Descriptions should clearly communicate benefits
      expect(monthly.description, contains('Unlock'));
      expect(monthly.description, contains('unlimited'));
      expect(monthly.description, contains('premium'));
      expect(monthly.description, contains('analytics'));
      
      expect(yearly.description, contains('Unlock'));
      expect(yearly.description, contains('Save'));
      expect(yearly.description, contains('20%'));
    });
    
    test('should follow Google Play pricing guidelines', () {
      final monthly = ProCatalog.monthly;
      final yearly = ProCatalog.yearly;
      
      // Prices should be in standard increments
      expect(monthly.price, '\$9.99');
      expect(yearly.price, '\$95.99');
      
      // Micros should match displayed prices
      expect(monthly.priceAmountMicros, 9990000.0); // $9.99 * 1,000,000
      expect(yearly.priceAmountMicros, 95990000.0); // $95.99 * 1,000,000
    });
    
    test('should provide adequate feature justification for pricing', () {
      final features = ProCatalog.proFeatures;
      final benefits = ProCatalog.featureBenefits;
      
      // Should have enough features to justify monthly pricing
      expect(features.length, greaterThanOrEqualTo(8));
      
      // Benefits should be concrete and valuable
      expect(benefits.length, greaterThanOrEqualTo(6));
      
      // Each benefit should be specific and actionable
      benefits.values.forEach((benefit) {
        expect(benefit.length, greaterThan(20)); // Detailed descriptions
        expect(benefit, isNot(contains('TODO')));
        expect(benefit, isNot(contains('TBD')));
      });
    });
  });
}
/// Pro subscription catalog for MindTrainer
/// Contains monthly and yearly Pro subscription products with fake events for tests

/// Pro subscription plans available in MindTrainer
class ProProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final double priceAmountMicros;
  final String priceCurrencyCode;
  final String subscriptionPeriod; // P1M for monthly, P1Y for yearly
  final String? introductoryPrice;
  final String? introductoryPricePeriod;
  
  const ProProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
    required this.subscriptionPeriod,
    this.introductoryPrice,
    this.introductoryPricePeriod,
  });
  
  bool get isMonthly => subscriptionPeriod == 'P1M';
  bool get isYearly => subscriptionPeriod == 'P1Y';
  
  /// Monthly equivalent price for comparison
  double get monthlyEquivalentPrice {
    if (isMonthly) {
      return priceAmountMicros / 1000000;
    } else if (isYearly) {
      return (priceAmountMicros / 1000000) / 12;
    }
    return priceAmountMicros / 1000000;
  }
  
  /// Savings percentage compared to monthly (for yearly plans)
  double get savingsPercent {
    if (!isYearly) return 0.0;
    
    const monthlyPrice = 9.99; // Base monthly price
    final yearlyMonthlyEquivalent = monthlyEquivalentPrice;
    return ((monthlyPrice - yearlyMonthlyEquivalent) / monthlyPrice) * 100;
  }
  
  Map<String, dynamic> toJson() => {
    'productId': id,
    'title': title,
    'description': description,
    'price': price,
    'priceAmountMicros': priceAmountMicros,
    'priceCurrencyCode': priceCurrencyCode,
    'subscriptionPeriod': subscriptionPeriod,
    'introductoryPrice': introductoryPrice,
    'introductoryPricePeriod': introductoryPricePeriod,
  };
  
  factory ProProduct.fromJson(Map<String, dynamic> json) {
    return ProProduct(
      id: json['productId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      priceAmountMicros: json['priceAmountMicros'] as double,
      priceCurrencyCode: json['priceCurrencyCode'] as String,
      subscriptionPeriod: json['subscriptionPeriod'] as String,
      introductoryPrice: json['introductoryPrice'] as String?,
      introductoryPricePeriod: json['introductoryPricePeriod'] as String?,
    );
  }
}

/// Purchase information for a Pro subscription
class ProPurchase {
  final String purchaseToken;
  final String productId;
  final String orderId;
  final int purchaseTime;
  final int purchaseState; // 0: purchased, 1: pending, 2: unspecified
  final bool acknowledged;
  final bool autoRenewing;
  final String? obfuscatedAccountId;
  final String? developerPayload;
  
  const ProPurchase({
    required this.purchaseToken,
    required this.productId,
    required this.orderId,
    required this.purchaseTime,
    required this.purchaseState,
    required this.acknowledged,
    required this.autoRenewing,
    this.obfuscatedAccountId,
    this.developerPayload,
  });
  
  bool get isPurchased => purchaseState == 0;
  bool get isPending => purchaseState == 1;
  
  DateTime get purchaseDateTime => 
      DateTime.fromMillisecondsSinceEpoch(purchaseTime);
  
  Map<String, dynamic> toJson() => {
    'purchaseToken': purchaseToken,
    'productId': productId,
    'orderId': orderId,
    'purchaseTime': purchaseTime,
    'purchaseState': purchaseState,
    'acknowledged': acknowledged,
    'autoRenewing': autoRenewing,
    'obfuscatedAccountId': obfuscatedAccountId,
    'developerPayload': developerPayload,
  };
  
  factory ProPurchase.fromJson(Map<String, dynamic> json) {
    return ProPurchase(
      purchaseToken: json['purchaseToken'] as String,
      productId: json['productId'] as String,
      orderId: json['orderId'] as String,
      purchaseTime: json['purchaseTime'] as int,
      purchaseState: json['purchaseState'] as int,
      acknowledged: json['acknowledged'] as bool,
      autoRenewing: json['autoRenewing'] as bool,
      obfuscatedAccountId: json['obfuscatedAccountId'] as String?,
      developerPayload: json['developerPayload'] as String?,
    );
  }
}

/// MindTrainer Pro subscription catalog
class ProCatalog {
  // Product IDs that match Google Play Console SKUs
  static const String monthlyProductId = 'mindtrainer_pro_monthly';
  static const String yearlyProductId = 'mindtrainer_pro_yearly';
  
  /// Monthly Pro subscription
  static const ProProduct monthly = ProProduct(
    id: monthlyProductId,
    title: 'MindTrainer Pro Monthly',
    description: 'Unlock unlimited focus sessions, premium features, and advanced analytics',
    price: '\$9.99',
    priceAmountMicros: 9990000.0, // $9.99 in micros
    priceCurrencyCode: 'USD',
    subscriptionPeriod: 'P1M',
  );
  
  /// Yearly Pro subscription (with 20% savings)
  static const ProProduct yearly = ProProduct(
    id: yearlyProductId,
    title: 'MindTrainer Pro Yearly',
    description: 'Unlock unlimited focus sessions, premium features, and advanced analytics. Save 20%!',
    price: '\$95.99',
    priceAmountMicros: 95990000.0, // $95.99 in micros (20% savings)
    priceCurrencyCode: 'USD',
    subscriptionPeriod: 'P1Y',
    introductoryPrice: '\$47.99',
    introductoryPricePeriod: 'P1M',
  );
  
  /// All available Pro products
  static List<ProProduct> get allProducts => [monthly, yearly];
  
  /// Get product by ID
  static ProProduct? getProductById(String productId) {
    try {
      return allProducts.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }
  
  /// Get monthly product
  static ProProduct get monthlyProduct => monthly;
  
  /// Get yearly product  
  static ProProduct get yearlyProduct => yearly;
  
  /// Check if a product ID is valid
  static bool isValidProductId(String productId) {
    return allProducts.any((product) => product.id == productId);
  }
  
  /// Get product display name for UI
  static String getDisplayName(String productId) {
    switch (productId) {
      case monthlyProductId:
        return 'Monthly';
      case yearlyProductId:
        return 'Yearly';
      default:
        return 'Unknown';
    }
  }
  
  /// Get savings message for yearly plan
  static String get yearlySavingsMessage {
    final savings = yearly.savingsPercent;
    return 'Save ${savings.toStringAsFixed(0)}% with yearly plan';
  }
  
  /// Pro features included in subscription
  static const List<String> proFeatures = [
    'Unlimited daily focus sessions',
    'Premium meditation environments',
    'Advanced progress tracking',
    'Detailed focus analytics',
    'Custom session lengths',
    'Offline mode access',
    'Priority customer support',
    'Early access to new features',
  ];
  
  /// Get feature benefits for marketing copy
  static Map<String, String> get featureBenefits => {
    'Unlimited Sessions': 'No daily limits - focus as much as you want',
    'Premium Environments': 'Exclusive soundscapes and visual themes',
    'Advanced Analytics': 'Deep insights into your focus patterns',
    'Custom Lengths': 'Sessions from 5 minutes to 2 hours',
    'Offline Mode': 'Practice anywhere without internet',
    'Priority Support': 'Get help when you need it most',
  };
}
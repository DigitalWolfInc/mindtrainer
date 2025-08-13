/// Typed models for Play Billing platform channel communication
/// 
/// These classes match the payload structure from BillingHandler.kt
/// to ensure type safety and proper data handling.

import 'billing_constants.dart';

/// Result of a billing operation
class BillingResult {
  final int responseCode;
  final String? debugMessage;

  const BillingResult({
    required this.responseCode,
    this.debugMessage,
  });

  /// Standard response codes (matching Google Play Billing)
  static const int ok = BillingResponseCodes.ok;
  static const int userCanceled = BillingResponseCodes.userCanceled;
  static const int serviceUnavailable = BillingResponseCodes.serviceUnavailable;
  static const int billingUnavailable = BillingResponseCodes.billingUnavailable;
  static const int itemUnavailable = BillingResponseCodes.itemUnavailable;
  static const int developerError = BillingResponseCodes.developerError;
  static const int errorCode = BillingResponseCodes.error;

  bool get isSuccess => responseCode == ok;
  bool get isUserCanceled => responseCode == userCanceled;
  bool get isError => responseCode != ok;

  /// Create from platform channel Map
  factory BillingResult.fromMap(Map<String, Object?> map) {
    return BillingResult(
      responseCode: _asInt(map['responseCode']) ?? errorCode,
      debugMessage: map['debugMessage'] as String?,
    );
  }

  /// Convenience constructor for errors
  factory BillingResult.error(String code, String message) {
    return BillingResult(
      responseCode: errorCode,
      debugMessage: '$code: $message',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'responseCode': responseCode,
      'debugMessage': debugMessage,
    };
  }

  @override
  String toString() => 'BillingResult(code: $responseCode, message: $debugMessage)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingResult &&
          runtimeType == other.runtimeType &&
          responseCode == other.responseCode &&
          debugMessage == other.debugMessage;

  @override
  int get hashCode => responseCode.hashCode ^ debugMessage.hashCode;
}

/// Information about a product available for purchase
class ProductInfo {
  final String productId;
  final String? title;
  final String? description;
  final String? price;
  final int? priceAmountMicros;
  final String? priceCurrencyCode;
  final String? subscriptionPeriod;
  final String? introductoryPrice;
  final String? introductoryPricePeriod;

  const ProductInfo({
    required this.productId,
    this.title,
    this.description,
    this.price,
    this.priceAmountMicros,
    this.priceCurrencyCode,
    this.subscriptionPeriod,
    this.introductoryPrice,
    this.introductoryPricePeriod,
  });

  /// Create from platform channel Map
  factory ProductInfo.fromMap(Map<String, Object?> map) {
    return ProductInfo(
      productId: map['productId'] as String? ?? '',
      title: map['title'] as String?,
      description: map['description'] as String?,
      price: map['price'] as String?,
      priceAmountMicros: _asInt(map['priceAmountMicros']),
      priceCurrencyCode: map['priceCurrencyCode'] as String?,
      subscriptionPeriod: map['subscriptionPeriod'] as String?,
      introductoryPrice: map['introductoryPrice'] as String?,
      introductoryPricePeriod: map['introductoryPricePeriod'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'productId': productId,
      'title': title,
      'description': description,
      'price': price,
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
      'subscriptionPeriod': subscriptionPeriod,
      'introductoryPrice': introductoryPrice,
      'introductoryPricePeriod': introductoryPricePeriod,
    };
  }

  bool get isSubscription => subscriptionPeriod != null;
  bool get hasIntroductoryOffer => introductoryPrice != null;

  @override
  String toString() => 'ProductInfo(id: $productId, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductInfo &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          title == other.title &&
          price == other.price;

  @override
  int get hashCode => productId.hashCode ^ title.hashCode ^ price.hashCode;
}

/// Information about a completed purchase
class PurchaseInfo {
  final String? productId;
  final String? purchaseToken;
  final bool acknowledged;
  final bool autoRenewing;
  final int? priceMicros;
  final String? price;
  final String? originalJson;
  final String? orderId;
  final int? purchaseTime;
  final int? purchaseState;
  final String? obfuscatedAccountId;
  final String? developerPayload;
  final String? origin;

  const PurchaseInfo({
    this.productId,
    this.purchaseToken,
    this.acknowledged = false,
    this.autoRenewing = false,
    this.priceMicros,
    this.price,
    this.originalJson,
    this.orderId,
    this.purchaseTime,
    this.purchaseState,
    this.obfuscatedAccountId,
    this.developerPayload,
    this.origin,
  });

  /// Create from platform channel Map
  factory PurchaseInfo.fromMap(Map<String, Object?> map) {
    return PurchaseInfo(
      productId: map['productId'] as String?,
      purchaseToken: map['purchaseToken'] as String?,
      acknowledged: map['acknowledged'] as bool? ?? false,
      autoRenewing: map['autoRenewing'] as bool? ?? false,
      priceMicros: _asInt(map['priceMicros']),
      price: map['price'] as String?,
      originalJson: map['originalJson'] as String?,
      orderId: map['orderId'] as String?,
      purchaseTime: _asInt(map['purchaseTime']),
      purchaseState: _asInt(map['purchaseState']),
      obfuscatedAccountId: map['obfuscatedAccountId'] as String?,
      developerPayload: map['developerPayload'] as String?,
      origin: map['origin'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'productId': productId,
      'purchaseToken': purchaseToken,
      'acknowledged': acknowledged,
      'autoRenewing': autoRenewing,
      'priceMicros': priceMicros,
      'price': price,
      'originalJson': originalJson,
      'orderId': orderId,
      'purchaseTime': purchaseTime,
      'purchaseState': purchaseState,
      'obfuscatedAccountId': obfuscatedAccountId,
      'developerPayload': developerPayload,
      'origin': origin,
    };
  }

  /// Purchase states (matching Google Play Billing)
  static const int statePending = PurchaseStates.pending;
  static const int statePurchased = PurchaseStates.purchased;
  static const int stateCanceled = PurchaseStates.canceled;

  bool get isPending => purchaseState == statePending;
  bool get isPurchased => purchaseState == statePurchased;
  bool get isCanceled => purchaseState == stateCanceled;
  bool get isValid => isPurchased && purchaseToken != null;
  
  /// Check if this purchase came from a restore operation
  bool get isFromRestore => origin == 'restore';
  
  /// Check if this purchase came from a new purchase
  bool get isFromPurchase => origin == 'purchase';
  
  /// Get a human-readable purchase state string
  String get purchaseStateString {
    switch (purchaseState) {
      case statePending:
        return 'PENDING';
      case statePurchased:
        return 'PURCHASED';
      case stateCanceled:
        return 'CANCELED';
      default:
        return 'UNSPECIFIED';
    }
  }

  DateTime? get purchaseDateTime => 
      purchaseTime != null ? DateTime.fromMillisecondsSinceEpoch(purchaseTime!) : null;

  @override
  String toString() => 
      'PurchaseInfo(productId: $productId, token: ${purchaseToken?.substring(0, 8)}...)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseInfo &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          purchaseToken == other.purchaseToken &&
          orderId == other.orderId;

  @override
  int get hashCode => 
      productId.hashCode ^ purchaseToken.hashCode ^ orderId.hashCode;
}

/// Billing configuration and product constants
/// 
/// @deprecated Use ProductIds from billing_constants.dart instead
class BillingProducts {
  // Product IDs (must match Google Play Console and Android configuration)
  static const String proMonthly = ProductIds.proMonthly;
  static const String proYearly = ProductIds.proYearly;
  
  /// All subscription product IDs
  static const List<String> allSubscriptions = ProductIds.allSubscriptions;
  
  /// Check if a product ID represents a Pro subscription
  static bool isProProduct(String? productId) {
    return ProductIds.isProProduct(productId ?? '');
  }
  
  /// Get display name for product ID
  static String getProductDisplayName(String productId) {
    return SubscriptionDisplayNames.forProductId(productId);
  }
}

/// Helper function to safely convert platform values to integers
/// Handles both int and long values from Kotlin
int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
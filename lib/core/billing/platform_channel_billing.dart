import 'dart:async';
import 'package:flutter/services.dart';
import 'billing_adapter.dart';
import 'pro_catalog.dart';

/// Platform channel implementation for Google Play Billing
/// Communicates with native Android code for real billing operations
class PlatformChannelBilling {
  static const MethodChannel _channel = MethodChannel('mindtrainer/billing');
  
  final StreamController<List<ProPurchase>> _purchaseController = StreamController.broadcast();
  bool _isInitialized = false;
  
  /// Stream of purchase updates from platform
  Stream<List<ProPurchase>> get purchaseUpdates => _purchaseController.stream;
  
  /// Initialize the platform channel
  Future<BillingResult> initialize() async {
    if (_isInitialized) {
      return const BillingResult(responseCode: BillingResultCode.ok);
    }
    
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
      final result = await _channel.invokeMethod<Map>('initialize');
      
      if (result != null && result['responseCode'] == 0) {
        _isInitialized = true;
        return const BillingResult(responseCode: BillingResultCode.ok);
      } else {
        return BillingResult(
          responseCode: _mapResponseCode(result?['responseCode'] ?? 8),
          debugMessage: result?['debugMessage'] ?? 'Initialization failed',
        );
      }
    } catch (e) {
      return BillingResult(
        responseCode: BillingResultCode.error,
        debugMessage: 'Platform channel error: ${e.toString()}',
      );
    }
  }
  
  /// Connect to billing service
  Future<BillingResult> startConnection() async {
    if (!_isInitialized) {
      final initResult = await initialize();
      if (initResult.isError) return initResult;
    }
    
    try {
      final result = await _channel.invokeMethod<Map>('startConnection', {
        'sandboxMode': true, // Use sandbox mode for development
      });
      return BillingResult(
        responseCode: _mapResponseCode(result?['responseCode'] ?? 8),
        debugMessage: result?['debugMessage'],
      );
    } catch (e) {
      return BillingResult(
        responseCode: BillingResultCode.error,
        debugMessage: 'Connection failed: ${e.toString()}',
      );
    }
  }
  
  /// End connection to billing service
  Future<void> endConnection() async {
    try {
      await _channel.invokeMethod('endConnection');
    } catch (e) {
      // Silent fail on disconnect
    }
  }
  
  /// Query product details
  Future<BillingResult> queryProductDetails(List<String> productIds) async {
    try {
      final result = await _channel.invokeMethod<List>('queryProducts', {
        'productIds': productIds,
        'productType': 'subs', // Subscriptions
      });
      
      // The existing handler returns the products directly, not a result map
      if (result != null) {
        return const BillingResult(responseCode: BillingResultCode.ok);
      } else {
        return const BillingResult(
          responseCode: BillingResultCode.error,
          debugMessage: 'Failed to query products',
        );
      }
    } catch (e) {
      return BillingResult(
        responseCode: BillingResultCode.error,
        debugMessage: 'Query failed: ${e.toString()}',
      );
    }
  }
  
  /// Get queried product details
  Future<List<ProProduct>> getAvailableProducts() async {
    try {
      final result = await _channel.invokeMethod<List>('queryProducts', {
        'productIds': ['mindtrainer_pro_monthly', 'mindtrainer_pro_yearly'],
        'productType': 'subs',
      });
      if (result == null) return [];
      
      return result.map((productData) {
        final data = Map<String, dynamic>.from(productData);
        return ProProduct(
          id: data['productId'] as String,
          title: data['title'] as String,
          description: data['description'] as String,
          price: data['price'] as String,
          priceAmountMicros: (data['priceAmountMicros'] as num).toDouble(),
          priceCurrencyCode: data['priceCurrencyCode'] as String,
          subscriptionPeriod: _inferSubscriptionPeriod(data['productId'] as String),
          introductoryPrice: null, // Will be populated from actual Play Store data
          introductoryPricePeriod: null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Infer subscription period from product ID
  String _inferSubscriptionPeriod(String productId) {
    if (productId.contains('monthly')) return 'P1M';
    if (productId.contains('yearly')) return 'P1Y';
    return 'P1M'; // Default to monthly
  }
  
  /// Launch billing flow
  Future<BillingResult> launchBillingFlow(String productId) async {
    try {
      final result = await _channel.invokeMethod<Map>('launchPurchaseFlow', {
        'productId': productId,
        'productType': 'subs',
      });
      
      return BillingResult(
        responseCode: _mapResponseCode(result?['responseCode'] ?? 8),
        debugMessage: result?['debugMessage'],
      );
    } catch (e) {
      return BillingResult(
        responseCode: BillingResultCode.error,
        debugMessage: 'Purchase failed: ${e.toString()}',
      );
    }
  }
  
  /// Query existing purchases
  Future<BillingResult> queryPurchases() async {
    try {
      final result = await _channel.invokeMethod<List>('queryPurchases', {
        'productType': 'subs',
      });
      
      if (result != null) {
        return const BillingResult(responseCode: BillingResultCode.ok);
      } else {
        return const BillingResult(
          responseCode: BillingResultCode.error,
          debugMessage: 'Failed to query purchases',
        );
      }
    } catch (e) {
      return BillingResult(
        responseCode: BillingResultCode.error,
        debugMessage: 'Query purchases failed: ${e.toString()}',
      );
    }
  }
  
  /// Get current purchases
  Future<List<ProPurchase>> getCurrentPurchases() async {
    try {
      final result = await _channel.invokeMethod<List>('queryPurchases', {
        'productType': 'subs',
      });
      if (result == null) return [];
      
      return result.map((purchaseData) {
        final data = Map<String, dynamic>.from(purchaseData);
        return ProPurchase(
          purchaseToken: data['purchaseToken'] as String,
          productId: data['productId'] as String,
          orderId: data['orderId'] as String? ?? 'unknown_order',
          purchaseTime: data['purchaseTime'] as int,
          purchaseState: data['state'] as int? ?? 0, // Use 'state' from existing handler
          acknowledged: data['acknowledged'] as bool,
          autoRenewing: data['autoRenewing'] as bool? ?? false,
          obfuscatedAccountId: null, // Not provided by existing handler
          developerPayload: null, // Not provided by existing handler
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Acknowledge a purchase
  Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    try {
      final result = await _channel.invokeMethod<Map>('acknowledgePurchase', {
        'purchaseToken': purchaseToken,
      });
      
      return BillingResult(
        responseCode: _mapResponseCode(result?['responseCode'] ?? 8),
        debugMessage: result?['debugMessage'],
      );
    } catch (e) {
      return BillingResult(
        responseCode: BillingResultCode.error,
        debugMessage: 'Acknowledge failed: ${e.toString()}',
      );
    }
  }
  
  /// Handle method calls from platform
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPurchasesUpdated':
        final purchases = await _parsePurchasesFromCall(call.arguments);
        _purchaseController.add(purchases);
        break;
      case 'onConnectionStateChanged':
        // Handle connection state changes
        break;
      default:
        // Unknown method call
        break;
    }
  }
  
  /// Parse purchases from method call
  Future<List<ProPurchase>> _parsePurchasesFromCall(dynamic arguments) async {
    try {
      if (arguments is! Map) return [];
      
      final purchases = arguments['purchases'] as List?;
      if (purchases == null) return [];
      
      return purchases.map((purchaseData) {
        final data = Map<String, dynamic>.from(purchaseData);
        return ProPurchase(
          purchaseToken: data['purchaseToken'] as String,
          productId: data['productId'] as String,
          orderId: data['orderId'] as String? ?? 'unknown_order',
          purchaseTime: data['purchaseTime'] as int,
          purchaseState: data['state'] as int? ?? 0,
          acknowledged: data['acknowledged'] as bool,
          autoRenewing: data['autoRenewing'] as bool? ?? false,
          obfuscatedAccountId: null,
          developerPayload: null,
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Map platform response codes to our enum
  BillingResultCode _mapResponseCode(int? code) {
    switch (code) {
      case 0:
        return BillingResultCode.ok;
      case 1:
        return BillingResultCode.userCanceled;
      case 2:
        return BillingResultCode.serviceUnavailable;
      case 3:
        return BillingResultCode.billingUnavailable;
      case 4:
        return BillingResultCode.itemNotOwned;
      case 5:
        return BillingResultCode.itemAlreadyOwned;
      case 6:
        return BillingResultCode.itemUnavailable;
      case 7:
        return BillingResultCode.developerError;
      case 9:
        return BillingResultCode.featureNotSupported;
      case 10:
        return BillingResultCode.serviceDisconnected;
      case 11:
        return BillingResultCode.networkError;
      default:
        return BillingResultCode.error;
    }
  }
  
  /// Dispose resources
  void dispose() {
    _purchaseController.close();
    _isInitialized = false;
  }
}
import 'dart:async';
import 'package:flutter/services.dart';

import 'models.dart';
import 'billing_constants.dart';

/// Platform channel interface for Google Play Billing integration
/// 
/// Communicates with the native Android BillingHandler.kt implementation
/// Channel name must match: "mindtrainer/billing"
class BillingChannel {
  static const MethodChannel _channel = MethodChannel(BillingChannels.main);
  static const String _channelName = BillingChannels.main;
  
  // Stream controllers for billing events
  static final StreamController<List<PurchaseInfo>> _purchaseUpdatesController = 
      StreamController<List<PurchaseInfo>>.broadcast();
  
  static final StreamController<BillingResult> _connectionController = 
      StreamController<BillingResult>.broadcast();

  /// Stream of purchase updates from the platform
  static Stream<List<PurchaseInfo>> get purchaseUpdates => 
      _purchaseUpdatesController.stream;

  /// Stream of connection state changes
  static Stream<BillingResult> get connectionUpdates => 
      _connectionController.stream;

  /// Initialize the billing channel and set up method call handling
  static Future<void> initialize() async {
    _channel.setMethodCallHandler(_handleMethodCall);
    
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('initialize');
      final billingResult = BillingResult.fromMap(castToStringMap(result ?? {}));
      _connectionController.add(billingResult);
    } catch (e) {
      _connectionController.add(BillingResult.error('INITIALIZE_FAILED', e.toString()));
    }
  }

  /// Start connection to billing service
  static Future<BillingResult> startConnection() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('startConnection');
      return BillingResult.fromMap(castToStringMap(result ?? {}));
    } catch (e) {
      return BillingResult.error(BillingErrorCodes.connectionFailed, e.toString());
    }
  }

  /// End connection to billing service
  static Future<void> endConnection() async {
    try {
      await _channel.invokeMethod('endConnection');
    } catch (e) {
      // Log error but don't throw - connection cleanup should be silent
    }
  }

  /// Query available product details
  static Future<BillingResult> queryProductDetails(List<String> productIds) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'queryProductDetails',
        {'productIds': productIds},
      );
      return BillingResult.fromMap(castToStringMap(result ?? {}));
    } catch (e) {
      return BillingResult.error('QUERY_FAILED', e.toString());
    }
  }

  /// Get available products (after querying)
  static Future<List<ProductInfo>> getAvailableProducts() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('getAvailableProducts');
      if (result == null) return [];
      
      return result
          .where((item) => item is Map)
          .map((item) => ProductInfo.fromMap(Map<String, Object?>.from(item as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Launch billing flow for a specific product
  static Future<BillingResult> launchBillingFlow(String productId) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'launchBillingFlow',
        {'productId': productId},
      );
      return BillingResult.fromMap(castToStringMap(result ?? {}));
    } catch (e) {
      return BillingResult.error('PURCHASE_FAILED', e.toString());
    }
  }

  /// Query existing purchases
  static Future<BillingResult> queryPurchases() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>('queryPurchases');
      return BillingResult.fromMap(castToStringMap(result ?? {}));
    } catch (e) {
      return BillingResult.error('QUERY_PURCHASES_FAILED', e.toString());
    }
  }

  /// Get current purchases (after querying)
  static Future<List<PurchaseInfo>> getCurrentPurchases() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('getCurrentPurchases');
      if (result == null) return [];
      
      return result
          .where((item) => item is Map)
          .map((item) => PurchaseInfo.fromMap(Map<String, Object?>.from(item as Map)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Acknowledge a purchase
  static Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'acknowledgePurchase',
        {'purchaseToken': purchaseToken},
      );
      return BillingResult.fromMap(castToStringMap(result ?? {}));
    } catch (e) {
      return BillingResult.error('ACKNOWLEDGE_FAILED', e.toString());
    }
  }

  /// Handle incoming method calls from the platform
  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPurchasesUpdated':
        final purchasesList = call.arguments as List<Object?>?;
        if (purchasesList != null) {
          final purchases = purchasesList
              .where((item) => item is Map)
              .map((item) => PurchaseInfo.fromMap(Map<String, Object?>.from(item as Map)))
              .toList();
          _purchaseUpdatesController.add(purchases);
        }
        break;
      
      case 'onBillingServiceDisconnected':
        _connectionController.add(
          BillingResult.error('SERVICE_DISCONNECTED', 'Billing service disconnected')
        );
        break;
        
      default:
        // Unknown method call - ignore
        break;
    }
  }

  /// Dispose of resources
  static void dispose() {
    _purchaseUpdatesController.close();
    _connectionController.close();
  }

  /// Helper to safely cast platform channel results to Map<String, Object?>
  static Map<String, Object?> castToStringMap(Map<Object?, Object?> source) {
    return Map<String, Object?>.from(source);
  }
}
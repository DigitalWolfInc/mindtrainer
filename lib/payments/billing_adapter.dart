import 'dart:async';
import '../core/payments/play_billing_adapter.dart';
import '../core/payments/real_play_billing_adapter.dart';
import '../settings/diagnostics.dart';

/// Simplified billing adapter interface for paywall integration
/// Wraps the existing PlayBillingAdapter infrastructure
class BillingAdapter {
  static const bool _diagEnabled = true;
  final PlayBillingAdapter _adapter;
  Function(List<BillingProduct>)? _onProductDetails;
  
  BillingAdapter._(this._adapter);
  
  static BillingAdapter? _instance;
  
  static BillingAdapter get instance {
    _instance ??= BillingAdapter._(PlayBillingAdapterFactory.create());
    return _instance!;
  }
  
  /// Initialize the billing adapter
  Future<void> initialize() async {
    await _adapter.startConnection();
  }
  
  /// Purchase a subscription product
  Future<void> purchase(String productId) async {
    if (_diagEnabled) {
      Diag.d('Billing', 'Purchase attempt: $productId');
    }
    
    try {
      final result = await _adapter.launchSubscriptionPurchaseFlow(productId);
      if (!result.success) {
        if (_diagEnabled) {
          Diag.d('Billing', 'Purchase failed: $productId (${result.responseCode})');
        }
        throw BillingException._fromResult(result);
      }
      
      if (_diagEnabled) {
        Diag.d('Billing', 'Purchase complete: $productId');
      }
    } catch (e) {
      if (_diagEnabled) {
        Diag.d('Billing', 'Purchase error: $productId ($e)');
      }
      rethrow;
    }
  }
  
  /// Query and restore existing purchases
  Future<void> queryPurchases() async {
    if (_diagEnabled) {
      Diag.d('Billing', 'Restore begin');
    }
    
    try {
      await _adapter.queryPurchases();
      if (_diagEnabled) {
        Diag.d('Billing', 'Restore end');
      }
    } catch (e) {
      if (_diagEnabled) {
        Diag.d('Billing', 'Restore error: $e');
      }
      rethrow;
    }
    // The purchases are handled through the existing EntitlementResolver integration
  }
  
  /// Open subscription management (placeholder)
  Future<void> manageSubscriptions() async {
    // This would typically open the Play Store subscription management
    // For now, it's a stub that indicates the functionality is not available
    throw const BillingException._(
      code: 'manage_subscriptions_not_available',
      message: 'Subscription management not implemented',
    );
  }
  
  /// Query product details and notify listeners
  Future<void> queryProductDetails(List<String> productIds) async {
    if (_diagEnabled) {
      Diag.d('Billing', 'Product details query: ${productIds.join(', ')}');
    }
    
    try {
      final products = await _adapter.querySubscriptionProducts(productIds);
      if (_diagEnabled) {
        Diag.d('Billing', 'Product details arrival: ${products.length} products');
      }
      _onProductDetails?.call(products);
    } catch (e) {
      if (_diagEnabled) {
        Diag.d('Billing', 'Product details error: $e');
      }
      // Ignore errors in product details query - prices will remain stale/missing
    }
  }
  
  /// Set callback for product details updates (private API for PaywallVM)
  void _setOnProductDetailsCallback(Function(List<BillingProduct>) callback) {
    _onProductDetails = callback;
  }
  
  /// Check if billing is available
  Future<bool> isBillingAvailable() async {
    return await _adapter.isSubscriptionSupported();
  }
  
  /// Get connection state
  BillingConnectionState get connectionState => _adapter.connectionState;
  
  /// Listen to connection state changes
  Stream<BillingConnectionState> get connectionStateStream => 
      _adapter.connectionStateStream;
  
  /// Listen to purchase updates
  Stream<List<BillingPurchase>> get purchaseUpdateStream => 
      _adapter.purchaseUpdateStream;
  
  /// Clean up resources
  Future<void> dispose() async {
    await _adapter.endConnection();
    _onProductDetails = null;
  }
  
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}

/// Exception thrown by billing operations
class BillingException implements Exception {
  final String code;
  final String message;
  
  const BillingException._({
    required this.code,
    required this.message,
  });
  
  factory BillingException._fromResult(BillingResult result) {
    String code;
    String message = result.debugMessage ?? 'Unknown error';
    
    switch (result.responseCode) {
      case 1:
        code = 'purchase_canceled';
        break;
      case 6:
        code = 'offline';
        break;
      case 7:
        code = 'already_owned';
        break;
      default:
        code = 'unknown';
        break;
    }
    
    return BillingException._(code: code, message: message);
  }
  
  @override
  String toString() => 'BillingException($code: $message)';
}
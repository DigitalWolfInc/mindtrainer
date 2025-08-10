/// Play Billing Adapter Skeleton for MindTrainer
/// 
/// Provides the adapter interface for Google Play Billing integration.
/// Currently contains skeleton implementation - actual SDK calls will be added later.
/// Designed to be Google Play policy compliant with no charity-based perks.

import 'dart:async';
import 'pro_status.dart';
import 'subscription_gateway.dart';

/// Play Billing connection state
enum BillingConnectionState {
  /// Not connected to Play Billing service
  disconnected,
  /// Connecting to Play Billing service
  connecting,
  /// Connected and ready for billing operations
  connected,
  /// Connection failed
  error,
}

/// Play Billing purchase state
enum PurchaseState {
  /// Purchase is pending user action
  pending,
  /// Purchase completed successfully
  purchased,
  /// User cancelled the purchase
  cancelled,
  /// Purchase failed due to error
  failed,
}

/// Play Billing product details from Google Play
class BillingProduct {
  /// Product ID (e.g., 'pro_monthly', 'pro_yearly')
  final String productId;
  
  /// Product type (subscription)
  final String type;
  
  /// Display title from Google Play Console
  final String title;
  
  /// Description from Google Play Console
  final String description;
  
  /// Formatted price string (e.g., '$9.99')
  final String price;
  
  /// Price in micros (price * 1,000,000)
  final int priceAmountMicros;
  
  /// Currency code (e.g., 'USD')
  final String priceCurrencyCode;
  
  const BillingProduct({
    required this.productId,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BillingProduct &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          type == other.type &&
          price == other.price;
  
  @override
  int get hashCode => productId.hashCode ^ type.hashCode ^ price.hashCode;
  
  @override
  String toString() => 'BillingProduct(id: $productId, price: $price)';
}

/// Play Billing purchase record
class BillingPurchase {
  /// Purchase token from Google Play
  final String purchaseToken;
  
  /// Product ID that was purchased
  final String productId;
  
  /// Current purchase state
  final PurchaseState state;
  
  /// Purchase timestamp in milliseconds
  final int purchaseTime;
  
  /// Whether purchase is acknowledged
  final bool acknowledged;
  
  /// Auto-renewing subscription flag
  final bool autoRenewing;
  
  const BillingPurchase({
    required this.purchaseToken,
    required this.productId,
    required this.state,
    required this.purchaseTime,
    this.acknowledged = false,
    this.autoRenewing = false,
  });
  
  @override
  String toString() => 'BillingPurchase(product: $productId, state: $state)';
}

/// Result of billing operation
class BillingResult {
  /// Whether the operation was successful
  final bool success;
  
  /// Response code from Play Billing
  final int responseCode;
  
  /// Debug message for failures
  final String? debugMessage;
  
  const BillingResult({
    required this.success,
    required this.responseCode,
    this.debugMessage,
  });
  
  /// Create successful result
  const BillingResult.ok() : this(success: true, responseCode: 0);
  
  /// Create user cancelled result
  const BillingResult.cancelled() : this(success: false, responseCode: 1);
  
  /// Create error result
  const BillingResult.error(String message, int code) 
      : this(success: false, responseCode: code, debugMessage: message);
  
  @override
  String toString() => success 
      ? 'BillingResult.success'
      : 'BillingResult.error($responseCode: $debugMessage)';
}

/// Abstract adapter for Google Play Billing
/// 
/// This will be implemented with actual Google Play Billing SDK calls.
/// Current skeleton allows for testing and development without SDK dependency.
abstract class PlayBillingAdapter {
  /// Current connection state
  BillingConnectionState get connectionState;
  
  /// Stream of connection state changes
  Stream<BillingConnectionState> get connectionStateStream;
  
  /// Stream of purchase updates
  Stream<List<BillingPurchase>> get purchaseUpdateStream;
  
  /// Initialize and connect to Play Billing service
  Future<BillingResult> startConnection();
  
  /// Disconnect from Play Billing service
  Future<void> endConnection();
  
  /// Query available subscription products
  Future<List<BillingProduct>> querySubscriptionProducts(List<String> productIds);
  
  /// Launch subscription purchase flow
  Future<BillingResult> launchSubscriptionPurchaseFlow(String productId);
  
  /// Query existing purchases
  Future<List<BillingPurchase>> queryPurchases();
  
  /// Acknowledge a purchase (required for subscriptions)
  Future<BillingResult> acknowledgePurchase(String purchaseToken);
  
  /// Check if subscription features are supported
  Future<bool> isSubscriptionSupported();
}

/// Fake Play Billing adapter for testing and development
/// 
/// Simulates Google Play Billing behavior without actual SDK integration.
/// Emits realistic events and state transitions for automated testing.
class FakePlayBillingAdapter implements PlayBillingAdapter {
  final StreamController<BillingConnectionState> _connectionController = 
      StreamController<BillingConnectionState>.broadcast();
  final StreamController<List<BillingPurchase>> _purchaseController = 
      StreamController<List<BillingPurchase>>.broadcast();
  
  BillingConnectionState _connectionState = BillingConnectionState.disconnected;
  final List<BillingPurchase> _activePurchases = [];
  final List<BillingProduct> _availableProducts = [];
  
  /// Test configuration
  final bool _simulateConnectionFailure;
  final bool _simulatePurchaseFailure;
  final bool _simulateUserCancel;
  
  FakePlayBillingAdapter({
    bool simulateConnectionFailure = false,
    bool simulatePurchaseFailure = false,
    bool simulateUserCancel = false,
  }) : _simulateConnectionFailure = simulateConnectionFailure,
       _simulatePurchaseFailure = simulatePurchaseFailure,
       _simulateUserCancel = simulateUserCancel {
    _initializeFakeProducts();
  }
  
  @override
  BillingConnectionState get connectionState => _connectionState;
  
  @override
  Stream<BillingConnectionState> get connectionStateStream => 
      _connectionController.stream;
  
  @override
  Stream<List<BillingPurchase>> get purchaseUpdateStream => 
      _purchaseController.stream;
  
  @override
  Future<BillingResult> startConnection() async {
    _setConnectionState(BillingConnectionState.connecting);
    
    // Simulate connection delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_simulateConnectionFailure) {
      _setConnectionState(BillingConnectionState.error);
      return const BillingResult.error('Connection failed', 6); // SERVICE_UNAVAILABLE
    }
    
    _setConnectionState(BillingConnectionState.connected);
    return const BillingResult.ok();
  }
  
  @override
  Future<void> endConnection() async {
    _setConnectionState(BillingConnectionState.disconnected);
    await _connectionController.close();
    await _purchaseController.close();
  }
  
  @override
  Future<List<BillingProduct>> querySubscriptionProducts(List<String> productIds) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (_connectionState != BillingConnectionState.connected) {
      return [];
    }
    
    return _availableProducts.where((p) => productIds.contains(p.productId)).toList();
  }
  
  @override
  Future<BillingResult> launchSubscriptionPurchaseFlow(String productId) async {
    if (_connectionState != BillingConnectionState.connected) {
      return const BillingResult.error('Not connected', 6);
    }
    
    if (!_availableProducts.any((p) => p.productId == productId)) {
      return const BillingResult.error('Product not found', 4);
    }
    
    // Simulate purchase flow delay
    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (_simulateUserCancel) {
      return const BillingResult.cancelled();
    }
    
    if (_simulatePurchaseFailure) {
      return const BillingResult.error('Purchase failed', 7);
    }
    
    // Simulate successful purchase
    final purchase = BillingPurchase(
      purchaseToken: 'fake_token_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      state: PurchaseState.purchased,
      purchaseTime: DateTime.now().millisecondsSinceEpoch,
      acknowledged: false,
      autoRenewing: true,
    );
    
    _activePurchases.add(purchase);
    _purchaseController.add(List.unmodifiable(_activePurchases));
    
    return const BillingResult.ok();
  }
  
  @override
  Future<List<BillingPurchase>> queryPurchases() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.unmodifiable(_activePurchases);
  }
  
  @override
  Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    await Future.delayed(const Duration(milliseconds: 100));
    
    final purchaseIndex = _activePurchases.indexWhere((p) => p.purchaseToken == purchaseToken);
    if (purchaseIndex == -1) {
      return const BillingResult.error('Purchase not found', 8);
    }
    
    // Update purchase to acknowledged
    final purchase = _activePurchases[purchaseIndex];
    _activePurchases[purchaseIndex] = BillingPurchase(
      purchaseToken: purchase.purchaseToken,
      productId: purchase.productId,
      state: purchase.state,
      purchaseTime: purchase.purchaseTime,
      acknowledged: true,
      autoRenewing: purchase.autoRenewing,
    );
    
    return const BillingResult.ok();
  }
  
  @override
  Future<bool> isSubscriptionSupported() async {
    return true; // Fake adapter always supports subscriptions
  }
  
  void _setConnectionState(BillingConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }
  
  void _initializeFakeProducts() {
    _availableProducts.addAll([
      const BillingProduct(
        productId: 'pro_monthly',
        type: 'subs',
        title: 'MindTrainer Pro Monthly',
        description: 'Monthly Pro subscription with all premium features',
        price: '\$9.99',
        priceAmountMicros: 9990000,
        priceCurrencyCode: 'USD',
      ),
      const BillingProduct(
        productId: 'pro_yearly',
        type: 'subs',
        title: 'MindTrainer Pro Yearly',
        description: 'Yearly Pro subscription with all premium features',
        price: '\$99.99',
        priceAmountMicros: 99990000,
        priceCurrencyCode: 'USD',
      ),
    ]);
  }
  
  /// Test helper: Simulate a purchase cancellation
  void simulateCancel() {
    _purchaseController.add(List.unmodifiable(_activePurchases));
  }
  
  /// Test helper: Clear all purchases
  void clearPurchases() {
    _activePurchases.clear();
    _purchaseController.add(List.unmodifiable(_activePurchases));
  }
  
  /// Test helper: Add a fake purchase
  void addFakePurchase(String productId) {
    final purchase = BillingPurchase(
      purchaseToken: 'fake_token_${DateTime.now().millisecondsSinceEpoch}',
      productId: productId,
      state: PurchaseState.purchased,
      purchaseTime: DateTime.now().millisecondsSinceEpoch,
      acknowledged: true,
      autoRenewing: true,
    );
    
    _activePurchases.add(purchase);
    _purchaseController.add(List.unmodifiable(_activePurchases));
  }
}
import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';

import 'models.dart';
import 'billing_constants.dart';

/// Fake billing adapter for testing and development
/// 
/// Provides a complete mock implementation of the Google Play Billing API
/// that can be used for testing without requiring Google Play services.
/// Supports success/failure simulation and configurable purchase outcomes.
class FakeBillingAdapter {
  static const String _channelName = BillingChannels.fake;
  static FakeBillingAdapter? _instance;
  
  bool _isConnected = false;
  final Random _random = Random();
  final List<ProductInfo> _mockProducts = [];
  final List<PurchaseInfo> _mockPurchases = [];
  Timer? _delayTimer;
  
  // Configuration options
  double _successRate = FakeBillingConfig.defaultSuccessRate;
  Duration _operationDelay = FakeBillingConfig.defaultOperationDelay;
  bool _simulateNetworkDelays = FakeBillingConfig.defaultSimulateNetworkDelays;
  String? _forceErrorCode;
  
  FakeBillingAdapter._();
  
  static FakeBillingAdapter get instance {
    _instance ??= FakeBillingAdapter._();
    return _instance!;
  }
  
  // Configuration methods
  void setSuccessRate(double rate) {
    _successRate = rate.clamp(0.0, 1.0);
  }
  
  void setOperationDelay(Duration delay) {
    _operationDelay = delay;
  }
  
  void setSimulateNetworkDelays(bool simulate) {
    _simulateNetworkDelays = simulate;
  }
  
  void forceError(String? errorCode) {
    _forceErrorCode = errorCode;
  }
  
  void reset() {
    _isConnected = false;
    _mockPurchases.clear();
    _forceErrorCode = null;
    _successRate = FakeBillingConfig.defaultSuccessRate;
    _operationDelay = FakeBillingConfig.defaultOperationDelay;
    _simulateNetworkDelays = FakeBillingConfig.defaultSimulateNetworkDelays;
    _delayTimer?.cancel();
  }

  /// Initialize the fake billing adapter
  Future<BillingResult> initialize() async {
    await _simulateDelay();
    
    if (_forceErrorCode != null) {
      return _createErrorResult(_forceErrorCode!, 'Forced error for testing');
    }
    
    _initializeMockProducts();
    
    return BillingResult(
      responseCode: BillingResult.ok,
      debugMessage: BillingDebugMessages.fakeBillingInitialized,
    );
  }

  /// Start connection to fake billing service
  Future<BillingResult> startConnection() async {
    await _simulateDelay();
    
    if (_forceErrorCode != null) {
      return _createErrorResult(_forceErrorCode!, 'Connection forced to fail');
    }
    
    if (!_shouldSucceed()) {
      return BillingResult(
        responseCode: BillingResult.serviceUnavailable,
        debugMessage: 'Fake connection failed (random)',
      );
    }
    
    _isConnected = true;
    
    return BillingResult(
      responseCode: BillingResult.ok,
      debugMessage: BillingDebugMessages.fakeConnected,
    );
  }

  /// End connection to fake billing service
  Future<void> endConnection() async {
    _isConnected = false;
    _mockPurchases.clear();
  }

  /// Query fake product details
  Future<BillingResult> queryProductDetails(List<String> productIds) async {
    await _simulateDelay();
    
    if (!_isConnected) {
      return BillingResult(
        responseCode: BillingResult.serviceUnavailable,
        debugMessage: 'Not connected to billing service',
      );
    }
    
    if (_forceErrorCode != null) {
      return _createErrorResult(_forceErrorCode!, 'Query forced to fail');
    }
    
    if (!_shouldSucceed()) {
      return BillingResult(
        responseCode: BillingResult.itemUnavailable,
        debugMessage: 'Products temporarily unavailable',
      );
    }
    
    return BillingResult(
      responseCode: BillingResult.ok,
      debugMessage: BillingDebugMessages.fakeProductsQueried,
    );
  }

  /// Get available fake products
  Future<List<ProductInfo>> getAvailableProducts() async {
    await _simulateDelay();
    
    return List.from(_mockProducts);
  }

  /// Launch fake billing flow
  Future<BillingResult> launchBillingFlow(String productId) async {
    await _simulateDelay();
    
    if (!_isConnected) {
      return BillingResult(
        responseCode: BillingResult.serviceUnavailable,
        debugMessage: 'Not connected to billing service',
      );
    }
    
    if (_forceErrorCode != null) {
      return _createErrorResult(_forceErrorCode!, 'Purchase forced to fail');
    }
    
    // Simulate different purchase outcomes
    final outcome = _random.nextDouble();
    
    if (outcome < FakeBillingConfig.userCancellationRate) {
      return BillingResult(
        responseCode: BillingResult.userCanceled,
        debugMessage: BillingDebugMessages.userCanceledPurchase,
      );
    } else if (outcome < FakeBillingConfig.userCancellationRate + FakeBillingConfig.paymentFailureRate) {
      return BillingResult(
        responseCode: BillingResult.errorCode,
        debugMessage: 'Payment method failed (fake)',
      );
    } else if (outcome < _successRate + FakeBillingConfig.userCancellationRate + FakeBillingConfig.paymentFailureRate) {
      // Configurable success rate
      final purchase = _createFakePurchase(productId);
      _mockPurchases.add(purchase);
      
      // Simulate async purchase update
      Timer(const Duration(milliseconds: 500), () {
        _notifyPurchaseUpdate([purchase]);
      });
      
      return BillingResult(
        responseCode: BillingResult.ok,
        debugMessage: BillingDebugMessages.fakePurchaseSuccessful,
      );
    } else {
      // Random failure
      return BillingResult(
        responseCode: BillingResult.errorCode,
        debugMessage: 'Purchase failed due to random error (fake)',
      );
    }
  }

  /// Query fake purchases
  Future<BillingResult> queryPurchases() async {
    await _simulateDelay();
    
    if (!_isConnected) {
      return BillingResult(
        responseCode: BillingResult.serviceUnavailable,
        debugMessage: 'Not connected to billing service',
      );
    }
    
    if (_forceErrorCode != null) {
      return _createErrorResult(_forceErrorCode!, 'Query purchases forced to fail');
    }
    
    return BillingResult(
      responseCode: BillingResult.ok,
      debugMessage: 'Purchases queried successfully (fake)',
    );
  }

  /// Get current fake purchases
  Future<List<PurchaseInfo>> getCurrentPurchases() async {
    await _simulateDelay();
    
    return List.from(_mockPurchases);
  }

  /// Acknowledge fake purchase
  Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    await _simulateDelay();
    
    if (!_isConnected) {
      return BillingResult(
        responseCode: BillingResult.serviceUnavailable,
        debugMessage: 'Not connected to billing service',
      );
    }
    
    if (_forceErrorCode != null) {
      return _createErrorResult(_forceErrorCode!, 'Acknowledge forced to fail');
    }
    
    // Find and acknowledge the purchase
    final purchaseIndex = _mockPurchases.indexWhere(
      (p) => p.purchaseToken == purchaseToken
    );
    
    if (purchaseIndex >= 0) {
      final purchase = _mockPurchases[purchaseIndex];
      final acknowledgedPurchase = PurchaseInfo(
        productId: purchase.productId,
        purchaseToken: purchase.purchaseToken,
        acknowledged: true,
        autoRenewing: purchase.autoRenewing,
        priceMicros: purchase.priceMicros,
        price: purchase.price,
        originalJson: purchase.originalJson,
        orderId: purchase.orderId,
        purchaseTime: purchase.purchaseTime,
        purchaseState: purchase.purchaseState,
        obfuscatedAccountId: purchase.obfuscatedAccountId,
        developerPayload: purchase.developerPayload,
      );
      
      _mockPurchases[purchaseIndex] = acknowledgedPurchase;
      
      return BillingResult(
        responseCode: BillingResult.ok,
        debugMessage: 'Purchase acknowledged (fake)',
      );
    } else {
      return BillingResult(
        responseCode: BillingResult.itemUnavailable,
        debugMessage: 'Purchase not found',
      );
    }
  }

  /// Add a fake existing purchase (for testing restoration)
  void addFakePurchase(String productId, {
    bool acknowledged = true,
    bool autoRenewing = true,
    DateTime? purchaseTime,
  }) {
    final purchase = _createFakePurchase(
      productId,
      acknowledged: acknowledged,
      autoRenewing: autoRenewing,
      purchaseTime: purchaseTime,
    );
    _mockPurchases.add(purchase);
  }

  /// Remove all fake purchases
  void clearPurchases() {
    _mockPurchases.clear();
  }

  /// Simulate a purchase update notification
  void simulatePurchaseUpdate(String productId) {
    final purchase = _createFakePurchase(productId);
    _mockPurchases.add(purchase);
    _notifyPurchaseUpdate([purchase]);
  }

  /// Simulate service disconnection
  void simulateDisconnection() {
    _isConnected = false;
    _notifyDisconnection();
  }

  /// Internal: Initialize mock products
  void _initializeMockProducts() {
    _mockProducts.clear();
    _mockProducts.addAll([
      ProductInfo(
        productId: ProductIds.proMonthly,
        title: 'MindTrainer Pro Monthly (Fake)',
        description: 'Monthly subscription for testing',
        price: FakeBillingConfig.fakeMonthlyPrice,
        priceAmountMicros: FakeBillingConfig.fakeMonthlyPriceMicros,
        priceCurrencyCode: FakeBillingConfig.fakeCurrencyCode,
        subscriptionPeriod: FakeBillingConfig.fakeMonthlyPeriod,
      ),
      ProductInfo(
        productId: ProductIds.proYearly,
        title: 'MindTrainer Pro Yearly (Fake)',
        description: 'Yearly subscription for testing',
        price: FakeBillingConfig.fakeYearlyPrice,
        priceAmountMicros: FakeBillingConfig.fakeYearlyPriceMicros,
        priceCurrencyCode: FakeBillingConfig.fakeCurrencyCode,
        subscriptionPeriod: FakeBillingConfig.fakeYearlyPeriod,
      ),
    ]);
  }

  /// Internal: Create a fake purchase
  PurchaseInfo _createFakePurchase(
    String productId, {
    bool acknowledged = false,
    bool autoRenewing = true,
    DateTime? purchaseTime,
  }) {
    final now = purchaseTime ?? DateTime.now();
    final token = 'fake_token_${now.millisecondsSinceEpoch}_${_random.nextInt(9999)}';
    final orderId = 'fake_order_${now.millisecondsSinceEpoch}';
    
    return PurchaseInfo(
      productId: productId,
      purchaseToken: token,
      acknowledged: acknowledged,
      autoRenewing: autoRenewing,
      purchaseState: PurchaseInfo.statePurchased,
      purchaseTime: now.millisecondsSinceEpoch,
      orderId: orderId,
      obfuscatedAccountId: 'fake_account_${_random.nextInt(999999)}',
    );
  }

  /// Internal: Create an error result
  BillingResult _createErrorResult(String errorCode, String message) {
    final responseCode = _mapErrorCodeToResponseCode(errorCode);
    return BillingResult(
      responseCode: responseCode,
      debugMessage: '$message (Error: $errorCode)',
    );
  }

  /// Internal: Map error codes to response codes
  int _mapErrorCodeToResponseCode(String errorCode) {
    switch (errorCode) {
      case 'USER_CANCELED':
        return BillingResult.userCanceled;
      case 'SERVICE_UNAVAILABLE':
        return BillingResult.serviceUnavailable;
      case 'BILLING_UNAVAILABLE':
        return BillingResult.billingUnavailable;
      case 'ITEM_UNAVAILABLE':
        return BillingResult.itemUnavailable;
      case 'DEVELOPER_ERROR':
        return BillingResult.developerError;
      default:
        return BillingResult.errorCode;
    }
  }

  /// Internal: Check if operation should succeed
  bool _shouldSucceed() {
    return _random.nextDouble() < _successRate;
  }

  /// Internal: Simulate network delay
  Future<void> _simulateDelay() async {
    if (_simulateNetworkDelays && _operationDelay > Duration.zero) {
      await Future.delayed(_operationDelay);
    }
  }

  /// Internal: Notify about purchase updates (would be handled by platform channel)
  void _notifyPurchaseUpdate(List<PurchaseInfo> purchases) {
    // In a real implementation, this would send through the platform channel
    // For testing, this could be connected to a stream or callback
  }

  /// Internal: Notify about disconnection (would be handled by platform channel)
  void _notifyDisconnection() {
    // In a real implementation, this would send through the platform channel
    // For testing, this could be connected to a stream or callback
  }
}

/// Error mapping utilities for billing operations
class BillingErrorMapper {
  /// Map platform exceptions to user-friendly messages
  static String mapErrorToUserMessage(String? errorCode, String? debugMessage) {
    return BillingErrorMessages.forErrorCode(errorCode, debugMessage);
  }
  
  /// Map BillingResult response codes to error codes
  static String mapResponseCodeToErrorCode(int responseCode) {
    switch (responseCode) {
      case BillingResult.ok:
        return BillingErrorCodes.success;
      case BillingResult.userCanceled:
        return BillingErrorCodes.userCanceled;
      case BillingResult.serviceUnavailable:
        return BillingErrorCodes.serviceUnavailable;
      case BillingResult.billingUnavailable:
        return BillingErrorCodes.billingUnavailable;
      case BillingResult.itemUnavailable:
        return BillingErrorCodes.itemUnavailable;
      case BillingResult.developerError:
        return BillingErrorCodes.developerError;
      case BillingResult.errorCode:
      default:
        return BillingErrorCodes.unknownError;
    }
  }
  
  /// Check if an error is retryable
  static bool isRetryableError(String? errorCode) {
    return BillingRetryConfig.isRetryable(errorCode);
  }
  
  /// Get retry delay for retryable errors
  static Duration getRetryDelay(int attemptNumber) {
    // Exponential backoff: 1s, 2s, 4s, 8s, max 30s
    final delaySeconds = (pow(2, attemptNumber - 1) as int).clamp(
      BillingRetryConfig.baseRetryDelaySeconds, 
      BillingRetryConfig.maxRetryDelaySeconds
    );
    return Duration(seconds: delaySeconds);
  }
}
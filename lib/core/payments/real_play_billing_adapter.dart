/// Real Google Play Billing Adapter for MindTrainer
/// 
/// Connects to native Android Google Play Billing Library via platform channels.
/// Handles all subscription operations including purchase, acknowledgment, and restoration.

import 'dart:async';
import 'package:flutter/services.dart';
import 'play_billing_adapter.dart';

/// Real Google Play Billing adapter using native Android SDK
class RealPlayBillingAdapter implements PlayBillingAdapter {
  static const MethodChannel _channel = MethodChannel('mindtrainer/billing');
  
  final StreamController<BillingConnectionState> _connectionController = 
      StreamController<BillingConnectionState>.broadcast();
  final StreamController<List<BillingPurchase>> _purchaseController = 
      StreamController<List<BillingPurchase>>.broadcast();
  
  BillingConnectionState _connectionState = BillingConnectionState.disconnected;
  bool _initialized = false;

  /// Create real billing adapter with optional sandbox mode
  RealPlayBillingAdapter({bool sandboxMode = false}) {
    // Only initialize in non-test environments
    try {
      _initializeChannelListeners();
    } catch (e) {
      // Ignore in test mode - channels may not be available
    }
  }

  @override
  BillingConnectionState get connectionState => _connectionState;

  @override
  Stream<BillingConnectionState> get connectionStateStream => 
      _connectionController.stream;

  @override
  Stream<List<BillingPurchase>> get purchaseUpdateStream => 
      _purchaseController.stream;

  /// Initialize method channel listeners for callbacks from native code
  void _initializeChannelListeners() {
    if (_initialized) return;
    _initialized = true;

    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'onConnectionStateChanged':
          final stateIndex = call.arguments['state'] as int;
          _handleConnectionStateChanged(stateIndex);
          break;
          
        case 'onPurchasesUpdated':
          final purchasesData = call.arguments['purchases'] as List<dynamic>;
          _handlePurchasesUpdated(purchasesData);
          break;
      }
    });
  }

  /// Handle connection state changes from native code
  void _handleConnectionStateChanged(int stateIndex) {
    final newState = BillingConnectionState.values[stateIndex];
    _connectionState = newState;
    _connectionController.add(newState);
  }

  /// Handle purchase updates from native code
  void _handlePurchasesUpdated(List<dynamic> purchasesData) {
    final purchases = purchasesData
        .cast<Map<dynamic, dynamic>>()
        .map((data) => _parseBillingPurchase(data))
        .toList();
    
    _purchaseController.add(purchases);
  }

  @override
  Future<BillingResult> startConnection() async {
    try {
      _setConnectionState(BillingConnectionState.connecting);
      
      final result = await _channel.invokeMethod('startConnection', {
        'sandboxMode': false, // Use production mode by default
      });
      
      return _parseBillingResult(result);
    } catch (e) {
      _setConnectionState(BillingConnectionState.error);
      return BillingResult.error('Platform channel error: $e', -1);
    }
  }

  @override
  Future<void> endConnection() async {
    try {
      await _channel.invokeMethod('endConnection');
      _setConnectionState(BillingConnectionState.disconnected);
    } catch (e) {
      // Ignore errors on disconnection
    }
    
    await _connectionController.close();
    await _purchaseController.close();
  }

  @override
  Future<List<BillingProduct>> querySubscriptionProducts(List<String> productIds) async {
    try {
      final result = await _channel.invokeMethod('queryProducts', {
        'productIds': productIds,
        'productType': 'subs',
      });

      if (result is List) {
        return result
            .cast<Map<dynamic, dynamic>>()
            .map((data) => _parseBillingProduct(data))
            .toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<BillingResult> launchSubscriptionPurchaseFlow(String productId) async {
    try {
      final result = await _channel.invokeMethod('launchPurchaseFlow', {
        'productId': productId,
        'productType': 'subs',
      });
      
      return _parseBillingResult(result);
    } catch (e) {
      return BillingResult.error('Platform channel error: $e', -1);
    }
  }

  @override
  Future<List<BillingPurchase>> queryPurchases() async {
    try {
      final result = await _channel.invokeMethod('queryPurchases', {
        'productType': 'subs',
      });

      if (result is List) {
        return result
            .cast<Map<dynamic, dynamic>>()
            .map((data) => _parseBillingPurchase(data))
            .toList();
      }
      
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    try {
      final result = await _channel.invokeMethod('acknowledgePurchase', {
        'purchaseToken': purchaseToken,
      });
      
      return _parseBillingResult(result);
    } catch (e) {
      return BillingResult.error('Platform channel error: $e', -1);
    }
  }

  @override
  Future<bool> isSubscriptionSupported() async {
    try {
      final result = await _channel.invokeMethod('isSubscriptionSupported');
      return result as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Parse BillingResult from platform method call
  BillingResult _parseBillingResult(dynamic data) {
    if (data is Map) {
      final success = data['success'] as bool? ?? false;
      final responseCode = data['responseCode'] as int? ?? -1;
      final debugMessage = data['debugMessage'] as String?;
      
      if (success) {
        return const BillingResult.ok();
      } else if (responseCode == 1) { // USER_CANCELED
        return const BillingResult.cancelled();
      } else {
        return BillingResult.error(debugMessage ?? 'Unknown error', responseCode);
      }
    }
    
    return const BillingResult.error('Invalid result format', -1);
  }

  /// Parse BillingProduct from platform data
  BillingProduct _parseBillingProduct(Map<dynamic, dynamic> data) {
    return BillingProduct(
      productId: data['productId'] as String? ?? '',
      type: data['type'] as String? ?? 'subs',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: data['price'] as String? ?? '',
      priceAmountMicros: (data['priceAmountMicros'] as num?)?.toInt() ?? 0,
      priceCurrencyCode: data['priceCurrencyCode'] as String? ?? 'USD',
    );
  }

  /// Parse BillingPurchase from platform data
  BillingPurchase _parseBillingPurchase(Map<dynamic, dynamic> data) {
    final stateIndex = data['state'] as int? ?? 3;
    final state = stateIndex < PurchaseState.values.length 
        ? PurchaseState.values[stateIndex] 
        : PurchaseState.failed;

    return BillingPurchase(
      purchaseToken: data['purchaseToken'] as String? ?? '',
      productId: data['productId'] as String? ?? '',
      state: state,
      purchaseTime: (data['purchaseTime'] as num?)?.toInt() ?? 0,
      acknowledged: data['acknowledged'] as bool? ?? false,
      autoRenewing: data['autoRenewing'] as bool? ?? false,
    );
  }

  /// Set connection state and notify listeners
  void _setConnectionState(BillingConnectionState state) {
    _connectionState = state;
    _connectionController.add(state);
  }
}

/// Factory for creating billing adapters based on build configuration
class PlayBillingAdapterFactory {
  /// Create the appropriate billing adapter based on build configuration
  /// 
  /// Uses fake adapter for debug/testing, real adapter for release
  static PlayBillingAdapter create({bool useFakeForTesting = false}) {
    // In debug mode or when explicitly requested, use fake adapter
    const isDebug = bool.fromEnvironment('dart.vm.product') == false;
    
    if (isDebug || useFakeForTesting) {
      return FakePlayBillingAdapter();
    }
    
    // Use real adapter for production
    return RealPlayBillingAdapter();
  }
  
  /// Create fake adapter for testing
  static FakePlayBillingAdapter createFake({
    bool simulateConnectionFailure = false,
    bool simulatePurchaseFailure = false,
    bool simulateUserCancel = false,
  }) {
    return FakePlayBillingAdapter(
      simulateConnectionFailure: simulateConnectionFailure,
      simulatePurchaseFailure: simulatePurchaseFailure,
      simulateUserCancel: simulateUserCancel,
    );
  }
  
  /// Create real adapter for production
  static RealPlayBillingAdapter createReal({bool sandboxMode = false}) {
    return RealPlayBillingAdapter(sandboxMode: sandboxMode);
  }
}
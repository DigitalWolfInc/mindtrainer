/// Platform Billing Adapter for Google Play Billing SDK
/// 
/// Integrates with native Android Google Play Billing via platform channels.
/// Maintains compatibility with fake billing for testing.

import 'dart:async';
import 'package:flutter/services.dart';
import 'billing_config.dart';
import 'play_billing_adapter.dart';

/// Build mode configuration for billing
enum BillingMode {
  /// Use fake billing for testing and development
  fake,
  /// Use real Google Play Billing SDK
  production,
  /// Use Google Play Billing in sandbox mode
  sandbox,
}

/// Platform-specific billing adapter using Google Play Billing SDK
class PlatformBillingAdapter implements PlayBillingAdapter {
  static const MethodChannel _channel = MethodChannel('mindtrainer.billing');
  
  final BillingMode _mode;
  final StreamController<BillingConnectionState> _connectionController = 
      StreamController<BillingConnectionState>.broadcast();
  final StreamController<List<BillingPurchase>> _purchaseController = 
      StreamController<List<BillingPurchase>>.broadcast();
  
  BillingConnectionState _connectionState = BillingConnectionState.disconnected;
  late final FakePlayBillingAdapter? _fakeAdapter;
  
  PlatformBillingAdapter({BillingMode mode = BillingMode.production}) : _mode = mode {
    if (_mode == BillingMode.fake) {
      _fakeAdapter = FakePlayBillingAdapter();
    } else {
      _fakeAdapter = null;
      _setupPlatformChannels();
    }
  }
  
  /// Setup platform channel listeners for native events
  void _setupPlatformChannels() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  /// Handle method calls from native Android code
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onConnectionStateChanged':
        final stateIndex = call.arguments['state'] as int;
        final newState = BillingConnectionState.values[stateIndex];
        _connectionState = newState;
        _connectionController.add(newState);
        break;
        
      case 'onPurchasesUpdated':
        final purchasesData = call.arguments['purchases'] as List<dynamic>;
        final purchases = purchasesData.map((data) => _parsePurchase(data)).toList();
        _purchaseController.add(purchases);
        break;
        
      default:
        throw UnimplementedError('Method ${call.method} not implemented');
    }
  }
  
  /// Parse purchase data from native platform
  BillingPurchase _parsePurchase(Map<dynamic, dynamic> data) {
    return BillingPurchase(
      purchaseToken: data['purchaseToken'] as String,
      productId: data['productId'] as String,
      state: PurchaseState.values[data['state'] as int],
      purchaseTime: data['purchaseTime'] as int,
      acknowledged: data['acknowledged'] as bool? ?? false,
      autoRenewing: data['autoRenewing'] as bool? ?? false,
    );
  }
  
  /// Parse billing product data from native platform
  BillingProduct _parseProduct(Map<dynamic, dynamic> data) {
    return BillingProduct(
      productId: data['productId'] as String,
      type: data['type'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      price: data['price'] as String,
      priceAmountMicros: data['priceAmountMicros'] as int,
      priceCurrencyCode: data['priceCurrencyCode'] as String,
    );
  }
  
  @override
  BillingConnectionState get connectionState {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.connectionState;
    }
    return _connectionState;
  }
  
  @override
  Stream<BillingConnectionState> get connectionStateStream {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.connectionStateStream;
    }
    return _connectionController.stream;
  }
  
  @override
  Stream<List<BillingPurchase>> get purchaseUpdateStream {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.purchaseUpdateStream;
    }
    return _purchaseController.stream;
  }
  
  @override
  Future<BillingResult> startConnection() async {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.startConnection();
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('startConnection', {
        'sandboxMode': _mode == BillingMode.sandbox,
      });
      
      if (result == null) {
        return const BillingResult.error('Null response from platform', -1);
      }
      
      final success = result['success'] as bool;
      final responseCode = result['responseCode'] as int;
      final debugMessage = result['debugMessage'] as String?;
      
      return BillingResult(
        success: success,
        responseCode: responseCode,
        debugMessage: debugMessage,
      );
    } on PlatformException catch (e) {
      return BillingResult.error('Platform error: ${e.message}', -1);
    }
  }
  
  @override
  Future<void> endConnection() async {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.endConnection();
    }
    
    try {
      await _channel.invokeMethod('endConnection');
      _connectionState = BillingConnectionState.disconnected;
      _connectionController.add(_connectionState);
    } on PlatformException catch (e) {
      // Log error but don't throw - cleanup should be best effort
      print('Error ending billing connection: ${e.message}');
    }
    
    await _connectionController.close();
    await _purchaseController.close();
  }
  
  @override
  Future<List<BillingProduct>> querySubscriptionProducts(List<String> productIds) async {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.querySubscriptionProducts(productIds);
    }
    
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('queryProducts', {
        'productIds': productIds,
        'productType': 'subs',
      });
      
      if (result == null) return [];
      
      return result.map((data) => _parseProduct(data as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      print('Error querying products: ${e.message}');
      return [];
    }
  }
  
  @override
  Future<BillingResult> launchSubscriptionPurchaseFlow(String productId) async {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.launchSubscriptionPurchaseFlow(productId);
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('launchPurchaseFlow', {
        'productId': productId,
        'productType': 'subs',
      });
      
      if (result == null) {
        return const BillingResult.error('Null response from purchase flow', -1);
      }
      
      final success = result['success'] as bool;
      final responseCode = result['responseCode'] as int;
      final debugMessage = result['debugMessage'] as String?;
      
      return BillingResult(
        success: success,
        responseCode: responseCode,
        debugMessage: debugMessage,
      );
    } on PlatformException catch (e) {
      return BillingResult.error('Platform error: ${e.message}', -1);
    }
  }
  
  @override
  Future<List<BillingPurchase>> queryPurchases() async {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.queryPurchases();
    }
    
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('queryPurchases', {
        'productType': 'subs',
      });
      
      if (result == null) return [];
      
      return result.map((data) => _parsePurchase(data as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      print('Error querying purchases: ${e.message}');
      return [];
    }
  }
  
  @override
  Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.acknowledgePurchase(purchaseToken);
    }
    
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('acknowledgePurchase', {
        'purchaseToken': purchaseToken,
      });
      
      if (result == null) {
        return const BillingResult.error('Null response from acknowledge', -1);
      }
      
      final success = result['success'] as bool;
      final responseCode = result['responseCode'] as int;
      final debugMessage = result['debugMessage'] as String?;
      
      return BillingResult(
        success: success,
        responseCode: responseCode,
        debugMessage: debugMessage,
      );
    } on PlatformException catch (e) {
      return BillingResult.error('Platform error: ${e.message}', -1);
    }
  }
  
  @override
  Future<bool> isSubscriptionSupported() async {
    if (_mode == BillingMode.fake) {
      return _fakeAdapter!.isSubscriptionSupported();
    }
    
    try {
      final result = await _channel.invokeMethod<bool>('isSubscriptionSupported');
      return result ?? false;
    } on PlatformException catch (e) {
      print('Error checking subscription support: ${e.message}');
      return false;
    }
  }
  
  /// Get current billing mode for debugging
  BillingMode get currentMode => _mode;
  
  /// Check if running in test/fake mode
  bool get isFakeMode => _mode == BillingMode.fake;
  
  /// Check if running in sandbox mode
  bool get isSandboxMode => _mode == BillingMode.sandbox;
}

/// Factory for creating billing adapters based on build configuration
class BillingAdapterFactory {
  /// Create billing adapter based on build mode and environment
  static PlayBillingAdapter create() {
    BillingConfig.printConfig();
    
    if (BillingConfig.isFakeMode) {
      return PlatformBillingAdapter(mode: BillingMode.fake);
    } else if (BillingConfig.isSandboxMode) {
      return PlatformBillingAdapter(mode: BillingMode.sandbox);
    } else {
      return PlatformBillingAdapter(mode: BillingMode.production);
    }
  }
  
  /// Create fake adapter explicitly for testing
  static PlayBillingAdapter createFake({
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
  
  /// Create platform adapter explicitly for production
  static PlayBillingAdapter createPlatform({BillingMode mode = BillingMode.production}) {
    return PlatformBillingAdapter(mode: mode);
  }
}
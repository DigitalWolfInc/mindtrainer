/// Billing adapter for Google Play Billing integration
/// Provides both real SDK integration and fake mode for testing

import 'dart:async';
import 'dart:math';
import 'pro_catalog.dart';
import 'platform_channel_billing.dart';
import 'billing_config.dart';

/// Billing result status codes
enum BillingResultCode {
  ok, // 0
  userCanceled, // 1
  serviceUnavailable, // 2
  billingUnavailable, // 3
  itemNotOwned, // 4
  itemAlreadyOwned, // 5
  itemUnavailable, // 6
  developerError, // 7
  error, // 8
  featureNotSupported, // 9
  serviceDisconnected, // 10
  networkError, // 11
}

/// Billing adapter result wrapper
class BillingResult {
  final BillingResultCode responseCode;
  final String? debugMessage;
  
  const BillingResult({
    required this.responseCode,
    this.debugMessage,
  });
  
  bool get isSuccess => responseCode == BillingResultCode.ok;
  bool get isUserCanceled => responseCode == BillingResultCode.userCanceled;
  bool get isError => responseCode != BillingResultCode.ok;
  
  @override
  String toString() => 'BillingResult(${responseCode.name}, $debugMessage)';
}

/// Purchase update listener callback
typedef PurchaseUpdateCallback = void Function(List<ProPurchase> purchases);

/// Billing service connection state
enum BillingServiceState {
  disconnected,
  connecting,
  connected,
  closed,
}

/// Main billing adapter interface
abstract class BillingAdapter {
  /// Current connection state
  BillingServiceState get connectionState;
  
  /// Set purchase update listener
  void setPurchaseUpdateListener(PurchaseUpdateCallback listener);
  
  /// Start connection to billing service
  Future<BillingResult> startConnection();
  
  /// End connection to billing service
  Future<void> endConnection();
  
  /// Query available products
  Future<BillingResult> queryProductDetails(List<String> productIds);
  
  /// Get queried products
  List<ProProduct> get availableProducts;
  
  /// Launch purchase flow
  Future<BillingResult> launchBillingFlow(String productId);
  
  /// Query existing purchases
  Future<BillingResult> queryPurchases();
  
  /// Get current purchases
  List<ProPurchase> get currentPurchases;
  
  /// Acknowledge a purchase
  Future<BillingResult> acknowledgePurchase(String purchaseToken);
  
  /// Check if Pro subscription is active
  bool get isProActive;
  
  /// Get active Pro purchase if any
  ProPurchase? get activeProPurchase;
  
  /// Dispose resources
  void dispose();
}

/// Fake billing adapter for testing
class FakeBillingAdapter implements BillingAdapter {
  BillingServiceState _connectionState = BillingServiceState.disconnected;
  PurchaseUpdateCallback? _purchaseUpdateListener;
  List<ProProduct> _availableProducts = [];
  List<ProPurchase> _currentPurchases = [];
  bool _fakeProActive = false;
  
  // Simulate network delay
  static const Duration _networkDelay = Duration(milliseconds: 500);
  
  @override
  BillingServiceState get connectionState => _connectionState;
  
  @override
  List<ProProduct> get availableProducts => List.unmodifiable(_availableProducts);
  
  @override
  List<ProPurchase> get currentPurchases => List.unmodifiable(_currentPurchases);
  
  @override
  bool get isProActive => _fakeProActive;
  
  @override
  ProPurchase? get activeProPurchase {
    if (!_fakeProActive) return null;
    return _currentPurchases.where((p) => p.isPurchased && p.autoRenewing).firstOrNull;
  }
  
  @override
  void setPurchaseUpdateListener(PurchaseUpdateCallback listener) {
    _purchaseUpdateListener = listener;
  }
  
  @override
  Future<BillingResult> startConnection() async {
    _connectionState = BillingServiceState.connecting;
    
    // Simulate connection delay
    await Future.delayed(_networkDelay);
    
    _connectionState = BillingServiceState.connected;
    
    return const BillingResult(responseCode: BillingResultCode.ok);
  }
  
  @override
  Future<void> endConnection() async {
    _connectionState = BillingServiceState.disconnected;
    _availableProducts.clear();
    _currentPurchases.clear();
  }
  
  @override
  Future<BillingResult> queryProductDetails(List<String> productIds) async {
    await Future.delayed(_networkDelay);
    
    if (_connectionState != BillingServiceState.connected) {
      return const BillingResult(
        responseCode: BillingResultCode.serviceDisconnected,
        debugMessage: 'Billing service not connected',
      );
    }
    
    _availableProducts.clear();
    
    for (final productId in productIds) {
      final product = ProCatalog.getProductById(productId);
      if (product != null) {
        _availableProducts.add(product);
      }
    }
    
    return const BillingResult(responseCode: BillingResultCode.ok);
  }
  
  @override
  Future<BillingResult> launchBillingFlow(String productId) async {
    await Future.delayed(_networkDelay);
    
    if (_connectionState != BillingServiceState.connected) {
      return const BillingResult(
        responseCode: BillingResultCode.serviceDisconnected,
        debugMessage: 'Billing service not connected',
      );
    }
    
    if (!ProCatalog.isValidProductId(productId)) {
      return const BillingResult(
        responseCode: BillingResultCode.itemUnavailable,
        debugMessage: 'Product not available',
      );
    }
    
    // Simulate user purchase decision (80% success rate)
    final random = Random();
    if (random.nextDouble() < 0.8) {
      // Simulate successful purchase
      final purchase = _createFakePurchase(productId);
      _currentPurchases.add(purchase);
      _fakeProActive = true;
      
      // Notify listener
      _purchaseUpdateListener?.call([purchase]);
      
      return const BillingResult(responseCode: BillingResultCode.ok);
    } else {
      // Simulate user cancellation
      return const BillingResult(
        responseCode: BillingResultCode.userCanceled,
        debugMessage: 'User canceled purchase',
      );
    }
  }
  
  @override
  Future<BillingResult> queryPurchases() async {
    await Future.delayed(_networkDelay);
    
    if (_connectionState != BillingServiceState.connected) {
      return const BillingResult(
        responseCode: BillingResultCode.serviceDisconnected,
        debugMessage: 'Billing service not connected',
      );
    }
    
    // In real implementation, this would query Google Play
    // For fake adapter, return current purchases
    return const BillingResult(responseCode: BillingResultCode.ok);
  }
  
  @override
  Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    await Future.delayed(_networkDelay);
    
    if (_connectionState != BillingServiceState.connected) {
      return const BillingResult(
        responseCode: BillingResultCode.serviceDisconnected,
        debugMessage: 'Billing service not connected',
      );
    }
    
    // Find purchase by token and mark as acknowledged
    for (int i = 0; i < _currentPurchases.length; i++) {
      if (_currentPurchases[i].purchaseToken == purchaseToken) {
        final purchase = _currentPurchases[i];
        final acknowledgedPurchase = ProPurchase(
          purchaseToken: purchase.purchaseToken,
          productId: purchase.productId,
          orderId: purchase.orderId,
          purchaseTime: purchase.purchaseTime,
          purchaseState: purchase.purchaseState,
          acknowledged: true,
          autoRenewing: purchase.autoRenewing,
          obfuscatedAccountId: purchase.obfuscatedAccountId,
          developerPayload: purchase.developerPayload,
        );
        _currentPurchases[i] = acknowledgedPurchase;
        break;
      }
    }
    
    return const BillingResult(responseCode: BillingResultCode.ok);
  }
  
  @override
  void dispose() {
    _connectionState = BillingServiceState.closed;
    _purchaseUpdateListener = null;
    _availableProducts.clear();
    _currentPurchases.clear();
    _fakeProActive = false;
  }
  
  // Test helpers for fake adapter
  
  /// Simulate Pro activation for testing
  void simulateProActivation(String productId) {
    final purchase = _createFakePurchase(productId);
    _currentPurchases.add(purchase);
    _fakeProActive = true;
    _purchaseUpdateListener?.call([purchase]);
  }
  
  /// Simulate Pro expiration for testing
  void simulateProExpiration() {
    _fakeProActive = false;
    _currentPurchases.clear();
    _purchaseUpdateListener?.call([]);
  }
  
  /// Create fake purchase for testing
  ProPurchase _createFakePurchase(String productId) {
    final now = DateTime.now();
    final random = Random();
    
    return ProPurchase(
      purchaseToken: 'fake_token_${now.millisecondsSinceEpoch}_${random.nextInt(10000)}',
      productId: productId,
      orderId: 'fake_order_${now.millisecondsSinceEpoch}',
      purchaseTime: now.millisecondsSinceEpoch,
      purchaseState: 0, // Purchased
      acknowledged: false,
      autoRenewing: true,
      obfuscatedAccountId: 'fake_account_${random.nextInt(1000000)}',
      developerPayload: null,
    );
  }
}

/// Real Google Play Billing adapter using platform channels
class GooglePlayBillingAdapter implements BillingAdapter {
  BillingServiceState _connectionState = BillingServiceState.disconnected;
  PurchaseUpdateCallback? _purchaseUpdateListener;
  List<ProProduct> _availableProducts = [];
  List<ProPurchase> _currentPurchases = [];
  
  late final PlatformChannelBilling _platformBilling;
  StreamSubscription<List<ProPurchase>>? _purchaseSubscription;
  
  GooglePlayBillingAdapter() {
    _platformBilling = PlatformChannelBilling();
  }
  
  @override
  BillingServiceState get connectionState => _connectionState;
  
  @override
  List<ProProduct> get availableProducts => List.unmodifiable(_availableProducts);
  
  @override
  List<ProPurchase> get currentPurchases => List.unmodifiable(_currentPurchases);
  
  @override
  bool get isProActive {
    return _currentPurchases.any((p) => 
      p.isPurchased && 
      p.acknowledged && 
      p.autoRenewing &&
      ProCatalog.isValidProductId(p.productId)
    );
  }
  
  @override
  ProPurchase? get activeProPurchase {
    if (!isProActive) return null;
    return _currentPurchases
        .where((p) => p.isPurchased && p.autoRenewing)
        .firstOrNull;
  }
  
  @override
  void setPurchaseUpdateListener(PurchaseUpdateCallback listener) {
    _purchaseUpdateListener = listener;
    
    // Set up platform purchase stream listener
    _purchaseSubscription?.cancel();
    _purchaseSubscription = _platformBilling.purchaseUpdates.listen((purchases) {
      _currentPurchases = purchases;
      _purchaseUpdateListener?.call(purchases);
    });
  }
  
  @override
  Future<BillingResult> startConnection() async {
    _connectionState = BillingServiceState.connecting;
    
    final result = await _platformBilling.startConnection();
    if (result.isSuccess) {
      _connectionState = BillingServiceState.connected;
    } else {
      _connectionState = BillingServiceState.disconnected;
    }
    
    return result;
  }
  
  @override
  Future<void> endConnection() async {
    await _platformBilling.endConnection();
    _connectionState = BillingServiceState.disconnected;
    _availableProducts.clear();
    _currentPurchases.clear();
    _purchaseSubscription?.cancel();
  }
  
  @override
  Future<BillingResult> queryProductDetails(List<String> productIds) async {
    final result = await _platformBilling.queryProductDetails(productIds);
    
    if (result.isSuccess) {
      _availableProducts = await _platformBilling.getAvailableProducts();
    }
    
    return result;
  }
  
  @override
  Future<BillingResult> launchBillingFlow(String productId) async {
    return await _platformBilling.launchBillingFlow(productId);
  }
  
  @override
  Future<BillingResult> queryPurchases() async {
    final result = await _platformBilling.queryPurchases();
    
    if (result.isSuccess) {
      _currentPurchases = await _platformBilling.getCurrentPurchases();
    }
    
    return result;
  }
  
  @override
  Future<BillingResult> acknowledgePurchase(String purchaseToken) async {
    return await _platformBilling.acknowledgePurchase(purchaseToken);
  }
  
  @override
  void dispose() {
    _connectionState = BillingServiceState.closed;
    _purchaseUpdateListener = null;
    _availableProducts.clear();
    _currentPurchases.clear();
    _purchaseSubscription?.cancel();
    _platformBilling.dispose();
  }
}

/// Billing adapter factory
class BillingAdapterFactory {
  /// Create billing adapter instance
  /// Set [useFakeAdapter] to override environment-based detection
  /// If not specified, uses BillingConfig to determine adapter type
  static BillingAdapter create({bool? useFakeAdapter}) {
    final shouldUseFake = useFakeAdapter ?? BillingConfig.useFakeBilling;
    
    if (shouldUseFake) {
      return FakeBillingAdapter();
    } else {
      return GooglePlayBillingAdapter();
    }
  }
  
  /// Create fake adapter explicitly (for testing)
  static FakeBillingAdapter createFake() => FakeBillingAdapter();
  
  /// Create real adapter explicitly (for production)
  static GooglePlayBillingAdapter createReal() => GooglePlayBillingAdapter();
  
  /// Get current configuration info
  static String getConfigInfo() => BillingConfig.getConfigDescription();
}
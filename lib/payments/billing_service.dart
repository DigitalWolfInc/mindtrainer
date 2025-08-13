import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api.dart';
import 'billing_constants.dart';
import 'channel.dart';
import 'models.dart';
import 'pro_state.dart';
import 'receipt_store.dart';

/// Comprehensive billing service integrating platform channels with Pro state
/// 
/// This service acts as the main interface between the UI and the billing system,
/// handling product loading, purchases, restoration, and state management.
class BillingService extends ChangeNotifier {
  static BillingService? _instance;
  
  final ProState _proState = ProState.instance;
  bool _isInitialized = false;
  bool _isConnected = false;
  bool _isLoading = false;
  List<ProductInfo> _availableProducts = [];
  String? _lastError;
  StreamSubscription? _purchaseSubscription;
  StreamSubscription? _connectionSubscription;

  BillingService._();

  /// Singleton instance
  static BillingService get instance {
    _instance ??= BillingService._();
    return _instance!;
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isProActive => _proState.isProActive;
  List<ProductInfo> get availableProducts => List.unmodifiable(_availableProducts);
  String? get lastError => _lastError;
  ProState get proState => _proState;

  /// Initialize the billing service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      
      // Initialize platform channel
      await BillingChannel.initialize();
      
      // Initialize Pro state
      await _proState.initialize();
      
      // Set up event listeners
      _purchaseSubscription = BillingChannel.purchaseUpdates.listen(
        _onPurchaseUpdated,
        onError: _onPurchaseError,
      );
      
      _connectionSubscription = BillingChannel.connectionUpdates.listen(
        _onConnectionUpdate,
        onError: _onConnectionError,
      );
      
      // Listen to ProState changes
      _proState.addListener(_onProStateChanged);
      
      _isInitialized = true;
      _clearError();
      
    } catch (e) {
      _setError('Failed to initialize billing service: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Connect to billing service and load products
  Future<void> connect() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isConnected) return;

    try {
      _setLoading(true);
      
      // Start connection
      final result = await BillingChannel.startConnection();
      if (!result.isSuccess) {
        throw Exception('Connection failed: ${result.debugMessage}');
      }
      
      _isConnected = true;
      
      // Load available products
      await _loadProducts();
      
      // Restore purchases
      await restorePurchases();
      
      _clearError();
      
    } catch (e) {
      _setError('Failed to connect to billing service: $e');
      _isConnected = false;
    } finally {
      _setLoading(false);
    }
  }

  /// Disconnect from billing service
  Future<void> disconnect() async {
    _isConnected = false;
    _availableProducts.clear();
    await BillingChannel.endConnection();
    notifyListeners();
  }

  /// Purchase a product
  Future<bool> purchaseProduct(String productId) async {
    if (!_isConnected) {
      _setError(BillingErrorMessages.notConnected);
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      final result = await PurchaseAPI.startPurchase(productId);
      
      if (result.isSuccess) {
        // Purchase flow launched successfully
        // The result will come through the purchase updates stream
        return true;
      } else if (result.isUserCanceled) {
        // User canceled - not an error
        return false;
      } else if (result.responseCode == BillingResponseCodes.itemAlreadyOwned) {
        // Handle ITEM_ALREADY_OWNED by triggering restore
        await _proState.handleItemAlreadyOwnedError(productId);
        _setError('You already own this subscription. Purchase history has been restored.');
        return false;
      } else {
        _setError('Purchase failed: ${result.debugMessage}');
        return false;
      }
      
    } catch (e) {
      _setError('Purchase error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    if (!_isConnected) {
      _setError(BillingErrorMessages.notConnected);
      return;
    }

    try {
      _setLoading(true);
      
      // Use ProState's restoration logic
      await _proState.restoreFromBillingService();
      
      // Clear any ProState errors and use our own error handling
      if (_proState.lastError != null) {
        _setError(_proState.lastError!);
        _proState.clearError();
      } else {
        _clearError();
      }
      
    } catch (e) {
      _setError('Restore failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get product by ID
  ProductInfo? getProduct(String productId) {
    try {
      return _availableProducts.firstWhere((p) => p.productId == productId);
    } catch (e) {
      return null;
    }
  }

  /// Get all Pro products
  List<ProductInfo> getProProducts() {
    return _availableProducts
        .where((p) => BillingProducts.isProProduct(p.productId))
        .toList();
  }

  /// Check if a specific product is available
  bool isProductAvailable(String productId) {
    return _availableProducts.any((p) => p.productId == productId);
  }

  /// Get subscription info for UI display
  BillingSubscriptionInfo getSubscriptionInfo() {
    final purchase = _proState.activePurchase;
    return BillingSubscriptionInfo(
      isActive: _proState.isProActive,
      productId: _proState.activeProductId,
      product: _proState.activeProductId != null 
          ? getProduct(_proState.activeProductId!) 
          : null,
      purchase: purchase,
    );
  }

  /// Reset for testing
  static void resetInstance() {
    _instance?._dispose();
    _instance = null;
  }

  /// Internal: Load products from billing service
  Future<void> _loadProducts() async {
    try {
      // Query product details
      final queryResult = await BillingChannel.queryProductDetails(
        BillingProducts.allSubscriptions,
      );
      
      if (!queryResult.isSuccess) {
        throw Exception('Product query failed: ${queryResult.debugMessage}');
      }
      
      // Get available products
      _availableProducts = await BillingChannel.getAvailableProducts();
      
      notifyListeners();
      
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }

  /// Internal: Handle purchase updates from platform
  void _onPurchaseUpdated(List<PurchaseInfo> purchases) async {
    try {
      // Forward to ProState for processing
      await _proState.onPurchaseUpdated(purchases);
    } catch (e) {
      _setError('Purchase processing failed: $e');
    }
  }

  /// Internal: Handle purchase errors
  void _onPurchaseError(Object error) {
    _setError('Purchase stream error: $error');
  }

  /// Internal: Handle connection updates
  void _onConnectionUpdate(BillingResult result) {
    if (result.isError) {
      _isConnected = false;
      _setError('Connection lost: ${result.debugMessage}');
    }
  }

  /// Internal: Handle connection errors
  void _onConnectionError(Object error) {
    _isConnected = false;
    _setError('Connection error: $error');
  }

  /// Internal: Handle ProState changes
  void _onProStateChanged() {
    notifyListeners();
  }

  /// Internal: Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Internal: Set error state
  void _setError(String error) {
    _lastError = error;
    notifyListeners();
  }

  /// Internal: Clear error state
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  /// Internal: Clean up resources
  void _dispose() {
    _purchaseSubscription?.cancel();
    _connectionSubscription?.cancel();
    _proState.removeListener(_onProStateChanged);
    disconnect();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}

/// Subscription information for UI display
class BillingSubscriptionInfo {
  final bool isActive;
  final String? productId;
  final ProductInfo? product;
  final PurchaseInfo? purchase;

  const BillingSubscriptionInfo({
    required this.isActive,
    this.productId,
    this.product,
    this.purchase,
  });

  String? get displayName => product != null 
      ? BillingProducts.getProductDisplayName(product!.productId)
      : null;
  
  String? get formattedPrice => product?.price;
  
  DateTime? get purchaseDate => purchase?.purchaseDateTime;
  
  bool get isAutoRenewing => purchase?.autoRenewing ?? false;

  @override
  String toString() => 
      'BillingSubscriptionInfo(active: $isActive, product: $displayName)';
}

/// Integration helper for existing Pro catalog system
class BillingCatalogIntegration {
  /// Convert ProductInfo to legacy format for existing UI
  static Map<String, dynamic> productToLegacyFormat(ProductInfo product) {
    return {
      'productId': _mapToLegacyProductId(product.productId),
      'title': product.title ?? BillingProducts.getProductDisplayName(product.productId),
      'description': product.description ?? '',
      'price': product.price ?? '',
      'priceAmountMicros': product.priceAmountMicros,
      'priceCurrencyCode': product.priceCurrencyCode ?? 'USD',
      'subscriptionPeriod': product.subscriptionPeriod,
    };
  }

  /// Map new product IDs to legacy product IDs
  static String _mapToLegacyProductId(String productId) {
    return LegacyProductMapping.toLegacy(productId);
  }

  /// Map legacy product IDs to new product IDs
  static String mapFromLegacyProductId(String legacyProductId) {
    return LegacyProductMapping.fromLegacy(legacyProductId);
  }
}
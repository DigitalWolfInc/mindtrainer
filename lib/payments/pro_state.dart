import 'package:flutter/foundation.dart';

import 'billing_constants.dart';
import 'channel.dart';
import 'models.dart';
import 'receipt_store.dart';

/// Pro subscription state management with automatic restore
/// 
/// Manages the user's Pro subscription status, handles purchase receipts,
/// and provides reactive state updates for UI components.
class ProState extends ChangeNotifier {
  static ProState? _instance;
  final ReceiptStore _receiptStore = ReceiptStore.instance;
  
  bool _isProActive = false;
  bool _isInitialized = false;
  bool _isRestoring = false;
  String? _activeProductId;
  PurchaseInfo? _activePurchase;
  String? _lastError;
  
  // Pending purchase tracking
  final Map<String, PurchaseInfo> _pendingPurchases = {};
  String? _lastItemAlreadyOwnedProductId;

  ProState._();

  /// Singleton instance
  static ProState get instance {
    _instance ??= ProState._();
    return _instance!;
  }

  // Getters
  bool get isProActive => _isProActive;
  bool get isInitialized => _isInitialized;
  bool get isRestoring => _isRestoring;
  String? get activeProductId => _activeProductId;
  PurchaseInfo? get activePurchase => _activePurchase;
  String? get lastError => _lastError;
  
  /// Get pending purchases map (read-only copy)
  Map<String, PurchaseInfo> get pendingPurchases => Map.unmodifiable(_pendingPurchases);
  
  /// Check if a specific product has a pending purchase
  bool hasPendingPurchase(String productId) => _pendingPurchases.containsKey(productId);
  
  /// Get pending purchase for a product
  PurchaseInfo? getPendingPurchase(String productId) => _pendingPurchases[productId];
  
  /// Get the product ID that last triggered ITEM_ALREADY_OWNED error
  String? get lastItemAlreadyOwnedProductId => _lastItemAlreadyOwnedProductId;
  
  /// Handle ITEM_ALREADY_OWNED error and trigger restore
  Future<void> handleItemAlreadyOwnedError(String productId) async {
    _lastItemAlreadyOwnedProductId = productId;
    notifyListeners();
    
    // Automatically trigger restore to handle the owned item
    await restoreFromBillingService();
  }
  
  /// Clear the ITEM_ALREADY_OWNED error state
  void clearItemAlreadyOwnedError() {
    _lastItemAlreadyOwnedProductId = null;
    notifyListeners();
  }

  /// Initialize Pro state and restore from saved receipts
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _receiptStore.initialize();
      await _restoreFromLocalReceipts();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      _lastError = 'Failed to initialize Pro state: $e';
      _isInitialized = true; // Still mark as initialized to prevent retries
      notifyListeners();
    }
  }

  /// Restore Pro status from remote billing service
  /// 
  /// This should be called on app start after billing service connection
  /// to ensure we have the latest purchase state from Google Play.
  Future<void> restoreFromBillingService() async {
    if (_isRestoring) return;

    _isRestoring = true;
    _lastError = null;
    notifyListeners();

    try {
      // Query current purchases from billing service
      final queryResult = await BillingChannel.queryPurchases();
      
      if (!queryResult.isSuccess) {
        _lastError = 'Failed to query purchases: ${queryResult.debugMessage}';
        return;
      }

      // Get current purchases
      final purchases = await BillingChannel.getCurrentPurchases();
      
      // Process each purchase
      for (final purchase in purchases) {
        if (purchase.isValid && ProductIds.isProProduct(purchase.productId ?? '')) {
          await _processPurchase(purchase);
        }
      }

      // Update Pro status based on stored receipts
      await _updateProStatusFromReceipts();
      
    } catch (e) {
      _lastError = 'Restore failed: $e';
    } finally {
      _isRestoring = false;
      notifyListeners();
    }
  }

  /// Process a new purchase (called after successful purchase)
  Future<void> processPurchase(PurchaseInfo purchase) async {
    await _processPurchase(purchase);
    await _updateProStatusFromReceipts();
    notifyListeners();
  }

  /// Handle purchase updates from billing service
  Future<void> onPurchaseUpdated(List<PurchaseInfo> purchases) async {
    for (final purchase in purchases) {
      if (ProductIds.isProProduct(purchase.productId ?? '')) {
        await _processPurchase(purchase);
      }
    }
    
    await _updateProStatusFromReceipts();
    notifyListeners();
  }

  /// Manually activate Pro (for testing or special cases)
  void setProActive(bool active, {String? productId, PurchaseInfo? purchase}) {
    _isProActive = active;
    _activeProductId = active ? productId : null;
    _activePurchase = active ? purchase : null;
    notifyListeners();
  }

  /// Clear error state
  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  /// Get Pro state summary for debugging
  Map<String, dynamic> getDebugInfo() {
    return {
      'isProActive': _isProActive,
      'isInitialized': _isInitialized,
      'isRestoring': _isRestoring,
      'activeProductId': _activeProductId,
      'activePurchaseToken': _activePurchase?.purchaseToken,
      'receiptCount': _receiptStore.receiptCount,
      'lastError': _lastError,
      'hasValidReceipts': _receiptStore.hasValidProReceipt(),
    };
  }

  /// Reset instance for testing (test use only)
  static void resetInstance() {
    _instance = null;
  }

  /// Internal: Process a purchase and store receipt if valid
  Future<void> _processPurchase(PurchaseInfo purchase) async {
    try {
      final productId = purchase.productId;
      if (productId == null) return;
      
      // Handle pending purchases
      if (purchase.isPending) {
        _pendingPurchases[productId] = purchase;
        // Pending purchases don't make Pro active, just track them
        notifyListeners();
        return;
      }
      
      // Remove from pending if this purchase is now complete
      if (_pendingPurchases.containsKey(productId)) {
        _pendingPurchases.remove(productId);
      }
      
      // Process completed purchase
      if (purchase.isValid && ProductIds.isProProduct(productId)) {
        await _receiptStore.saveReceipt(purchase);
        
        // Update Pro status
        await _updateProStatusFromReceipts();
        
        // Acknowledge purchase if not already acknowledged
        if (!purchase.acknowledged && purchase.purchaseToken != null) {
          final ackResult = await BillingChannel.acknowledgePurchase(purchase.purchaseToken!);
          if (!ackResult.isSuccess) {
            // Log acknowledgment failure but don't fail the whole operation
            _lastError = 'Failed to acknowledge purchase: ${ackResult.debugMessage}';
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      _lastError = 'Failed to process purchase: $e';
      notifyListeners();
    }
  }

  /// Internal: Restore Pro status from local receipt store
  Future<void> _restoreFromLocalReceipts() async {
    await _updateProStatusFromReceipts();
  }

  /// Internal: Update Pro status based on stored receipts
  Future<void> _updateProStatusFromReceipts() async {
    final hasValidReceipt = _receiptStore.hasValidProReceipt();
    final mostRecentPurchase = _receiptStore.getMostRecentProPurchase();

    _isProActive = hasValidReceipt;
    _activeProductId = mostRecentPurchase?.productId;
    _activePurchase = mostRecentPurchase;
  }
}

/// Pro subscription info for UI display
class ProSubscriptionInfo {
  final bool isActive;
  final String? productId;
  final String? displayName;
  final DateTime? purchaseDate;
  final bool isAutoRenewing;
  final String? subscriptionPeriod;

  const ProSubscriptionInfo({
    required this.isActive,
    this.productId,
    this.displayName,
    this.purchaseDate,
    this.isAutoRenewing = false,
    this.subscriptionPeriod,
  });

  /// Create from current Pro state
  static ProSubscriptionInfo fromProState(ProState proState) {
    final purchase = proState.activePurchase;
    
    return ProSubscriptionInfo(
      isActive: proState.isProActive,
      productId: proState.activeProductId,
      displayName: proState.activeProductId != null 
          ? SubscriptionDisplayNames.forProductId(proState.activeProductId!)
          : null,
      purchaseDate: purchase?.purchaseDateTime,
      isAutoRenewing: purchase?.autoRenewing ?? false,
      subscriptionPeriod: _getSubscriptionPeriod(proState.activeProductId),
    );
  }

  /// Get human-readable subscription period
  static String? _getSubscriptionPeriod(String? productId) {
    switch (productId) {
      case ProductIds.proMonthly:
        return 'Monthly';
      case ProductIds.proYearly:
        return 'Yearly';
      default:
        return null;
    }
  }

  @override
  String toString() => 
      'ProSubscriptionInfo(active: $isActive, product: $displayName)';
}
/// Play Billing Pro Manager for MindTrainer
/// 
/// Integrates Play Billing adapter with Pro subscription management.
/// Handles purchase flows, state synchronization, and fake events for testing.

import 'dart:async';
import 'play_billing_adapter.dart';
import 'real_play_billing_adapter.dart';
import 'pro_catalog.dart';
import 'pro_status.dart';
import 'subscription_gateway.dart';
import '../../payments/entitlement_resolver.dart';

/// Pro Manager with Play Billing integration
class PlayBillingProManager {
  final PlayBillingAdapter _adapter;
  final ProCatalog _baseCatalog;
  final EntitlementResolver _entitlementResolver;
  
  StreamSubscription<List<BillingPurchase>>? _purchaseSubscription;
  StreamSubscription<BillingConnectionState>? _connectionSubscription;
  
  ProStatus _currentStatus = const ProStatus.free();
  ProCatalog _catalog;
  BillingConnectionState _connectionState = BillingConnectionState.disconnected;
  
  /// Stream controller for purchase events (for testing)
  final StreamController<PurchaseEvent> _purchaseEventController =
      StreamController<PurchaseEvent>.broadcast();
  
  PlayBillingProManager(this._adapter, this._baseCatalog, this._entitlementResolver)
      : _catalog = _baseCatalog;
  
  /// Factory constructor that uses the appropriate billing adapter based on build mode
  factory PlayBillingProManager.create(ProCatalog catalog) {
    final adapter = PlayBillingAdapterFactory.create();
    return PlayBillingProManager(adapter, catalog, EntitlementResolver.instance);
  }
  
  /// Factory constructor for testing with fake adapter
  factory PlayBillingProManager.fake(ProCatalog catalog, {
    bool simulateConnectionFailure = false,
    bool simulatePurchaseFailure = false,
    bool simulateUserCancel = false,
  }) {
    final adapter = PlayBillingAdapterFactory.createFake(
      simulateConnectionFailure: simulateConnectionFailure,
      simulatePurchaseFailure: simulatePurchaseFailure,
      simulateUserCancel: simulateUserCancel,
    );
    return PlayBillingProManager(adapter, catalog, EntitlementResolver.instance);
  }
  
  /// Current Pro status
  ProStatus get currentStatus => _currentStatus;
  
  /// Current Pro catalog with billing product info
  ProCatalog get catalog => _catalog;
  
  /// Current billing connection state
  BillingConnectionState get connectionState => _connectionState;
  
  /// Whether Pro features are currently active
  bool get isProActive => _entitlementResolver.isPro;
  
  /// Stream of purchase events (for testing and UI feedback)
  Stream<PurchaseEvent> get purchaseEventStream => _purchaseEventController.stream;
  
  /// Initialize the manager and connect to Play Billing
  Future<bool> initialize() async {
    try {
      // Initialize entitlement resolver first
      await _entitlementResolver.initialize();
      
      // Set up connection state monitoring
      _connectionSubscription = _adapter.connectionStateStream.listen((state) {
        _connectionState = state;
        if (state == BillingConnectionState.connected) {
          _loadCatalogWithBillingInfo();
          _queryExistingPurchases();
        }
      });
      
      // Set up purchase monitoring
      _purchaseSubscription = _adapter.purchaseUpdateStream.listen((purchases) {
        _processPurchaseUpdates(purchases);
      });
      
      // Connect to billing service
      final result = await _adapter.startConnection();
      
      // If connection succeeded, load catalog immediately
      if (result.success) {
        await _loadCatalogWithBillingInfo();
        await _queryExistingPurchases();
      }
      
      return result.success;
    } catch (e) {
      return false;
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    await _connectionSubscription?.cancel();
    await _purchaseEventController.close();
    await _adapter.endConnection();
  }
  
  /// Launch purchase flow for a specific plan
  Future<PurchaseFlowResult> purchasePlan(String productId) async {
    if (_connectionState != BillingConnectionState.connected) {
      _emitPurchaseEvent(PurchaseEvent.failed(
        productId: productId,
        error: 'Not connected to Play Billing',
      ));
      return PurchaseFlowResult.error('Not connected to Play Billing');
    }
    
    final plan = _catalog.findPlanById(productId);
    if (plan == null) {
      _emitPurchaseEvent(PurchaseEvent.failed(
        productId: productId,
        error: 'Plan not found',
      ));
      return PurchaseFlowResult.error('Plan not found');
    }
    
    _emitPurchaseEvent(PurchaseEvent.started(productId: productId));
    
    try {
      final result = await _adapter.launchSubscriptionPurchaseFlow(productId);
      
      if (result.success) {
        // Purchase success will be handled via purchaseUpdateStream
        return PurchaseFlowResult.success();
      } else if (result.responseCode == 1) {
        _emitPurchaseEvent(PurchaseEvent.cancelled(productId: productId));
        return PurchaseFlowResult.cancelled();
      } else {
        final errorMsg = result.debugMessage ?? 'Purchase failed';
        _emitPurchaseEvent(PurchaseEvent.failed(
          productId: productId,
          error: errorMsg,
        ));
        return PurchaseFlowResult.error(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Purchase exception: $e';
      _emitPurchaseEvent(PurchaseEvent.failed(
        productId: productId,
        error: errorMsg,
      ));
      return PurchaseFlowResult.error(errorMsg);
    }
  }
  
  /// Restore previous purchases
  Future<bool> restorePurchases() async {
    try {
      final purchases = await _adapter.queryPurchases();
      _processPurchaseUpdates(purchases);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if billing service is available
  Future<bool> isBillingAvailable() async {
    return await _adapter.isSubscriptionSupported();
  }
  
  /// Load catalog with actual billing product information
  Future<void> _loadCatalogWithBillingInfo() async {
    try {
      final products = await _adapter.querySubscriptionProducts(_baseCatalog.productIds);
      _catalog = _baseCatalog.withBillingProducts(products);
    } catch (e) {
      // Keep base catalog on error
      _catalog = _baseCatalog;
    }
  }
  
  /// Query and process existing purchases
  Future<void> _queryExistingPurchases() async {
    try {
      final purchases = await _adapter.queryPurchases();
      _processPurchaseUpdates(purchases);
    } catch (e) {
      // Ignore query errors - stay with current status
    }
  }
  
  /// Process purchase updates from billing service
  void _processPurchaseUpdates(List<BillingPurchase> purchases) {
    // Convert billing purchases to purchase info maps
    final purchaseInfos = purchases.map((p) => {
      'purchaseToken': p.purchaseToken,
      'productId': p.productId,
      'purchaseState': p.state == PurchaseState.purchased ? 'purchased' : 
                     p.state == PurchaseState.pending ? 'pending' : 'cancelled',
      'purchaseTime': p.purchaseTime,
      'acknowledged': p.acknowledged,
      'source': 'play_billing',
      'autoRenewing': p.autoRenewing,
    }).toList();
    
    // Process through entitlement resolver
    _entitlementResolver.processReceiptsFromBilling(purchaseInfos);
    
    // Update legacy ProStatus for backward compatibility
    final entitlement = _entitlementResolver.currentEntitlement;
    if (entitlement.isPro && !entitlement.isExpired) {
      _currentStatus = ProStatus.activePro(
        expiresAt: entitlement.until,
        autoRenewing: true, // Assume auto-renewing for active subscriptions
      );
    } else {
      _currentStatus = const ProStatus.free();
    }
    
    // Emit purchase events for active purchases
    final activePurchases = purchases.where((p) => 
        p.state == PurchaseState.purchased &&
        (_catalog.findPlanById(p.productId) != null)
    ).toList();
    
    for (final purchase in activePurchases) {
      _emitPurchaseEvent(PurchaseEvent.completed(
        productId: purchase.productId,
        purchaseToken: purchase.purchaseToken,
      ));
      
      // Acknowledge purchase if not already acknowledged
      if (!purchase.acknowledged) {
        _adapter.acknowledgePurchase(purchase.purchaseToken);
      }
    }
  }
  
  /// Emit purchase event for testing and UI feedback
  void _emitPurchaseEvent(PurchaseEvent event) {
    if (!_purchaseEventController.isClosed) {
      _purchaseEventController.add(event);
    }
  }
}

/// Purchase flow result
class PurchaseFlowResult {
  final bool success;
  final bool cancelled;
  final String? error;
  
  const PurchaseFlowResult({
    required this.success,
    this.cancelled = false,
    this.error,
  });
  
  const PurchaseFlowResult.success() : this(success: true);
  const PurchaseFlowResult.cancelled() : this(success: false, cancelled: true);
  const PurchaseFlowResult.error(String error) : this(success: false, error: error);
  
  @override
  String toString() {
    if (success) return 'PurchaseFlowResult.success';
    if (cancelled) return 'PurchaseFlowResult.cancelled';
    return 'PurchaseFlowResult.error($error)';
  }
}

/// Purchase event for testing and UI feedback
class PurchaseEvent {
  final PurchaseEventType type;
  final String productId;
  final String? purchaseToken;
  final String? error;
  final DateTime timestamp;
  
  PurchaseEvent({
    required this.type,
    required this.productId,
    this.purchaseToken,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  PurchaseEvent.started({required String productId})
      : this(type: PurchaseEventType.started, productId: productId);
  
  PurchaseEvent.completed({
    required String productId,
    required String purchaseToken,
  }) : this(
    type: PurchaseEventType.completed,
    productId: productId,
    purchaseToken: purchaseToken,
  );
  
  PurchaseEvent.cancelled({required String productId})
      : this(type: PurchaseEventType.cancelled, productId: productId);
  
  PurchaseEvent.failed({
    required String productId,
    required String error,
  }) : this(
    type: PurchaseEventType.failed,
    productId: productId,
    error: error,
  );
  
  @override
  String toString() => 'PurchaseEvent($type: $productId)';
}

/// Purchase event types
enum PurchaseEventType {
  /// Purchase flow started
  started,
  /// Purchase completed successfully
  completed,
  /// Purchase cancelled by user
  cancelled,
  /// Purchase failed with error
  failed,
}

/// Enhanced ProManager that implements the original interface
/// but uses Play Billing under the hood
class PlayBillingProManagerAdapter implements SubscriptionGateway {
  final PlayBillingProManager _manager;
  
  PlayBillingProManagerAdapter(this._manager);
  
  @override
  Future<ProStatus> getCurrentStatus() async {
    return _manager.currentStatus;
  }
  
  @override
  Future<SubscriptionResult> purchaseSubscription(SubscriptionProduct product) async {
    final productId = product == SubscriptionProduct.proMonthly 
        ? 'pro_monthly' 
        : 'pro_yearly';
    
    final result = await _manager.purchasePlan(productId);
    
    if (result.success) {
      return SubscriptionResult.success(_manager.currentStatus);
    } else if (result.cancelled) {
      return const SubscriptionResult.error('Purchase cancelled by user');
    } else {
      return SubscriptionResult.error(result.error ?? 'Purchase failed');
    }
  }
  
  @override
  Future<SubscriptionResult> restorePurchases() async {
    final success = await _manager.restorePurchases();
    
    if (success) {
      return SubscriptionResult.success(_manager.currentStatus);
    } else {
      return const SubscriptionResult.error('Failed to restore purchases');
    }
  }
  
  @override
  Future<SubscriptionResult> cancelSubscription() async {
    // Note: Actual cancellation is handled through Play Store UI
    // This is just for consistency with the interface
    return const SubscriptionResult.error('Cancellation handled through Play Store');
  }
  
  @override
  Future<bool> isBillingAvailable() async {
    return await _manager.isBillingAvailable();
  }
}
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'billing_adapter.dart';
import 'entitlement_resolver.dart';
import 'stores/price_cache_store.dart';
import 'models/price_cache.dart';
import 'models/entitlement.dart';

class PaywallVM extends ChangeNotifier {
  static PaywallVM? _instance;
  
  final EntitlementResolver _entitlementResolver;
  final PriceCacheStore _priceCacheStore;
  final BillingAdapter _billingAdapter;
  
  StreamSubscription<Entitlement>? _entitlementSubscription;
  
  bool _isPro = false;
  String? _monthlyPrice;
  String? _yearlyPrice;
  bool _pricesStale = false;
  bool _isBusy = false;
  String? _error;
  bool _offline = false;
  DateTime _lastActionTime = DateTime.fromMillisecondsSinceEpoch(0);
  
  static const Duration _debounceDelay = Duration(milliseconds: 800);
  static const Duration _priceStaleThreshold = Duration(hours: 48);

  PaywallVM._(this._entitlementResolver, this._priceCacheStore, this._billingAdapter);

  static PaywallVM get instance {
    _instance ??= PaywallVM._(
      EntitlementResolver.instance,
      PriceCacheStore.instance,
      BillingAdapter.instance,
    );
    return _instance!;
  }

  // Getters
  bool get isPro => _isPro;
  String? get monthlyPrice => _monthlyPrice;
  String? get yearlyPrice => _yearlyPrice;
  bool get pricesStale => _pricesStale;
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get offline => _offline;

  Future<void> initialize() async {
    await _entitlementResolver.initialize();
    await _billingAdapter.initialize();
    
    // Subscribe to entitlement changes
    _entitlementSubscription = _entitlementResolver.entitlementStream.listen((entitlement) {
      _isPro = entitlement.isPro;
      notifyListeners();
    });
    
    // Load initial state
    _isPro = _entitlementResolver.isPro;
    await _updateFromCache();
  }

  Future<void> _updateFromCache() async {
    try {
      final cache = await _priceCacheStore.getCache();
      
      if (cache.isEmpty) {
        _monthlyPrice = null;
        _yearlyPrice = null;
        _pricesStale = false;
      } else {
        _monthlyPrice = cache.getPriceForProduct('mindtrainer_pro_monthly') ?? 
                       cache.getPriceForProduct('pro_monthly');
        _yearlyPrice = cache.getPriceForProduct('mindtrainer_pro_yearly') ?? 
                      cache.getPriceForProduct('pro_yearly');
        
        _pricesStale = cache.age > _priceStaleThreshold;
      }
      
      _offline = false; // Successfully read cache
      _error = null;
    } catch (e) {
      // Cache read failed, but don't mark as offline unless it's a known offline error
      _monthlyPrice = null;
      _yearlyPrice = null;
      _pricesStale = false;
    }
    
    notifyListeners();
  }

  Future<void> _withBusy(Future<void> Function() action) async {
    if (_isBusy) return;
    
    _isBusy = true;
    _error = null;
    notifyListeners();
    
    try {
      await action();
    } catch (e) {
      _error = _mapError(e);
      _offline = _isOfflineError(e);
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  bool _shouldDebounce() {
    final now = DateTime.now();
    if (now.difference(_lastActionTime) < _debounceDelay) {
      return true;
    }
    _lastActionTime = now;
    return false;
  }

  Future<void> buyMonthly() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.purchase('mindtrainer_pro_monthly');
    });
  }

  Future<void> buyYearly() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.purchase('mindtrainer_pro_yearly');
    });
  }

  Future<void> restore() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.queryPurchases();
    });
  }

  Future<void> manage() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.manageSubscriptions();
    });
  }

  String _mapError(dynamic error) {
    // Handle BillingException specifically
    if (error is BillingException) {
      switch (error.code) {
        case 'purchase_canceled':
          return 'Purchase canceled';
        case 'already_owned':
          return 'Already owned';
        case 'offline':
          return 'Offline';
        case 'manage_subscriptions_not_available':
          return 'Open Google Play Store to manage subscriptions';
        default:
          return 'Try again';
      }
    }
    
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('cancel')) {
      return 'Purchase canceled';
    } else if (errorStr.contains('already') || errorStr.contains('owned')) {
      return 'Already owned';
    } else if (errorStr.contains('offline') || errorStr.contains('network') || errorStr.contains('unavailable')) {
      return 'Offline';
    } else if (errorStr.contains('restore_failed')) {
      return 'Restore failed. Try again.';
    } else if (errorStr.contains('manage_subscriptions_not_available')) {
      return 'Open Google Play Store to manage subscriptions';
    } else {
      return 'Try again';
    }
  }

  bool _isOfflineError(dynamic error) {
    // Handle BillingException specifically
    if (error is BillingException) {
      return error.code == 'offline';
    }
    
    final errorStr = error.toString().toLowerCase();
    return errorStr.contains('offline') || 
           errorStr.contains('network') || 
           errorStr.contains('unavailable') ||
           errorStr.contains('connection');
  }

  void clearError() {
    _error = null;
    _offline = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _entitlementSubscription?.cancel();
    super.dispose();
  }

  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

}
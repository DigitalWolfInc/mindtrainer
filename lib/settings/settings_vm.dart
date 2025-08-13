/// Settings ViewModel for MindTrainer
/// 
/// Centralizes Pro status, data management, privacy settings, and diagnostics.
/// Integrates with existing EntitlementResolver, BillingAdapter, and export/import services.

import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../payments/entitlement_resolver.dart';
import '../payments/billing_adapter.dart';
import '../payments/stores/price_cache_store.dart';
import '../payments/models/price_cache.dart';
import '../payments/models/entitlement.dart';
import '../features/focus_session/domain/io_service.dart';
import 'email_optin_store.dart';
import 'diagnostics.dart';

class SettingsVM extends ChangeNotifier {
  /// Helper to extract product ID from entitlement
  /// Handles different possible field names without changing the model
  /// @visibleForTesting
  static String? _productIdOf(Entitlement e) {
    final d = e as dynamic;
    try {
      final v = d.productId;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = d.identifier;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final v = d.id;
      if (v is String && v.isNotEmpty) return v;
    } catch (_) {}
    return null;
  }
  static SettingsVM? _instance;
  static SettingsVM get instance => _instance ??= SettingsVM._();
  
  SettingsVM._();
  
  final EntitlementResolver _entitlementResolver = EntitlementResolver.instance;
  final BillingAdapter _billingAdapter = BillingAdapter.instance;
  final PriceCacheStore _priceCacheStore = PriceCacheStore.instance;
  final EmailOptInStore _emailStore = EmailOptInStore.instance;
  
  StreamSubscription<Entitlement>? _entitlementSubscription;
  DateTime _lastActionTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _debounceDelay = Duration(milliseconds: 800);
  
  // State
  bool _isPro = false;
  String? _productId;
  String? _monthlyPrice;
  String? _yearlyPrice;
  bool _pricesStale = false;
  bool _busy = false;
  String? _status;
  bool _emailOptIn = false;
  List<String> _diagLines = [];
  
  // Getters
  bool get isPro => _isPro;
  String get proLabel => _isPro ? 'Pro — thanks!' : 'Free';
  String? get productId => _productId;
  String? get monthlyPrice => _monthlyPrice;
  String? get yearlyPrice => _yearlyPrice;
  bool get pricesStale => _pricesStale;
  bool get busy => _busy;
  String? get status => _status;
  bool get emailOptIn => _emailOptIn;
  List<String> get diagLines => List.unmodifiable(_diagLines);
  
  /// Initialize the Settings VM
  Future<void> initialize() async {
    // Initialize stores
    await _emailStore.init();
    _emailOptIn = _emailStore.optedIn;
    
    // Subscribe to entitlement changes
    _entitlementSubscription = _entitlementResolver.entitlementStream.listen((entitlement) {
      _isPro = entitlement.isPro;
      _productId = entitlement.isPro ? _productIdOf(entitlement) : null;
      notifyListeners();
    });
    
    // Load initial entitlement state
    _isPro = _entitlementResolver.isPro;
    final currentEntitlement = _entitlementResolver.currentEntitlement;
    _productId = currentEntitlement.isPro ? _productIdOf(currentEntitlement) : null;
    
    // Load price cache
    await _loadPriceCache();
    
    // Load initial diagnostics
    refreshDiagnostics();
    
    notifyListeners();
  }
  
  /// Load price cache for display
  Future<void> _loadPriceCache() async {
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
        
        _pricesStale = cache.age > Duration(hours: 48);
      }
    } catch (e) {
      _monthlyPrice = null;
      _yearlyPrice = null;
      _pricesStale = false;
    }
  }
  
  /// Check if action should be debounced
  bool _shouldDebounce() {
    final now = DateTime.now();
    if (now.difference(_lastActionTime) < _debounceDelay) {
      return true;
    }
    _lastActionTime = now;
    return false;
  }
  
  /// Execute action with busy state and error handling
  Future<void> _withBusy(Future<void> Function() action) async {
    if (_busy) return;
    
    _busy = true;
    _status = null;
    notifyListeners();
    
    try {
      await action();
    } catch (e) {
      _status = _mapError(e);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
  
  /// Buy monthly subscription
  Future<void> buyMonthly() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.purchase('mindtrainer_pro_monthly');
      _status = 'Purchase initiated';
    });
  }
  
  /// Buy yearly subscription
  Future<void> buyYearly() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.purchase('mindtrainer_pro_yearly');
      _status = 'Purchase initiated';
    });
  }
  
  /// Restore purchases
  Future<void> restore() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.queryPurchases();
      _status = 'Restore completed';
    });
  }
  
  /// Manage subscriptions
  Future<void> manage() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _billingAdapter.manageSubscriptions();
      _status = 'Opening subscription management';
    });
  }
  
  /// Toggle email opt-in preference
  Future<void> toggleEmailOptIn(bool value) async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      await _emailStore.setOptIn(value);
      _emailOptIn = value;
      _status = value ? 'Email updates enabled' : 'Email updates disabled';
    });
  }
  
  /// Export sessions to default location
  Future<void> exportSessions() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // Export both CSV and JSON
      final csvPath = path.join(dir.path, 'mindtrainer_sessions_$timestamp.csv');
      final jsonPath = path.join(dir.path, 'mindtrainer_sessions_$timestamp.json');
      
      final csvResult = await FocusSessionIOService.exportCsv(csvPath);
      final jsonResult = await FocusSessionIOService.exportJson(jsonPath);
      
      if (csvResult.success && jsonResult.success) {
        _status = 'Exported to Documents folder (CSV + JSON)';
      } else if (csvResult.success) {
        _status = 'Exported CSV to Documents folder';
      } else if (jsonResult.success) {
        _status = 'Exported JSON to Documents folder';
      } else {
        throw Exception('Export failed');
      }
    });
  }
  
  /// Import sessions from default location
  Future<void> importSessions() async {
    if (_shouldDebounce()) return;
    
    await _withBusy(() async {
      final dir = await getApplicationDocumentsDirectory();
      
      // Look for the most recent JSON file
      final files = await dir.list().toList();
      final jsonFiles = files
          .whereType<io.File>()
          .where((f) => f.path.contains('mindtrainer_sessions_') && f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      if (jsonFiles.isEmpty) {
        _status = 'No import files found in Documents folder';
        return;
      }
      final importFile = jsonFiles.first;
      
      final result = await FocusSessionIOService.importJson(importFile.path);
      
      if (result.success) {
        _status = result.data ?? 'Import completed';
      } else {
        throw Exception(result.errorMessage ?? 'Import failed');
      }
    });
  }
  
  /// Refresh diagnostics data
  void refreshDiagnostics() {
    _diagLines = Diag.dump();
    notifyListeners();
  }
  
  /// Clear status message
  void clearStatus() {
    _status = null;
    notifyListeners();
  }
  
  /// Map errors to user-friendly messages
  String _mapError(dynamic error) {
    if (error is BillingException) {
      switch (error.code) {
        case 'purchase_canceled':
          return 'Canceled';
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
      return 'Canceled';
    } else if (errorStr.contains('network') || errorStr.contains('offline')) {
      return 'Offline';
    } else {
      return 'Try again';
    }
  }
  
  @override
  void dispose() {
    _entitlementSubscription?.cancel();
    super.dispose();
  }
  
  /// Reset instance for testing
  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }
}
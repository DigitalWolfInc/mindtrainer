/// Pro Manager for MindTrainer
/// 
/// Central manager for Pro subscription status and feature gating.
/// Coordinates with subscription gateway and provides feature access control.

import 'pro_status.dart';
import 'subscription_gateway.dart';

/// Manager for Pro subscription features and status
class ProManager {
  final SubscriptionGateway _gateway;
  ProStatus _cachedStatus = const ProStatus.free();
  DateTime? _lastRefresh;
  
  ProManager(this._gateway);
  
  /// Get current Pro status (cached with refresh logic)
  ProStatus get current => _cachedStatus;
  
  /// Whether Pro features are currently available
  bool get isProActive => _cachedStatus.isPro && !_cachedStatus.isExpired;
  
  /// Refresh subscription status from gateway
  Future<ProStatus> refreshStatus() async {
    try {
      _cachedStatus = await _gateway.getCurrentStatus();
      _lastRefresh = DateTime.now();
      return _cachedStatus;
    } catch (e) {
      // On error, keep existing cached status
      return _cachedStatus;
    }
  }
  
  /// Purchase Pro subscription
  Future<SubscriptionResult> purchaseSubscription(SubscriptionProduct product) async {
    final result = await _gateway.purchaseSubscription(product);
    
    // Update cached status if purchase succeeded
    if (result.success && result.status != null) {
      _cachedStatus = result.status!;
      _lastRefresh = DateTime.now();
    }
    
    return result;
  }
  
  /// Restore previous purchases
  Future<SubscriptionResult> restorePurchases() async {
    final result = await _gateway.restorePurchases();
    
    // Update cached status if restore succeeded
    if (result.success && result.status != null) {
      _cachedStatus = result.status!;
      _lastRefresh = DateTime.now();
    }
    
    return result;
  }
  
  /// Cancel active subscription
  Future<SubscriptionResult> cancelSubscription() async {
    final result = await _gateway.cancelSubscription();
    
    // Update cached status if cancellation succeeded
    if (result.success && result.status != null) {
      _cachedStatus = result.status!;
      _lastRefresh = DateTime.now();
    }
    
    return result;
  }
  
  /// Check if subscription status needs refresh (older than 1 hour)
  bool get needsRefresh {
    if (_lastRefresh == null) return true;
    final hourAgo = DateTime.now().subtract(const Duration(hours: 1));
    return _lastRefresh!.isBefore(hourAgo);
  }
  
  /// Initialize manager with initial status check
  Future<void> initialize() async {
    await refreshStatus();
  }
}

/// Default feature gate that unlocks all Pro features when subscription is active
class DefaultProGate {
  final ProManager _proManager;
  
  const DefaultProGate(this._proManager);
  
  /// Whether unlimited focus sessions are available
  bool get unlimitedSessions => _proManager.isProActive;
  
  /// Whether advanced insights are available
  bool get advancedInsights => _proManager.isProActive;
  
  /// Whether export/import features are available
  bool get dataExport => _proManager.isProActive;
  
  /// Whether coaching features are available
  bool get coachingFeatures => _proManager.isProActive;
  
  /// Whether premium themes are available
  bool get premiumThemes => _proManager.isProActive;
  
  /// Whether ad-free experience is active
  bool get adFree => _proManager.isProActive;
  
  /// Get list of all Pro features (for display in UI)
  List<String> get proFeatures => [
    'Unlimited focus sessions',
    'Advanced insights and analytics',
    'Data export and backup',
    'AI coaching conversations',
    'Premium themes and customization',
    'Ad-free experience',
  ];
}
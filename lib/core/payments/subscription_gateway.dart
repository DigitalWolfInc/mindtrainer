/// Subscription Gateway Port for MindTrainer
/// 
/// Abstracts platform-specific payment processing (Google Play Billing, App Store, etc.)
/// Implementation will be added later with actual SDK integration.

import 'pro_status.dart';

/// Result of a subscription operation
class SubscriptionResult {
  final bool success;
  final ProStatus? status;
  final String? errorMessage;
  
  const SubscriptionResult({
    required this.success,
    this.status,
    this.errorMessage,
  });
  
  /// Create successful result
  const SubscriptionResult.success(ProStatus status)
      : this(success: true, status: status);
  
  /// Create error result
  const SubscriptionResult.error(String message)
      : this(success: false, errorMessage: message);
}

/// Available subscription products
enum SubscriptionProduct {
  /// Monthly Pro subscription ($10/month)
  proMonthly,
  /// Yearly Pro subscription ($100/year)  
  proYearly,
}

/// Abstract gateway for subscription operations
abstract class SubscriptionGateway {
  /// Get current subscription status
  Future<ProStatus> getCurrentStatus();
  
  /// Initiate subscription purchase flow
  Future<SubscriptionResult> purchaseSubscription(SubscriptionProduct product);
  
  /// Restore previous purchases
  Future<SubscriptionResult> restorePurchases();
  
  /// Cancel active subscription
  Future<SubscriptionResult> cancelSubscription();
  
  /// Check if billing service is available
  Future<bool> isBillingAvailable();
}

/// Fake implementation for testing and development
class FakeSubscriptionGateway implements SubscriptionGateway {
  ProStatus _currentStatus;
  final bool _billingAvailable;
  
  FakeSubscriptionGateway({
    ProStatus? initialStatus,
    bool billingAvailable = true,
  }) : _currentStatus = initialStatus ?? const ProStatus.free(),
       _billingAvailable = billingAvailable;
  
  @override
  Future<ProStatus> getCurrentStatus() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentStatus;
  }
  
  @override
  Future<SubscriptionResult> purchaseSubscription(SubscriptionProduct product) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!_billingAvailable) {
      return const SubscriptionResult.error('Billing service not available');
    }
    
    // Simulate successful purchase
    final expiresAt = DateTime.now().add(
      product == SubscriptionProduct.proMonthly
          ? const Duration(days: 30)
          : const Duration(days: 365)
    );
    
    _currentStatus = ProStatus.activePro(
      expiresAt: expiresAt,
      autoRenewing: true,
    );
    
    return SubscriptionResult.success(_currentStatus);
  }
  
  @override
  Future<SubscriptionResult> restorePurchases() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (!_billingAvailable) {
      return const SubscriptionResult.error('Billing service not available');
    }
    
    // For fake implementation, just return current status
    return SubscriptionResult.success(_currentStatus);
  }
  
  @override
  Future<SubscriptionResult> cancelSubscription() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    _currentStatus = const ProStatus.free();
    return SubscriptionResult.success(_currentStatus);
  }
  
  @override
  Future<bool> isBillingAvailable() async {
    return _billingAvailable;
  }
  
  /// Test helper to manually set status
  void setStatus(ProStatus status) {
    _currentStatus = status;
  }
}
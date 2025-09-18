/// Centralized timeout constants for MindTrainer billing and UI operations
/// 
/// This module eliminates hardcoded 10-second timers and provides a single
/// source of truth for all timeout behavior across the application.

/// Centralized timeout constants
class Timeouts {
  // === Billing Operations ===
  
  /// Connection timeout for billing service startup
  static const Duration billingConnect = Duration(seconds: 6);
  
  /// Purchase flow timeout - how long to wait for purchase events
  static const Duration purchaseFlowGuard = Duration(seconds: 15);
  
  /// Restore purchases timeout - how long to wait for restore completion
  static const Duration restoreGuard = Duration(seconds: 8);
  
  // === UI Responsiveness ===
  
  /// Debounce delay for spinner/loading states to prevent flicker
  static const Duration spinnerDebounce = Duration(milliseconds: 250);
  
  /// Short delay for UI transitions and state changes
  static const Duration uiTransition = Duration(milliseconds: 300);
  
  // === Backoff and Retry ===
  
  /// Minimum backoff delay for retry operations
  static const Duration backoffMin = Duration(milliseconds: 200);
  
  /// Maximum backoff delay for retry operations (mirrors Android)
  static const Duration backoffMax = Duration(seconds: 5);
  
  // === Pending State Management ===
  
  /// How long to show "purchase pending" before switching to subtle reminder
  static const Duration pendingGracePeriod = Duration(minutes: 10);
  
  /// Interval for checking purchase status when pending
  static const Duration statusCheckInterval = Duration(seconds: 30);
  
  // Prevent instantiation
  Timeouts._();
}
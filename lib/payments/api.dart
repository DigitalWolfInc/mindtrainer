/// Purchase API for billing operations
/// 
/// Provides high-level API for purchase operations, including
/// startPurchase, warmProducts, and subscription management.

import 'dart:async';
import 'package:flutter/services.dart';
import '../foundation/clock.dart';
import '../foundation/timeouts.dart';
import 'billing_constants.dart';
import 'channel.dart';
import 'models.dart';

/// High-level purchase API wrapper
class PurchaseAPI {
  PurchaseAPI._();
  
  /// Clock for timeout handling - can be overridden for testing
  static Clock _clock = const SystemClock();
  
  /// Set the clock instance (primarily for testing)
  static void setClock(Clock clock) {
    _clock = clock;
  }
  
  /// Start a purchase flow for the specified product
  /// 
  /// This is the main entry point for initiating purchases from UI.
  /// The actual purchase outcome will be delivered via purchase update events.
  static Future<BillingResult> startPurchase(String productId) async {
    try {
      final result = await MethodChannel(BillingChannels.main).invokeMethod<Map<Object?, Object?>>(
        'startPurchase',
        {'productId': productId},
      );
      return BillingResult.fromMap(BillingChannel.castToStringMap(result ?? {}));
    } catch (e) {
      return BillingResult.error(BillingErrorCodes.unknownError, e.toString());
    }
  }
  
  /// Warm the ProductDetails cache with specified product IDs
  /// 
  /// This ensures price and product information is available for
  /// purchase events and restore operations.
  static Future<BillingResult> warmProducts([List<String>? productIds]) async {
    try {
      final ids = productIds ?? ProductIds.allSubscriptions;
      final result = await MethodChannel(BillingChannels.main).invokeMethod<Map<Object?, Object?>>(
        'warmProducts',
        {'productIds': ids},
      );
      return BillingResult.fromMap(BillingChannel.castToStringMap(result ?? {}));
    } catch (e) {
      return BillingResult.error(BillingErrorCodes.unknownError, e.toString());
    }
  }
  
  /// Change subscription from one product to another (placeholder)
  /// 
  /// This is a placeholder for subscription upgrade/downgrade functionality.
  /// Currently returns UNIMPLEMENTED until Play Console base plans are configured.
  static Future<BillingResult> changeSubscription({
    required String fromProductId,
    required String toProductId,
    String prorationMode = 'IMMEDIATE_WITH_TIME_PRORATION',
  }) async {
    try {
      final result = await MethodChannel(BillingChannels.main).invokeMethod<Map<Object?, Object?>>(
        'changeSubscription',
        {
          'fromProductId': fromProductId,
          'toProductId': toProductId,
          'prorationMode': prorationMode,
        },
      );
      return BillingResult.fromMap(BillingChannel.castToStringMap(result ?? {}));
    } catch (e) {
      // For now, return unimplemented - this will be enabled once Play Console is configured
      return BillingResult(
        responseCode: BillingResponseCodes.developerError,
        debugMessage: 'UNIMPLEMENTED: Subscription changes require Play Console base plan configuration',
      );
    }
  }
  
  /// Start a purchase with timeout guard
  /// 
  /// This wraps startPurchase with a timeout that triggers a user-friendly
  /// timeout state without failing the actual purchase flow.
  static Future<PurchaseFlowResult> startPurchaseWithGuard(
    String productId, {
    Duration? timeout,
    void Function()? onTimeout,
  }) async {
    timeout ??= Timeouts.purchaseFlowGuard;
    
    // Start the purchase immediately
    final purchaseResult = await startPurchase(productId);
    
    if (!purchaseResult.isSuccess) {
      return PurchaseFlowResult.error(purchaseResult);
    }
    
    // Set up a timeout guard
    Timer? timeoutTimer;
    bool hasTimedOut = false;
    
    timeoutTimer = _clock.timer(timeout, () {
      hasTimedOut = true;
      onTimeout?.call();
    });
    
    // Return success immediately - timeout handling is separate
    return PurchaseFlowResult.success(purchaseResult, () {
      if (!hasTimedOut) {
        timeoutTimer?.cancel();
      }
    });
  }
  
  /// Restore purchases with timeout guard
  static Future<BillingResult> restorePurchasesWithGuard({
    Duration? timeout,
    void Function()? onTimeout,
  }) async {
    timeout ??= Timeouts.restoreGuard;
    
    // This would call the actual restore method when implemented
    // For now, return a placeholder
    return BillingResult(
      responseCode: BillingResponseCodes.ok,
      debugMessage: 'Restore guard not yet implemented',
    );
  }
}

/// Purchase event origin constants  
class PurchaseOrigins {
  static const String purchase = 'purchase';
  static const String restore = 'restore';
  static const String unknown = 'unknown';
  
  // Prevent instantiation
  PurchaseOrigins._();
}

/// Result of a guarded purchase flow that includes timeout handling
class PurchaseFlowResult {
  final BillingResult billingResult;
  final bool isSuccess;
  final void Function()? _cleanup;
  
  PurchaseFlowResult._(this.billingResult, this.isSuccess, this._cleanup);
  
  /// Create a success result
  static PurchaseFlowResult success(BillingResult result, void Function()? cleanup) {
    return PurchaseFlowResult._(result, true, cleanup);
  }
  
  /// Create an error result
  static PurchaseFlowResult error(BillingResult result) {
    return PurchaseFlowResult._(result, false, null);
  }
  
  /// Clean up any pending timers or resources
  void dispose() {
    _cleanup?.call();
  }
}
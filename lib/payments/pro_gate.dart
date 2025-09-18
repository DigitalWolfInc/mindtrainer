import 'package:flutter/material.dart';
import 'entitlement_resolver.dart';

class ProGate {
  static final EntitlementResolver _resolver = EntitlementResolver.instance;
  
  /// Shows paywall if user is not Pro, returns true if gate intercepted
  static Future<bool> maybePromptPaywall(BuildContext context) async {
    if (_resolver.isPro) {
      return false; // User is Pro, no gate needed
    }
    
    // User is not Pro, show paywall
    await Navigator.of(context).pushNamed('/paywall');
    return true; // Gate intercepted
  }
  
  /// Soft-gate wrapper for actions - shows paywall if not Pro, otherwise executes action
  static Future<void> gatedAction(
    BuildContext context, 
    VoidCallback action, {
    String? debugName,
  }) async {
    final intercepted = await maybePromptPaywall(context);
    if (!intercepted) {
      // User is Pro, execute the action
      action();
    }
    // If intercepted, user saw paywall - no action executed
  }
  
  /// Check if user is Pro without showing paywall
  static bool get isPro => _resolver.isPro;
  
  /// Get current entitlement for debugging
  static String get entitlementDebug => _resolver.currentEntitlement.toString();
}

/// Convenience extension for BuildContext to easily access gating
extension ProGateContext on BuildContext {
  /// Shows paywall if user is not Pro, returns true if gate intercepted
  Future<bool> maybePromptPaywall() => ProGate.maybePromptPaywall(this);
  
  /// Soft-gate wrapper for actions
  Future<void> gatedAction(VoidCallback action, {String? debugName}) => 
      ProGate.gatedAction(this, action, debugName: debugName);
      
  /// Check if user is Pro without showing paywall
  bool get isPro => ProGate.isPro;
}
import 'dart:convert';
import 'dart:io';

/// Analytics tracking for Pro conversion funnels and drop-off points
/// Uses pure Dart implementation with local logging for privacy compliance
class ConversionAnalytics {
  static const String _logFile = 'conversion_analytics.log';
  static final ConversionAnalytics _instance = ConversionAnalytics._internal();
  
  factory ConversionAnalytics() => _instance;
  ConversionAnalytics._internal();
  
  /// Track user entering conversion funnel
  void trackFunnelEntry(String entryPoint, Map<String, dynamic>? context) {
    _logEvent('funnel_entry', {
      'entry_point': entryPoint,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'context': context ?? {},
    });
  }
  
  /// Track user progressing through funnel stages
  void trackFunnelStep(String step, String previousStep, Map<String, dynamic>? metadata) {
    _logEvent('funnel_step', {
      'step': step,
      'previous_step': previousStep,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata ?? {},
    });
  }
  
  /// Track user dropping off from funnel
  void trackFunnelDropOff(String dropOffPoint, String reason, Map<String, dynamic>? context) {
    _logEvent('funnel_drop_off', {
      'drop_off_point': dropOffPoint,
      'reason': reason,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'context': context ?? {},
    });
  }
  
  /// Track successful Pro conversion
  void trackConversion(String productId, String source, Map<String, dynamic>? metadata) {
    _logEvent('conversion_success', {
      'product_id': productId,
      'source': source,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata ?? {},
    });
  }
  
  /// Track Pro feature usage to measure engagement
  void trackProFeatureUsage(String feature, String action, Map<String, dynamic>? details) {
    _logEvent('pro_feature_usage', {
      'feature': feature,
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'details': details ?? {},
    });
  }
  
  /// Track upgrade prompts shown to users
  void trackUpgradePromptShown(String location, String promptType, Map<String, dynamic>? context) {
    _logEvent('upgrade_prompt_shown', {
      'location': location,
      'prompt_type': promptType,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'context': context ?? {},
    });
  }
  
  /// Track user interaction with upgrade prompts
  void trackUpgradePromptInteraction(String location, String action, Map<String, dynamic>? details) {
    _logEvent('upgrade_prompt_interaction', {
      'location': location,
      'action': action, // 'tap', 'dismiss', 'ignore'
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'details': details ?? {},
    });
  }
  
  /// Track billing flow events
  void trackBillingEvent(String event, String result, Map<String, dynamic>? metadata) {
    _logEvent('billing_event', {
      'event': event,
      'result': result,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata ?? {},
    });
  }
  
  /// Track user journey through app screens
  void trackScreenNavigation(String fromScreen, String toScreen, Map<String, dynamic>? context) {
    _logEvent('screen_navigation', {
      'from_screen': fromScreen,
      'to_screen': toScreen,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'context': context ?? {},
    });
  }
  
  /// Track user engagement metrics
  void trackEngagement(String metric, double value, Map<String, dynamic>? metadata) {
    _logEvent('engagement_metric', {
      'metric': metric,
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'metadata': metadata ?? {},
    });
  }
  
  /// Log analytics event to local file (privacy-first approach)
  void _logEvent(String eventType, Map<String, dynamic> data) {
    try {
      final event = {
        'event_type': eventType,
        'session_id': _getSessionId(),
        'user_type': _getUserType(),
        'data': data,
      };
      
      final logEntry = '${jsonEncode(event)}\n';
      
      // In a real implementation, this would use proper file I/O
      // For now, we'll just print to debug console
      print('ANALYTICS: $logEntry');
      
      // TODO: In production, write to secure local file or send to analytics service
      // _appendToLogFile(logEntry);
      
    } catch (e) {
      // Silent fail - never let analytics crash the app
      print('Analytics logging failed: $e');
    }
  }
  
  /// Get current session identifier
  String _getSessionId() {
    // In real implementation, this would be a persistent session ID
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }
  
  /// Get user type (free/pro)
  String _getUserType() {
    // In real implementation, this would check actual Pro status
    return 'free'; // Default assumption
  }
  
  /// Get analytics summary for debugging
  Map<String, dynamic> getAnalyticsSummary() {
    return {
      'session_id': _getSessionId(),
      'user_type': _getUserType(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'events_logged': 'see_debug_console', // In real implementation, count from file
    };
  }
  
  /// Clear analytics data (for privacy compliance)
  void clearAnalyticsData() {
    try {
      // TODO: In production, clear the log file
      print('ANALYTICS: Data cleared');
    } catch (e) {
      print('Analytics clear failed: $e');
    }
  }
}

/// Pre-defined conversion funnel steps
class ConversionFunnelSteps {
  static const String appLaunch = 'app_launch';
  static const String homeScreenView = 'home_screen_view';
  static const String proFeatureView = 'pro_feature_view';
  static const String upgradePromptView = 'upgrade_prompt_view';
  static const String upgradeDialogView = 'upgrade_dialog_view';
  static const String billingFlowStart = 'billing_flow_start';
  static const String purchaseComplete = 'purchase_complete';
  static const String proFeatureUnlock = 'pro_feature_unlock';
}

/// Pre-defined drop-off reasons
class DropOffReasons {
  static const String userDismissed = 'user_dismissed';
  static const String userCanceled = 'user_canceled';
  static const String billingError = 'billing_error';
  static const String networkError = 'network_error';
  static const String priceRejection = 'price_rejection';
  static const String featureNotUnderstood = 'feature_not_understood';
  static const String timingNotRight = 'timing_not_right';
}

/// Pre-defined entry points for conversion tracking
class ConversionEntryPoints {
  static const String homeScreenProBadge = 'home_screen_pro_badge';
  static const String analyticsLockedFeature = 'analytics_locked_feature';
  static const String analyticsUpgradeStar = 'analytics_upgrade_star';
  static const String sessionLimit = 'session_limit';
  static const String premiumFeatureBlocked = 'premium_feature_blocked';
  static const String settingsUpgrade = 'settings_upgrade';
  static const String organicDiscovery = 'organic_discovery';
}
/// Pro Conversion Analytics for MindTrainer
/// 
/// Tracks Pro subscription conversion events, drop-off points, and user behavior
/// for optimization and business intelligence.

import 'dart:async';

/// Pro conversion event types for analytics tracking
enum ProConversionEvent {
  /// User viewed Pro features/upgrade screen
  upgradeScreenViewed,
  /// User clicked upgrade CTA button
  upgradeCtaClicked,
  /// User started purchase flow
  purchaseFlowStarted,
  /// User completed purchase successfully
  purchaseCompleted,
  /// User cancelled purchase during flow
  purchaseCancelled,
  /// Purchase failed due to error
  purchaseFailed,
  /// User restored previous purchase
  purchaseRestored,
  /// User hit free tier limit (session limit, etc.)
  freeTierLimitHit,
  /// User viewed Pro feature while locked
  lockedFeatureViewed,
  /// User attempted to use locked Pro feature
  lockedFeatureAttempted,
  /// Pro feature was successfully used
  proFeatureUsed,
  /// User viewed Pro pricing/catalog
  pricingViewed,
  /// User compared free vs Pro features
  featureComparisonViewed,
}

/// Pro conversion analytics data point
class ProConversionData {
  /// Event type
  final ProConversionEvent event;
  
  /// Timestamp of the event
  final DateTime timestamp;
  
  /// User's current Pro status (free/pro)
  final String userTier;
  
  /// Feature or product involved
  final String? feature;
  
  /// Product ID for purchase events
  final String? productId;
  
  /// Error message for failed events
  final String? error;
  
  /// Additional context data
  final Map<String, dynamic> properties;
  
  ProConversionData({
    required this.event,
    required this.userTier,
    this.feature,
    this.productId,
    this.error,
    this.properties = const {},
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Convert to analytics event format
  Map<String, dynamic> toAnalyticsEvent() {
    return {
      'event': event.name,
      'timestamp': timestamp.toIso8601String(),
      'user_tier': userTier,
      'feature': feature,
      'product_id': productId,
      'error': error,
      ...properties,
    };
  }
  
  @override
  String toString() => 'ProConversion($event: $userTier)';
}

/// Interface for analytics providers
abstract class AnalyticsProvider {
  /// Track a single analytics event
  Future<void> track(String eventName, Map<String, dynamic> properties);
  
  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties);
  
  /// Identify user (for session tracking)
  Future<void> identify(String userId, Map<String, dynamic> traits);
}

/// Fake analytics provider for testing and development
class FakeAnalyticsProvider implements AnalyticsProvider {
  final List<Map<String, dynamic>> trackedEvents = [];
  final Map<String, dynamic> userProperties = {};
  String? currentUserId;
  Map<String, dynamic> userTraits = {};
  
  @override
  Future<void> track(String eventName, Map<String, dynamic> properties) async {
    trackedEvents.add({
      'event': eventName,
      'properties': Map<String, dynamic>.from(properties),
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
  
  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    userProperties.addAll(properties);
  }
  
  @override
  Future<void> identify(String userId, Map<String, dynamic> traits) async {
    currentUserId = userId;
    userTraits = Map<String, dynamic>.from(traits);
  }
  
  /// Clear all tracked data (for testing)
  void clear() {
    trackedEvents.clear();
    userProperties.clear();
    currentUserId = null;
    userTraits.clear();
  }
}

/// Pro conversion analytics tracker
class ProConversionAnalytics {
  final List<AnalyticsProvider> _providers;
  final StreamController<ProConversionData> _eventController = 
      StreamController<ProConversionData>.broadcast();
  
  ProConversionAnalytics(this._providers);
  
  /// Factory for testing with fake provider
  factory ProConversionAnalytics.fake() {
    return ProConversionAnalytics([FakeAnalyticsProvider()]);
  }
  
  /// Stream of conversion events (for testing and debugging)
  Stream<ProConversionData> get eventStream => _eventController.stream;
  
  /// Track a Pro conversion event
  Future<void> track(ProConversionData data) async {
    // Add to stream for testing/debugging
    if (!_eventController.isClosed) {
      _eventController.add(data);
    }
    
    // Send to all analytics providers
    final analyticsEvent = data.toAnalyticsEvent();
    for (final provider in _providers) {
      try {
        await provider.track('pro_conversion', analyticsEvent);
      } catch (e) {
        // Log error but don't block user experience
      }
    }
  }
  
  /// Convenient method to track upgrade screen views
  Future<void> trackUpgradeScreenView(String userTier, {
    String? source,
    String? feature,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.upgradeScreenViewed,
      userTier: userTier,
      feature: feature,
      properties: {
        'source': source,
      },
    ));
  }
  
  /// Track upgrade CTA clicks
  Future<void> trackUpgradeCtaClick(String userTier, {
    required String ctaLocation,
    String? feature,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.upgradeCtaClicked,
      userTier: userTier,
      feature: feature,
      properties: {
        'cta_location': ctaLocation,
      },
    ));
  }
  
  /// Track purchase flow events
  Future<void> trackPurchaseStarted(String userTier, String productId) async {
    await track(ProConversionData(
      event: ProConversionEvent.purchaseFlowStarted,
      userTier: userTier,
      productId: productId,
    ));
  }
  
  Future<void> trackPurchaseCompleted(String userTier, String productId, {
    double? priceUsd,
    String? paymentMethod,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.purchaseCompleted,
      userTier: userTier,
      productId: productId,
      properties: {
        'price_usd': priceUsd,
        'payment_method': paymentMethod,
      },
    ));
  }
  
  Future<void> trackPurchaseCancelled(String userTier, String productId) async {
    await track(ProConversionData(
      event: ProConversionEvent.purchaseCancelled,
      userTier: userTier,
      productId: productId,
    ));
  }
  
  Future<void> trackPurchaseFailed(String userTier, String productId, String error) async {
    await track(ProConversionData(
      event: ProConversionEvent.purchaseFailed,
      userTier: userTier,
      productId: productId,
      error: error,
    ));
  }
  
  /// Track free tier limitations
  Future<void> trackFreeTierLimit(String limitType, {
    int? currentUsage,
    int? limit,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.freeTierLimitHit,
      userTier: 'free',
      feature: limitType,
      properties: {
        'current_usage': currentUsage,
        'limit': limit,
      },
    ));
  }
  
  /// Track locked feature interactions
  Future<void> trackLockedFeatureView(String feature, {
    String? location,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.lockedFeatureViewed,
      userTier: 'free',
      feature: feature,
      properties: {
        'location': location,
      },
    ));
  }
  
  Future<void> trackLockedFeatureAttempt(String feature, {
    String? action,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.lockedFeatureAttempted,
      userTier: 'free',
      feature: feature,
      properties: {
        'action': action,
      },
    ));
  }
  
  /// Track successful Pro feature usage
  Future<void> trackProFeatureUsed(String feature, {
    Map<String, dynamic>? featureData,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.proFeatureUsed,
      userTier: 'pro',
      feature: feature,
      properties: featureData ?? {},
    ));
  }
  
  /// Track pricing and comparison views
  Future<void> trackPricingViewed(String userTier, {
    String? source,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.pricingViewed,
      userTier: userTier,
      properties: {
        'source': source,
      },
    ));
  }
  
  Future<void> trackFeatureComparison(String userTier, {
    List<String>? featuresCompared,
  }) async {
    await track(ProConversionData(
      event: ProConversionEvent.featureComparisonViewed,
      userTier: userTier,
      properties: {
        'features_compared': featuresCompared,
      },
    ));
  }
  
  /// Set user properties for segmentation
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    for (final provider in _providers) {
      try {
        await provider.setUserProperties(properties);
      } catch (e) {
        // Log error but don't block
      }
    }
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _eventController.close();
  }
}

/// Helper mixin for widgets/services that track Pro conversions
mixin ProConversionTracking {
  ProConversionAnalytics? _analytics;
  
  /// Initialize analytics tracking
  void initializeAnalytics(ProConversionAnalytics analytics) {
    _analytics = analytics;
  }
  
  /// Track upgrade screen view
  Future<void> trackUpgradeView(String userTier, {
    String? source,
    String? feature,
  }) async {
    await _analytics?.trackUpgradeScreenView(userTier, source: source, feature: feature);
  }
  
  /// Track CTA click
  Future<void> trackCtaClick(String userTier, String location, {
    String? feature,
  }) async {
    await _analytics?.trackUpgradeCtaClick(userTier, ctaLocation: location, feature: feature);
  }
  
  /// Track free tier limit hit
  Future<void> trackLimitHit(String limitType, {
    int? usage,
    int? limit,
  }) async {
    await _analytics?.trackFreeTierLimit(limitType, currentUsage: usage, limit: limit);
  }
  
  /// Track locked feature interaction
  Future<void> trackLockedFeature(String feature, {
    bool attempted = false,
    String? location,
  }) async {
    if (attempted) {
      await _analytics?.trackLockedFeatureAttempt(feature, action: 'attempted');
    } else {
      await _analytics?.trackLockedFeatureView(feature, location: location);
    }
  }
  
  /// Track Pro feature usage
  Future<void> trackProUsage(String feature, {
    Map<String, dynamic>? data,
  }) async {
    await _analytics?.trackProFeatureUsed(feature, featureData: data);
  }
}

/// Analytics configuration and setup
class ProAnalyticsConfig {
  /// Whether analytics tracking is enabled
  final bool enabled;
  
  /// Debug mode (use fake provider)
  final bool debugMode;
  
  /// Analytics provider configurations
  final Map<String, dynamic> providerConfigs;
  
  const ProAnalyticsConfig({
    this.enabled = true,
    this.debugMode = false,
    this.providerConfigs = const {},
  });
  
  /// Create config for production
  const ProAnalyticsConfig.production({
    Map<String, dynamic> providerConfigs = const {},
  }) : this(
    enabled: true,
    debugMode: false,
    providerConfigs: providerConfigs,
  );
  
  /// Create config for development/testing
  const ProAnalyticsConfig.debug() : this(
    enabled: true,
    debugMode: true,
    providerConfigs: const {},
  );
  
  /// Create config with analytics disabled
  const ProAnalyticsConfig.disabled() : this(
    enabled: false,
    debugMode: false,
    providerConfigs: const {},
  );
}
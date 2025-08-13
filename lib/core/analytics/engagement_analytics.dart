/// Enhanced Analytics System for MindTrainer Post-Launch
/// 
/// Tracks Pro feature engagement, free→Pro conversion funnel, drop-off points
/// in onboarding and purchase flows for business optimization.

import 'dart:async';
import 'dart:convert';
import '../storage/local_storage.dart';
import 'pro_conversion_analytics.dart';

/// Onboarding step tracking
enum OnboardingStep {
  appLaunch,
  splashViewed,
  welcomeScreen,
  permissionsRequested,
  firstSessionPrompt,
  firstSessionStarted,
  firstSessionCompleted,
  goalSettingPrompted,
  goalSet,
  onboardingCompleted,
}

/// Purchase funnel step tracking
enum PurchaseFunnelStep {
  upgradePromptShown,
  upgradePromptClicked,
  pricingScreenViewed,
  planSelected,
  purchaseFlowStarted,
  billingSheetShown,
  paymentMethodEntered,
  purchaseAttempted,
  purchaseCompleted,
  purchaseFailed,
  purchaseCancelled,
  proFeaturesFirstUsed,
}

/// Pro feature usage categories
enum ProFeatureCategory {
  unlimitedSessions,
  premiumEnvironments,
  breathingPatterns,
  advancedAnalytics,
  dataExport,
  customGoals,
  premiumThemes,
  aiCoaching,
}

/// User engagement level
enum EngagementLevel {
  newUser,      // 0-2 days
  exploring,    // 3-7 days  
  engaged,      // 8-30 days
  committed,    // 31-90 days
  champion,     // 90+ days
}

/// Analytics event with enhanced context
class EngagementAnalyticsEvent {
  final String eventName;
  final DateTime timestamp;
  final Map<String, dynamic> properties;
  final String? userId;
  final String sessionId;
  
  EngagementAnalyticsEvent({
    required this.eventName,
    required this.properties,
    this.userId,
    required this.sessionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  Map<String, dynamic> toJson() => {
    'eventName': eventName,
    'timestamp': timestamp.toIso8601String(),
    'properties': properties,
    'userId': userId,
    'sessionId': sessionId,
  };
  
  factory EngagementAnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return EngagementAnalyticsEvent(
      eventName: json['eventName'],
      timestamp: DateTime.parse(json['timestamp']),
      properties: Map<String, dynamic>.from(json['properties'] ?? {}),
      userId: json['userId'],
      sessionId: json['sessionId'],
    );
  }
}

/// Funnel analysis data
class FunnelAnalysis {
  final String funnelName;
  final List<String> steps;
  final Map<String, int> stepCounts;
  final Map<String, double> conversionRates;
  final DateTime analyzedAt;
  
  FunnelAnalysis({
    required this.funnelName,
    required this.steps,
    required this.stepCounts,
    required this.conversionRates,
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now();
  
  /// Get conversion rate between two steps
  double getStepConversion(String fromStep, String toStep) {
    final fromCount = stepCounts[fromStep] ?? 0;
    final toCount = stepCounts[toStep] ?? 0;
    
    if (fromCount == 0) return 0.0;
    return toCount / fromCount;
  }
  
  /// Get biggest drop-off point
  String? getBiggestDropOff() {
    double biggestDrop = 0.0;
    String? dropOffStep;
    
    for (int i = 0; i < steps.length - 1; i++) {
      final currentStep = steps[i];
      final nextStep = steps[i + 1];
      final dropRate = 1.0 - getStepConversion(currentStep, nextStep);
      
      if (dropRate > biggestDrop) {
        biggestDrop = dropRate;
        dropOffStep = nextStep;
      }
    }
    
    return dropOffStep;
  }
}

/// User cohort analysis
class UserCohort {
  final DateTime cohortDate;
  final int totalUsers;
  final Map<int, int> retentionByDay; // day -> active users
  final Map<int, double> retentionRates; // day -> retention rate
  
  UserCohort({
    required this.cohortDate,
    required this.totalUsers,
    required this.retentionByDay,
    required this.retentionRates,
  });
  
  /// Get retention rate for specific day
  double getRetentionRate(int day) => retentionRates[day] ?? 0.0;
  
  /// Get Day 1, 7, 30 retention rates
  Map<String, double> getKeyRetentionRates() => {
    'day1': getRetentionRate(1),
    'day7': getRetentionRate(7),
    'day30': getRetentionRate(30),
  };
}

/// Enhanced analytics system
class EngagementAnalytics {
  final LocalStorage _storage;
  final ProConversionAnalytics _proAnalytics;
  
  static const String _eventsKey = 'engagement_events';
  static const String _sessionIdKey = 'current_session_id';
  static const String _userPropertiesKey = 'user_properties';
  static const String _onboardingStateKey = 'onboarding_state';
  
  final StreamController<EngagementAnalyticsEvent> _eventController =
      StreamController<EngagementAnalyticsEvent>.broadcast();
  
  String? _currentSessionId;
  Map<String, dynamic> _userProperties = {};
  
  EngagementAnalytics(this._storage, this._proAnalytics);
  
  /// Stream of analytics events
  Stream<EngagementAnalyticsEvent> get eventStream => _eventController.stream;
  
  /// Initialize analytics system
  Future<void> initialize() async {
    await _loadUserProperties();
    await _startNewSession();
  }
  
  /// Track onboarding step
  Future<void> trackOnboardingStep(OnboardingStep step, {
    Map<String, dynamic>? properties,
  }) async {
    final stepIndex = OnboardingStep.values.indexOf(step);
    final totalSteps = OnboardingStep.values.length;
    
    await trackEvent('onboarding_step', {
      'step': step.name,
      'step_index': stepIndex,
      'progress_percentage': (stepIndex / totalSteps * 100).round(),
      'total_steps': totalSteps,
      ...properties ?? {},
    });
    
    // Update onboarding state
    await _updateOnboardingState(step);
    
    // Track completion
    if (step == OnboardingStep.onboardingCompleted) {
      await trackEvent('onboarding_completed', {
        'duration_from_launch': _getTimeSinceSessionStart(),
      });
    }
  }
  
  /// Track purchase funnel step
  Future<void> trackPurchaseFunnelStep(PurchaseFunnelStep step, {
    Map<String, dynamic>? properties,
  }) async {
    final stepIndex = PurchaseFunnelStep.values.indexOf(step);
    
    await trackEvent('purchase_funnel', {
      'step': step.name,
      'step_index': stepIndex,
      'user_tier': _userProperties['isPro'] ? 'pro' : 'free',
      ...properties ?? {},
    });
    
    // Track specific conversion events with Pro analytics
    switch (step) {
      case PurchaseFunnelStep.upgradePromptClicked:
        await _proAnalytics.trackUpgradeCtaClick('free', 
          ctaLocation: properties?['source'] ?? 'unknown',
        );
        break;
      case PurchaseFunnelStep.purchaseCompleted:
        await _proAnalytics.trackPurchaseCompleted('free', 
          properties?['product_id'] ?? 'unknown',
          priceUsd: properties?['price_usd'],
        );
        break;
      case PurchaseFunnelStep.purchaseFailed:
        await _proAnalytics.trackPurchaseFailed('free',
          properties?['product_id'] ?? 'unknown',
          properties?['error'] ?? 'Unknown error',
        );
        break;
      case PurchaseFunnelStep.purchaseCancelled:
        await _proAnalytics.trackPurchaseCancelled('free',
          properties?['product_id'] ?? 'unknown',
        );
        break;
      default:
        break;
    }
  }
  
  /// Track Pro feature engagement
  Future<void> trackProFeatureUsage(ProFeatureCategory feature, {
    required String action, // 'viewed', 'used', 'completed'
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent('pro_feature_usage', {
      'feature': feature.name,
      'action': action,
      'user_tier': _userProperties['isPro'] ? 'pro' : 'free',
      ...properties ?? {},
    });
    
    // Track with Pro analytics if user is Pro
    if (_userProperties['isPro'] == true) {
      await _proAnalytics.trackProFeatureUsed(feature.name, 
        featureData: properties,
      );
    } else {
      // Track locked feature interaction for free users
      if (action == 'viewed' || action == 'attempted') {
        await _proAnalytics.trackLockedFeatureView(feature.name,
          location: properties?['location'],
        );
      }
    }
  }
  
  /// Track app performance metrics
  Future<void> trackPerformanceMetric(String metricName, double value, {
    String? unit,
    Map<String, dynamic>? properties,
  }) async {
    await trackEvent('performance_metric', {
      'metric_name': metricName,
      'value': value,
      'unit': unit,
      'device_info': await _getDeviceInfo(),
      ...properties ?? {},
    });
  }
  
  /// Track user engagement level change
  Future<void> trackEngagementLevelChange(
    EngagementLevel fromLevel, 
    EngagementLevel toLevel,
  ) async {
    await trackEvent('engagement_level_changed', {
      'from_level': fromLevel.name,
      'to_level': toLevel.name,
      'days_active': _userProperties['days_active'] ?? 0,
      'total_sessions': _userProperties['total_sessions'] ?? 0,
    });
  }
  
  /// Set user properties
  Future<void> setUserProperties(Map<String, dynamic> properties) async {
    _userProperties.addAll(properties);
    await _saveUserProperties();
  }
  
  /// Track generic event
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    final event = EngagementAnalyticsEvent(
      eventName: eventName,
      properties: {
        ...properties,
        ..._userProperties,
        'session_id': _currentSessionId,
        'timestamp_local': DateTime.now().toIso8601String(),
      },
      userId: _userProperties['user_id'],
      sessionId: _currentSessionId ?? 'unknown',
    );
    
    await _saveEvent(event);
    
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }
  
  /// Analyze onboarding funnel
  Future<FunnelAnalysis> analyzeOnboardingFunnel({
    DateTime? since,
  }) async {
    final events = await _getEvents(
      eventName: 'onboarding_step', 
      since: since ?? DateTime.now().subtract(const Duration(days: 30)),
    );
    
    final stepCounts = <String, int>{};
    
    for (final event in events) {
      final step = event.properties['step'] as String?;
      if (step != null) {
        stepCounts[step] = (stepCounts[step] ?? 0) + 1;
      }
    }
    
    final steps = OnboardingStep.values.map((s) => s.name).toList();
    final conversionRates = <String, double>{};
    
    // Calculate conversion rates
    for (int i = 0; i < steps.length - 1; i++) {
      final currentStep = steps[i];
      final nextStep = steps[i + 1];
      final currentCount = stepCounts[currentStep] ?? 0;
      final nextCount = stepCounts[nextStep] ?? 0;
      
      conversionRates['$currentStep -> $nextStep'] = 
          currentCount > 0 ? nextCount / currentCount : 0.0;
    }
    
    return FunnelAnalysis(
      funnelName: 'onboarding',
      steps: steps,
      stepCounts: stepCounts,
      conversionRates: conversionRates,
    );
  }
  
  /// Analyze purchase funnel
  Future<FunnelAnalysis> analyzePurchaseFunnel({
    DateTime? since,
  }) async {
    final events = await _getEvents(
      eventName: 'purchase_funnel',
      since: since ?? DateTime.now().subtract(const Duration(days: 30)),
    );
    
    final stepCounts = <String, int>{};
    
    for (final event in events) {
      final step = event.properties['step'] as String?;
      if (step != null) {
        stepCounts[step] = (stepCounts[step] ?? 0) + 1;
      }
    }
    
    final steps = PurchaseFunnelStep.values.map((s) => s.name).toList();
    final conversionRates = <String, double>{};
    
    // Calculate conversion rates
    for (int i = 0; i < steps.length - 1; i++) {
      final currentStep = steps[i];
      final nextStep = steps[i + 1];
      final currentCount = stepCounts[currentStep] ?? 0;
      final nextCount = stepCounts[nextStep] ?? 0;
      
      conversionRates['$currentStep -> $nextStep'] = 
          currentCount > 0 ? nextCount / currentCount : 0.0;
    }
    
    return FunnelAnalysis(
      funnelName: 'purchase',
      steps: steps,
      stepCounts: stepCounts,
      conversionRates: conversionRates,
    );
  }
  
  /// Get Pro feature usage analytics
  Future<Map<String, dynamic>> getProFeatureAnalytics({
    DateTime? since,
  }) async {
    final events = await _getEvents(
      eventName: 'pro_feature_usage',
      since: since ?? DateTime.now().subtract(const Duration(days: 30)),
    );
    
    final featureUsage = <String, Map<String, int>>{};
    final userTierBreakdown = <String, Map<String, int>>{};
    
    for (final event in events) {
      final feature = event.properties['feature'] as String?;
      final action = event.properties['action'] as String?;
      final userTier = event.properties['user_tier'] as String? ?? 'unknown';
      
      if (feature != null && action != null) {
        featureUsage[feature] = featureUsage[feature] ?? {};
        featureUsage[feature]![action] = (featureUsage[feature]![action] ?? 0) + 1;
        
        userTierBreakdown[feature] = userTierBreakdown[feature] ?? {};
        userTierBreakdown[feature]![userTier] = 
            (userTierBreakdown[feature]![userTier] ?? 0) + 1;
      }
    }
    
    return {
      'feature_usage': featureUsage,
      'user_tier_breakdown': userTierBreakdown,
      'total_events': events.length,
      'analyzed_period': since?.toIso8601String(),
    };
  }
  
  /// Get performance metrics summary
  Future<Map<String, dynamic>> getPerformanceMetrics({
    DateTime? since,
  }) async {
    final events = await _getEvents(
      eventName: 'performance_metric',
      since: since ?? DateTime.now().subtract(const Duration(days: 7)),
    );
    
    final metrics = <String, List<double>>{};
    
    for (final event in events) {
      final metricName = event.properties['metric_name'] as String?;
      final value = event.properties['value'] as double?;
      
      if (metricName != null && value != null) {
        metrics[metricName] = metrics[metricName] ?? [];
        metrics[metricName]!.add(value);
      }
    }
    
    final summary = <String, Map<String, double>>{};
    
    for (final entry in metrics.entries) {
      final values = entry.value;
      values.sort();
      
      summary[entry.key] = {
        'min': values.first,
        'max': values.last,
        'avg': values.reduce((a, b) => a + b) / values.length,
        'median': values[values.length ~/ 2],
        'p95': values[(values.length * 0.95).round() - 1],
      };
    }
    
    return {
      'metrics': summary,
      'total_measurements': events.length,
      'analyzed_period': since?.toIso8601String(),
    };
  }
  
  /// Dispose resources
  Future<void> dispose() async {
    await _eventController.close();
  }
  
  // Private methods
  
  Future<void> _startNewSession() async {
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    await _storage.setString(_sessionIdKey, _currentSessionId!);
    
    await trackEvent('session_started', {
      'session_id': _currentSessionId,
    });
  }
  
  Future<void> _loadUserProperties() async {
    final propertiesJson = await _storage.getString(_userPropertiesKey);
    if (propertiesJson != null) {
      try {
        _userProperties = Map<String, dynamic>.from(jsonDecode(propertiesJson));
      } catch (e) {
        _userProperties = {};
      }
    }
  }
  
  Future<void> _saveUserProperties() async {
    final propertiesJson = jsonEncode(_userProperties);
    await _storage.setString(_userPropertiesKey, propertiesJson);
  }
  
  Future<void> _saveEvent(EngagementAnalyticsEvent event) async {
    final events = await _getEvents();
    events.add(event);
    
    // Keep only last 5000 events to manage storage
    if (events.length > 5000) {
      events.removeRange(0, events.length - 5000);
    }
    
    final eventsJson = jsonEncode(events.map((e) => e.toJson()).toList());
    await _storage.setString(_eventsKey, eventsJson);
  }
  
  Future<List<EngagementAnalyticsEvent>> _getEvents({
    String? eventName,
    DateTime? since,
  }) async {
    final eventsJson = await _storage.getString(_eventsKey);
    if (eventsJson == null) return [];
    
    try {
      final List<dynamic> eventsList = jsonDecode(eventsJson);
      List<EngagementAnalyticsEvent> events = eventsList
          .map((json) => EngagementAnalyticsEvent.fromJson(json))
          .toList();
      
      if (eventName != null) {
        events = events.where((e) => e.eventName == eventName).toList();
      }
      
      if (since != null) {
        events = events.where((e) => e.timestamp.isAfter(since)).toList();
      }
      
      return events;
    } catch (e) {
      return [];
    }
  }
  
  Future<void> _updateOnboardingState(OnboardingStep step) async {
    final currentState = await _storage.getString(_onboardingStateKey);
    final stateData = currentState != null 
        ? Map<String, dynamic>.from(jsonDecode(currentState))
        : <String, dynamic>{};
    
    stateData['current_step'] = step.name;
    stateData['updated_at'] = DateTime.now().toIso8601String();
    stateData['completed_steps'] = (stateData['completed_steps'] as List<dynamic>? ?? [])
      ..add(step.name);
    
    await _storage.setString(_onboardingStateKey, jsonEncode(stateData));
  }
  
  int _getTimeSinceSessionStart() {
    if (_currentSessionId == null) return 0;
    
    try {
      final sessionStartTime = int.parse(_currentSessionId!.split('_')[1]);
      return DateTime.now().millisecondsSinceEpoch - sessionStartTime;
    } catch (e) {
      return 0;
    }
  }
  
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    // In a real implementation, this would gather device information
    return {
      'platform': 'unknown',
      'version': 'unknown',
      'model': 'unknown',
    };
  }
}
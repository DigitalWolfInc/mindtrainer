/// Analytics Expansion for MindTrainer Growth Tracking
/// 
/// Tracks engagement with Pro features, conversion events,
/// and onboarding/purchase flow drop-off points.

import 'dart:convert';
import '../storage/local_storage.dart';

/// Analytics event types for growth tracking
enum GrowthEvent {
  // Onboarding flow
  onboardingStarted,
  onboardingStepCompleted,
  onboardingAbandoned,
  onboardingCompleted,
  
  // Pro feature engagement
  proFeatureViewed,
  proFeatureAttempted,
  proFeatureBlocked,
  proFeaturePreview,
  
  // Purchase flow
  purchaseFlowStarted,
  purchaseFlowAbandoned,
  purchaseFlowCompleted,
  purchaseFlowError,
  
  // Conversion events
  freeToProConversion,
  conversionTrigger,
  upsellShown,
  upsellDismissed,
  upsellConverted,
  
  // Feature usage
  unlimitedSessionsUsed,
  advancedAnalyticsViewed,
  aiCoachPlusEngaged,
  dataExportUsed,
  customGoalCreated,
  
  // Retention events
  dayOneReturn,
  dayThreeReturn,
  daySevenReturn,
  dayThirtyReturn,
  
  // Engagement quality
  deepSessionCompleted,
  streakMilestone,
  goalAchieved,
  insightDiscovered,
}

/// Event metadata for context
class EventMetadata {
  final Map<String, dynamic> data;
  
  const EventMetadata(this.data);
  
  /// Get string value
  String? getString(String key) => data[key] as String?;
  
  /// Get int value
  int? getInt(String key) => data[key] as int?;
  
  /// Get double value
  double? getDouble(String key) => data[key] as double?;
  
  /// Get bool value
  bool? getBool(String key) => data[key] as bool?;
  
  /// Convert to JSON
  Map<String, dynamic> toJson() => Map<String, dynamic>.from(data);
}

/// Analytics event record
class AnalyticsEvent {
  final GrowthEvent event;
  final DateTime timestamp;
  final EventMetadata metadata;
  final String sessionId;
  
  const AnalyticsEvent({
    required this.event,
    required this.timestamp,
    required this.metadata,
    required this.sessionId,
  });
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'event': event.toString(),
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata.toJson(),
      'sessionId': sessionId,
    };
  }
  
  /// Create from JSON
  factory AnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      event: GrowthEvent.values.firstWhere(
        (e) => e.toString() == json['event'],
        orElse: () => GrowthEvent.onboardingStarted,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      metadata: EventMetadata(json['metadata'] ?? {}),
      sessionId: json['sessionId'] ?? '',
    );
  }
}

/// Funnel analysis for conversion tracking
class ConversionFunnel {
  final String name;
  final List<GrowthEvent> steps;
  final Map<GrowthEvent, int> stepCounts;
  final Duration timeWindow;
  
  const ConversionFunnel({
    required this.name,
    required this.steps,
    required this.stepCounts,
    this.timeWindow = const Duration(days: 7),
  });
  
  /// Calculate conversion rate between steps
  double getConversionRate(GrowthEvent from, GrowthEvent to) {
    final fromCount = stepCounts[from] ?? 0;
    final toCount = stepCounts[to] ?? 0;
    
    if (fromCount == 0) return 0.0;
    return toCount / fromCount;
  }
  
  /// Get overall funnel conversion rate
  double get overallConversionRate {
    if (steps.isEmpty) return 0.0;
    
    final firstStep = steps.first;
    final lastStep = steps.last;
    
    return getConversionRate(firstStep, lastStep);
  }
  
  /// Get drop-off rate at specific step
  double getDropoffRate(GrowthEvent step) {
    final stepIndex = steps.indexOf(step);
    if (stepIndex == -1 || stepIndex == steps.length - 1) return 0.0;
    
    final nextStep = steps[stepIndex + 1];
    return 1.0 - getConversionRate(step, nextStep);
  }
}

/// Growth analytics system
class GrowthAnalytics {
  static const String _eventsKey = 'growth_events';
  static const String _sessionKey = 'current_session_id';
  static const int _maxStoredEvents = 1000;
  
  final LocalStorage _storage;
  String _currentSessionId = '';
  final List<AnalyticsEvent> _sessionEvents = [];
  
  GrowthAnalytics(this._storage);
  
  /// Initialize analytics system
  Future<void> initialize() async {
    _currentSessionId = _generateSessionId();
    await _storage.setString(_sessionKey, _currentSessionId);
    
    // Clean up old events periodically
    await _cleanupOldEvents();
  }
  
  /// Track growth event
  Future<void> trackEvent(
    GrowthEvent event, {
    Map<String, dynamic> metadata = const {},
  }) async {
    final analyticsEvent = AnalyticsEvent(
      event: event,
      timestamp: DateTime.now(),
      metadata: EventMetadata(metadata),
      sessionId: _currentSessionId,
    );
    
    _sessionEvents.add(analyticsEvent);
    await _persistEvent(analyticsEvent);
  }
  
  /// Track onboarding step completion
  Future<void> trackOnboardingStep(int stepNumber, String stepName) async {
    await trackEvent(
      GrowthEvent.onboardingStepCompleted,
      metadata: {
        'step_number': stepNumber,
        'step_name': stepName,
        'total_steps': 5, // Adjust based on actual onboarding
      },
    );
  }
  
  /// Track Pro feature interaction
  Future<void> trackProFeatureInteraction(
    String featureName,
    String action, {
    bool wasBlocked = false,
  }) async {
    GrowthEvent event;
    if (action == 'viewed') {
      event = GrowthEvent.proFeatureViewed;
    } else if (action == 'attempted') {
      event = wasBlocked ? GrowthEvent.proFeatureBlocked : GrowthEvent.proFeatureAttempted;
    } else {
      event = GrowthEvent.proFeaturePreview;
    }
    
    await trackEvent(event, metadata: {
      'feature_name': featureName,
      'action': action,
      'blocked': wasBlocked,
    });
  }
  
  /// Track purchase flow step
  Future<void> trackPurchaseFlowStep(
    String step, {
    String? product,
    String? error,
  }) async {
    GrowthEvent event;
    switch (step) {
      case 'started':
        event = GrowthEvent.purchaseFlowStarted;
        break;
      case 'abandoned':
        event = GrowthEvent.purchaseFlowAbandoned;
        break;
      case 'completed':
        event = GrowthEvent.purchaseFlowCompleted;
        break;
      case 'error':
        event = GrowthEvent.purchaseFlowError;
        break;
      default:
        return;
    }
    
    await trackEvent(event, metadata: {
      'step': step,
      if (product != null) 'product': product,
      if (error != null) 'error': error,
    });
  }
  
  /// Track conversion event
  Future<void> trackConversion({
    required String trigger,
    required String variant,
    bool converted = false,
  }) async {
    if (converted) {
      await trackEvent(GrowthEvent.freeToProConversion, metadata: {
        'trigger': trigger,
        'variant': variant,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
    
    await trackEvent(GrowthEvent.conversionTrigger, metadata: {
      'trigger': trigger,
      'variant': variant,
      'converted': converted,
    });
  }
  
  /// Track upsell interaction
  Future<void> trackUpsell({
    required String trigger,
    required String action, // 'shown', 'dismissed', 'converted'
    String? messageStyle,
  }) async {
    GrowthEvent event;
    switch (action) {
      case 'shown':
        event = GrowthEvent.upsellShown;
        break;
      case 'dismissed':
        event = GrowthEvent.upsellDismissed;
        break;
      case 'converted':
        event = GrowthEvent.upsellConverted;
        break;
      default:
        return;
    }
    
    await trackEvent(event, metadata: {
      'trigger': trigger,
      'action': action,
      if (messageStyle != null) 'message_style': messageStyle,
    });
  }
  
  /// Get conversion funnel analysis
  Future<ConversionFunnel> getConversionFunnel(
    String funnelName,
    List<GrowthEvent> steps, {
    Duration? timeWindow,
  }) async {
    final events = await _getRecentEvents(timeWindow ?? const Duration(days: 30));
    final stepCounts = <GrowthEvent, int>{};
    
    for (final step in steps) {
      stepCounts[step] = events.where((e) => e.event == step).length;
    }
    
    return ConversionFunnel(
      name: funnelName,
      steps: steps,
      stepCounts: stepCounts,
      timeWindow: timeWindow ?? const Duration(days: 30),
    );
  }
  
  /// Get Pro feature engagement metrics
  Future<Map<String, dynamic>> getProFeatureEngagement() async {
    final events = await _getRecentEvents(const Duration(days: 30));
    
    final proEvents = events.where((e) => [
      GrowthEvent.proFeatureViewed,
      GrowthEvent.proFeatureAttempted,
      GrowthEvent.proFeatureBlocked,
      GrowthEvent.unlimitedSessionsUsed,
      GrowthEvent.advancedAnalyticsViewed,
      GrowthEvent.aiCoachPlusEngaged,
      GrowthEvent.dataExportUsed,
      GrowthEvent.customGoalCreated,
    ].contains(e.event));
    
    final featureEngagement = <String, Map<String, int>>{};
    
    for (final event in proEvents) {
      final featureName = event.metadata.getString('feature_name') ?? 'unknown';
      
      featureEngagement.putIfAbsent(featureName, () => {
        'viewed': 0,
        'attempted': 0,
        'blocked': 0,
        'used': 0,
      });
      
      switch (event.event) {
        case GrowthEvent.proFeatureViewed:
          featureEngagement[featureName]!['viewed'] = 
              (featureEngagement[featureName]!['viewed'] ?? 0) + 1;
          break;
        case GrowthEvent.proFeatureAttempted:
          featureEngagement[featureName]!['attempted'] = 
              (featureEngagement[featureName]!['attempted'] ?? 0) + 1;
          break;
        case GrowthEvent.proFeatureBlocked:
          featureEngagement[featureName]!['blocked'] = 
              (featureEngagement[featureName]!['blocked'] ?? 0) + 1;
          break;
        default:
          featureEngagement[featureName]!['used'] = 
              (featureEngagement[featureName]!['used'] ?? 0) + 1;
          break;
      }
    }
    
    return {
      'total_events': proEvents.length,
      'feature_breakdown': featureEngagement,
      'most_viewed': _getMostEngaged(featureEngagement, 'viewed'),
      'most_blocked': _getMostEngaged(featureEngagement, 'blocked'),
    };
  }
  
  /// Get retention metrics
  Future<Map<String, double>> getRetentionMetrics() async {
    final allEvents = await _getAllStoredEvents();
    final userStartDate = _getUserStartDate(allEvents);
    
    if (userStartDate == null) return {};
    
    final now = DateTime.now();
    final daysSinceStart = now.difference(userStartDate).inDays;
    
    final retentionMetrics = <String, double>{};
    
    // Day 1 retention
    if (daysSinceStart >= 1) {
      final day1Return = allEvents.any((e) => 
          e.event == GrowthEvent.dayOneReturn || 
          (e.timestamp.isAfter(userStartDate.add(const Duration(days: 1))) &&
           e.timestamp.isBefore(userStartDate.add(const Duration(days: 2)))));
      retentionMetrics['day_1'] = day1Return ? 1.0 : 0.0;
    }
    
    // Day 3 retention
    if (daysSinceStart >= 3) {
      final day3Return = allEvents.any((e) => 
          e.event == GrowthEvent.dayThreeReturn ||
          (e.timestamp.isAfter(userStartDate.add(const Duration(days: 3))) &&
           e.timestamp.isBefore(userStartDate.add(const Duration(days: 4)))));
      retentionMetrics['day_3'] = day3Return ? 1.0 : 0.0;
    }
    
    // Day 7 retention
    if (daysSinceStart >= 7) {
      final day7Return = allEvents.any((e) => 
          e.event == GrowthEvent.daySevenReturn ||
          (e.timestamp.isAfter(userStartDate.add(const Duration(days: 7))) &&
           e.timestamp.isBefore(userStartDate.add(const Duration(days: 8)))));
      retentionMetrics['day_7'] = day7Return ? 1.0 : 0.0;
    }
    
    return retentionMetrics;
  }
  
  /// Export analytics data for analysis
  Future<Map<String, dynamic>> exportAnalyticsData() async {
    final allEvents = await _getAllStoredEvents();
    
    return {
      'total_events': allEvents.length,
      'date_range': {
        'start': allEvents.isNotEmpty ? allEvents.last.timestamp.toIso8601String() : null,
        'end': allEvents.isNotEmpty ? allEvents.first.timestamp.toIso8601String() : null,
      },
      'events': allEvents.map((e) => e.toJson()).toList(),
      'summary': await _generateAnalyticsSummary(allEvents),
    };
  }
  
  /// Generate session ID
  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
  
  /// Persist event to storage
  Future<void> _persistEvent(AnalyticsEvent event) async {
    try {
      final events = await _getAllStoredEvents();
      
      events.insert(0, event);
      
      // Keep only recent events
      if (events.length > _maxStoredEvents) {
        events.removeRange(_maxStoredEvents, events.length);
      }
      
      final jsonEvents = events.map((e) => e.toJson()).toList();
      await _storage.setString(_eventsKey, jsonEncode(jsonEvents));
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Get recent events within time window
  Future<List<AnalyticsEvent>> _getRecentEvents(Duration timeWindow) async {
    final allEvents = await _getAllStoredEvents();
    final cutoff = DateTime.now().subtract(timeWindow);
    
    return allEvents.where((e) => e.timestamp.isAfter(cutoff)).toList();
  }
  
  /// Get all stored events
  Future<List<AnalyticsEvent>> _getAllStoredEvents() async {
    try {
      final stored = await _storage.getString(_eventsKey);
      if (stored != null) {
        final List<dynamic> jsonEvents = jsonDecode(stored);
        return jsonEvents
            .map((json) => AnalyticsEvent.fromJson(json))
            .toList();
      }
    } catch (e) {
      // Ignore errors
    }
    
    return [];
  }
  
  /// Clean up old events
  Future<void> _cleanupOldEvents() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final events = await _getAllStoredEvents();
    
    final recentEvents = events.where((e) => e.timestamp.isAfter(cutoff)).toList();
    
    if (recentEvents.length != events.length) {
      final jsonEvents = recentEvents.map((e) => e.toJson()).toList();
      await _storage.setString(_eventsKey, jsonEncode(jsonEvents));
    }
  }
  
  /// Get most engaged feature
  String _getMostEngaged(Map<String, Map<String, int>> data, String metric) {
    String mostEngaged = '';
    int maxCount = 0;
    
    data.forEach((feature, metrics) {
      final count = metrics[metric] ?? 0;
      if (count > maxCount) {
        maxCount = count;
        mostEngaged = feature;
      }
    });
    
    return mostEngaged;
  }
  
  /// Get user start date from events
  DateTime? _getUserStartDate(List<AnalyticsEvent> events) {
    if (events.isEmpty) return null;
    
    // Find onboarding started or app first launch
    final startEvent = events.lastWhere(
      (e) => e.event == GrowthEvent.onboardingStarted,
      orElse: () => events.last,
    );
    
    return startEvent.timestamp;
  }
  
  /// Generate analytics summary
  Future<Map<String, dynamic>> _generateAnalyticsSummary(List<AnalyticsEvent> events) async {
    final eventCounts = <GrowthEvent, int>{};
    
    for (final event in events) {
      eventCounts[event.event] = (eventCounts[event.event] ?? 0) + 1;
    }
    
    final conversionFunnel = await getConversionFunnel(
      'purchase_flow',
      [
        GrowthEvent.purchaseFlowStarted,
        GrowthEvent.purchaseFlowCompleted,
      ],
    );
    
    return {
      'event_counts': eventCounts.map((k, v) => MapEntry(k.toString(), v)),
      'conversion_rate': conversionFunnel.overallConversionRate,
      'pro_feature_engagement': await getProFeatureEngagement(),
      'retention_metrics': await getRetentionMetrics(),
    };
  }
}
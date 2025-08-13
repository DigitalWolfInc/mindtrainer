/// Optimization Manager for MindTrainer
/// 
/// Integrates all optimization systems: A/B testing, engagement tracking,
/// upsell strategy, analytics, and performance profiling.

import '../storage/local_storage.dart';
import 'experiment_framework.dart';
import 'engagement_system.dart';
import 'upsell_strategy.dart';
import 'analytics_expansion.dart';
import 'performance_profiler.dart';

/// Centralized optimization manager
class OptimizationManager {
  final LocalStorage _storage;
  
  late final ExperimentFramework experiments;
  late final FeatureFlags featureFlags;
  late final EngagementSystem engagement;
  late final UpsellStrategy upsell;
  late final GrowthAnalytics analytics;
  late final PerformanceProfiler performance;
  
  bool _initialized = false;
  
  OptimizationManager(this._storage) {
    experiments = ExperimentFramework(_storage);
    featureFlags = FeatureFlags(experiments);
    engagement = EngagementSystem(_storage, experiments);
    upsell = UpsellStrategy(_storage, experiments, engagement);
    analytics = GrowthAnalytics(_storage);
    performance = PerformanceProfiler(_storage);
  }
  
  /// Initialize all optimization systems
  Future<void> initialize() async {
    if (_initialized) return;
    
    await performance.measureOperation(
      PerformanceMetric.appStartup,
      'optimization_initialization',
      () async {
        // Initialize in order of dependency
        await experiments.initialize();
        await engagement.initialize();
        await upsell.initialize();
        await analytics.initialize();
        await performance.initialize();
        
        // Register standard experiments
        _registerStandardExperiments();
        
        // Track initialization completion
        await analytics.trackEvent(GrowthEvent.onboardingCompleted);
        
        _initialized = true;
      },
    );
  }
  
  /// Handle app startup measurement
  Future<void> measureAppStartup() async {
    performance.startMeasurement(PerformanceMetric.appStartup, 'full_startup');
  }
  
  /// Complete app startup measurement
  Future<void> completeAppStartup() async {
    final measurement = await performance.endMeasurement(
      PerformanceMetric.appStartup, 
      'full_startup',
    );
    
    if (measurement != null) {
      await analytics.trackEvent(
        GrowthEvent.onboardingStarted,
        metadata: {
          'startup_time_ms': measurement.duration.inMilliseconds,
          'performance_level': measurement.level.toString(),
        },
      );
    }
  }
  
  /// Handle user session start
  Future<void> onSessionStart() async {
    await engagement.trackEvent(EngagementEvent.sessionStart);
    await analytics.trackEvent(GrowthEvent.onboardingStarted);
  }
  
  /// Handle user session completion
  Future<void> onSessionComplete(Map<String, dynamic> sessionData) async {
    await engagement.trackEvent(
      EngagementEvent.sessionComplete, 
      metadata: sessionData,
    );
    
    await analytics.trackEvent(
      GrowthEvent.deepSessionCompleted,
      metadata: sessionData,
    );
    
    // Check for upsell opportunities
    await _checkPostSessionUpsells(sessionData);
  }
  
  /// Handle Pro feature interaction
  Future<void> onProFeatureInteraction(
    String featureName,
    String action, {
    bool wasBlocked = false,
  }) async {
    // Track engagement
    final event = wasBlocked 
        ? EngagementEvent.proFeatureAttempt 
        : EngagementEvent.appLaunch;
    await engagement.trackEvent(event);
    
    // Track analytics
    await analytics.trackProFeatureInteraction(featureName, action, wasBlocked: wasBlocked);
    
    // Evaluate upsell opportunity if blocked
    if (wasBlocked) {
      final opportunity = await upsell.evaluateTrigger(
        UpsellTrigger.featureDiscovery,
        {'blocked_feature': featureName, 'action': action},
      );
      
      if (opportunity != null) {
        await analytics.trackUpsell(
          trigger: UpsellTrigger.featureDiscovery.toString(),
          action: 'opportunity_created',
        );
      }
    }
  }
  
  /// Handle purchase flow events
  Future<void> onPurchaseFlowEvent(
    String step, {
    String? product,
    String? error,
  }) async {
    await analytics.trackPurchaseFlowStep(step, product: product, error: error);
    
    if (step == 'completed') {
      await engagement.trackEvent(EngagementEvent.proUpgrade);
      await analytics.trackEvent(GrowthEvent.freeToProConversion);
    }
  }
  
  /// Get current engagement cues for UI
  Future<List<EngagementCue>> getEngagementCues() async {
    return await engagement.generateCues();
  }
  
  /// Handle cue dismissal
  Future<void> dismissEngagementCue(CueType type) async {
    await engagement.dismissCue(type);
    await analytics.trackEvent(
      GrowthEvent.upsellDismissed,
      metadata: {'cue_type': type.toString()},
    );
  }
  
  /// Evaluate and get upsell message for trigger
  Future<UpsellMessage?> evaluateUpsellTrigger(
    UpsellTrigger trigger,
    Map<String, dynamic> context,
  ) async {
    final opportunity = await upsell.evaluateTrigger(trigger, context);
    if (opportunity == null) return null;
    
    await analytics.trackUpsell(
      trigger: trigger.toString(),
      action: 'shown',
      messageStyle: experiments.getConfig('upsell_message_style', 'tone', 'supportive'),
    );
    
    return upsell.getUpsellMessage(opportunity);
  }
  
  /// Handle upsell interaction
  Future<void> onUpsellInteraction({
    required UpsellTrigger trigger,
    required String action,
    UpsellOpportunity? opportunity,
  }) async {
    await analytics.trackUpsell(
      trigger: trigger.toString(),
      action: action,
    );
    
    if (opportunity != null) {
      await upsell.recordConversionAttempt(
        opportunity: opportunity,
        converted: action == 'converted',
        dismissed: action == 'dismissed',
      );
    }
  }
  
  /// Measure screen transition
  Future<T> measureScreenTransition<T>(
    String screenName,
    Future<T> Function() transition,
  ) async {
    return await performance.measureOperation(
      PerformanceMetric.screenTransition,
      'transition_to_$screenName',
      transition,
    );
  }
  
  /// Measure widget build performance
  T measureWidgetBuild<T>(
    String widgetName,
    T Function() build,
  ) {
    return performance.measureSync(
      PerformanceMetric.widgetBuild,
      'build_$widgetName',
      build,
    );
  }
  
  /// Measure data operation
  Future<T> measureDataOperation<T>(
    String operation,
    Future<T> Function() task,
  ) async {
    return await performance.measureOperation(
      PerformanceMetric.dataQuery,
      operation,
      task,
    );
  }
  
  /// Get comprehensive analytics report
  Future<Map<String, dynamic>> getAnalyticsReport() async {
    return {
      'engagement_pattern': (await engagement.getEngagementPattern()).level.toString(),
      'growth_analytics': await analytics.exportAnalyticsData(),
      'performance_summary': await performance.getPerformanceSummary(),
      'startup_analysis': await performance.getStartupAnalysis(),
      'experiment_assignments': experiments.assignments,
      'retention_metrics': await analytics.getRetentionMetrics(),
    };
  }
  
  /// Export all optimization data
  Future<Map<String, dynamic>> exportOptimizationData() async {
    return {
      'export_timestamp': DateTime.now().toIso8601String(),
      'experiments': {
        'assignments': experiments.assignments,
      },
      'engagement': {
        'pattern': await engagement.getEngagementPattern(),
      },
      'analytics': await analytics.exportAnalyticsData(),
      'performance': await performance.exportPerformanceData(),
    };
  }
  
  /// Register standard experiments
  void _registerStandardExperiments() {
    MindTrainerExperiments.registerAll(experiments);
    
    // Register additional feature flags
    featureFlags.registerFeatureToggle(
      'pro_feature_previews',
      'Pro Feature Previews',
      enabledPercentage: 100.0, // Always on
    );
    
    featureFlags.registerFeatureToggle(
      'performance_monitoring',
      'Performance Monitoring',
      enabledPercentage: 100.0, // Always on
    );
    
    featureFlags.registerFeatureToggle(
      'advanced_upsell_timing',
      'Advanced Upsell Timing',
      enabledPercentage: 50.0, // A/B test
    );
  }
  
  /// Check for post-session upsell opportunities
  Future<void> _checkPostSessionUpsells(Map<String, dynamic> sessionData) async {
    final sessionCount = sessionData['session_count'] as int? ?? 0;
    final duration = sessionData['duration_minutes'] as int? ?? 0;
    
    // Session limit reached opportunity
    if (sessionCount >= 5) { // Free tier limit
      await upsell.evaluateTrigger(
        UpsellTrigger.sessionLimitReached,
        sessionData,
      );
    }
    
    // Strong engagement opportunity
    if (duration >= 10) { // Long session indicates engagement
      await upsell.evaluateTrigger(
        UpsellTrigger.highEngagement,
        sessionData,
      );
    }
    
    // Check streak opportunities
    final pattern = await engagement.getEngagementPattern();
    if (pattern.consecutiveDays >= 3) {
      await upsell.evaluateTrigger(
        UpsellTrigger.strongStreakDay,
        {'streak_days': pattern.consecutiveDays},
      );
    }
  }
}

/// Extension for easy integration with existing code
extension OptimizationExtensions on OptimizationManager {
  /// Quick feature flag check
  bool isFeatureEnabled(String featureId) {
    return featureFlags.isEnabled(featureId);
  }
  
  /// Quick experiment variant check
  bool isInExperimentVariant(String experimentId, String variantId) {
    return experiments.isInVariant(experimentId, variantId);
  }
  
  /// Quick performance measurement
  Future<T> measure<T>(String operation, Future<T> Function() task) async {
    return await performance.measureOperation(
      PerformanceMetric.heavyComputation,
      operation,
      task,
    );
  }
}
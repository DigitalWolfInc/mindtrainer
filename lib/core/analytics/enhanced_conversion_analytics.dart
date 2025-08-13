import 'dart:convert';
import 'conversion_analytics.dart';

/// Enhanced analytics service with comprehensive Pro feature usage and conversion tracking
/// Extends base ConversionAnalytics with detailed behavioral analysis
class EnhancedConversionAnalytics extends ConversionAnalytics {
  static final EnhancedConversionAnalytics _instance = EnhancedConversionAnalytics._internal();
  
  factory EnhancedConversionAnalytics() => _instance;
  EnhancedConversionAnalytics._internal();

  /// Track detailed Pro feature usage with context
  void trackProFeatureEngagement(String feature, String action, Map<String, dynamic>? context) {
    _logEvent('pro_feature_engagement', {
      'feature': feature,
      'action': action, // 'view', 'interact', 'export', 'analyze'
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'session_context': context ?? {},
      'feature_depth': _calculateFeatureDepth(feature, action),
    });
  }

  /// Track user journey through Pro discovery process
  void trackProDiscoveryJourney(String stage, String trigger, Map<String, dynamic>? metadata) {
    _logEvent('pro_discovery_journey', {
      'stage': stage, // 'awareness', 'interest', 'consideration', 'trial', 'adoption'
      'trigger': trigger,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'journey_metadata': metadata ?? {},
    });
  }

  /// Track conversion funnel with granular steps
  void trackDetailedFunnelStep(String step, String previousStep, Map<String, dynamic>? context) {
    final stepOrder = _getFunnelStepOrder(step);
    final previousStepOrder = _getFunnelStepOrder(previousStep);
    
    _logEvent('detailed_funnel_step', {
      'current_step': step,
      'previous_step': previousStep,
      'step_order': stepOrder,
      'step_progression': stepOrder - previousStepOrder,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'context': context ?? {},
      'funnel_health': _calculateFunnelHealth(stepOrder),
    });
  }

  /// Track user hesitation patterns
  void trackUserHesitation(String location, String hesitationType, Map<String, dynamic>? signals) {
    _logEvent('user_hesitation', {
      'location': location,
      'hesitation_type': hesitationType, // 'price_concern', 'feature_unclear', 'timing_poor', 'value_question'
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hesitation_signals': signals ?? {},
    });
  }

  /// Track conversion momentum indicators
  void trackConversionMomentum(String indicator, double strength, Map<String, dynamic>? context) {
    _logEvent('conversion_momentum', {
      'indicator': indicator, // 'high_engagement', 'feature_exploration', 'repeated_visits', 'social_validation'
      'strength': strength, // 0.0 to 1.0
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'momentum_context': context ?? {},
    });
  }

  /// Track feature stickiness for Pro users
  void trackFeatureStickiness(String feature, int usageFrequency, double retentionScore) {
    _logEvent('feature_stickiness', {
      'feature': feature,
      'usage_frequency': usageFrequency, // uses per week
      'retention_score': retentionScore, // 0.0 to 1.0
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'stickiness_category': _categorizeStickiness(retentionScore),
    });
  }

  /// Track upgrade prompt optimization metrics
  void trackPromptOptimization(String promptId, String variant, Map<String, dynamic> performance) {
    _logEvent('prompt_optimization', {
      'prompt_id': promptId,
      'variant': variant,
      'performance_metrics': performance,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'optimization_score': _calculateOptimizationScore(performance),
    });
  }

  /// Track user segmentation for targeted messaging
  void trackUserSegment(String segmentId, Map<String, dynamic> segmentData) {
    _logEvent('user_segment', {
      'segment_id': segmentId,
      'segment_data': segmentData,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'segment_confidence': _calculateSegmentConfidence(segmentData),
    });
  }

  /// Track cohort behavior analysis
  void trackCohortBehavior(String cohortId, String behavior, Map<String, dynamic> metrics) {
    _logEvent('cohort_behavior', {
      'cohort_id': cohortId,
      'behavior': behavior,
      'metrics': metrics,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Track conversion attribution
  void trackConversionAttribution(String conversionId, List<String> touchpoints, Map<String, dynamic> attribution) {
    _logEvent('conversion_attribution', {
      'conversion_id': conversionId,
      'touchpoints': touchpoints,
      'attribution_model': attribution,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'primary_driver': _identifyPrimaryDriver(touchpoints, attribution),
    });
  }

  /// Track competitive intelligence
  void trackCompetitiveIntel(String competitor, String feature, String userFeedback) {
    _logEvent('competitive_intel', {
      'competitor': competitor,
      'feature': feature,
      'user_feedback': userFeedback,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'sentiment': _analyzeSentiment(userFeedback),
    });
  }

  /// Calculate feature depth based on usage pattern
  String _calculateFeatureDepth(String feature, String action) {
    final depthScores = {
      'view': 1,
      'interact': 2,
      'analyze': 3,
      'export': 4,
      'customize': 5,
    };
    
    final score = depthScores[action] ?? 1;
    if (score >= 4) return 'power_user';
    if (score >= 2) return 'engaged_user';
    return 'casual_user';
  }

  /// Get funnel step order for progression analysis
  int _getFunnelStepOrder(String step) {
    final stepOrders = {
      'app_launch': 1,
      'home_screen_view': 2,
      'pro_feature_discovery': 3,
      'pro_feature_interaction': 4,
      'upgrade_prompt_view': 5,
      'upgrade_dialog_view': 6,
      'billing_flow_start': 7,
      'payment_method_select': 8,
      'purchase_confirm': 9,
      'purchase_complete': 10,
      'pro_feature_unlock': 11,
      'pro_feature_first_use': 12,
    };
    
    return stepOrders[step] ?? 0;
  }

  /// Calculate funnel health score
  double _calculateFunnelHealth(int stepOrder) {
    // Higher step order indicates progress through funnel
    return (stepOrder / 12.0).clamp(0.0, 1.0);
  }

  /// Categorize feature stickiness
  String _categorizeStickiness(double retentionScore) {
    if (retentionScore >= 0.8) return 'highly_sticky';
    if (retentionScore >= 0.6) return 'moderately_sticky';
    if (retentionScore >= 0.4) return 'somewhat_sticky';
    return 'low_stickiness';
  }

  /// Calculate prompt optimization score
  double _calculateOptimizationScore(Map<String, dynamic> performance) {
    final clickRate = performance['click_rate'] ?? 0.0;
    final conversionRate = performance['conversion_rate'] ?? 0.0;
    final dismissRate = performance['dismiss_rate'] ?? 1.0;
    
    // Weighted score favoring conversion with low dismissal
    return (clickRate * 0.3 + conversionRate * 0.6 - dismissRate * 0.1).clamp(0.0, 1.0);
  }

  /// Calculate segment confidence
  double _calculateSegmentConfidence(Map<String, dynamic> segmentData) {
    final dataPoints = segmentData.length;
    final completeness = segmentData.values.where((v) => v != null).length / dataPoints;
    
    return completeness.clamp(0.0, 1.0);
  }

  /// Identify primary conversion driver
  String _identifyPrimaryDriver(List<String> touchpoints, Map<String, dynamic> attribution) {
    if (touchpoints.isEmpty) return 'unknown';
    
    // Simple heuristic - in real implementation, use attribution weights
    final lastTouchpoint = touchpoints.last;
    final highValueTouchpoints = ['analytics_locked_feature', 'post_session_prompt', 'streak_achievement'];
    
    if (highValueTouchpoints.contains(lastTouchpoint)) {
      return lastTouchpoint;
    }
    
    return touchpoints.first; // First touch attribution as fallback
  }

  /// Simple sentiment analysis
  String _analyzeSentiment(String feedback) {
    final positiveWords = ['good', 'great', 'love', 'excellent', 'amazing', 'helpful'];
    final negativeWords = ['bad', 'hate', 'terrible', 'awful', 'confusing', 'expensive'];
    
    final lowerFeedback = feedback.toLowerCase();
    final positiveCount = positiveWords.where((word) => lowerFeedback.contains(word)).length;
    final negativeCount = negativeWords.where((word) => lowerFeedback.contains(word)).length;
    
    if (positiveCount > negativeCount) return 'positive';
    if (negativeCount > positiveCount) return 'negative';
    return 'neutral';
  }

  /// Generate comprehensive analytics report
  Map<String, dynamic> generateAnalyticsReport() {
    return {
      'report_timestamp': DateTime.now().toIso8601String(),
      'conversion_funnel': {
        'total_entries': 'calculated_from_logs',
        'step_progression_rates': 'calculated_from_detailed_funnel_steps',
        'drop_off_points': 'identified_from_funnel_analysis',
        'optimization_opportunities': 'derived_from_hesitation_patterns',
      },
      'pro_feature_adoption': {
        'feature_usage_rates': 'calculated_from_engagement_events',
        'stickiness_scores': 'derived_from_retention_analysis',
        'power_user_indicators': 'based_on_feature_depth',
      },
      'user_segmentation': {
        'behavioral_segments': 'identified_from_engagement_patterns',
        'conversion_propensity': 'calculated_from_momentum_indicators',
        'churn_risk_assessment': 'based_on_usage_patterns',
      },
      'optimization_insights': {
        'best_performing_prompts': 'ranked_by_optimization_score',
        'optimal_timing_patterns': 'derived_from_conversion_data',
        'messaging_effectiveness': 'based_on_ab_test_results',
      },
      'competitive_analysis': {
        'feature_gaps': 'identified_from_user_feedback',
        'market_positioning': 'derived_from_competitive_intel',
      },
    };
  }

  /// Get user's conversion readiness score
  double calculateConversionReadiness(Map<String, dynamic> userMetrics) {
    final engagementScore = userMetrics['engagement_score'] ?? 0.0;
    final featureExploration = userMetrics['features_explored'] ?? 0;
    final sessionQuality = userMetrics['avg_session_quality'] ?? 0.0;
    final appUsageDays = userMetrics['days_active'] ?? 0;
    final proFeatureInteractions = userMetrics['pro_interactions'] ?? 0;
    
    // Weighted score calculation
    final readinessScore = (
      engagementScore * 0.25 +
      (featureExploration / 10.0).clamp(0.0, 1.0) * 0.20 +
      sessionQuality * 0.20 +
      (appUsageDays / 14.0).clamp(0.0, 1.0) * 0.15 +
      (proFeatureInteractions / 5.0).clamp(0.0, 1.0) * 0.20
    ).clamp(0.0, 1.0);
    
    // Log readiness calculation for analysis
    _logEvent('conversion_readiness_calculated', {
      'readiness_score': readinessScore,
      'input_metrics': userMetrics,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    
    return readinessScore;
  }
}

/// Extended conversion entry points for enhanced tracking
class EnhancedConversionEntryPoints extends ConversionEntryPoints {
  static const String postSessionHighScore = 'post_session_high_score';
  static const String streakMilestone = 'streak_milestone';
  static const String goalCompletion = 'goal_completion';
  static const String featureDiscovery = 'feature_discovery';
  static const String powerUserBehavior = 'power_user_behavior';
  static const String competitiveComparison = 'competitive_comparison';
  static const String socialValidation = 'social_validation';
  static const String seasonalPromotion = 'seasonal_promotion';
}

/// Extended funnel steps for detailed tracking
class EnhancedFunnelSteps extends ConversionFunnelSteps {
  static const String proFeatureDiscovery = 'pro_feature_discovery';
  static const String proFeatureInteraction = 'pro_feature_interaction';
  static const String paymentMethodSelect = 'payment_method_select';
  static const String purchaseConfirm = 'purchase_confirm';
  static const String proFeatureFirstUse = 'pro_feature_first_use';
  static const String proFeatureHabitFormation = 'pro_feature_habit_formation';
}

/// Enhanced drop-off reasons with more granular tracking
class EnhancedDropOffReasons extends DropOffReasons {
  static const String priceObjection = 'price_objection';
  static const String featureUnclear = 'feature_unclear';
  static const String competitorPreference = 'competitor_preference';
  static const String technicalIssue = 'technical_issue';
  static const String trustConcern = 'trust_concern';
  static const String usageInfrequent = 'usage_infrequent';
  static const String alternativeFound = 'alternative_found';
}
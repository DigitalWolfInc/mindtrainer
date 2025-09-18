/// Pro Feature Expansion Planning System for MindTrainer
/// 
/// Analyzes feature performance quarterly, identifies underused features,
/// and plans annual Pro feature expansions based on user feedback and market trends.

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../storage/local_storage.dart';
import '../analytics/engagement_analytics.dart';
import '../analytics/pro_feature_analysis.dart';

/// Pro feature performance status
enum FeaturePerformanceStatus {
  excellent,  // High engagement, strong conversion impact
  good,       // Solid performance, meeting expectations
  fair,       // Moderate performance, room for improvement
  poor,       // Low engagement, needs attention
  underused,  // Very low usage, consider replacement
}

/// Quarterly feature performance report
class FeaturePerformanceReport {
  final String featureId;
  final String featureName;
  final DateTime reportPeriodStart;
  final DateTime reportPeriodEnd;
  final FeaturePerformanceStatus status;
  final double engagementRate;      // % of Pro users who used this feature
  final double conversionImpact;    // Correlation with free->Pro conversions
  final double retentionImpact;     // Impact on Pro user retention
  final int totalUsageEvents;       // Total feature usage events
  final int uniqueUsers;            // Unique users who used the feature
  final double averageSessionsPerUser; // Avg sessions per user who used it
  final Map<String, dynamic> metadata;
  
  FeaturePerformanceReport({
    required this.featureId,
    required this.featureName,
    required this.reportPeriodStart,
    required this.reportPeriodEnd,
    required this.status,
    required this.engagementRate,
    required this.conversionImpact,
    required this.retentionImpact,
    required this.totalUsageEvents,
    required this.uniqueUsers,
    required this.averageSessionsPerUser,
    this.metadata = const {},
  });
  
  /// Overall performance score (0-100)
  int get performanceScore {
    // Weighted scoring
    final engagementScore = (engagementRate * 100) * 0.4;
    final conversionScore = (conversionImpact * 100) * 0.3;
    final retentionScore = (retentionImpact * 100) * 0.3;
    
    return (engagementScore + conversionScore + retentionScore).round().clamp(0, 100);
  }
  
  /// Whether this feature needs attention
  bool get needsAttention => status == FeaturePerformanceStatus.poor || 
                            status == FeaturePerformanceStatus.underused;
  
  /// Recommendation based on performance
  String get recommendation {
    switch (status) {
      case FeaturePerformanceStatus.excellent:
        return 'Feature performing excellently. Consider expanding or promoting.';
      case FeaturePerformanceStatus.good:
        return 'Feature performing well. Monitor and maintain current approach.';
      case FeaturePerformanceStatus.fair:
        return 'Feature has potential. Consider UX improvements or better discovery.';
      case FeaturePerformanceStatus.poor:
        return 'Feature underperforming. Needs significant improvement or redesign.';
      case FeaturePerformanceStatus.underused:
        return 'Feature rarely used. Consider replacement with more valuable feature.';
    }
  }
  
  Map<String, dynamic> toJson() => {
    'featureId': featureId,
    'featureName': featureName,
    'reportPeriodStart': reportPeriodStart.toIso8601String(),
    'reportPeriodEnd': reportPeriodEnd.toIso8601String(),
    'status': status.name,
    'engagementRate': engagementRate,
    'conversionImpact': conversionImpact,
    'retentionImpact': retentionImpact,
    'totalUsageEvents': totalUsageEvents,
    'uniqueUsers': uniqueUsers,
    'averageSessionsPerUser': averageSessionsPerUser,
    'performanceScore': performanceScore,
    'metadata': metadata,
  };
}

/// Annual Pro expansion plan
class ProExpansionPlan {
  final int year;
  final DateTime createdAt;
  final List<ProFeatureAnalysisResult> proposedFeatures;
  final List<String> featuresToDeprecate;
  final List<String> featuresToImprove;
  final Map<String, dynamic> marketAnalysis;
  final Map<String, dynamic> competitorAnalysis;
  final Map<String, dynamic> userFeedbackSummary;
  final int estimatedDevelopmentMonths;
  final double projectedRevenueImpact;
  
  ProExpansionPlan({
    required this.year,
    required this.createdAt,
    required this.proposedFeatures,
    required this.featuresToDeprecate,
    required this.featuresToImprove,
    required this.marketAnalysis,
    required this.competitorAnalysis,
    required this.userFeedbackSummary,
    required this.estimatedDevelopmentMonths,
    required this.projectedRevenueImpact,
  });
  
  /// Top priority features for implementation
  List<ProFeatureAnalysisResult> get topPriorityFeatures => 
      proposedFeatures.where((f) => f.isHighPriority).toList();
  
  /// Quick win features that are easy to implement
  List<ProFeatureAnalysisResult> get quickWinFeatures =>
      proposedFeatures.where((f) => f.isQuickWin).toList();
  
  Map<String, dynamic> toJson() => {
    'year': year,
    'createdAt': createdAt.toIso8601String(),
    'proposedFeatures': proposedFeatures.map((f) => {
      'featureName': f.featureName,
      'category': f.category,
      'overallPriorityScore': f.overallPriorityScore,
      'riskAdjustedPriority': f.riskAdjustedPriority,
      'isHighPriority': f.isHighPriority,
      'isQuickWin': f.isQuickWin,
    }).toList(),
    'featuresToDeprecate': featuresToDeprecate,
    'featuresToImprove': featuresToImprove,
    'marketAnalysis': marketAnalysis,
    'competitorAnalysis': competitorAnalysis,
    'userFeedbackSummary': userFeedbackSummary,
    'estimatedDevelopmentMonths': estimatedDevelopmentMonths,
    'projectedRevenueImpact': projectedRevenueImpact,
  };
}

/// Pro expansion planning system
class ProExpansionPlanner {
  final LocalStorage _storage;
  final EngagementAnalytics _analytics;
  final ProFeatureAnalyzer _featureAnalyzer;
  
  static const String _performanceReportsKey = 'feature_performance_reports';
  static const String _expansionPlansKey = 'pro_expansion_plans';
  static const String _userFeedbackKey = 'user_feedback_summary';
  static const String _marketDataKey = 'market_analysis_data';
  
  // Known Pro feature categories for analysis
  static const List<String> _proFeatureIds = [
    'unlimited_sessions',
    'breathing_patterns',
    'pomodoro_integration',
    'premium_nature_sounds',
    'advanced_analytics',
    'custom_session_lengths',
    'focus_insights',
    'mood_tracking',
    'data_export',
    'premium_themes',
  ];
  
  ProExpansionPlanner(this._storage, this._analytics, this._featureAnalyzer);
  
  /// Generate quarterly feature performance reports
  Future<List<FeaturePerformanceReport>> generateQuarterlyReports() async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 90));
    
    final reports = <FeaturePerformanceReport>[];
    
    for (final featureId in _proFeatureIds) {
      final report = await _analyzeFeaturePerformance(
        featureId: featureId,
        startDate: startDate,
        endDate: endDate,
      );
      
      if (report != null) {
        reports.add(report);
      }
    }
    
    await _savePerformanceReports(reports);
    
    if (kDebugMode) {
      print('Generated ${reports.length} quarterly performance reports');
      final underperforming = reports.where((r) => r.needsAttention).length;
      print('Features needing attention: $underperforming');
    }
    
    return reports;
  }
  
  /// Create annual Pro expansion plan
  Future<ProExpansionPlan> createAnnualExpansionPlan(int year) async {
    // Analyze current feature performance
    final performanceReports = await _getLatestPerformanceReports();
    
    // Get feature analysis for potential new features
    final potentialFeatures = await _featureAnalyzer.analyzePotentialFeatures();
    
    // Identify features to deprecate or improve
    final featuresToDeprecate = _identifyDeprecationCandidates(performanceReports);
    final featuresToImprove = _identifyImprovementCandidates(performanceReports);
    
    // Analyze market trends and competitor features
    final marketAnalysis = await _analyzeMarketTrends(year);
    final competitorAnalysis = await _analyzeCompetitorFeatures();
    
    // Compile user feedback
    final userFeedback = await _compileUserFeedback();
    
    // Select top features for implementation
    final selectedFeatures = await _selectFeaturesForImplementation(
      potentialFeatures,
      performanceReports,
      marketAnalysis,
    );
    
    // Estimate development effort and revenue impact
    final developmentEstimate = _estimateDevelopmentEffort(selectedFeatures);
    final revenueProjection = _projectRevenueImpact(selectedFeatures, performanceReports);
    
    final plan = ProExpansionPlan(
      year: year,
      createdAt: DateTime.now(),
      proposedFeatures: selectedFeatures,
      featuresToDeprecate: featuresToDeprecate,
      featuresToImprove: featuresToImprove,
      marketAnalysis: marketAnalysis,
      competitorAnalysis: competitorAnalysis,
      userFeedbackSummary: userFeedback,
      estimatedDevelopmentMonths: developmentEstimate,
      projectedRevenueImpact: revenueProjection,
    );
    
    await _saveExpansionPlan(plan);
    
    if (kDebugMode) {
      print('Created annual expansion plan for $year');
      print('Proposed features: ${selectedFeatures.length}');
      print('Features to deprecate: ${featuresToDeprecate.length}');
      print('Estimated development: $developmentEstimate months');
      print('Projected revenue impact: \$${revenueProjection.toStringAsFixed(0)}');
    }
    
    return plan;
  }
  
  /// Get feature improvement recommendations
  Future<List<Map<String, dynamic>>> getImprovementRecommendations() async {
    final reports = await _getLatestPerformanceReports();
    final recommendations = <Map<String, dynamic>>[];
    
    for (final report in reports.where((r) => r.needsAttention)) {
      final actions = await _generateImprovementActions(report);
      
      recommendations.add({
        'feature_id': report.featureId,
        'feature_name': report.featureName,
        'status': report.status.name,
        'performance_score': report.performanceScore,
        'primary_issue': _identifyPrimaryIssue(report),
        'recommended_actions': actions,
        'priority': _calculateImprovementPriority(report),
        'estimated_effort': _estimateImprovementEffort(report),
      });
    }
    
    // Sort by priority (highest first)
    recommendations.sort((a, b) => (b['priority'] as int).compareTo(a['priority'] as int));
    
    return recommendations;
  }
  
  /// Get annual expansion summary
  Future<Map<String, dynamic>> getExpansionSummary({int? year}) async {
    final targetYear = year ?? DateTime.now().year;
    final plan = await _getExpansionPlan(targetYear);
    
    if (plan == null) {
      return {
        'year': targetYear,
        'status': 'no_plan',
        'message': 'No expansion plan exists for $targetYear',
      };
    }
    
    final reports = await _getLatestPerformanceReports();
    
    return {
      'year': targetYear,
      'status': 'active',
      'created_at': plan.createdAt.toIso8601String(),
      'feature_pipeline': {
        'total_proposed': plan.proposedFeatures.length,
        'high_priority': plan.topPriorityFeatures.length,
        'quick_wins': plan.quickWinFeatures.length,
      },
      'maintenance_actions': {
        'features_to_deprecate': plan.featuresToDeprecate.length,
        'features_to_improve': plan.featuresToImprove.length,
      },
      'projections': {
        'development_months': plan.estimatedDevelopmentMonths,
        'revenue_impact': plan.projectedRevenueImpact,
      },
      'current_performance': {
        'features_analyzed': reports.length,
        'excellent_performers': reports.where((r) => r.status == FeaturePerformanceStatus.excellent).length,
        'underperformers': reports.where((r) => r.needsAttention).length,
        'avg_engagement_rate': reports.isEmpty ? 0.0 : reports.map((r) => r.engagementRate).reduce((a, b) => a + b) / reports.length,
      },
    };
  }
  
  /// Track feature performance metric
  Future<void> trackFeatureUsage({
    required String featureId,
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    await _analytics.trackProFeatureUsage(
      _getProFeatureCategory(featureId),
      action: action,
      properties: {
        'feature_id': featureId,
        'user_id': userId,
        ...metadata ?? {},
      },
    );
  }
  
  // Private helper methods
  
  Future<FeaturePerformanceReport?> _analyzeFeaturePerformance({
    required String featureId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Get feature usage data from analytics
    final featureAnalytics = await _analytics.getProFeatureAnalytics(since: startDate);
    final featureUsage = featureAnalytics['feature_usage'] as Map<String, dynamic>? ?? {};
    final userTierBreakdown = featureAnalytics['user_tier_breakdown'] as Map<String, dynamic>? ?? {};
    
    final featureName = _getFeatureName(featureId);
    final featureData = featureUsage[featureId] as Map<String, int>? ?? {};
    final tierData = userTierBreakdown[featureId] as Map<String, int>? ?? {};
    
    final totalUsage = featureData.values.fold<int>(0, (sum, count) => sum + count);
    final proUserUsage = tierData['pro'] ?? 0;
    
    if (totalUsage == 0) {
      return FeaturePerformanceReport(
        featureId: featureId,
        featureName: featureName,
        reportPeriodStart: startDate,
        reportPeriodEnd: endDate,
        status: FeaturePerformanceStatus.underused,
        engagementRate: 0.0,
        conversionImpact: 0.0,
        retentionImpact: 0.0,
        totalUsageEvents: 0,
        uniqueUsers: 0,
        averageSessionsPerUser: 0.0,
      );
    }
    
    // Calculate metrics (these would be more sophisticated in a real implementation)
    final engagementRate = _calculateEngagementRate(featureId, proUserUsage);
    final conversionImpact = _calculateConversionImpact(featureId);
    final retentionImpact = _calculateRetentionImpact(featureId);
    final status = _determinePerformanceStatus(engagementRate, conversionImpact, retentionImpact);
    
    return FeaturePerformanceReport(
      featureId: featureId,
      featureName: featureName,
      reportPeriodStart: startDate,
      reportPeriodEnd: endDate,
      status: status,
      engagementRate: engagementRate,
      conversionImpact: conversionImpact,
      retentionImpact: retentionImpact,
      totalUsageEvents: totalUsage,
      uniqueUsers: proUserUsage,
      averageSessionsPerUser: proUserUsage > 0 ? totalUsage / proUserUsage : 0.0,
    );
  }
  
  String _getFeatureName(String featureId) {
    final Map<String, String> featureNames = {
      'unlimited_sessions': 'Unlimited Daily Sessions',
      'breathing_patterns': 'Guided Breathing Patterns',
      'pomodoro_integration': 'Pomodoro Timer Integration',
      'premium_nature_sounds': 'Premium Nature Sounds',
      'advanced_analytics': 'Advanced Session Analytics',
      'custom_session_lengths': 'Custom Session Lengths',
      'focus_insights': 'Focus Performance Insights',
      'mood_tracking': 'Mood & Emotion Tracking',
      'data_export': 'Session Data Export',
      'premium_themes': 'Premium Visual Themes',
    };
    
    return featureNames[featureId] ?? featureId;
  }
  
  ProFeatureCategory _getProFeatureCategory(String featureId) {
    final Map<String, ProFeatureCategory> categoryMap = {
      'unlimited_sessions': ProFeatureCategory.unlimitedSessions,
      'breathing_patterns': ProFeatureCategory.breathingPatterns,
      'pomodoro_integration': ProFeatureCategory.advancedAnalytics,
      'premium_nature_sounds': ProFeatureCategory.premiumEnvironments,
      'advanced_analytics': ProFeatureCategory.advancedAnalytics,
      'custom_session_lengths': ProFeatureCategory.customGoals,
      'focus_insights': ProFeatureCategory.advancedAnalytics,
      'mood_tracking': ProFeatureCategory.advancedAnalytics,
      'data_export': ProFeatureCategory.dataExport,
      'premium_themes': ProFeatureCategory.premiumThemes,
    };
    
    return categoryMap[featureId] ?? ProFeatureCategory.unlimitedSessions;
  }
  
  double _calculateEngagementRate(String featureId, int usage) {
    // Simplified calculation - in reality would use actual Pro user counts
    final totalProUsers = 1000; // Mock data
    return usage / totalProUsers;
  }
  
  double _calculateConversionImpact(String featureId) {
    // Simplified correlation calculation
    final Map<String, double> impacts = {
      'unlimited_sessions': 0.85,
      'breathing_patterns': 0.75,
      'pomodoro_integration': 0.65,
      'premium_nature_sounds': 0.60,
      'advanced_analytics': 0.55,
      'custom_session_lengths': 0.45,
      'focus_insights': 0.50,
      'mood_tracking': 0.40,
      'data_export': 0.25,
      'premium_themes': 0.30,
    };
    
    return impacts[featureId] ?? 0.3;
  }
  
  double _calculateRetentionImpact(String featureId) {
    // Simplified retention correlation
    final Map<String, double> impacts = {
      'unlimited_sessions': 0.80,
      'breathing_patterns': 0.70,
      'advanced_analytics': 0.65,
      'pomodoro_integration': 0.60,
      'premium_nature_sounds': 0.55,
      'mood_tracking': 0.50,
      'custom_session_lengths': 0.45,
      'focus_insights': 0.40,
      'premium_themes': 0.35,
      'data_export': 0.20,
    };
    
    return impacts[featureId] ?? 0.3;
  }
  
  FeaturePerformanceStatus _determinePerformanceStatus(
    double engagementRate,
    double conversionImpact,
    double retentionImpact,
  ) {
    final score = (engagementRate * 0.4) + (conversionImpact * 0.3) + (retentionImpact * 0.3);
    
    if (score >= 0.8) return FeaturePerformanceStatus.excellent;
    if (score >= 0.6) return FeaturePerformanceStatus.good;
    if (score >= 0.4) return FeaturePerformanceStatus.fair;
    if (score >= 0.2) return FeaturePerformanceStatus.poor;
    return FeaturePerformanceStatus.underused;
  }
  
  List<String> _identifyDeprecationCandidates(List<FeaturePerformanceReport> reports) {
    return reports
        .where((r) => r.status == FeaturePerformanceStatus.underused && r.engagementRate < 0.05)
        .map((r) => r.featureId)
        .toList();
  }
  
  List<String> _identifyImprovementCandidates(List<FeaturePerformanceReport> reports) {
    return reports
        .where((r) => r.status == FeaturePerformanceStatus.poor || r.status == FeaturePerformanceStatus.fair)
        .map((r) => r.featureId)
        .toList();
  }
  
  Future<Map<String, dynamic>> _analyzeMarketTrends(int year) async {
    // In a real implementation, this would analyze market data
    return {
      'trending_categories': ['AI/ML Integration', 'Social Features', 'Wearable Integration'],
      'declining_categories': ['Basic Themes', 'Simple Export'],
      'emerging_opportunities': ['Voice Guidance', 'AR Meditation', 'Biometric Integration'],
      'market_growth_rate': 0.15,
      'competitor_feature_gaps': ['Sleep Stories', 'Live Sessions', 'Community Challenges'],
    };
  }
  
  Future<Map<String, dynamic>> _analyzeCompetitorFeatures() async {
    // Mock competitor analysis
    return {
      'leading_features': ['Sleep Stories', 'Live Meditation Sessions', 'Community Challenges'],
      'feature_gaps': ['Advanced Breathing Patterns', 'Productivity Integration'],
      'pricing_analysis': {
        'avg_monthly_price': 12.99,
        'our_competitive_position': 'mid-range',
      },
    };
  }
  
  Future<Map<String, dynamic>> _compileUserFeedback() async {
    // In a real implementation, this would analyze user feedback data
    return {
      'most_requested': ['Sleep features', 'More breathing patterns', 'Social sharing'],
      'pain_points': ['Complex UI', 'Limited customization', 'Slow loading'],
      'satisfaction_score': 4.2,
      'nps_score': 45,
    };
  }
  
  Future<List<ProFeatureAnalysisResult>> _selectFeaturesForImplementation(
    List<ProFeatureAnalysisResult> potentialFeatures,
    List<FeaturePerformanceReport> performanceReports,
    Map<String, dynamic> marketAnalysis,
  ) async {
    // Select top features based on priority and market fit
    final selected = potentialFeatures
        .where((f) => f.overallPriorityScore >= 70.0)
        .take(8) // Limit to 8 features for annual plan
        .toList();
    
    return selected;
  }
  
  int _estimateDevelopmentEffort(List<ProFeatureAnalysisResult> features) {
    // Rough estimation based on development effort scores
    double totalEffort = 0;
    
    for (final feature in features) {
      // Convert effort score to months (lower score = more effort)
      final effortMonths = (100 - feature.developmentEffortScore) / 25;
      totalEffort += effortMonths;
    }
    
    return (totalEffort * 0.6).round(); // Account for parallel development
  }
  
  double _projectRevenueImpact(
    List<ProFeatureAnalysisResult> features,
    List<FeaturePerformanceReport> currentPerformance,
  ) {
    // Simplified revenue projection
    double projectedImpact = 0;
    
    for (final feature in features) {
      final conversionLift = feature.conversionImpactScore / 100 * 0.1; // 10% of conversion score
      final revenuePerConversion = 120; // Average annual revenue per Pro user
      projectedImpact += conversionLift * revenuePerConversion * 1000; // 1000 potential conversions
    }
    
    return projectedImpact;
  }
  
  Future<List<String>> _generateImprovementActions(FeaturePerformanceReport report) async {
    final actions = <String>[];
    
    if (report.engagementRate < 0.3) {
      actions.add('Improve feature discoverability in UI');
      actions.add('Add onboarding tutorial for feature');
    }
    
    if (report.conversionImpact < 0.4) {
      actions.add('Enhance feature preview for free users');
      actions.add('Add compelling upgrade messaging');
    }
    
    if (report.retentionImpact < 0.4) {
      actions.add('Improve feature stickiness and habit formation');
      actions.add('Add progress tracking and achievements');
    }
    
    if (report.averageSessionsPerUser < 2.0) {
      actions.add('Simplify feature workflow');
      actions.add('Add quick-start options');
    }
    
    return actions;
  }
  
  String _identifyPrimaryIssue(FeaturePerformanceReport report) {
    if (report.engagementRate < 0.2) return 'Low Discovery';
    if (report.conversionImpact < 0.3) return 'Weak Value Proposition';
    if (report.retentionImpact < 0.3) return 'Poor Retention';
    if (report.averageSessionsPerUser < 1.5) return 'Complex UX';
    return 'General Performance';
  }
  
  int _calculateImprovementPriority(FeaturePerformanceReport report) {
    // Higher priority for features with high potential but current underperformance
    int priority = (100 - report.performanceScore);
    
    // Boost priority for features with high conversion potential
    if (report.conversionImpact > 0.6) priority += 20;
    
    // Boost priority for features with some usage (not completely unused)
    if (report.totalUsageEvents > 100) priority += 10;
    
    return priority.clamp(0, 100);
  }
  
  int _estimateImprovementEffort(FeaturePerformanceReport report) {
    // Estimate effort in person-weeks
    int effort = 2; // Base effort
    
    if (report.engagementRate < 0.1) effort += 3; // Discovery improvements
    if (report.conversionImpact < 0.3) effort += 2; // Value prop work
    if (report.retentionImpact < 0.3) effort += 4; // Retention features
    if (report.averageSessionsPerUser < 1.0) effort += 3; // UX overhaul
    
    return effort;
  }
  
  Future<void> _savePerformanceReports(List<FeaturePerformanceReport> reports) async {
    final reportsJson = jsonEncode(reports.map((r) => r.toJson()).toList());
    await _storage.setString(_performanceReportsKey, reportsJson);
  }
  
  Future<List<FeaturePerformanceReport>> _getLatestPerformanceReports() async {
    final reportsJson = await _storage.getString(_performanceReportsKey);
    if (reportsJson == null) return [];
    
    try {
      final List<dynamic> reportsList = jsonDecode(reportsJson);
      return reportsList.map((json) => _performanceReportFromJson(json)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading performance reports: $e');
      }
      return [];
    }
  }
  
  Future<void> _saveExpansionPlan(ProExpansionPlan plan) async {
    final plansJson = await _storage.getString(_expansionPlansKey) ?? '[]';
    final List<dynamic> plans = jsonDecode(plansJson);
    
    plans.add(plan.toJson());
    
    // Keep only last 5 years of plans
    if (plans.length > 5) {
      plans.removeRange(0, plans.length - 5);
    }
    
    await _storage.setString(_expansionPlansKey, jsonEncode(plans));
  }
  
  Future<ProExpansionPlan?> _getExpansionPlan(int year) async {
    final plansJson = await _storage.getString(_expansionPlansKey);
    if (plansJson == null) return null;
    
    try {
      final List<dynamic> plans = jsonDecode(plansJson);
      final planJson = plans.firstWhere(
        (p) => p['year'] == year,
        orElse: () => null,
      );
      
      return planJson != null ? _expansionPlanFromJson(planJson) : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading expansion plan: $e');
      }
      return null;
    }
  }
  
  FeaturePerformanceReport _performanceReportFromJson(Map<String, dynamic> json) {
    return FeaturePerformanceReport(
      featureId: json['featureId'],
      featureName: json['featureName'],
      reportPeriodStart: DateTime.parse(json['reportPeriodStart']),
      reportPeriodEnd: DateTime.parse(json['reportPeriodEnd']),
      status: FeaturePerformanceStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => FeaturePerformanceStatus.fair,
      ),
      engagementRate: json['engagementRate'],
      conversionImpact: json['conversionImpact'],
      retentionImpact: json['retentionImpact'],
      totalUsageEvents: json['totalUsageEvents'],
      uniqueUsers: json['uniqueUsers'],
      averageSessionsPerUser: json['averageSessionsPerUser'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  ProExpansionPlan _expansionPlanFromJson(Map<String, dynamic> json) {
    return ProExpansionPlan(
      year: json['year'],
      createdAt: DateTime.parse(json['createdAt']),
      proposedFeatures: [], // Simplified for storage
      featuresToDeprecate: List<String>.from(json['featuresToDeprecate'] ?? []),
      featuresToImprove: List<String>.from(json['featuresToImprove'] ?? []),
      marketAnalysis: Map<String, dynamic>.from(json['marketAnalysis'] ?? {}),
      competitorAnalysis: Map<String, dynamic>.from(json['competitorAnalysis'] ?? {}),
      userFeedbackSummary: Map<String, dynamic>.from(json['userFeedbackSummary'] ?? {}),
      estimatedDevelopmentMonths: json['estimatedDevelopmentMonths'],
      projectedRevenueImpact: json['projectedRevenueImpact'],
    );
  }
}
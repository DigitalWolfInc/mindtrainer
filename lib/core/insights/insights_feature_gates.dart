/// Insights Feature Gates for MindTrainer Pro
/// 
/// Controls access to advanced analytics and insights based on subscription status.
/// Free users get basic stats; Pro users get correlations, associations, and trends.

import '../payments/pro_feature_gates.dart';

/// Result of checking insights feature access
class InsightsAccessResult {
  final bool allowed;
  final String? upgradeMessage;
  final String featureName;
  
  const InsightsAccessResult({
    required this.allowed,
    required this.featureName,
    this.upgradeMessage,
  });
  
  /// Feature is accessible
  const InsightsAccessResult.allowed(String featureName)
    : this(allowed: true, featureName: featureName);
  
  /// Feature requires Pro upgrade
  const InsightsAccessResult.requiresPro(String featureName, String message)
    : this(allowed: false, featureName: featureName, upgradeMessage: message);
}

/// Advanced insights feature access controller
class InsightsFeatureGates {
  final MindTrainerProGates _gates;
  
  const InsightsFeatureGates(this._gates);
  
  /// Check if user can access mood-focus correlations
  InsightsAccessResult checkMoodFocusCorrelations() {
    if (_gates.moodFocusCorrelations) {
      return const InsightsAccessResult.allowed('Mood-Focus Correlations');
    }
    
    return const InsightsAccessResult.requiresPro(
      'Mood-Focus Correlations',
      'Discover how your mood affects focus performance with Pro analytics.',
    );
  }
  
  /// Check if user can access tag performance associations
  InsightsAccessResult checkTagAssociations() {
    if (_gates.tagAssociations) {
      return const InsightsAccessResult.allowed('Tag Associations');
    }
    
    return const InsightsAccessResult.requiresPro(
      'Tag Associations', 
      'See which tags are linked to your best focus days with Pro insights.',
    );
  }
  
  /// Check if user can access keyword uplift analysis
  InsightsAccessResult checkKeywordUplift() {
    if (_gates.keywordUplift) {
      return const InsightsAccessResult.allowed('Keyword Uplift');
    }
    
    return const InsightsAccessResult.requiresPro(
      'Keyword Uplift',
      'Analyze which words in your notes predict better focus with Pro.',
    );
  }
  
  /// Check if user can access extended insights history
  InsightsAccessResult checkExtendedHistory() {
    if (_gates.extendedInsightsHistory) {
      return const InsightsAccessResult.allowed('Extended History');
    }
    
    return const InsightsAccessResult.requiresPro(
      'Extended History',
      'Access insights beyond 30 days to see long-term patterns with Pro.',
    );
  }
  
  /// Get available insights features for current user
  List<String> getAvailableFeatures() {
    final features = <String>['Basic Statistics', 'Recent Trends'];
    
    if (_gates.advancedAnalytics) {
      features.addAll([
        'Mood-Focus Correlations',
        'Tag Performance Analysis', 
        'Keyword Uplift Insights',
        'Extended Historical Data',
        'Multi-dimensional Trends',
      ]);
    }
    
    return features;
  }
  
  /// Get locked insights features for current user
  List<String> getLockedFeatures() {
    if (_gates.advancedAnalytics) {
      return []; // Pro users have no locked features
    }
    
    return [
      'Mood-Focus Correlations',
      'Tag Performance Analysis',
      'Keyword Uplift Insights', 
      'Extended Historical Data',
      'Multi-dimensional Trends',
    ];
  }
  
  /// Get insights date range limit for current user
  DateTime getInsightsDateLimit() {
    if (_gates.extendedInsightsHistory) {
      // Pro users can access all historical data
      return DateTime(2020); // Arbitrary early date
    } else {
      // Free users limited to 30 days
      return DateTime.now().subtract(const Duration(days: 30));
    }
  }
  
  /// Check if date range is allowed for current user
  bool isDateRangeAllowed(DateTime from, DateTime to) {
    final limit = getInsightsDateLimit();
    return from.isAfter(limit) || from.isAtSameMomentAs(limit);
  }
  
  /// Get filtered date range respecting user limits
  ({DateTime from, DateTime to}) getFilteredDateRange(DateTime from, DateTime to) {
    final limit = getInsightsDateLimit();
    final adjustedFrom = from.isBefore(limit) ? limit : from;
    return (from: adjustedFrom, to: to);
  }
  
  /// Get upgrade prompt for advanced insights
  String getInsightsUpgradePrompt() {
    return 'Unlock powerful insights with Pro! '
           'Discover mood-focus connections, tag performance patterns, '
           'and keyword analysis to optimize your mental training.';
  }
  
  /// Get Pro insights feature descriptions
  Map<String, String> getProInsightsFeatures() {
    return {
      'Mood-Focus Correlations': 'Statistical analysis of how mood affects focus performance',
      'Tag Associations': 'Identify which session tags predict your best focus days',
      'Keyword Uplift': 'Discover note keywords linked to longer, better sessions',
      'Extended History': 'Access insights beyond 30 days for long-term trend analysis',
      'Multi-dimensional Analysis': 'Complex pattern recognition across all your data',
    };
  }
  
  /// Check if insights data should be filtered for free users
  bool shouldFilterInsightsData() {
    return !_gates.advancedAnalytics;
  }
  
  /// Get insights tier description for current user
  String getInsightsTierDescription() {
    if (_gates.advancedAnalytics) {
      return 'Pro Analytics - Full insights with unlimited history';
    } else {
      return 'Free Analytics - Basic stats for the last 30 days';
    }
  }
}
import 'dart:math';
import '../analytics/conversion_analytics.dart';

/// Pure Dart A/B testing framework for UI and copy variants
/// Uses deterministic assignment based on user ID for consistency
class ABTestFramework {
  final ConversionAnalytics _analytics = ConversionAnalytics();
  static final ABTestFramework _instance = ABTestFramework._internal();
  
  factory ABTestFramework() => _instance;
  ABTestFramework._internal();

  final Map<String, ABTest> _activeTests = {};
  final Map<String, String> _userAssignments = {}; // In real app, persist to storage

  /// Initialize A/B tests for the current session
  void initializeTests() {
    _setupCopyVariantTests();
    _setupUIVariantTests();
    _setupTimingTests();
    _setupPromptTests();
  }

  /// Set up copy variant tests for different messaging approaches
  void _setupCopyVariantTests() {
    // Test upgrade prompt messaging
    _activeTests['upgrade_prompt_copy'] = ABTest(
      testId: 'upgrade_prompt_copy',
      testName: 'Upgrade Prompt Copy Variants',
      variants: [
        ABVariant(
          variantId: 'control',
          name: 'Control - Standard Message',
          weight: 25,
          config: {
            'title': 'Upgrade to Pro',
            'message': 'Unlock advanced analytics features to optimize your focus journey.',
            'cta': 'Upgrade',
            'secondary': 'Not Now',
          },
        ),
        ABVariant(
          variantId: 'value_focused',
          name: 'Value-Focused Messaging',
          weight: 25,
          config: {
            'title': 'Transform Your Focus',
            'message': 'Discover exactly what drives your best sessions with Pro analytics insights.',
            'cta': 'Get Insights',
            'secondary': 'Maybe Later',
          },
        ),
        ABVariant(
          variantId: 'urgency_based',
          name: 'Urgency-Based Messaging',
          weight: 25,
          config: {
            'title': 'Don\'t Miss Out',
            'message': 'You\'re already engaged - unlock your full potential with Pro features.',
            'cta': 'Unlock Now',
            'secondary': 'Skip',
          },
        ),
        ABVariant(
          variantId: 'social_proof',
          name: 'Social Proof Messaging',
          weight: 25,
          config: {
            'title': 'Join Thousands of Pro Users',
            'message': 'Pro users report 40% better focus consistency with our advanced analytics.',
            'cta': 'Join Pro Community',
            'secondary': 'Stay Basic',
          },
        ),
      ],
      isActive: true,
    );

    // Test Pro badge copy
    _activeTests['pro_badge_text'] = ABTest(
      testId: 'pro_badge_text',
      testName: 'Pro Badge Text Variants',
      variants: [
        ABVariant(
          variantId: 'control',
          name: 'Control - PRO',
          weight: 33,
          config: {'badge_text': 'PRO'},
        ),
        ABVariant(
          variantId: 'upgrade',
          name: 'Action-Oriented - UPGRADE',
          weight: 33,
          config: {'badge_text': 'UPGRADE'},
        ),
        ABVariant(
          variantId: 'plus',
          name: 'Simple - PLUS',
          weight: 34,
          config: {'badge_text': 'PLUS'},
        ),
      ],
      isActive: true,
    );
  }

  /// Set up UI variant tests for visual elements
  void _setupUIVariantTests() {
    // Test Pro badge colors
    _activeTests['pro_badge_color'] = ABTest(
      testId: 'pro_badge_color',
      testName: 'Pro Badge Color Variants',
      variants: [
        ABVariant(
          variantId: 'control',
          name: 'Control - Amber',
          weight: 25,
          config: {
            'badge_color': 'amber',
            'text_color': 'black',
          },
        ),
        ABVariant(
          variantId: 'gold',
          name: 'Gold Variant',
          weight: 25,
          config: {
            'badge_color': 'gold',
            'text_color': 'black',
          },
        ),
        ABVariant(
          variantId: 'purple',
          name: 'Purple Premium',
          weight: 25,
          config: {
            'badge_color': 'purple',
            'text_color': 'white',
          },
        ),
        ABVariant(
          variantId: 'gradient',
          name: 'Gradient Badge',
          weight: 25,
          config: {
            'badge_color': 'gradient',
            'text_color': 'white',
          },
        ),
      ],
      isActive: true,
    );

    // Test upgrade button styling
    _activeTests['upgrade_button_style'] = ABTest(
      testId: 'upgrade_button_style',
      testName: 'Upgrade Button Style Variants',
      variants: [
        ABVariant(
          variantId: 'control',
          name: 'Control - Standard',
          weight: 50,
          config: {
            'style': 'elevated',
            'color_scheme': 'amber',
            'icon': 'star',
          },
        ),
        ABVariant(
          variantId: 'premium',
          name: 'Premium Look',
          weight: 50,
          config: {
            'style': 'elevated',
            'color_scheme': 'gradient_gold',
            'icon': 'diamond',
          },
        ),
      ],
      isActive: true,
    );
  }

  /// Set up timing-based tests
  void _setupTimingTests() {
    _activeTests['prompt_timing'] = ABTest(
      testId: 'prompt_timing',
      testName: 'Prompt Timing Strategy',
      variants: [
        ABVariant(
          variantId: 'immediate',
          name: 'Immediate Prompts',
          weight: 50,
          config: {
            'delay_seconds': 0,
            'show_on_first_visit': true,
          },
        ),
        ABVariant(
          variantId: 'delayed',
          name: 'Delayed Prompts',
          weight: 50,
          config: {
            'delay_seconds': 5,
            'show_on_first_visit': false,
          },
        ),
      ],
      isActive: true,
    );
  }

  /// Set up prompt frequency tests
  void _setupPromptTests() {
    _activeTests['prompt_frequency'] = ABTest(
      testId: 'prompt_frequency',
      testName: 'Prompt Frequency Strategy',
      variants: [
        ABVariant(
          variantId: 'gentle',
          name: 'Gentle Approach',
          weight: 33,
          config: {
            'max_prompts_per_day': 1,
            'cooldown_hours': 24,
          },
        ),
        ABVariant(
          variantId: 'moderate',
          name: 'Moderate Approach',
          weight: 33,
          config: {
            'max_prompts_per_day': 2,
            'cooldown_hours': 12,
          },
        ),
        ABVariant(
          variantId: 'active',
          name: 'Active Approach',
          weight: 34,
          config: {
            'max_prompts_per_day': 3,
            'cooldown_hours': 8,
          },
        ),
      ],
      isActive: true,
    );
  }

  /// Get variant for a specific test
  ABVariant? getVariant(String testId, [String? userId]) {
    final test = _activeTests[testId];
    if (test == null || !test.isActive) return null;

    userId ??= _generateUserId();
    
    // Check cached assignment
    final cacheKey = '${testId}_$userId';
    if (_userAssignments.containsKey(cacheKey)) {
      final variantId = _userAssignments[cacheKey]!;
      return test.variants.firstWhere((v) => v.variantId == variantId);
    }

    // Assign variant deterministically
    final assignedVariant = _assignVariant(test, userId);
    _userAssignments[cacheKey] = assignedVariant.variantId;
    
    // Track assignment
    _analytics.trackEngagement('ab_test_assignment', 1.0, {
      'test_id': testId,
      'variant_id': assignedVariant.variantId,
      'variant_name': assignedVariant.name,
      'user_id_hash': _hashUserId(userId),
    });

    return assignedVariant;
  }

  /// Assign variant based on consistent hashing
  ABVariant _assignVariant(ABTest test, String userId) {
    final hash = _hashString('${test.testId}_$userId');
    final randomValue = hash % 100;
    
    int cumulativeWeight = 0;
    for (final variant in test.variants) {
      cumulativeWeight += variant.weight;
      if (randomValue < cumulativeWeight) {
        return variant;
      }
    }
    
    return test.variants.last; // Fallback
  }

  /// Track conversion for A/B test variant
  void trackConversion(String testId, String conversionEvent, [String? userId]) {
    userId ??= _generateUserId();
    final cacheKey = '${testId}_$userId';
    final variantId = _userAssignments[cacheKey];
    
    if (variantId != null) {
      _analytics.trackConversion('ab_test_conversion', 'ab_test', {
        'test_id': testId,
        'variant_id': variantId,
        'conversion_event': conversionEvent,
        'user_id_hash': _hashUserId(userId),
      });
    }
  }

  /// Track interaction for A/B test variant
  void trackInteraction(String testId, String interaction, Map<String, dynamic>? metadata, [String? userId]) {
    userId ??= _generateUserId();
    final cacheKey = '${testId}_$userId';
    final variantId = _userAssignments[cacheKey];
    
    if (variantId != null) {
      _analytics.trackEngagement('ab_test_interaction', 1.0, {
        'test_id': testId,
        'variant_id': variantId,
        'interaction': interaction,
        'user_id_hash': _hashUserId(userId),
        'metadata': metadata ?? {},
      });
    }
  }

  /// Get configuration value for current variant
  T? getConfig<T>(String testId, String configKey, [String? userId]) {
    final variant = getVariant(testId, userId);
    return variant?.config[configKey] as T?;
  }

  /// Get test results summary for analysis
  Map<String, dynamic> getTestSummary() {
    return {
      'active_tests': _activeTests.length,
      'total_assignments': _userAssignments.length,
      'tests': _activeTests.map((id, test) => MapEntry(id, {
        'name': test.testName,
        'variants': test.variants.length,
        'is_active': test.isActive,
      })),
    };
  }

  /// Consistent hash function for user assignment
  int _hashString(String input) {
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = ((hash << 5) - hash + input.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    return hash.abs();
  }

  /// Generate consistent user ID hash for privacy
  String _hashUserId(String userId) {
    return _hashString(userId).toString();
  }

  /// Generate user ID (in real app, would be persistent)
  String _generateUserId() {
    return 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Clear test assignments (for testing purposes)
  void clearAssignments() {
    _userAssignments.clear();
  }
}

/// A/B test definition
class ABTest {
  final String testId;
  final String testName;
  final List<ABVariant> variants;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;

  ABTest({
    required this.testId,
    required this.testName,
    required this.variants,
    required this.isActive,
    this.startDate,
    this.endDate,
  });

  /// Validate that variant weights sum to 100
  bool get isValidWeights {
    final totalWeight = variants.fold(0, (sum, v) => sum + v.weight);
    return totalWeight == 100;
  }
}

/// A/B test variant
class ABVariant {
  final String variantId;
  final String name;
  final int weight; // Percentage (0-100)
  final Map<String, dynamic> config;

  ABVariant({
    required this.variantId,
    required this.name,
    required this.weight,
    required this.config,
  });
}

/// Helper methods for using A/B test results in UI
extension ABTestUI on ABTestFramework {
  /// Get Pro badge text based on A/B test
  String getProBadgeText([String? userId]) {
    return getConfig<String>('pro_badge_text', 'badge_text', userId) ?? 'PRO';
  }

  /// Get Pro badge colors based on A/B test
  Map<String, String> getProBadgeColors([String? userId]) {
    final variant = getVariant('pro_badge_color', userId);
    return {
      'badge_color': variant?.config['badge_color'] ?? 'amber',
      'text_color': variant?.config['text_color'] ?? 'black',
    };
  }

  /// Get upgrade prompt configuration
  Map<String, String> getUpgradePromptConfig([String? userId]) {
    final variant = getVariant('upgrade_prompt_copy', userId);
    return {
      'title': variant?.config['title'] ?? 'Upgrade to Pro',
      'message': variant?.config['message'] ?? 'Unlock advanced features.',
      'cta': variant?.config['cta'] ?? 'Upgrade',
      'secondary': variant?.config['secondary'] ?? 'Not Now',
    };
  }

  /// Get prompt timing configuration
  Map<String, dynamic> getPromptTimingConfig([String? userId]) {
    final variant = getVariant('prompt_timing', userId);
    return {
      'delay_seconds': variant?.config['delay_seconds'] ?? 0,
      'show_on_first_visit': variant?.config['show_on_first_visit'] ?? true,
    };
  }

  /// Get prompt frequency configuration  
  Map<String, int> getPromptFrequencyConfig([String? userId]) {
    final variant = getVariant('prompt_frequency', userId);
    return {
      'max_prompts_per_day': variant?.config['max_prompts_per_day'] ?? 1,
      'cooldown_hours': variant?.config['cooldown_hours'] ?? 24,
    };
  }
}
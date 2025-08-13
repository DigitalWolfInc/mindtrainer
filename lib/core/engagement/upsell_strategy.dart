/// Upsell Strategy System for MindTrainer Pro
/// 
/// Identifies optimal moments for upgrade prompts and provides policy-compliant
/// messaging with different styles (supportive, achievement-based, curiosity-based).

import 'dart:math';
import '../payments/pro_feature_gates.dart';
import '../analytics/pro_conversion_analytics.dart';

/// Upsell moment types - when to show upgrade prompts
enum UpsellMoment {
  /// User hits daily session limit (5 sessions)
  dailyLimitReached,
  /// User completes a streak milestone (3, 7, 14, 30 days)
  streakMilestone,
  /// User has been consistently active (5+ days with sessions)
  highEngagement,
  /// User tries to access Pro feature (environments, breathing patterns)
  proFeatureBlocked,
  /// User completes a goal or achievement
  achievementUnlocked,
  /// Perfect timing: end of successful session
  postSessionSuccess,
  /// User explores settings/preferences (showing interest in customization)
  customizationInterest,
}

/// Upsell message style variants
enum UpsellMessageStyle {
  /// Supportive, encouraging tone
  supportive,
  /// Achievement-focused, celebration tone  
  achievement,
  /// Curiosity-driven, discovery tone
  curiosity,
  /// Practical benefits, value-focused tone
  value,
}

/// Upsell message content
class UpsellMessage {
  final String title;
  final String message;
  final String ctaText;
  final UpsellMessageStyle style;
  final Map<String, dynamic> context;
  
  const UpsellMessage({
    required this.title,
    required this.message,
    required this.ctaText,
    required this.style,
    this.context = const {},
  });
}

/// Upsell opportunity data
class UpsellOpportunity {
  final UpsellMoment moment;
  final UpsellMessage message;
  final double confidenceScore; // 0.0 - 1.0
  final DateTime timestamp;
  final Map<String, dynamic> contextData;
  
  UpsellOpportunity({
    required this.moment,
    required this.message,
    required this.confidenceScore,
    DateTime? timestamp,
    this.contextData = const {},
  }) : timestamp = timestamp ?? DateTime.now();
  
  /// Whether this is a high-confidence opportunity
  bool get isHighConfidence => confidenceScore >= 0.7;
  
  /// Whether this is a prime opportunity  
  bool get isPrime => confidenceScore >= 0.8;
}

/// Upsell strategy configuration
class UpsellConfig {
  /// Maximum upsells per day to avoid spam
  final int maxUpseIlsPerDay;
  
  /// Minimum time between upsells (hours)
  final int minHoursBetweenUpsells;
  
  /// Whether to use A/B testing for message styles
  final bool enableStyleTesting;
  
  /// Cool-down period after user dismisses upsell (hours)
  final int dismissCooldownHours;
  
  const UpsellConfig({
    this.maxUpseIlsPerDay = 3,
    this.minHoursBetweenUpsells = 2,
    this.enableStyleTesting = true,
    this.dismissCooldownHours = 24,
  });
}

/// Main upsell strategy system
class UpsellStrategy {
  final MindTrainerProGates _proGates;
  final ProConversionAnalytics _analytics;
  final UpsellConfig _config;
  
  final Map<UpsellMoment, DateTime> _lastShownTimes = {};
  final Map<UpsellMoment, int> _dismissCounts = {};
  final Random _random = Random();
  
  UpsellStrategy(
    this._proGates,
    this._analytics,
    this._config,
  );
  
  /// Check if an upsell opportunity should be shown
  Future<UpsellOpportunity?> evaluateUpsellOpportunity(
    UpsellMoment moment,
    Map<String, dynamic> context,
  ) async {
    // Don't upsell Pro users
    if (_proGates.isProActive) return null;
    
    // Check rate limiting
    if (!_shouldShowUpsell(moment)) return null;
    
    // Calculate confidence score
    final confidence = _calculateConfidenceScore(moment, context);
    if (confidence < 0.5) return null;
    
    // Generate appropriate message
    final message = _generateMessage(moment, context);
    
    // Track analytics
    await _analytics.trackUpgradeScreenView('free', 
      source: moment.name,
      feature: context['feature'] as String?,
    );
    
    return UpsellOpportunity(
      moment: moment,
      message: message,
      confidenceScore: confidence,
      contextData: context,
    );
  }
  
  /// Record that user dismissed an upsell
  Future<void> recordDismissal(UpsellMoment moment) async {
    _lastShownTimes[moment] = DateTime.now();
    _dismissCounts[moment] = (_dismissCounts[moment] ?? 0) + 1;
    
    // Track analytics
    await _analytics.track(ProConversionData(
      event: ProConversionEvent.upgradeScreenViewed,
      userTier: 'free',
      properties: {
        'moment': moment.name,
        'action': 'dismissed',
        'dismiss_count': _dismissCounts[moment],
      },
    ));
  }
  
  /// Record that user clicked upgrade from upsell
  Future<void> recordUpgradeClick(UpsellMoment moment, UpsellMessageStyle style) async {
    await _analytics.trackUpgradeCtaClick('free', 
      ctaLocation: moment.name,
    );
    
    await _analytics.track(ProConversionData(
      event: ProConversionEvent.upgradeCtaClicked,
      userTier: 'free',
      properties: {
        'moment': moment.name,
        'message_style': style.name,
        'confidence': _calculateConfidenceScore(moment, {}),
      },
    ));
  }
  
  // Private methods
  
  bool _shouldShowUpsell(UpsellMoment moment) {
    final lastShown = _lastShownTimes[moment];
    if (lastShown != null) {
      final hoursSince = DateTime.now().difference(lastShown).inHours;
      if (hoursSince < _config.minHoursBetweenUpsells) return false;
    }
    
    // Check dismiss count - reduce frequency for repeatedly dismissed upsells
    final dismissCount = _dismissCounts[moment] ?? 0;
    if (dismissCount >= 3) return false; // Stop showing after 3 dismissals
    
    return true;
  }
  
  double _calculateConfidenceScore(UpsellMoment moment, Map<String, dynamic> context) {
    double baseScore = 0.5;
    
    switch (moment) {
      case UpsellMoment.dailyLimitReached:
        baseScore = 0.9; // High confidence - clear value prop
        break;
      case UpsellMoment.streakMilestone:
        final streak = context['streak'] as int? ?? 0;
        baseScore = 0.6 + (streak / 30).clamp(0.0, 0.3); // Higher for longer streaks
        break;
      case UpsellMoment.highEngagement:
        final sessionCount = context['recent_sessions'] as int? ?? 0;
        baseScore = 0.5 + (sessionCount / 20).clamp(0.0, 0.3);
        break;
      case UpsellMoment.proFeatureBlocked:
        baseScore = 0.8; // High interest demonstrated
        break;
      case UpsellMoment.achievementUnlocked:
        baseScore = 0.7; // Good mood for upgrade
        break;
      case UpsellMoment.postSessionSuccess:
        final rating = context['session_rating'] as int? ?? 3;
        baseScore = 0.4 + (rating / 5) * 0.3; // Higher for better ratings
        break;
      case UpsellMoment.customizationInterest:
        baseScore = 0.6; // Shows interest in features
        break;
    }
    
    // Reduce score based on dismiss history
    final dismissCount = _dismissCounts[moment] ?? 0;
    baseScore *= (1.0 - (dismissCount * 0.2)).clamp(0.1, 1.0);
    
    return baseScore.clamp(0.0, 1.0);
  }
  
  UpsellMessage _generateMessage(UpsellMoment moment, Map<String, dynamic> context) {
    final style = _selectMessageStyle();
    
    switch (moment) {
      case UpsellMoment.dailyLimitReached:
        return _generateDailyLimitMessage(style, context);
      case UpsellMoment.streakMilestone:
        return _generateStreakMessage(style, context);
      case UpsellMoment.highEngagement:
        return _generateEngagementMessage(style, context);
      case UpsellMoment.proFeatureBlocked:
        return _generateBlockedFeatureMessage(style, context);
      case UpsellMoment.achievementUnlocked:
        return _generateAchievementMessage(style, context);
      case UpsellMoment.postSessionSuccess:
        return _generatePostSessionMessage(style, context);
      case UpsellMoment.customizationInterest:
        return _generateCustomizationMessage(style, context);
    }
  }
  
  UpsellMessageStyle _selectMessageStyle() {
    if (_config.enableStyleTesting) {
      // A/B test different styles
      return UpsellMessageStyle.values[_random.nextInt(UpsellMessageStyle.values.length)];
    }
    return UpsellMessageStyle.supportive;
  }
  
  UpsellMessage _generateDailyLimitMessage(UpsellMessageStyle style, Map<String, dynamic> context) {
    switch (style) {
      case UpsellMessageStyle.supportive:
        return const UpsellMessage(
          title: "You're dedicated to your practice!",
          message: "You've completed 5 focus sessions today—amazing commitment! "
                  "Pro users enjoy unlimited daily sessions to maintain their flow state.",
          ctaText: "Continue with Pro",
          style: UpsellMessageStyle.supportive,
        );
      case UpsellMessageStyle.achievement:
        return const UpsellMessage(
          title: "5 sessions completed! 🎯",
          message: "You're in the zone today! Why stop when you're crushing it? "
                  "Upgrade to Pro for unlimited sessions and keep the momentum going.",
          ctaText: "Unlock Unlimited",
          style: UpsellMessageStyle.achievement,
        );
      case UpsellMessageStyle.curiosity:
        return const UpsellMessage(
          title: "What could you achieve with more sessions?",
          message: "You've reached today's free session limit, but your focus is just getting started. "
                  "Discover what unlimited practice feels like.",
          ctaText: "Explore Pro",
          style: UpsellMessageStyle.curiosity,
        );
      case UpsellMessageStyle.value:
        return const UpsellMessage(
          title: "Ready for unlimited sessions?",
          message: "You're getting great value from MindTrainer! Pro adds unlimited daily sessions, "
                  "premium environments, and breathing guides for just \$0.33/day.",
          ctaText: "See Pro Plans",
          style: UpsellMessageStyle.value,
        );
    }
  }
  
  UpsellMessage _generateStreakMessage(UpsellMessageStyle style, Map<String, dynamic> context) {
    final streak = context['streak'] as int? ?? 0;
    
    switch (style) {
      case UpsellMessageStyle.supportive:
        return UpsellMessage(
          title: "$streak-day streak! Keep it growing 🔥",
          message: "Your consistency is inspiring! Pro features like premium environments "
                  "and breathing patterns help deepen your daily practice.",
          ctaText: "Enhance Your Streak",
          style: UpsellMessageStyle.supportive,
        );
      case UpsellMessageStyle.achievement:
        return UpsellMessage(
          title: "🏆 $streak days of excellence!",
          message: "You're crushing your mindfulness goals! Celebrate this achievement "
                  "by unlocking all the premium tools that match your dedication.",
          ctaText: "Claim Pro Features",
          style: UpsellMessageStyle.achievement,
        );
      case UpsellMessageStyle.curiosity:
        return UpsellMessage(
          title: "What's next after $streak days?",
          message: "You've built an amazing habit! Curious what advanced breathing techniques "
                  "and forest soundscapes could add to your practice?",
          ctaText: "Discover More",
          style: UpsellMessageStyle.curiosity,
        );
      case UpsellMessageStyle.value:
        return UpsellMessage(
          title: "$streak-day streak deserves Pro tools",
          message: "Your commitment proves mindfulness matters to you. Pro features "
                  "provide the depth and variety serious practitioners need.",
          ctaText: "Match Your Commitment",
          style: UpsellMessageStyle.value,
        );
    }
  }
  
  UpsellMessage _generateEngagementMessage(UpsellMessageStyle style, Map<String, dynamic> context) {
    switch (style) {
      case UpsellMessageStyle.supportive:
        return const UpsellMessage(
          title: "You're building something beautiful",
          message: "Your regular practice shows real dedication to growth. Pro features "
                  "are designed to support committed practitioners like you.",
          ctaText: "Deepen Your Practice",
          style: UpsellMessageStyle.supportive,
        );
      default:
        return const UpsellMessage(
          title: "Consistent practice deserves premium tools",
          message: "You're showing up every day—that's incredible! Pro features help "
                  "engaged users like you explore deeper levels of focus and calm.",
          ctaText: "Unlock Pro Tools",
          style: UpsellMessageStyle.value,
        );
    }
  }
  
  UpsellMessage _generateBlockedFeatureMessage(UpsellMessageStyle style, Map<String, dynamic> context) {
    final feature = context['feature'] as String? ?? 'Pro feature';
    
    switch (style) {
      case UpsellMessageStyle.curiosity:
        return UpsellMessage(
          title: "Curious about $feature?",
          message: "This premium feature enhances your meditation experience with "
                  "advanced capabilities designed for deeper practice.",
          ctaText: "Try It Now",
          style: UpsellMessageStyle.curiosity,
        );
      default:
        return UpsellMessage(
          title: "Ready to unlock $feature?",
          message: "You're interested in premium features! Pro gives you access to "
                  "all advanced tools plus unlimited sessions.",
          ctaText: "Get Full Access",
          style: UpsellMessageStyle.value,
        );
    }
  }
  
  UpsellMessage _generateAchievementMessage(UpsellMessageStyle style, Map<String, dynamic> context) {
    switch (style) {
      case UpsellMessageStyle.achievement:
        return const UpsellMessage(
          title: "🎉 Achievement unlocked!",
          message: "You're making real progress! Celebrate by unlocking Pro features "
                  "that help high achievers like you reach even greater heights.",
          ctaText: "Level Up with Pro",
          style: UpsellMessageStyle.achievement,
        );
      default:
        return const UpsellMessage(
          title: "Great achievement!",
          message: "You're progressing beautifully in your mindfulness journey. "
                  "Pro features provide the advanced tools for continued growth.",
          ctaText: "Continue Growing",
          style: UpsellMessageStyle.supportive,
        );
    }
  }
  
  UpsellMessage _generatePostSessionMessage(UpsellMessageStyle style, Map<String, dynamic> context) {
    final rating = context['session_rating'] as int? ?? 3;
    
    if (rating >= 4) {
      return const UpsellMessage(
        title: "Amazing session! ✨",
        message: "You just had a great meditation! Imagine having access to "
                "premium environments and breathing guides for every session.",
        ctaText: "Enhance Every Session",
        style: UpsellMessageStyle.supportive,
      );
    }
    
    return const UpsellMessage(
      title: "Session complete!",
      message: "Pro users enjoy premium features that help make every session "
              "as effective as possible. Explore what you're missing!",
      ctaText: "See Pro Features",
      style: UpsellMessageStyle.curiosity,
    );
  }
  
  UpsellMessage _generateCustomizationMessage(UpsellMessageStyle style, Map<String, dynamic> context) {
    return const UpsellMessage(
      title: "Love customizing your experience?",
      message: "Pro features include premium themes, environment presets, "
              "and advanced settings for users who appreciate personalization.",
      ctaText: "Customize Everything",
      style: UpsellMessageStyle.curiosity,
    );
  }
}
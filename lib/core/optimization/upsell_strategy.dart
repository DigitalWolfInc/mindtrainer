/// Intelligent Upsell Strategy for MindTrainer
/// 
/// Identifies optimal moments for Pro upgrades and delivers
/// contextually relevant, policy-compliant messaging.

import 'dart:math';
import '../storage/local_storage.dart';
import '../payments/pro_status.dart';
import 'experiment_framework.dart';
import 'engagement_system.dart';

/// Upsell trigger contexts
enum UpsellTrigger {
  sessionLimitReached,
  strongStreakDay,
  coachingPhaseBlocked,
  analyticsInterest,
  exportAttempt,
  goalAchievement,
  highEngagement,
  featureDiscovery,
}

/// Upsell message styles for A/B testing
enum MessageStyle {
  supportive,
  achievement,
  curiosity,
}

/// Upsell opportunity scoring
class UpsellOpportunity {
  final UpsellTrigger trigger;
  final double score;
  final Map<String, dynamic> context;
  final DateTime timestamp;
  
  const UpsellOpportunity({
    required this.trigger,
    required this.score,
    required this.context,
    required this.timestamp,
  });
  
  /// Check if opportunity is high-value
  bool get isHighValue => score >= 0.7;
  
  /// Get contextual urgency
  UpsellUrgency get urgency {
    if (score >= 0.8) return UpsellUrgency.high;
    if (score >= 0.6) return UpsellUrgency.medium;
    return UpsellUrgency.low;
  }
}

/// Upsell urgency levels
enum UpsellUrgency { low, medium, high }

/// Upsell message configuration
class UpsellMessage {
  final String headline;
  final String body;
  final String ctaText;
  final String? secondaryAction;
  final MessageStyle style;
  final Map<String, dynamic> metadata;
  
  const UpsellMessage({
    required this.headline,
    required this.body,
    required this.ctaText,
    this.secondaryAction,
    required this.style,
    this.metadata = const {},
  });
  
  /// Create supportive style message
  factory UpsellMessage.supportive({
    required UpsellTrigger trigger,
    required Map<String, dynamic> context,
  }) {
    switch (trigger) {
      case UpsellTrigger.sessionLimitReached:
        return const UpsellMessage(
          headline: 'Keep the momentum going',
          body: 'You\'ve reached your daily limit, but your journey doesn\'t have to stop here. Continue practicing with unlimited sessions.',
          ctaText: 'Continue your growth',
          secondaryAction: 'Maybe later',
          style: MessageStyle.supportive,
        );
        
      case UpsellTrigger.strongStreakDay:
        final days = context['streak_days'] ?? 0;
        return UpsellMessage(
          headline: 'You\'re building something beautiful',
          body: '$days days of mindful practice shows real commitment. Unlock advanced insights to see how far you\'ve come.',
          ctaText: 'Deepen your practice',
          secondaryAction: 'Keep going free',
          style: MessageStyle.supportive,
        );
        
      case UpsellTrigger.coachingPhaseBlocked:
        return const UpsellMessage(
          headline: 'Your coach has more to share',
          body: 'There\'s personalized guidance waiting for you. Unlock the full coaching experience to accelerate your growth.',
          ctaText: 'Get full guidance',
          secondaryAction: 'Stay with basics',
          style: MessageStyle.supportive,
        );
        
      default:
        return const UpsellMessage(
          headline: 'Ready for more?',
          body: 'You\'ve been making great progress. Pro features can help you go even deeper.',
          ctaText: 'Explore Pro',
          style: MessageStyle.supportive,
        );
    }
  }
  
  /// Create achievement style message
  factory UpsellMessage.achievement({
    required UpsellTrigger trigger,
    required Map<String, dynamic> context,
  }) {
    switch (trigger) {
      case UpsellTrigger.sessionLimitReached:
        return const UpsellMessage(
          headline: 'You\'re on fire! 🔥',
          body: 'Crushing your daily limit shows dedication. Champions don\'t stop here - unlock unlimited practice.',
          ctaText: 'Unlock your potential',
          secondaryAction: 'Wait until tomorrow',
          style: MessageStyle.achievement,
        );
        
      case UpsellTrigger.strongStreakDay:
        final days = context['streak_days'] ?? 0;
        return UpsellMessage(
          headline: 'Streak champion! 🏆',
          body: '$days consecutive days! You\'ve proven your commitment. Pro analytics show exactly how much you\'ve grown.',
          ctaText: 'Celebrate with Pro',
          secondaryAction: 'Keep the streak',
          style: MessageStyle.achievement,
        );
        
      case UpsellTrigger.goalAchievement:
        return const UpsellMessage(
          headline: 'Goal crushed! 🎯',
          body: 'You just achieved something amazing. Set bigger goals and track advanced metrics with Pro.',
          ctaText: 'Level up',
          secondaryAction: 'Set new goal',
          style: MessageStyle.achievement,
        );
        
      default:
        return const UpsellMessage(
          headline: 'You\'re ready to level up',
          body: 'Your progress shows you\'re serious about growth. Pro features are built for achievers like you.',
          ctaText: 'Claim your upgrade',
          style: MessageStyle.achievement,
        );
    }
  }
  
  /// Create curiosity style message  
  factory UpsellMessage.curiosity({
    required UpsellTrigger trigger,
    required Map<String, dynamic> context,
  }) {
    switch (trigger) {
      case UpsellTrigger.sessionLimitReached:
        return const UpsellMessage(
          headline: 'What if you could go deeper?',
          body: 'You\'ve hit today\'s limit, but what insights are waiting beyond? Discover unlimited exploration.',
          ctaText: 'Discover more',
          secondaryAction: 'Wonder tomorrow',
          style: MessageStyle.curiosity,
        );
        
      case UpsellTrigger.analyticsInterest:
        return const UpsellMessage(
          headline: 'Hidden patterns in your data',
          body: 'There are insights about your mindfulness journey that only you can see. What would they reveal?',
          ctaText: 'Uncover insights',
          secondaryAction: 'Maybe later',
          style: MessageStyle.curiosity,
        );
        
      case UpsellTrigger.featureDiscovery:
        final feature = context['blocked_feature'] ?? 'advanced features';
        return UpsellMessage(
          headline: 'Ever wondered about $feature?',
          body: 'There\'s a whole dimension of mindfulness practice waiting to be explored. Curious what you\'d discover?',
          ctaText: 'Explore the unknown',
          secondaryAction: 'Stay curious',
          style: MessageStyle.curiosity,
        );
        
      default:
        return const UpsellMessage(
          headline: 'What\'s beyond the horizon?',
          body: 'You\'ve been exploring mindfulness beautifully. Pro features reveal what\'s possible next.',
          ctaText: 'See what\'s possible',
          style: MessageStyle.curiosity,
        );
    }
  }
}

/// Intelligent upsell strategy system
class UpsellStrategy {
  static const String _opportunityHistoryKey = 'upsell_opportunities';
  static const String _conversionAttemptsKey = 'conversion_attempts';
  static const String _cooldownKey = 'upsell_cooldown';
  
  final LocalStorage _storage;
  final ExperimentFramework _experiments;
  final EngagementSystem _engagement;
  final List<UpsellOpportunity> _sessionOpportunities = [];
  
  UpsellStrategy(this._storage, this._experiments, this._engagement);
  
  /// Initialize upsell strategy
  Future<void> initialize() async {
    // System is ready to track opportunities
  }
  
  /// Track potential upsell trigger
  Future<UpsellOpportunity?> evaluateTrigger(
    UpsellTrigger trigger, 
    Map<String, dynamic> context,
  ) async {
    // Check cooldown period
    if (await _isInCooldown()) {
      return null;
    }
    
    final score = await _calculateOpportunityScore(trigger, context);
    
    if (score < 0.3) {
      return null; // Too low probability
    }
    
    final opportunity = UpsellOpportunity(
      trigger: trigger,
      score: score,
      context: context,
      timestamp: DateTime.now(),
    );
    
    _sessionOpportunities.add(opportunity);
    await _persistOpportunity(opportunity);
    
    return opportunity;
  }
  
  /// Get upsell message for opportunity
  UpsellMessage getUpsellMessage(UpsellOpportunity opportunity) {
    final style = _getExperimentMessageStyle();
    
    switch (style) {
      case MessageStyle.supportive:
        return UpsellMessage.supportive(
          trigger: opportunity.trigger,
          context: opportunity.context,
        );
      case MessageStyle.achievement:
        return UpsellMessage.achievement(
          trigger: opportunity.trigger,
          context: opportunity.context,
        );
      case MessageStyle.curiosity:
        return UpsellMessage.curiosity(
          trigger: opportunity.trigger,
          context: opportunity.context,
        );
    }
  }
  
  /// Record conversion attempt
  Future<void> recordConversionAttempt({
    required UpsellOpportunity opportunity,
    required bool converted,
    required bool dismissed,
  }) async {
    final attempt = {
      'trigger': opportunity.trigger.toString(),
      'score': opportunity.score,
      'converted': converted,
      'dismissed': dismissed,
      'timestamp': DateTime.now().toIso8601String(),
      'message_style': _getExperimentMessageStyle().toString(),
    };
    
    await _persistConversionAttempt(attempt);
    
    // Set cooldown if dismissed
    if (dismissed) {
      await _setCooldown(converted ? 7 : 3); // Longer cooldown if converted
    }
    
    // Track engagement event
    if (converted) {
      await _engagement.trackEvent(EngagementEvent.proUpgrade);
    }
  }
  
  /// Calculate opportunity score based on context and engagement
  Future<double> _calculateOpportunityScore(
    UpsellTrigger trigger,
    Map<String, dynamic> context,
  ) async {
    final pattern = await _engagement.getEngagementPattern();
    final recentAttempts = await _getRecentConversionAttempts(7);
    
    double baseScore = _getBaseTriggerScore(trigger);
    
    // Engagement level multiplier
    switch (pattern.level) {
      case EngagementLevel.high:
        baseScore *= 1.3;
        break;
      case EngagementLevel.medium:
        baseScore *= 1.1;
        break;
      case EngagementLevel.low:
        baseScore *= 0.7;
        break;
    }
    
    // Streak bonus
    if (pattern.consecutiveDays >= 3) {
      baseScore *= 1.2;
    }
    
    // Recent attempt penalty
    final attemptPenalty = min(0.5, recentAttempts.length * 0.15);
    baseScore *= (1.0 - attemptPenalty);
    
    // Context-specific adjustments
    baseScore = _adjustScoreForContext(baseScore, trigger, context);
    
    return min(1.0, max(0.0, baseScore));
  }
  
  /// Get base score for trigger type
  double _getBaseTriggerScore(UpsellTrigger trigger) {
    switch (trigger) {
      case UpsellTrigger.sessionLimitReached:
        return 0.8; // High intent
      case UpsellTrigger.strongStreakDay:
        return 0.7; // Good engagement
      case UpsellTrigger.coachingPhaseBlocked:
        return 0.75; // Clear value demonstration
      case UpsellTrigger.analyticsInterest:
        return 0.6; // Interest but lower urgency
      case UpsellTrigger.exportAttempt:
        return 0.85; // Very high intent
      case UpsellTrigger.goalAchievement:
        return 0.65; // Positive moment
      case UpsellTrigger.highEngagement:
        return 0.5; // Good timing
      case UpsellTrigger.featureDiscovery:
        return 0.55; // Curiosity-driven
    }
  }
  
  /// Adjust score based on specific context
  double _adjustScoreForContext(
    double baseScore,
    UpsellTrigger trigger,
    Map<String, dynamic> context,
  ) {
    switch (trigger) {
      case UpsellTrigger.strongStreakDay:
        final days = context['streak_days'] as int? ?? 0;
        if (days >= 7) return baseScore * 1.2;
        if (days >= 14) return baseScore * 1.4;
        break;
        
      case UpsellTrigger.sessionLimitReached:
        final timeOfDay = DateTime.now().hour;
        if (timeOfDay >= 18 && timeOfDay <= 21) {
          return baseScore * 1.1; // Evening practice shows dedication
        }
        break;
        
      case UpsellTrigger.goalAchievement:
        final goalType = context['goal_type'] as String?;
        if (goalType == 'streak' || goalType == 'duration') {
          return baseScore * 1.15; // Achievement-oriented goals
        }
        break;
        
      default:
        break;
    }
    
    return baseScore;
  }
  
  /// Get experiment-driven message style
  MessageStyle _getExperimentMessageStyle() {
    final variant = _experiments.getVariant('upsell_message_style');
    
    switch (variant?.id) {
      case 'supportive':
        return MessageStyle.supportive;
      case 'achievement':
        return MessageStyle.achievement;
      case 'curiosity':
        return MessageStyle.curiosity;
      default:
        return MessageStyle.supportive;
    }
  }
  
  /// Check if in cooldown period
  Future<bool> _isInCooldown() async {
    try {
      final stored = await _storage.getString(_cooldownKey);
      if (stored != null) {
        final cooldownEnd = DateTime.parse(stored);
        return DateTime.now().isBefore(cooldownEnd);
      }
    } catch (e) {
      // Ignore errors
    }
    
    return false;
  }
  
  /// Set cooldown period
  Future<void> _setCooldown(int days) async {
    try {
      final cooldownEnd = DateTime.now().add(Duration(days: days));
      await _storage.setString(_cooldownKey, cooldownEnd.toIso8601String());
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Persist opportunity for analysis
  Future<void> _persistOpportunity(UpsellOpportunity opportunity) async {
    try {
      final opportunities = await _getStoredOpportunities();
      
      final opportunityData = {
        'trigger': opportunity.trigger.toString(),
        'score': opportunity.score,
        'context': opportunity.context,
        'timestamp': opportunity.timestamp.toIso8601String(),
      };
      
      opportunities.insert(0, opportunityData);
      if (opportunities.length > 50) {
        opportunities.removeLast();
      }
      
      await _storage.setString(
        _opportunityHistoryKey,
        LocalStorage.encodeJson(opportunities),
      );
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Persist conversion attempt
  Future<void> _persistConversionAttempt(Map<String, dynamic> attempt) async {
    try {
      final attempts = await _getStoredConversionAttempts();
      
      attempts.insert(0, attempt);
      if (attempts.length > 100) {
        attempts.removeLast();
      }
      
      await _storage.setString(
        _conversionAttemptsKey,
        LocalStorage.encodeJson(attempts),
      );
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Get stored opportunities
  Future<List<Map<String, dynamic>>> _getStoredOpportunities() async {
    try {
      final stored = await _storage.getString(_opportunityHistoryKey);
      if (stored != null) {
        final List<dynamic> data = LocalStorage.parseJson(stored) ?? [];
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Ignore errors
    }
    
    return [];
  }
  
  /// Get stored conversion attempts
  Future<List<Map<String, dynamic>>> _getStoredConversionAttempts() async {
    try {
      final stored = await _storage.getString(_conversionAttemptsKey);
      if (stored != null) {
        final List<dynamic> data = LocalStorage.parseJson(stored) ?? [];
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      // Ignore errors
    }
    
    return [];
  }
  
  /// Get recent conversion attempts
  Future<List<Map<String, dynamic>>> _getRecentConversionAttempts(int days) async {
    final attempts = await _getStoredConversionAttempts();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    
    return attempts.where((attempt) {
      try {
        final timestamp = DateTime.parse(attempt['timestamp'] as String);
        return timestamp.isAfter(cutoff);
      } catch (e) {
        return false;
      }
    }).toList();
  }
}
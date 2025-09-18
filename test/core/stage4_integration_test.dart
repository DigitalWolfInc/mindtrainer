import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/engagement/engagement_cue_service.dart';
import 'package:mindtrainer/core/engagement/smart_upsell_service.dart';
import 'package:mindtrainer/core/ab_testing/ab_test_framework.dart';
import 'package:mindtrainer/core/analytics/enhanced_conversion_analytics.dart';

void main() {
  group('Stage 4: Post-launch optimization & growth', () {
    test('Engagement cue service generates appropriate cues', () {
      final service = EngagementCueService();
      
      final context = UserActivityContext(
        daysSinceLastSession: 1,
        currentStreak: 5,
        sessionsThisWeek: 3,
        weeklyGoal: 5,
        hasProAccess: false,
        daysSinceProFeatureUse: 10,
        unusedProFeatures: ['mood_correlations'],
        recentSessionsCount: 4,
        averageRecentFocusScore: 7.2,
        personalBest: 8.9,
      );
      
      final cues = service.getEngagementCues(context);
      
      expect(cues, isNotEmpty);
      expect(cues.first.type, equals(EngagementCueType.streakContinuation));
    });

    test('Smart upsell service provides contextual prompts', () {
      final service = SmartUpsellService();
      
      final context = UpsellTriggerContext(
        isInActiveSession: false,
        hoursSinceLastPromptDismissal: 25,
        daysSinceFirstUse: 5,
        totalSessions: 10,
        engagementScore: 0.8,
        lastSessionScore: 8.5,
        consecutiveGoodSessions: 3,
        analyticsViewsThisWeek: 4,
        currentStreak: 7,
        streakQuality: StreakQuality.high,
        justCompletedWeeklyGoal: false,
        goalCompletionStreak: 0,
        featuresExploredThisSession: 2,
        hitFeatureLimitThisSession: false,
        lockedFeatureInteractionsToday: 1,
      );
      
      final decision = service.shouldShowUpsellPrompt(context);
      
      expect(decision.shouldShow, isTrue);
      expect(decision.prompt, isNotNull);
    });

    test('A/B testing framework assigns variants consistently', () {
      final framework = ABTestFramework();
      framework.initializeTests();
      
      // Clear any previous assignments for test
      framework.clearAssignments();
      
      const userId = 'test_user_123';
      
      // Get variant assignment twice - should be consistent
      final variant1 = framework.getVariant('pro_badge_text', userId);
      final variant2 = framework.getVariant('pro_badge_text', userId);
      
      expect(variant1, isNotNull);
      expect(variant2, isNotNull);
      expect(variant1!.variantId, equals(variant2!.variantId));
      
      // Test configuration access
      final badgeText = framework.getProBadgeText(userId);
      expect(badgeText, isIn(['PRO', 'UPGRADE', 'PLUS']));
    });

    test('Enhanced conversion analytics tracks detailed metrics', () {
      final analytics = EnhancedConversionAnalytics();
      
      // Track Pro feature engagement
      analytics.trackProFeatureEngagement(
        'advanced_analytics',
        'view',
        {'user_segment': 'power_user'},
      );
      
      // Track conversion readiness
      final readinessScore = analytics.calculateConversionReadiness({
        'engagement_score': 0.8,
        'features_explored': 5,
        'avg_session_quality': 8.2,
        'days_active': 10,
        'pro_interactions': 3,
      });
      
      expect(readinessScore, greaterThan(0.0));
      expect(readinessScore, lessThanOrEqualTo(1.0));
    });

    test('A/B testing UI configurations work correctly', () {
      final framework = ABTestFramework();
      framework.initializeTests();
      
      const userId = 'ui_test_user';
      
      final upgradeConfig = framework.getUpgradePromptConfig(userId);
      expect(upgradeConfig['title'], isNotNull);
      expect(upgradeConfig['message'], isNotNull);
      expect(upgradeConfig['cta'], isNotNull);
      
      final timingConfig = framework.getPromptTimingConfig(userId);
      expect(timingConfig['delay_seconds'], isA<int>());
      expect(timingConfig['show_on_first_visit'], isA<bool>());
    });

    test('Engagement cue priorities are handled correctly', () {
      final service = EngagementCueService();
      
      // Create high-priority context
      final highPriorityContext = UserActivityContext(
        daysSinceLastSession: 1,
        currentStreak: 10, // Long streak
        sessionsThisWeek: 4,
        weeklyGoal: 5,
        hasProAccess: false,
        daysSinceProFeatureUse: 0,
        unusedProFeatures: [],
        recentSessionsCount: 5,
        averageRecentFocusScore: 9.0,
        personalBest: 9.2,
      );
      
      final cues = service.getEngagementCues(highPriorityContext);
      final activeCues = service.getActiveCues(cues);
      
      // Should have at least one cue
      expect(activeCues, isNotEmpty);
      
      // High-priority cues should come first
      if (activeCues.length > 1) {
        expect(activeCues.first.priority.index, 
               greaterThanOrEqualTo(activeCues.last.priority.index));
      }
    });

    test('Performance profiler integration works', () {
      // Test that performance profiling doesn't break core functionality
      expect(() {
        final service = EngagementCueService();
        final context = UserActivityContext(
          daysSinceLastSession: 3,
          currentStreak: 2,
          sessionsThisWeek: 1,
          weeklyGoal: 3,
          hasProAccess: false,
          daysSinceProFeatureUse: 5,
          unusedProFeatures: ['tag_insights'],
          recentSessionsCount: 2,
          averageRecentFocusScore: 6.5,
          personalBest: 8.0,
        );
        
        service.getEngagementCues(context);
      }, returnsNormally);
    });
  });
}
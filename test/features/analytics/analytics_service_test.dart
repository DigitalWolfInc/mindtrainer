/// Unit tests for Advanced Analytics Service
/// Tests free behavior, Pro behavior, and transition scenarios

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/analytics/domain/analytics_service.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';

void main() {
  group('AdvancedAnalyticsService', () {
    late AdvancedAnalyticsService freeService;
    late AdvancedAnalyticsService proService;
    
    setUp(() {
      freeService = AdvancedAnalyticsService(
        MindTrainerProGates(() => false),
      );
      proService = AdvancedAnalyticsService(
        MindTrainerProGates(() => true),
      );
    });
    
    group('Basic Analytics', () {
      test('should provide basic analytics to all users', () {
        final freeAnalytics = freeService.getBasicAnalytics();
        final proAnalytics = proService.getBasicAnalytics();
        
        // Both free and pro users get basic analytics
        expect(freeAnalytics.totalSessions, greaterThan(0));
        expect(freeAnalytics.averageFocusScore, greaterThan(0));
        expect(freeAnalytics.totalFocusTime, greaterThan(Duration.zero));
        expect(freeAnalytics.topTags, isNotEmpty);
        expect(freeAnalytics.periodStart.isBefore(freeAnalytics.periodEnd), true);
        
        expect(proAnalytics.totalSessions, greaterThan(0));
        expect(proAnalytics.averageFocusScore, greaterThan(0));
        expect(proAnalytics.totalFocusTime, greaterThan(Duration.zero));
        expect(proAnalytics.topTags, isNotEmpty);
      });
      
      test('should respect history window limits for free users', () {
        final freeAnalytics = freeService.getBasicAnalytics();
        final expectedDays = freeService.historyWindowDays;
        
        expect(expectedDays, 30); // Free users limited to 30 days
        
        final actualDays = freeAnalytics.periodEnd.difference(freeAnalytics.periodStart).inDays;
        expect(actualDays, lessThanOrEqualTo(expectedDays));
      });
      
      test('should provide unlimited history for Pro users', () {
        final proAnalytics = proService.getBasicAnalytics();
        
        expect(proService.historyWindowDays, -1); // Unlimited
        expect(proService.hasExtendedHistory, true);
        
        // Pro users can get longer periods
        final days = proAnalytics.periodEnd.difference(proAnalytics.periodStart).inDays;
        expect(days, greaterThanOrEqualTo(30));
      });
      
      test('should generate consistent deterministic data', () {
        final analytics1 = freeService.getBasicAnalytics();
        final analytics2 = freeService.getBasicAnalytics();
        
        // Should be deterministic due to seeded Random
        expect(analytics1.totalSessions, analytics2.totalSessions);
        expect(analytics1.averageFocusScore, analytics2.averageFocusScore);
        expect(analytics1.totalFocusTime, analytics2.totalFocusTime);
        expect(analytics1.topTags, analytics2.topTags);
      });
    });
    
    group('Mood-Focus Correlations', () {
      test('should be empty for free users', () {
        final correlations = freeService.getMoodFocusCorrelations();
        expect(correlations, isEmpty);
      });
      
      test('should provide data for Pro users', () {
        final correlations = proService.getMoodFocusCorrelations();
        
        expect(correlations, isNotEmpty);
        expect(correlations.length, 5); // Should have 5 moods
        
        for (final correlation in correlations) {
          expect(correlation.mood, isNotEmpty);
          expect(correlation.averageFocusScore, inInclusiveRange(5.0, 9.0));
          expect(correlation.sessionCount, inInclusiveRange(2, 10));
          expect(['improving', 'stable', 'declining'], contains(correlation.trend));
        }
      });
      
      test('should include all expected moods', () {
        final correlations = proService.getMoodFocusCorrelations();
        final moods = correlations.map((c) => c.mood).toSet();
        
        expect(moods, containsAll(['calm', 'focused', 'anxious', 'energetic', 'tired']));
      });
    });
    
    group('Tag Performance Insights', () {
      test('should be empty for free users', () {
        final insights = freeService.getTagPerformanceInsights();
        expect(insights, isEmpty);
      });
      
      test('should provide data for Pro users', () {
        final insights = proService.getTagPerformanceInsights();
        
        expect(insights, isNotEmpty);
        expect(insights.length, 6); // Should have 6 tags
        
        for (final insight in insights) {
          expect(insight.tag, isNotEmpty);
          expect(insight.averageFocusScore, inInclusiveRange(6.0, 9.0));
          expect(insight.usageCount, inInclusiveRange(3, 18));
          expect(insight.uplift, inInclusiveRange(-1.0, 1.0));
        }
      });
      
      test('should sort by uplift descending', () {
        final insights = proService.getTagPerformanceInsights();
        
        for (int i = 1; i < insights.length; i++) {
          expect(insights[i-1].uplift, greaterThanOrEqualTo(insights[i].uplift));
        }
      });
      
      test('should include expected tags', () {
        final insights = proService.getTagPerformanceInsights();
        final tags = insights.map((i) => i.tag).toSet();
        
        expect(tags, containsAll(['morning', 'evening', 'focus', 'creativity', 'stress-relief', 'deep-work']));
      });
    });
    
    group('Keyword Uplift Analysis', () {
      test('should be empty for free users', () {
        final analysis = freeService.getKeywordUpliftAnalysis();
        expect(analysis, isEmpty);
      });
      
      test('should provide data for Pro users', () {
        final analysis = proService.getKeywordUpliftAnalysis();
        
        expect(analysis, isNotEmpty);
        expect(analysis.length, 5); // Should have 5 keywords
        
        for (final keyword in analysis) {
          expect(keyword.keyword, isNotEmpty);
          expect(keyword.upliftPercentage, inInclusiveRange(0.0, 25.0));
          expect(keyword.sessionCount, inInclusiveRange(4, 16));
          expect(keyword.context, isNotEmpty);
        }
      });
      
      test('should sort by uplift percentage descending', () {
        final analysis = proService.getKeywordUpliftAnalysis();
        
        for (int i = 1; i < analysis.length; i++) {
          expect(analysis[i-1].upliftPercentage, greaterThanOrEqualTo(analysis[i].upliftPercentage));
        }
      });
      
      test('should include expected keywords with contexts', () {
        final analysis = proService.getKeywordUpliftAnalysis();
        final keywords = analysis.map((k) => k.keyword).toSet();
        final contexts = analysis.map((k) => k.context).toSet();
        
        expect(keywords, containsAll(['breakthrough', 'clarity', 'peaceful', 'challenging', 'progress']));
        expect(contexts, containsAll(['session notes', 'post-session reflections', 'mood entries']));
      });
    });
    
    group('Pro Analytics Summary', () {
      test('should show locked state for free users', () {
        final summary = freeService.getProAnalyticsSummary();
        
        expect(summary['available'], false);
        expect(summary['lockedFeatures'], isNotEmpty);
        expect(summary['lockedFeatures'], contains('Mood-Focus Correlations'));
        expect(summary['lockedFeatures'], contains('Tag Performance'));
        expect(summary['lockedFeatures'], contains('Keyword Analysis'));
        expect(summary['lockedFeatures'], contains('Extended History'));
      });
      
      test('should show full data for Pro users', () {
        final summary = proService.getProAnalyticsSummary();
        
        expect(summary['available'], true);
        expect(summary['moodCorrelationCount'], 5);
        expect(summary['tagInsightCount'], 6);
        expect(summary['keywordAnalysisCount'], 5);
        expect(summary['historyWindowDays'], -1);
        expect(summary['topMoodForFocus'], isNotNull);
        expect(summary['bestPerformingTag'], isNotNull);
        expect(summary['topKeywordUplift'], isNotNull);
      });
    });
    
    group('Feature Gate Integration', () {
      test('should respect individual Pro gates', () {
        // Create service with gates that selectively allow features
        final selectiveGates = MindTrainerProGates(() => true);
        final service = AdvancedAnalyticsService(selectiveGates);
        
        // Verify service uses the gates correctly
        expect(service.hasExtendedHistory, selectiveGates.extendedInsightsHistory);
        expect(service.historyWindowDays, selectiveGates.insightsHistoryDays);
      });
      
      test('should handle edge case of limited days', () {
        // Test with specific day limits
        final analytics = freeService.getBasicAnalytics(limitDays: 7);
        
        final actualDays = analytics.periodEnd.difference(analytics.periodStart).inDays;
        expect(actualDays, lessThanOrEqualTo(7));
      });
    });
  });
  
  group('Analytics Data Models', () {
    group('SessionAnalytics', () {
      test('should create valid analytics object', () {
        final analytics = SessionAnalytics(
          totalSessions: 10,
          averageFocusScore: 8.5,
          totalFocusTime: Duration(hours: 2, minutes: 30),
          topTags: ['focus', 'morning'],
          periodStart: DateTime(2024, 1, 1),
          periodEnd: DateTime(2024, 1, 31),
        );
        
        expect(analytics.totalSessions, 10);
        expect(analytics.averageFocusScore, 8.5);
        expect(analytics.totalFocusTime.inMinutes, 150);
        expect(analytics.topTags, ['focus', 'morning']);
        expect(analytics.periodStart.month, 1);
        expect(analytics.periodEnd.month, 1);
      });
    });
    
    group('MoodFocusCorrelation', () {
      test('should create valid correlation object', () {
        final correlation = MoodFocusCorrelation(
          mood: 'focused',
          averageFocusScore: 8.7,
          sessionCount: 15,
          trend: 'improving',
        );
        
        expect(correlation.mood, 'focused');
        expect(correlation.averageFocusScore, 8.7);
        expect(correlation.sessionCount, 15);
        expect(correlation.trend, 'improving');
      });
    });
    
    group('TagPerformanceInsight', () {
      test('should create valid insight object', () {
        final insight = TagPerformanceInsight(
          tag: 'morning',
          averageFocusScore: 8.2,
          usageCount: 12,
          uplift: 0.5,
        );
        
        expect(insight.tag, 'morning');
        expect(insight.averageFocusScore, 8.2);
        expect(insight.usageCount, 12);
        expect(insight.uplift, 0.5);
      });
    });
    
    group('KeywordUpliftAnalysis', () {
      test('should create valid analysis object', () {
        final analysis = KeywordUpliftAnalysis(
          keyword: 'breakthrough',
          upliftPercentage: 15.5,
          sessionCount: 8,
          context: 'session notes',
        );
        
        expect(analysis.keyword, 'breakthrough');
        expect(analysis.upliftPercentage, 15.5);
        expect(analysis.sessionCount, 8);
        expect(analysis.context, 'session notes');
      });
    });
  });
}
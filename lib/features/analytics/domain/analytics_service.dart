import 'dart:math';
import '../../../core/payments/pro_feature_gates.dart';

/// Analytics data models

class SessionAnalytics {
  final int totalSessions;
  final double averageFocusScore;
  final Duration totalFocusTime;
  final List<String> topTags;
  final DateTime periodStart;
  final DateTime periodEnd;

  const SessionAnalytics({
    required this.totalSessions,
    required this.averageFocusScore,
    required this.totalFocusTime,
    required this.topTags,
    required this.periodStart,
    required this.periodEnd,
  });
}

class MoodFocusCorrelation {
  final String mood;
  final double averageFocusScore;
  final int sessionCount;
  final String trend; // 'improving', 'stable', 'declining'

  const MoodFocusCorrelation({
    required this.mood,
    required this.averageFocusScore,
    required this.sessionCount,
    required this.trend,
  });
}

class TagPerformanceInsight {
  final String tag;
  final double averageFocusScore;
  final int usageCount;
  final double uplift; // Compared to sessions without this tag

  const TagPerformanceInsight({
    required this.tag,
    required this.averageFocusScore,
    required this.usageCount,
    required this.uplift,
  });
}

class KeywordUpliftAnalysis {
  final String keyword;
  final double upliftPercentage;
  final int sessionCount;
  final String context; // Where this keyword appears most

  const KeywordUpliftAnalysis({
    required this.keyword,
    required this.upliftPercentage,
    required this.sessionCount,
    required this.context,
  });
}

/// Advanced Analytics Service
class AdvancedAnalyticsService {
  final MindTrainerProGates _proGates;

  const AdvancedAnalyticsService(this._proGates);

  /// Get basic analytics available to all users
  SessionAnalytics getBasicAnalytics({int? limitDays}) {
    final days = limitDays ?? (_proGates.insightsHistoryDays == -1 ? 365 : _proGates.insightsHistoryDays);
    final periodStart = DateTime.now().subtract(Duration(days: days));
    final periodEnd = DateTime.now();

    // Generate realistic fake data for basic analytics
    final random = Random(42); // Deterministic for consistency
    final totalSessions = random.nextInt(20) + 5;
    final averageFocusScore = 6.5 + random.nextDouble() * 2.5; // 6.5-9.0
    final totalMinutes = totalSessions * (15 + random.nextInt(30)); // 15-45 min per session
    final topTags = ['focus', 'morning', 'productivity']..shuffle(random);

    return SessionAnalytics(
      totalSessions: totalSessions,
      averageFocusScore: averageFocusScore,
      totalFocusTime: Duration(minutes: totalMinutes),
      topTags: topTags.take(3).toList(),
      periodStart: periodStart,
      periodEnd: periodEnd,
    );
  }

  /// Get mood-focus correlations (Pro only)
  List<MoodFocusCorrelation> getMoodFocusCorrelations() {
    if (!_proGates.moodFocusCorrelations) {
      return [];
    }

    // Generate realistic Pro analytics data
    final random = Random(123);
    final moods = ['calm', 'focused', 'anxious', 'energetic', 'tired'];
    
    return moods.map((mood) {
      final baseScore = 5.0 + random.nextDouble() * 4.0; // 5.0-9.0
      final sessionCount = random.nextInt(8) + 2; // 2-10 sessions
      final trends = ['improving', 'stable', 'declining'];
      final trend = trends[random.nextInt(trends.length)];
      
      return MoodFocusCorrelation(
        mood: mood,
        averageFocusScore: baseScore,
        sessionCount: sessionCount,
        trend: trend,
      );
    }).toList();
  }

  /// Get tag performance insights (Pro only)
  List<TagPerformanceInsight> getTagPerformanceInsights() {
    if (!_proGates.tagAssociations) {
      return [];
    }

    final random = Random(456);
    final tags = ['morning', 'evening', 'focus', 'creativity', 'stress-relief', 'deep-work'];
    
    return tags.map((tag) {
      final averageScore = 6.0 + random.nextDouble() * 3.0; // 6.0-9.0
      final usageCount = random.nextInt(15) + 3; // 3-18 uses
      final uplift = (random.nextDouble() - 0.5) * 2.0; // -1.0 to +1.0
      
      return TagPerformanceInsight(
        tag: tag,
        averageFocusScore: averageScore,
        usageCount: usageCount,
        uplift: uplift,
      );
    }).toList()
      ..sort((a, b) => b.uplift.compareTo(a.uplift)); // Sort by uplift descending
  }

  /// Get keyword uplift analysis (Pro only)
  List<KeywordUpliftAnalysis> getKeywordUpliftAnalysis() {
    if (!_proGates.keywordUplift) {
      return [];
    }

    final random = Random(789);
    final keywords = [
      {'keyword': 'breakthrough', 'context': 'session notes'},
      {'keyword': 'clarity', 'context': 'post-session reflections'},
      {'keyword': 'peaceful', 'context': 'mood entries'},
      {'keyword': 'challenging', 'context': 'difficulty ratings'},
      {'keyword': 'progress', 'context': 'goal tracking'},
    ];
    
    return keywords.map((keywordData) {
      final keyword = keywordData['keyword']!;
      final context = keywordData['context']!;
      final uplift = random.nextDouble() * 25.0; // 0-25% uplift
      final sessionCount = random.nextInt(12) + 4; // 4-16 sessions
      
      return KeywordUpliftAnalysis(
        keyword: keyword,
        upliftPercentage: uplift,
        sessionCount: sessionCount,
        context: context,
      );
    }).toList()
      ..sort((a, b) => b.upliftPercentage.compareTo(a.upliftPercentage));
  }

  /// Check if extended insights history is available
  bool get hasExtendedHistory => _proGates.extendedInsightsHistory;

  /// Get available history window in days
  int get historyWindowDays => _proGates.insightsHistoryDays;

  /// Get Pro analytics summary for display
  Map<String, dynamic> getProAnalyticsSummary() {
    if (!_proGates.advancedAnalytics) {
      return {
        'available': false,
        'lockedFeatures': ['Mood-Focus Correlations', 'Tag Performance', 'Keyword Analysis', 'Extended History'],
      };
    }

    final moodCorrelations = getMoodFocusCorrelations();
    final tagInsights = getTagPerformanceInsights();
    final keywordAnalysis = getKeywordUpliftAnalysis();

    return {
      'available': true,
      'moodCorrelationCount': moodCorrelations.length,
      'tagInsightCount': tagInsights.length,
      'keywordAnalysisCount': keywordAnalysis.length,
      'historyWindowDays': historyWindowDays,
      'topMoodForFocus': moodCorrelations.isNotEmpty 
          ? moodCorrelations.reduce((a, b) => a.averageFocusScore > b.averageFocusScore ? a : b).mood
          : null,
      'bestPerformingTag': tagInsights.isNotEmpty ? tagInsights.first.tag : null,
      'topKeywordUplift': keywordAnalysis.isNotEmpty ? keywordAnalysis.first.keyword : null,
    };
  }
}
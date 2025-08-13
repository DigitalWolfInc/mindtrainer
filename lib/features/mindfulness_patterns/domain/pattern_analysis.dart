/// Mindfulness Pattern Recognition for MindTrainer Pro
/// 
/// AI-powered pattern detection to identify optimal conditions for mindfulness practice.

import '../../../core/session_tags.dart';
import '../../../core/insights/mood_focus_insights.dart';

/// Time-of-day performance pattern
class TimeOfDayPattern {
  final int hour; // 0-23
  final double averageRating; // 1-5 session ratings
  final int sessionCount;
  final Duration averageDuration;
  final double completionRate; // 0-1
  final List<String> commonTags;
  
  const TimeOfDayPattern({
    required this.hour,
    required this.averageRating,
    required this.sessionCount,
    required this.averageDuration,
    required this.completionRate,
    required this.commonTags,
  });
  
  /// Get human-readable time description
  String get timeDescription {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }
  
  /// Get specific time range
  String get timeRange {
    final nextHour = (hour + 1) % 24;
    return '${hour.toString().padLeft(2, '0')}:00-${nextHour.toString().padLeft(2, '0')}:00';
  }
  
  /// Performance score (0-1)
  double get performanceScore {
    final ratingScore = (averageRating - 1) / 4; // Normalize 1-5 to 0-1
    return (ratingScore * 0.6) + (completionRate * 0.4);
  }
  
  /// Quality level based on performance
  PatternQuality get quality {
    if (performanceScore >= 0.8) return PatternQuality.excellent;
    if (performanceScore >= 0.6) return PatternQuality.good;
    if (performanceScore >= 0.4) return PatternQuality.fair;
    return PatternQuality.poor;
  }
}

/// Mood-to-outcome prediction
class MoodOutcomePattern {
  final int preMoodScore; // 1-5
  final double averagePostMoodImprovement;
  final double averageSessionRating;
  final int sessionCount;
  final Duration averageDuration;
  final List<String> effectiveTags;
  
  const MoodOutcomePattern({
    required this.preMoodScore,
    required this.averagePostMoodImprovement,
    required this.averageSessionRating,
    required this.sessionCount,
    required this.averageDuration,
    required this.effectiveTags,
  });
  
  /// Predicted outcome quality
  PatternQuality get predictedQuality {
    final moodImprovementScore = averagePostMoodImprovement / 2.0; // Max improvement is 2 points
    final sessionScore = (averageSessionRating - 1) / 4; // Normalize 1-5 to 0-1
    final combinedScore = (moodImprovementScore * 0.5) + (sessionScore * 0.5);
    
    if (combinedScore >= 0.8) return PatternQuality.excellent;
    if (combinedScore >= 0.6) return PatternQuality.good;
    if (combinedScore >= 0.4) return PatternQuality.fair;
    return PatternQuality.poor;
  }
  
  /// Get pre-mood description
  String get preMoodDescription {
    switch (preMoodScore) {
      case 1: return 'Very Low';
      case 2: return 'Low';
      case 3: return 'Neutral';
      case 4: return 'Good';
      case 5: return 'Excellent';
      default: return 'Unknown';
    }
  }
}

/// Environmental factor correlation
class EnvironmentalPattern {
  final String factor; // tag, weather, location, etc.
  final String value;
  final double averageRating;
  final double completionRate;
  final int sessionCount;
  final double correlationStrength; // 0-1, how strong the pattern is
  final PatternType patternType;
  
  const EnvironmentalPattern({
    required this.factor,
    required this.value,
    required this.averageRating,
    required this.completionRate,
    required this.sessionCount,
    required this.correlationStrength,
    required this.patternType,
  });
  
  /// Get impact description
  String get impactDescription {
    final performance = (averageRating - 1) / 4; // Normalize to 0-1
    if (performance >= 0.8) return 'Significantly enhances your practice';
    if (performance >= 0.6) return 'Improves your practice';
    if (performance >= 0.4) return 'Has moderate positive impact';
    if (performance >= 0.2) return 'Has slight positive impact';
    return 'May hinder your practice';
  }
}

/// Pattern quality levels
enum PatternQuality {
  poor,
  fair,
  good,
  excellent,
}

/// Pattern types
enum PatternType {
  temporal, // time-based
  contextual, // tag/environment based
  emotional, // mood-based
  behavioral, // session structure based
}

/// Personal recommendation based on patterns
class PersonalizedRecommendation {
  final String title;
  final String description;
  final List<String> actionItems;
  final double confidenceScore; // 0-1
  final PatternType basedOnPattern;
  final DateTime generatedAt;
  
  const PersonalizedRecommendation({
    required this.title,
    required this.description,
    required this.actionItems,
    required this.confidenceScore,
    required this.basedOnPattern,
    required this.generatedAt,
  });
  
  /// Confidence level description
  String get confidenceLevel {
    if (confidenceScore >= 0.8) return 'High';
    if (confidenceScore >= 0.6) return 'Medium';
    if (confidenceScore >= 0.4) return 'Low';
    return 'Experimental';
  }
}

/// Comprehensive mindfulness pattern analysis
class MindfulnessPatternAnalysis {
  final DateTime analysisDate;
  final int totalSessionsAnalyzed;
  final int daysCovered;
  
  final List<TimeOfDayPattern> timePatterns;
  final List<MoodOutcomePattern> moodPatterns;
  final List<EnvironmentalPattern> environmentalPatterns;
  final List<PersonalizedRecommendation> recommendations;
  
  final TimeOfDayPattern? bestTimePattern;
  final EnvironmentalPattern? strongestPositivePattern;
  final EnvironmentalPattern? strongestNegativePattern;
  
  const MindfulnessPatternAnalysis({
    required this.analysisDate,
    required this.totalSessionsAnalyzed,
    required this.daysCovered,
    required this.timePatterns,
    required this.moodPatterns,
    required this.environmentalPatterns,
    required this.recommendations,
    this.bestTimePattern,
    this.strongestPositivePattern,
    this.strongestNegativePattern,
  });
  
  /// Overall pattern strength (how much data we have)
  double get dataConfidence {
    if (totalSessionsAnalyzed >= 30) return 1.0;
    if (totalSessionsAnalyzed >= 20) return 0.8;
    if (totalSessionsAnalyzed >= 10) return 0.6;
    if (totalSessionsAnalyzed >= 5) return 0.4;
    return 0.2;
  }
  
  /// Get summary insights
  List<String> get keyInsights {
    final insights = <String>[];
    
    if (bestTimePattern != null) {
      insights.add(
        'Your best practice time is ${bestTimePattern!.timeDescription.toLowerCase()} '
        '(${bestTimePattern!.timeRange}) with ${bestTimePattern!.averageRating.toStringAsFixed(1)}/5 average rating'
      );
    }
    
    if (strongestPositivePattern != null) {
      insights.add(
        '${strongestPositivePattern!.factor}: "${strongestPositivePattern!.value}" '
        '${strongestPositivePattern!.impactDescription.toLowerCase()}'
      );
    }
    
    if (strongestNegativePattern != null && strongestNegativePattern!.averageRating < 3.0) {
      insights.add(
        'Consider avoiding ${strongestNegativePattern!.factor}: "${strongestNegativePattern!.value}" '
        'as it tends to reduce session quality'
      );
    }
    
    // Add mood insights
    final excellentMoodStates = moodPatterns
        .where((p) => p.predictedQuality == PatternQuality.excellent)
        .toList();
    
    if (excellentMoodStates.isNotEmpty) {
      final states = excellentMoodStates.map((p) => p.preMoodDescription.toLowerCase()).join(', ');
      insights.add('Practice works especially well when you\'re feeling $states');
    }
    
    return insights;
  }
  
  /// Get top recommendations
  List<PersonalizedRecommendation> get topRecommendations {
    final sorted = [...recommendations];
    sorted.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return sorted.take(3).toList();
  }
}
/// Pattern Analyzer Service for MindTrainer Pro
/// 
/// Analyzes user session data to identify mindfulness patterns and generate recommendations.

import 'dart:math';
import '../../../core/session_tags.dart';
import '../../../core/insights/mood_focus_insights.dart';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/pattern_analysis.dart';

/// Service for analyzing mindfulness patterns
class PatternAnalyzerService {
  static const String _analysisHistoryKey = 'pattern_analysis_history';
  static const String _lastAnalysisKey = 'last_pattern_analysis';
  static const int _minSessionsForAnalysis = 5;
  static const int _analysisPeriodDays = 60;
  
  final MindTrainerProGates _proGates;
  final LocalStorage _storage;
  
  PatternAnalyzerService(this._proGates, this._storage);
  
  /// Check if pattern analysis is available
  bool get isPatternAnalysisAvailable => _proGates.isProActive;
  
  /// Analyze sessions and generate pattern insights
  Future<MindfulnessPatternAnalysis?> analyzePatterns({
    required List<Session> sessions,
    required MoodSource moodSource,
  }) async {
    if (!isPatternAnalysisAvailable) {
      return null;
    }
    
    // Filter to recent sessions within analysis period
    final cutoffDate = DateTime.now().subtract(const Duration(days: _analysisPeriodDays));
    final recentSessions = sessions
        .where((session) => session.dateTime.isAfter(cutoffDate))
        .toList();
    
    if (recentSessions.length < _minSessionsForAnalysis) {
      return null; // Not enough data for meaningful analysis
    }
    
    // Get mood data for the same period
    final moodEntries = moodSource.entries(
      from: cutoffDate,
      to: DateTime.now(),
    ).toList();
    
    // Perform analysis
    final analysis = await _performAnalysis(recentSessions, moodEntries);
    
    // Cache the analysis
    await _cacheAnalysis(analysis);
    
    return analysis;
  }
  
  /// Get cached analysis if available and recent
  Future<MindfulnessPatternAnalysis?> getCachedAnalysis() async {
    try {
      final stored = await _storage.getString(_lastAnalysisKey);
      if (stored != null) {
        final data = LocalStorage.parseJson(stored);
        if (data != null) {
          final analysisDate = DateTime.parse(data['analysis_date'] as String);
          
          // Use cached analysis if it's less than 24 hours old
          if (DateTime.now().difference(analysisDate).inHours < 24) {
            return _parseAnalysisFromJson(data);
          }
        }
      }
    } catch (e) {
      // Ignore cache errors
    }
    
    return null;
  }
  
  /// Get personalized session suggestions based on current time and mood
  Future<List<String>> getPersonalizedSuggestions({
    int? currentMood,
    DateTime? preferredTime,
  }) async {
    if (!isPatternAnalysisAvailable) {
      return [];
    }
    
    final analysis = await getCachedAnalysis();
    if (analysis == null) {
      return [];
    }
    
    final suggestions = <String>[];
    final currentTime = preferredTime ?? DateTime.now();
    final currentHour = currentTime.hour;
    
    // Time-based suggestions
    final timePattern = analysis.timePatterns
        .where((p) => p.hour == currentHour)
        .firstOrNull;
    
    if (timePattern != null) {
      if (timePattern.quality == PatternQuality.excellent) {
        suggestions.add('Perfect timing! You typically have excellent sessions at this hour.');
      } else if (timePattern.quality == PatternQuality.poor) {
        final bestTime = analysis.bestTimePattern;
        if (bestTime != null) {
          suggestions.add(
            'Consider practicing during your peak time: ${bestTime.timeDescription} '
            '(${bestTime.timeRange}) for better results.'
          );
        }
      }
    }
    
    // Mood-based suggestions
    if (currentMood != null) {
      final moodPattern = analysis.moodPatterns
          .where((p) => p.preMoodScore == currentMood)
          .firstOrNull;
      
      if (moodPattern != null) {
        if (moodPattern.predictedQuality == PatternQuality.excellent) {
          suggestions.add('Great time to practice! Sessions starting from this mood typically go very well.');
        } else if (moodPattern.predictedQuality == PatternQuality.poor) {
          suggestions.add('A gentle, shorter session might be more beneficial right now.');
        }
        
        // Suggest effective tags for this mood state
        if (moodPattern.effectiveTags.isNotEmpty) {
          final topTags = moodPattern.effectiveTags.take(2).join(', ');
          suggestions.add('Try focusing on: $topTags');
        }
      }
    }
    
    // Environmental suggestions
    if (analysis.strongestPositivePattern != null) {
      final pattern = analysis.strongestPositivePattern!;
      suggestions.add('Consider ${pattern.factor}: "${pattern.value}" - ${pattern.impactDescription.toLowerCase()}');
    }
    
    return suggestions.take(3).toList(); // Limit to top 3 suggestions
  }
  
  /// Get analysis summary for display
  Future<Map<String, dynamic>> getAnalysisSummary() async {
    if (!isPatternAnalysisAvailable) {
      return {'error': 'Pro subscription required for pattern analysis'};
    }
    
    final analysis = await getCachedAnalysis();
    if (analysis == null) {
      return {'error': 'No analysis data available. Need at least $_minSessionsForAnalysis sessions.'};
    }
    
    return {
      'data_confidence': analysis.dataConfidence,
      'sessions_analyzed': analysis.totalSessionsAnalyzed,
      'days_covered': analysis.daysCovered,
      'key_insights': analysis.keyInsights,
      'best_time': analysis.bestTimePattern?.timeDescription,
      'best_time_range': analysis.bestTimePattern?.timeRange,
      'best_time_rating': analysis.bestTimePattern?.averageRating,
      'top_recommendations': analysis.topRecommendations.map((r) => {
        'title': r.title,
        'description': r.description,
        'confidence': r.confidenceLevel,
        'actions': r.actionItems,
      }).toList(),
    };
  }
  
  /// Perform the actual pattern analysis
  Future<MindfulnessPatternAnalysis> _performAnalysis(
    List<Session> sessions,
    List<MoodEntry> moodEntries,
  ) async {
    final analysisDate = DateTime.now();
    final daysCovered = _calculateDaysCovered(sessions);
    
    // Analyze time-of-day patterns
    final timePatterns = _analyzeTimePatterns(sessions);
    
    // Analyze mood-outcome patterns
    final moodPatterns = _analyzeMoodPatterns(sessions, moodEntries);
    
    // Analyze environmental patterns (tags)
    final environmentalPatterns = _analyzeEnvironmentalPatterns(sessions);
    
    // Generate recommendations
    final recommendations = _generateRecommendations(
      timePatterns,
      moodPatterns,
      environmentalPatterns,
    );
    
    // Find best patterns
    final bestTimePattern = timePatterns
        .where((p) => p.sessionCount >= 3)
        .fold<TimeOfDayPattern?>(null, (best, current) =>
            best == null || current.performanceScore > best.performanceScore ? current : best);
    
    final strongestPositivePattern = environmentalPatterns
        .where((p) => p.correlationStrength > 0.6 && p.averageRating >= 4.0)
        .fold<EnvironmentalPattern?>(null, (best, current) =>
            best == null || current.correlationStrength > best.correlationStrength ? current : best);
    
    final strongestNegativePattern = environmentalPatterns
        .where((p) => p.correlationStrength > 0.6 && p.averageRating < 3.0)
        .fold<EnvironmentalPattern?>(null, (best, current) =>
            best == null || current.correlationStrength > best.correlationStrength ? current : best);
    
    return MindfulnessPatternAnalysis(
      analysisDate: analysisDate,
      totalSessionsAnalyzed: sessions.length,
      daysCovered: daysCovered,
      timePatterns: timePatterns,
      moodPatterns: moodPatterns,
      environmentalPatterns: environmentalPatterns,
      recommendations: recommendations,
      bestTimePattern: bestTimePattern,
      strongestPositivePattern: strongestPositivePattern,
      strongestNegativePattern: strongestNegativePattern,
    );
  }
  
  /// Analyze time-of-day patterns
  List<TimeOfDayPattern> _analyzeTimePatterns(List<Session> sessions) {
    final hourlyData = <int, List<Session>>{};
    
    // Group sessions by hour
    for (final session in sessions) {
      final hour = session.dateTime.hour;
      hourlyData.putIfAbsent(hour, () => []).add(session);
    }
    
    final patterns = <TimeOfDayPattern>[];
    
    for (final entry in hourlyData.entries) {
      final hour = entry.key;
      final hourSessions = entry.value;
      
      if (hourSessions.length < 3) continue; // Need at least 3 sessions for pattern
      
      // Calculate metrics (using note as rating for now - in real implementation, 
      // you'd extract rating from session data)
      final ratings = hourSessions.map((s) => _extractRating(s)).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      
      final totalDuration = hourSessions
          .map((s) => s.durationMinutes)
          .reduce((a, b) => a + b);
      final averageDuration = Duration(minutes: totalDuration ~/ hourSessions.length);
      
      // Calculate completion rate (assume complete if duration >= 5 minutes)
      final completedSessions = hourSessions.where((s) => s.durationMinutes >= 5).length;
      final completionRate = completedSessions / hourSessions.length;
      
      // Get common tags
      final allTags = <String>[];
      for (final session in hourSessions) {
        allTags.addAll(session.tags);
      }
      final tagCounts = <String, int>{};
      for (final tag in allTags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
      final commonTags = tagCounts.entries
          .where((e) => e.value >= 2)
          .map((e) => e.key)
          .take(3)
          .toList();
      
      patterns.add(TimeOfDayPattern(
        hour: hour,
        averageRating: averageRating,
        sessionCount: hourSessions.length,
        averageDuration: averageDuration,
        completionRate: completionRate,
        commonTags: commonTags,
      ));
    }
    
    return patterns;
  }
  
  /// Analyze mood-outcome patterns
  List<MoodOutcomePattern> _analyzeMoodPatterns(
    List<Session> sessions,
    List<MoodEntry> moodEntries,
  ) {
    final moodSessionPairs = <int, List<Session>>{};
    
    // Match sessions with pre-session mood (within 2 hours)
    for (final session in sessions) {
      final preMoodEntry = moodEntries
          .where((mood) => 
              mood.at.isBefore(session.dateTime) &&
              session.dateTime.difference(mood.at).inHours <= 2)
          .fold<MoodEntry?>(null, (latest, current) =>
              latest == null || current.at.isAfter(latest.at) ? current : latest);
      
      if (preMoodEntry != null) {
        moodSessionPairs.putIfAbsent(preMoodEntry.score, () => []).add(session);
      }
    }
    
    final patterns = <MoodOutcomePattern>[];
    
    for (final entry in moodSessionPairs.entries) {
      final preMoodScore = entry.key;
      final moodSessions = entry.value;
      
      if (moodSessions.length < 3) continue;
      
      // Calculate average improvements and ratings
      final ratings = moodSessions.map((s) => _extractRating(s)).toList();
      final averageSessionRating = ratings.reduce((a, b) => a + b) / ratings.length;
      
      // For mood improvement, we'd need post-session mood data
      // For now, assume improvement based on session rating
      final averagePostMoodImprovement = max(0.0, averageSessionRating - 3.0) * 0.5;
      
      final totalDuration = moodSessions
          .map((s) => s.durationMinutes)
          .reduce((a, b) => a + b);
      final averageDuration = Duration(minutes: totalDuration ~/ moodSessions.length);
      
      // Get effective tags (tags that appear in higher-rated sessions)
      final highRatedSessions = moodSessions.where((s) => _extractRating(s) >= 4).toList();
      final effectiveTags = <String>[];
      if (highRatedSessions.isNotEmpty) {
        final tagCounts = <String, int>{};
        for (final session in highRatedSessions) {
          for (final tag in session.tags) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
        }
        effectiveTags.addAll(tagCounts.entries
            .where((e) => e.value >= 2)
            .map((e) => e.key)
            .take(3));
      }
      
      patterns.add(MoodOutcomePattern(
        preMoodScore: preMoodScore,
        averagePostMoodImprovement: averagePostMoodImprovement,
        averageSessionRating: averageSessionRating,
        sessionCount: moodSessions.length,
        averageDuration: averageDuration,
        effectiveTags: effectiveTags,
      ));
    }
    
    return patterns;
  }
  
  /// Analyze environmental patterns from tags
  List<EnvironmentalPattern> _analyzeEnvironmentalPatterns(List<Session> sessions) {
    final tagSessionMap = <String, List<Session>>{};
    
    // Group sessions by tags
    for (final session in sessions) {
      for (final tag in session.tags) {
        tagSessionMap.putIfAbsent(tag, () => []).add(session);
      }
    }
    
    final patterns = <EnvironmentalPattern>[];
    final overallAverageRating = sessions.map((s) => _extractRating(s)).reduce((a, b) => a + b) / sessions.length;
    
    for (final entry in tagSessionMap.entries) {
      final tag = entry.key;
      final tagSessions = entry.value;
      
      if (tagSessions.length < 3) continue;
      
      final ratings = tagSessions.map((s) => _extractRating(s)).toList();
      final averageRating = ratings.reduce((a, b) => a + b) / ratings.length;
      
      final completedSessions = tagSessions.where((s) => s.durationMinutes >= 5).length;
      final completionRate = completedSessions / tagSessions.length;
      
      // Calculate correlation strength based on:
      // 1. How different the rating is from overall average
      // 2. Consistency of the effect (low variance in ratings)
      final ratingDifference = (averageRating - overallAverageRating).abs();
      final ratingVariance = _calculateVariance(ratings.map((r) => r.toDouble()).toList());
      final correlationStrength = min(1.0, (ratingDifference / 2.0) * (1.0 - min(1.0, ratingVariance / 4.0)));
      
      patterns.add(EnvironmentalPattern(
        factor: 'tag',
        value: tag,
        averageRating: averageRating,
        completionRate: completionRate,
        sessionCount: tagSessions.length,
        correlationStrength: correlationStrength,
        patternType: PatternType.contextual,
      ));
    }
    
    // Sort by correlation strength
    patterns.sort((a, b) => b.correlationStrength.compareTo(a.correlationStrength));
    
    return patterns.take(10).toList(); // Top 10 patterns
  }
  
  /// Generate personalized recommendations
  List<PersonalizedRecommendation> _generateRecommendations(
    List<TimeOfDayPattern> timePatterns,
    List<MoodOutcomePattern> moodPatterns,
    List<EnvironmentalPattern> environmentalPatterns,
  ) {
    final recommendations = <PersonalizedRecommendation>[];
    
    // Time-based recommendations
    final bestTime = timePatterns
        .where((p) => p.sessionCount >= 3)
        .fold<TimeOfDayPattern?>(null, (best, current) =>
            best == null || current.performanceScore > best.performanceScore ? current : best);
    
    if (bestTime != null && bestTime.quality == PatternQuality.excellent) {
      recommendations.add(PersonalizedRecommendation(
        title: 'Optimize Your Practice Time',
        description: 'Your ${bestTime.timeDescription.toLowerCase()} sessions (${bestTime.timeRange}) '
                    'consistently perform ${bestTime.performanceScore >= 0.9 ? "exceptionally well" : "well"} '
                    'with an average rating of ${bestTime.averageRating.toStringAsFixed(1)}/5.',
        actionItems: [
          'Schedule regular practice sessions during ${bestTime.timeRange}',
          'Block calendar time for your optimal practice window',
          if (bestTime.commonTags.isNotEmpty) 'Focus on: ${bestTime.commonTags.join(", ")}',
        ],
        confidenceScore: min(1.0, bestTime.sessionCount / 10.0 * 0.8 + 0.2),
        basedOnPattern: PatternType.temporal,
        generatedAt: DateTime.now(),
      ));
    }
    
    // Environmental recommendations
    final topPositivePattern = environmentalPatterns
        .where((p) => p.averageRating >= 4.0 && p.correlationStrength > 0.6)
        .firstOrNull;
    
    if (topPositivePattern != null) {
      recommendations.add(PersonalizedRecommendation(
        title: 'Leverage Your Success Factor',
        description: 'Sessions tagged with "${topPositivePattern.value}" show significantly better outcomes. '
                    '${topPositivePattern.impactDescription}',
        actionItems: [
          'Include "${topPositivePattern.value}" in more of your practice sessions',
          'Explore related themes and approaches',
          'Track how this approach affects your overall well-being',
        ],
        confidenceScore: topPositivePattern.correlationStrength * 0.9,
        basedOnPattern: PatternType.contextual,
        generatedAt: DateTime.now(),
      ));
    }
    
    // Mood-based recommendations
    final challengingMoodPattern = moodPatterns
        .where((p) => p.preMoodScore <= 2 && p.predictedQuality != PatternQuality.poor)
        .firstOrNull;
    
    if (challengingMoodPattern != null) {
      recommendations.add(PersonalizedRecommendation(
        title: 'Support During Difficult Times',
        description: 'Even when starting from a low mood, your practice can be beneficial. '
                    'Sessions improve your state by an average of ${challengingMoodPattern.averagePostMoodImprovement.toStringAsFixed(1)} points.',
        actionItems: [
          'Practice gentle, shorter sessions when feeling low',
          if (challengingMoodPattern.effectiveTags.isNotEmpty) 
            'Try approaches: ${challengingMoodPattern.effectiveTags.join(", ")}',
          'Remember that practice helps even in difficult moments',
        ],
        confidenceScore: min(1.0, challengingMoodPattern.sessionCount / 8.0 * 0.7 + 0.3),
        basedOnPattern: PatternType.emotional,
        generatedAt: DateTime.now(),
      ));
    }
    
    return recommendations;
  }
  
  /// Extract rating from session (placeholder - would be actual rating field)
  double _extractRating(Session session) {
    // In real implementation, this would extract actual rating from session
    // For now, use a heuristic based on duration and tags
    if (session.durationMinutes >= 15) return 4.5;
    if (session.durationMinutes >= 10) return 4.0;
    if (session.durationMinutes >= 5) return 3.5;
    return 3.0;
  }
  
  /// Calculate days covered by sessions
  int _calculateDaysCovered(List<Session> sessions) {
    if (sessions.isEmpty) return 0;
    
    final dates = sessions.map((s) => 
        DateTime(s.dateTime.year, s.dateTime.month, s.dateTime.day)).toSet();
    return dates.length;
  }
  
  /// Calculate variance of a list of numbers
  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
  
  /// Cache analysis results
  Future<void> _cacheAnalysis(MindfulnessPatternAnalysis analysis) async {
    try {
      final data = _analysisToJson(analysis);
      await _storage.setString(_lastAnalysisKey, LocalStorage.encodeJson(data));
    } catch (e) {
      // Ignore cache errors
    }
  }
  
  /// Convert analysis to JSON
  Map<String, dynamic> _analysisToJson(MindfulnessPatternAnalysis analysis) {
    return {
      'analysis_date': analysis.analysisDate.toIso8601String(),
      'total_sessions_analyzed': analysis.totalSessionsAnalyzed,
      'days_covered': analysis.daysCovered,
      'data_confidence': analysis.dataConfidence,
      'key_insights': analysis.keyInsights,
      'best_time_pattern': analysis.bestTimePattern != null ? {
        'hour': analysis.bestTimePattern!.hour,
        'time_description': analysis.bestTimePattern!.timeDescription,
        'time_range': analysis.bestTimePattern!.timeRange,
        'average_rating': analysis.bestTimePattern!.averageRating,
        'performance_score': analysis.bestTimePattern!.performanceScore,
      } : null,
      'top_recommendations': analysis.topRecommendations.map((r) => {
        'title': r.title,
        'description': r.description,
        'confidence_score': r.confidenceScore,
        'confidence_level': r.confidenceLevel,
        'action_items': r.actionItems,
        'pattern_type': r.basedOnPattern.toString(),
      }).toList(),
    };
  }
  
  /// Parse analysis from JSON
  MindfulnessPatternAnalysis? _parseAnalysisFromJson(Map<String, dynamic> data) {
    try {
      // For caching, we store a simplified version with key insights
      // Full analysis would require re-running the analysis
      return MindfulnessPatternAnalysis(
        analysisDate: DateTime.parse(data['analysis_date'] as String),
        totalSessionsAnalyzed: data['total_sessions_analyzed'] as int,
        daysCovered: data['days_covered'] as int,
        timePatterns: [], // Would need full data structure
        moodPatterns: [], // Would need full data structure
        environmentalPatterns: [], // Would need full data structure
        recommendations: [], // Would need full data structure
        bestTimePattern: null, // Would parse from data
        strongestPositivePattern: null, // Would parse from data
        strongestNegativePattern: null, // Would parse from data
      );
    } catch (e) {
      return null;
    }
  }
}

// Extension to add firstOrNull method
extension FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
import 'dart:math';
import '../session_tags.dart';

/// Mood entry data contract for analytics
/// Assumptions: score is 1-5 scale where higher values indicate better/more energetic mood
class MoodEntry {
  final DateTime at;         // local time
  final int score;           // 1..5 scale
  final List<String> tags;   // optional mood tags
  
  const MoodEntry(this.at, this.score, [this.tags = const []]);
}

/// Provider interface for mood data without coupling to specific implementation
abstract class MoodSource {
  Iterable<MoodEntry> entries({DateTime? from, DateTime? to});
}

/// Daily aggregation of mood and focus data
class DailyMoodFocus {
  final DateTime day;              // local date at 00:00
  final double? moodMedian;        // null if no mood data
  final int sessionCount;
  final Duration totalDuration;
  final Duration avgDuration;
  
  const DailyMoodFocus({
    required this.day,
    this.moodMedian,
    required this.sessionCount,
    required this.totalDuration,
    required this.avgDuration,
  });
}

/// Summary statistics for days grouped by mood bucket
class MoodBucketSummary {
  final int mood;                  // 1..5
  final double avgTotalMinutes;
  final double avgSessionsPerDay;
  final double? goalAttainmentRate; // 0..1, null if goal not available
  
  const MoodBucketSummary({
    required this.mood,
    required this.avgTotalMinutes,
    required this.avgSessionsPerDay,
    this.goalAttainmentRate,
  });
}

/// Association between session tags and above/below median performance
class TagAssociation {
  final String tag;
  final double lift;               // percentage delta vs baseline
  final int days;                  // support (number of days)
  
  const TagAssociation({
    required this.tag,
    required this.lift,
    required this.days,
  });
}

/// Pure functions for mood-focus insights analysis
class MoodFocusInsights {
  
  /// Compute daily mood-focus linkage
  /// Sessions are allocated to day of completion (end time)
  static List<DailyMoodFocus> computeDailyMoodFocus(
    Iterable<Session> sessions,
    Iterable<MoodEntry> moods,
  ) {
    // Group sessions by completion day (session start + duration)
    final sessionsByDay = <DateTime, List<Session>>{};
    for (final session in sessions) {
      final completionTime = session.dateTime.add(Duration(minutes: session.durationMinutes));
      final day = _toLocalDate(completionTime);
      sessionsByDay.putIfAbsent(day, () => []).add(session);
    }
    
    // Group moods by day
    final moodsByDay = <DateTime, List<MoodEntry>>{};
    for (final mood in moods) {
      final day = _toLocalDate(mood.at);
      moodsByDay.putIfAbsent(day, () => []).add(mood);
    }
    
    // Get all days that have either sessions or moods
    final allDays = {...sessionsByDay.keys, ...moodsByDay.keys}.toList()..sort();
    
    final results = <DailyMoodFocus>[];
    for (final day in allDays) {
      final daySessions = sessionsByDay[day] ?? [];
      final dayMoods = moodsByDay[day] ?? [];
      
      // Calculate session aggregates
      final sessionCount = daySessions.length;
      final totalMinutes = daySessions.fold(0, (sum, s) => sum + s.durationMinutes);
      final totalDuration = Duration(minutes: totalMinutes);
      final avgDuration = sessionCount > 0 
        ? Duration(minutes: totalMinutes ~/ sessionCount)
        : Duration.zero;
      
      // Calculate mood median
      final moodMedian = dayMoods.isEmpty ? null : _calculateMedian(dayMoods.map((m) => m.score.toDouble()).toList());
      
      results.add(DailyMoodFocus(
        day: day,
        moodMedian: moodMedian,
        sessionCount: sessionCount,
        totalDuration: totalDuration,
        avgDuration: avgDuration,
      ));
    }
    
    return results;
  }
  
  /// Calculate Pearson correlation between daily mood median and total focus duration
  /// Returns null if n < 2 or correlation is undefined
  static double? pearsonMoodVsTotalDuration(List<DailyMoodFocus> rows) {
    // Filter to days with both mood and session data
    final validRows = rows.where((r) => r.moodMedian != null && r.totalDuration.inMinutes > 0).toList();
    
    if (validRows.length < 2) return null;
    
    final moodScores = validRows.map((r) => r.moodMedian!).toList();
    final durations = validRows.map((r) => r.totalDuration.inMinutes.toDouble()).toList();
    
    return _pearsonCorrelation(moodScores, durations);
  }
  
  /// Summarize statistics by mood bucket (1-5)
  static List<MoodBucketSummary> summarizeByMoodBucket(
    List<DailyMoodFocus> rows, {
    double Function(DateTime day)? goalAttainmentForDay,
  }) {
    // Group days by mood bucket (rounded to nearest integer)
    final bucketGroups = <int, List<DailyMoodFocus>>{};
    
    for (final row in rows) {
      if (row.moodMedian != null) {
        final bucket = row.moodMedian!.round().clamp(1, 5);
        bucketGroups.putIfAbsent(bucket, () => []).add(row);
      }
    }
    
    final summaries = <MoodBucketSummary>[];
    for (int mood = 1; mood <= 5; mood++) {
      final bucketRows = bucketGroups[mood] ?? [];
      
      if (bucketRows.isEmpty) {
        summaries.add(MoodBucketSummary(
          mood: mood,
          avgTotalMinutes: 0.0,
          avgSessionsPerDay: 0.0,
          goalAttainmentRate: null,
        ));
        continue;
      }
      
      final avgTotalMinutes = bucketRows.map((r) => r.totalDuration.inMinutes).fold(0, (a, b) => a + b) / bucketRows.length;
      final avgSessionsPerDay = bucketRows.map((r) => r.sessionCount).fold(0, (a, b) => a + b) / bucketRows.length;
      
      double? goalAttainmentRate;
      if (goalAttainmentForDay != null) {
        final attainmentRates = bucketRows.map((r) => goalAttainmentForDay(r.day)).toList();
        goalAttainmentRate = attainmentRates.fold(0.0, (a, b) => a + b) / attainmentRates.length;
      }
      
      summaries.add(MoodBucketSummary(
        mood: mood,
        avgTotalMinutes: avgTotalMinutes,
        avgSessionsPerDay: avgSessionsPerDay,
        goalAttainmentRate: goalAttainmentRate,
      ));
    }
    
    return summaries;
  }
  
  /// Analyze tag associations with above/below median performance
  static ({List<TagAssociation> topPositive, List<TagAssociation> topNegative}) analyzeTagAssociations(
    Iterable<Session> sessions,
    List<DailyMoodFocus> rows,
  ) {
    if (rows.isEmpty) {
      return (topPositive: <TagAssociation>[], topNegative: <TagAssociation>[]);
    }
    
    // Calculate median total duration across all days
    final totalDurations = rows.map((r) => r.totalDuration.inMinutes.toDouble()).toList()..sort();
    final medianDuration = _calculateMedian(totalDurations);
    
    // Group sessions by day
    final sessionsByDay = <DateTime, List<Session>>{};
    for (final session in sessions) {
      final completionTime = session.dateTime.add(Duration(minutes: session.durationMinutes));
      final day = _toLocalDate(completionTime);
      sessionsByDay.putIfAbsent(day, () => []).add(session);
    }
    
    // Analyze tag frequency in above vs below median days
    final tagStats = <String, ({int aboveDays, int belowDays})>{};
    int aboveMedianDays = 0;
    int belowMedianDays = 0;
    
    for (final row in rows) {
      final isAboveMedian = row.totalDuration.inMinutes >= medianDuration;
      final daySessions = sessionsByDay[row.day] ?? [];
      
      if (isAboveMedian) {
        aboveMedianDays++;
      } else {
        belowMedianDays++;
      }
      
      final dayTags = <String>{};
      for (final session in daySessions) {
        dayTags.addAll(session.tags);
      }
      
      for (final tag in dayTags) {
        final current = tagStats[tag] ?? (aboveDays: 0, belowDays: 0);
        if (isAboveMedian) {
          tagStats[tag] = (aboveDays: current.aboveDays + 1, belowDays: current.belowDays);
        } else {
          tagStats[tag] = (aboveDays: current.aboveDays, belowDays: current.belowDays + 1);
        }
      }
    }
    
    // Calculate lift for each tag
    final associations = <TagAssociation>[];
    for (final entry in tagStats.entries) {
      final tag = entry.key;
      final stats = entry.value;
      final totalDays = stats.aboveDays + stats.belowDays;
      
      if (totalDays < 1) continue; // Need minimum support
      
      final aboveRate = aboveMedianDays > 0 ? stats.aboveDays / aboveMedianDays : 0.0;
      final belowRate = belowMedianDays > 0 ? stats.belowDays / belowMedianDays : 0.0;
      final baseline = totalDays / (aboveMedianDays + belowMedianDays);
      
      if (baseline > 0) {
        final lift = ((aboveRate - belowRate) / baseline) * 100;
        associations.add(TagAssociation(
          tag: tag,
          lift: lift,
          days: totalDays,
        ));
      }
    }
    
    // Sort by lift and take top 5 positive and negative
    associations.sort((a, b) {
      final liftCompare = b.lift.compareTo(a.lift);
      if (liftCompare != 0) return liftCompare;
      return a.tag.compareTo(b.tag); // Alphabetical tie-breaking
    });
    
    final topPositive = associations.where((a) => a.lift > 0).take(5).toList();
    final topNegative = associations.where((a) => a.lift < 0).toList().reversed.take(5).toList();
    
    return (topPositive: topPositive, topNegative: topNegative);
  }
  
  /// Calculate keyword uplift in session notes
  static Map<String, double> keywordUplift(
    Iterable<Session> sessions,
    List<String> keywords,
  ) {
    if (keywords.isEmpty || sessions.isEmpty) {
      return {for (final keyword in keywords) keyword: 0.0};
    }
    
    final sessionsWithNotes = sessions.where((s) => s.note != null).toList();
    if (sessionsWithNotes.isEmpty) {
      return {for (final keyword in keywords) keyword: 0.0};
    }
    
    // Calculate baseline (average duration across all sessions with notes)
    final baselineDuration = sessionsWithNotes
      .map((s) => s.durationMinutes)
      .fold(0, (a, b) => a + b) / sessionsWithNotes.length;
    
    final upliftResults = <String, double>{};
    
    for (final keyword in keywords) {
      final keywordLower = keyword.toLowerCase();
      final matchingSessions = sessionsWithNotes
        .where((s) => s.note!.toLowerCase().contains(keywordLower))
        .toList();
      
      if (matchingSessions.isEmpty) {
        upliftResults[keyword] = 0.0;
        continue;
      }
      
      final keywordAvgDuration = matchingSessions
        .map((s) => s.durationMinutes)
        .fold(0, (a, b) => a + b) / matchingSessions.length;
      
      final uplift = baselineDuration > 0 
        ? ((keywordAvgDuration - baselineDuration) / baselineDuration) * 100
        : 0.0;
      
      upliftResults[keyword] = uplift;
    }
    
    return upliftResults;
  }
  
  // Private helper methods
  
  /// Convert DateTime to local date (ignoring time)
  static DateTime _toLocalDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
  
  /// Calculate median of a list of numbers
  static double _calculateMedian(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final sorted = List<double>.from(values)..sort();
    final n = sorted.length;
    
    if (n % 2 == 0) {
      return (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
    } else {
      return sorted[n ~/ 2];
    }
  }
  
  /// Calculate Pearson correlation coefficient
  static double? _pearsonCorrelation(List<double> x, List<double> y) {
    if (x.length != y.length || x.length < 2) return null;
    
    final n = x.length;
    final meanX = x.fold(0.0, (a, b) => a + b) / n;
    final meanY = y.fold(0.0, (a, b) => a + b) / n;
    
    double numerator = 0.0;
    double sumXSquared = 0.0;
    double sumYSquared = 0.0;
    
    for (int i = 0; i < n; i++) {
      final dx = x[i] - meanX;
      final dy = y[i] - meanY;
      numerator += dx * dy;
      sumXSquared += dx * dx;
      sumYSquared += dy * dy;
    }
    
    final denominator = sqrt(sumXSquared * sumYSquared);
    
    if (denominator == 0) return null; // Avoid division by zero
    
    final correlation = numerator / denominator;
    
    // Clamp to [-1, 1] to handle floating-point precision issues
    return correlation.clamp(-1.0, 1.0);
  }
}
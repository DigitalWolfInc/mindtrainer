/// Coach Insights Bridge for MindTrainer
/// 
/// Provides pure functions to analyze coaching activity patterns and correlate
/// them with mood/focus data from the existing insights system.
/// 
/// **Usage in UI:**
/// ```dart
/// // Summarize coaching activity for dashboards
/// final coachSummaries = summarizeCoachActivity(coachEvents);
/// 
/// // Calculate correlation with focus performance
/// final correlation = correlationPlansVsFocusMinutes(coachSummaries, moodFocusData);
/// if (correlation != null && correlation > 0.3) {
///   showInsight('Your action planning correlates with better focus!');
/// }
/// ```

import 'dart:math';
import '../coach/coach_events.dart';
import 'mood_focus_insights.dart';

/// Daily summary of coaching session activity
/// 
/// Aggregates coaching events by local day to enable correlation analysis
/// with mood and focus performance metrics.
class CoachDaySummary {
  /// The local date (year-month-day, time set to 00:00)
  final DateTime day;
  
  /// Number of journal entries (user replies) recorded this day
  final int journalingEntries;
  
  /// Number of reframe interactions (cognitive distortion processing)
  final int reframes;
  
  /// Number of plan commitments made (action planning)
  final int plansCommitted;
  
  /// Most frequently occurring tags, sorted by frequency descending
  final List<String> topTags;
  
  const CoachDaySummary({
    required this.day,
    required this.journalingEntries,
    required this.reframes,
    required this.plansCommitted,
    required this.topTags,
  });
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoachDaySummary &&
          runtimeType == other.runtimeType &&
          day == other.day &&
          journalingEntries == other.journalingEntries &&
          reframes == other.reframes &&
          plansCommitted == other.plansCommitted &&
          _listEquals(topTags, other.topTags);
  
  @override
  int get hashCode =>
      day.hashCode ^
      journalingEntries.hashCode ^
      reframes.hashCode ^
      plansCommitted.hashCode ^
      topTags.hashCode;
  
  @override
  String toString() => 'CoachDaySummary('
      'day: $day, '
      'journalingEntries: $journalingEntries, '
      'reframes: $reframes, '
      'plansCommitted: $plansCommitted, '
      'topTags: $topTags'
      ')';
}

/// Summarize coaching activity by day
/// 
/// Groups coaching events by local date and computes:
/// - Total user interactions (journaling entries)
/// - Cognitive reframing instances
/// - Action plan commitments
/// - Most common emotional/mental themes (tags)
List<CoachDaySummary> summarizeCoachActivity(
  Iterable<CoachEvent> events
) {
  if (events.isEmpty) return [];
  
  // Group events by local date
  final eventsByDay = <DateTime, List<CoachEvent>>{};
  for (final event in events) {
    final day = _toLocalDate(event.at);
    eventsByDay.putIfAbsent(day, () => []).add(event);
  }
  
  final summaries = <CoachDaySummary>[];
  
  for (final entry in eventsByDay.entries) {
    final day = entry.key;
    final dayEvents = entry.value;
    
    // Count journaling entries (all events represent user replies)
    final journalingEntries = dayEvents.length;
    
    // Count reframes (events from reframe phase with outcomes)
    final reframes = dayEvents
        .where((e) => e.phase == 'reframe' && e.outcome == CoachOutcome.reframed)
        .length;
    
    // Count plan commitments (events from plan phase with outcomes)
    final plansCommitted = dayEvents
        .where((e) => e.phase == 'plan' && e.outcome == CoachOutcome.planned)
        .length;
    
    // Calculate tag frequency and get top tags
    final tagCounts = <String, int>{};
    for (final event in dayEvents) {
      for (final tag in event.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    // Sort tags by frequency, then alphabetically for deterministic output
    final sortedTags = tagCounts.entries.toList()
      ..sort((a, b) {
        final freqCompare = b.value.compareTo(a.value);
        if (freqCompare != 0) return freqCompare;
        return a.key.compareTo(b.key);
      });
    
    final topTags = sortedTags.take(5).map((e) => e.key).toList();
    
    summaries.add(CoachDaySummary(
      day: day,
      journalingEntries: journalingEntries,
      reframes: reframes,
      plansCommitted: plansCommitted,
      topTags: topTags,
    ));
  }
  
  // Sort by day for consistent output
  summaries.sort((a, b) => a.day.compareTo(b.day));
  
  return summaries;
}

/// Calculate correlation between action planning and focus performance
/// 
/// Computes Pearson correlation coefficient between daily plan commitments
/// and total focus minutes from mood/focus data. Returns null if insufficient
/// data (n < 2) or correlation is undefined.
/// 
/// Correlation interpretation:
/// - > 0.3: Moderate positive correlation (planning helps focus)
/// - < -0.3: Moderate negative correlation (unusual, may indicate oveplanning)
/// - -0.3 to 0.3: Weak or no correlation
double? correlationPlansVsFocusMinutes(
  List<CoachDaySummary> coachDays,
  List<DailyMoodFocus> moodFocusDays
) {
  if (coachDays.isEmpty || moodFocusDays.isEmpty) return null;
  
  // Create lookup for mood/focus data by day
  final moodFocusMap = <DateTime, DailyMoodFocus>{};
  for (final moodFocus in moodFocusDays) {
    moodFocusMap[moodFocus.day] = moodFocus;
  }
  
  // Collect matched data points
  final planCounts = <double>[];
  final focusMinutes = <double>[];
  
  for (final coachDay in coachDays) {
    final moodFocus = moodFocusMap[coachDay.day];
    if (moodFocus != null && moodFocus.totalDuration.inMinutes > 0) {
      planCounts.add(coachDay.plansCommitted.toDouble());
      focusMinutes.add(moodFocus.totalDuration.inMinutes.toDouble());
    }
  }
  
  // Need at least 2 data points for correlation
  if (planCounts.length < 2) return null;
  
  return _pearsonCorrelation(planCounts, focusMinutes);
}

// Private helpers

/// Convert DateTime to local date (ignoring time)
DateTime _toLocalDate(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

/// Calculate Pearson correlation coefficient
/// Returns null if insufficient data or correlation is undefined
double? _pearsonCorrelation(List<double> x, List<double> y) {
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

/// Helper for list equality comparison
bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
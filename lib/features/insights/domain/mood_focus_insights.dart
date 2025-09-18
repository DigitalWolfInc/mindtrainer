import 'dart:math' as math;
import '../../mood_checkin/domain/checkin_entry.dart';
import '../../mood_checkin/domain/animal_mood.dart';

class DailyMoodFocusPair {
  final DateTime date;
  final double moodScore;
  final int focusMinutes;

  const DailyMoodFocusPair({
    required this.date,
    required this.moodScore,
    required this.focusMinutes,
  });
}

class MoodFocusInsightsResult {
  final List<DailyMoodFocusPair> dailyPairs;
  final double? weeklyCorrelation;
  final List<String> topFocusMoods;

  const MoodFocusInsightsResult({
    required this.dailyPairs,
    required this.weeklyCorrelation,
    required this.topFocusMoods,
  });
}

class MoodFocusInsightsService {
  /// Maps AnimalMood to numeric scores for correlation analysis
  /// Scale: 1-10 where higher scores indicate moods associated with higher energy/focus potential
  /// Documented in DECISIONS.md under "Mood Score Mapping"
  static const Map<String, double> _moodScoreMapping = {
    'energetic_rabbit': 9.0,   // High energy, ready for action
    'curious_cat': 8.0,        // Active interest and engagement
    'playful_dolphin': 7.0,    // Fun-seeking, moderately active
    'wise_owl': 6.0,           // Thoughtful, contemplative
    'gentle_deer': 4.0,        // Quiet, gentle energy
    'calm_turtle': 3.0,        // Low energy, peaceful pace
  };

  static double getMoodScore(AnimalMood mood) {
    return _moodScoreMapping[mood.id] ?? 5.0; // Default neutral score
  }

  static MoodFocusInsightsResult computeInsights({
    required List<CheckinEntry> checkins,
    required List<Map<String, dynamic>> focusSessions,
  }) {
    final dailyPairs = _computeDailyPairs(checkins, focusSessions);
    final weeklyCorrelation = _computePearsonCorrelation(dailyPairs);
    final topFocusMoods = _computeTopFocusMoods(checkins, focusSessions);

    return MoodFocusInsightsResult(
      dailyPairs: dailyPairs,
      weeklyCorrelation: weeklyCorrelation,
      topFocusMoods: topFocusMoods,
    );
  }

  static List<DailyMoodFocusPair> _computeDailyPairs(
    List<CheckinEntry> checkins,
    List<Map<String, dynamic>> focusSessions,
  ) {
    // Group checkins by local date
    final dailyMoods = <DateTime, List<double>>{};
    for (final checkin in checkins) {
      final date = _toLocalDate(checkin.timestamp);
      final score = getMoodScore(checkin.animalMood);
      dailyMoods.putIfAbsent(date, () => []).add(score);
    }

    // Group focus sessions by local date
    final dailyFocus = <DateTime, int>{};
    for (final session in focusSessions) {
      final dateTime = session['dateTime'] as DateTime;
      final minutes = session['durationMinutes'] as int;
      final date = _toLocalDate(dateTime);
      dailyFocus[date] = (dailyFocus[date] ?? 0) + minutes;
    }

    // Create pairs for days with both mood and focus data
    final pairs = <DailyMoodFocusPair>[];
    for (final date in dailyMoods.keys) {
      if (dailyFocus.containsKey(date)) {
        final avgMoodScore = dailyMoods[date]!.reduce((a, b) => a + b) / dailyMoods[date]!.length;
        final focusMinutes = dailyFocus[date]!;
        pairs.add(DailyMoodFocusPair(
          date: date,
          moodScore: avgMoodScore,
          focusMinutes: focusMinutes,
        ));
      }
    }

    // Sort by date descending (most recent first)
    pairs.sort((a, b) => b.date.compareTo(a.date));
    return pairs;
  }

  static double? _computePearsonCorrelation(List<DailyMoodFocusPair> pairs) {
    if (pairs.length < 5) return null; // Need at least 5 data points

    final n = pairs.length;
    final moodScores = pairs.map((p) => p.moodScore).toList();
    final focusMinutes = pairs.map((p) => p.focusMinutes.toDouble()).toList();

    // Calculate means
    final moodMean = moodScores.reduce((a, b) => a + b) / n;
    final focusMean = focusMinutes.reduce((a, b) => a + b) / n;

    // Calculate correlation components
    double numerator = 0;
    double moodSumSq = 0;
    double focusSumSq = 0;

    for (int i = 0; i < n; i++) {
      final moodDiff = moodScores[i] - moodMean;
      final focusDiff = focusMinutes[i] - focusMean;
      
      numerator += moodDiff * focusDiff;
      moodSumSq += moodDiff * moodDiff;
      focusSumSq += focusDiff * focusDiff;
    }

    final denominator = math.sqrt(moodSumSq * focusSumSq);
    if (denominator == 0) return 0.0; // Avoid division by zero

    return numerator / denominator;
  }

  static List<String> _computeTopFocusMoods(
    List<CheckinEntry> checkins,
    List<Map<String, dynamic>> focusSessions,
  ) {
    // Group focus sessions by date
    final dailyFocus = <DateTime, int>{};
    for (final session in focusSessions) {
      final dateTime = session['dateTime'] as DateTime;
      final minutes = session['durationMinutes'] as int;
      final date = _toLocalDate(dateTime);
      dailyFocus[date] = (dailyFocus[date] ?? 0) + minutes;
    }

    // Group checkins by mood and collect their focus minutes
    final moodFocusMinutes = <String, List<int>>{};
    for (final checkin in checkins) {
      final date = _toLocalDate(checkin.timestamp);
      final focusMinutes = dailyFocus[date];
      if (focusMinutes != null) {
        moodFocusMinutes
            .putIfAbsent(checkin.animalMood.name, () => [])
            .add(focusMinutes);
      }
    }

    // Calculate average focus minutes per mood
    final moodAverages = <String, double>{};
    for (final entry in moodFocusMinutes.entries) {
      final average = entry.value.reduce((a, b) => a + b) / entry.value.length;
      moodAverages[entry.key] = average;
    }

    // Get top 3 moods by average focus minutes
    final sortedMoods = moodAverages.entries.toList()
      ..sort((a, b) {
        final comparison = b.value.compareTo(a.value); // Descending by average
        if (comparison != 0) return comparison;
        return a.key.compareTo(b.key); // Alphabetical tie-breaker
      });

    return sortedMoods.take(3).map((e) => e.key).toList();
  }

  static DateTime _toLocalDate(DateTime dateTime) {
    return DateTime(dateTime.year, dateTime.month, dateTime.day);
  }
}
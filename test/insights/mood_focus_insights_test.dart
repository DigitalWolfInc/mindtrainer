import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/insights/domain/mood_focus_insights.dart';
import 'package:mindtrainer/features/mood_checkin/domain/checkin_entry.dart';
import 'package:mindtrainer/features/mood_checkin/domain/animal_mood.dart';
import 'dart:math' as math;

void main() {
  group('MoodFocusInsights', () {
    group('Mood Score Mapping', () {
      test('should return correct scores for all animal moods', () {
        // Test documented mapping from DECISIONS.md
        expect(MoodFocusInsightsService.getMoodScore(_findMoodById('energetic_rabbit')), 9.0);
        expect(MoodFocusInsightsService.getMoodScore(_findMoodById('curious_cat')), 8.0);
        expect(MoodFocusInsightsService.getMoodScore(_findMoodById('playful_dolphin')), 7.0);
        expect(MoodFocusInsightsService.getMoodScore(_findMoodById('wise_owl')), 6.0);
        expect(MoodFocusInsightsService.getMoodScore(_findMoodById('gentle_deer')), 4.0);
        expect(MoodFocusInsightsService.getMoodScore(_findMoodById('calm_turtle')), 3.0);
      });

      test('should return default score for unknown mood', () {
        final unknownMood = AnimalMood(
          id: 'unknown_animal',
          name: 'Unknown Animal',
          emoji: '❓',
          description: 'Unknown mood',
        );
        expect(MoodFocusInsightsService.getMoodScore(unknownMood), 5.0);
      });
    });

    group('Daily Pairs Computation', () {
      test('should compute daily pairs correctly', () {
        final checkins = [
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 9, 0), // Morning
            animalMood: _findMoodById('energetic_rabbit'), // 9.0
          ),
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 17, 0), // Evening same day
            animalMood: _findMoodById('calm_turtle'), // 3.0
          ),
          CheckinEntry(
            timestamp: DateTime(2024, 1, 16, 10, 0), // Next day
            animalMood: _findMoodById('curious_cat'), // 8.0
          ),
        ];

        final focusSessions = [
          {
            'dateTime': DateTime(2024, 1, 15, 14, 30),
            'durationMinutes': 45,
          },
          {
            'dateTime': DateTime(2024, 1, 15, 16, 0),
            'durationMinutes': 30,
          },
          {
            'dateTime': DateTime(2024, 1, 16, 11, 15),
            'durationMinutes': 60,
          },
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.dailyPairs.length, 2);
        
        // Check first day (should average mood scores: (9.0 + 3.0) / 2 = 6.0)
        final day1 = result.dailyPairs.firstWhere((p) => p.date.day == 15);
        expect(day1.moodScore, 6.0);
        expect(day1.focusMinutes, 75); // 45 + 30

        // Check second day
        final day2 = result.dailyPairs.firstWhere((p) => p.date.day == 16);
        expect(day2.moodScore, 8.0);
        expect(day2.focusMinutes, 60);
      });

      test('should ignore days with only mood or only focus data', () {
        final checkins = [
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 9, 0),
            animalMood: _findMoodById('energetic_rabbit'),
          ),
        ];

        final focusSessions = [
          {
            'dateTime': DateTime(2024, 1, 16, 14, 30), // Different day
            'durationMinutes': 45,
          },
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.dailyPairs, isEmpty); // No matching days
      });

      test('should handle timezone-safe local dates correctly', () {
        final checkins = [
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 23, 59), // Late night
            animalMood: _findMoodById('energetic_rabbit'),
          ),
        ];

        final focusSessions = [
          {
            'dateTime': DateTime(2024, 1, 15, 1, 0), // Early morning same day
            'durationMinutes': 30,
          },
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.dailyPairs.length, 1);
        expect(result.dailyPairs[0].date, DateTime(2024, 1, 15));
      });
    });

    group('Pearson Correlation Calculation', () {
      test('should calculate correlation with sample data', () {
        // Create predictable test data: high mood should correlate with high focus
        final checkins = List.generate(7, (i) {
          return CheckinEntry(
            timestamp: DateTime(2024, 1, 15 + i, 10, 0),
            animalMood: i < 4 ? _findMoodById('energetic_rabbit') : _findMoodById('calm_turtle'),
          );
        });

        final focusSessions = List.generate(7, (i) {
          return {
            'dateTime': DateTime(2024, 1, 15 + i, 14, 0),
            'durationMinutes': i < 4 ? 80 : 20, // High focus for high mood days
          };
        });

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.weeklyCorrelation, isNotNull);
        expect(result.weeklyCorrelation!, greaterThan(0.5)); // Should be positive correlation
      });

      test('should return null correlation for <5 paired days', () {
        final checkins = List.generate(3, (i) {
          return CheckinEntry(
            timestamp: DateTime(2024, 1, 15 + i, 10, 0),
            animalMood: _findMoodById('energetic_rabbit'),
          );
        });

        final focusSessions = List.generate(3, (i) {
          return {
            'dateTime': DateTime(2024, 1, 15 + i, 14, 0),
            'durationMinutes': 60,
          };
        });

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.weeklyCorrelation, isNull);
      });

      test('should handle perfect positive correlation', () {
        final checkins = List.generate(5, (i) {
          final mood = i == 0 ? 'energetic_rabbit' : 
                       i == 1 ? 'curious_cat' :
                       i == 2 ? 'playful_dolphin' :
                       i == 3 ? 'gentle_deer' : 'calm_turtle';
          return CheckinEntry(
            timestamp: DateTime(2024, 1, 15 + i, 10, 0),
            animalMood: _findMoodById(mood),
          );
        });

        final focusSessions = List.generate(5, (i) {
          return {
            'dateTime': DateTime(2024, 1, 15 + i, 14, 0),
            'durationMinutes': (i + 1) * 20, // Increasing focus
          };
        });

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.weeklyCorrelation, isNotNull);
        expect(result.weeklyCorrelation!.abs(), greaterThan(0.8)); // Strong correlation
      });

      test('should handle zero correlation case', () {
        final checkins = List.generate(5, (i) {
          return CheckinEntry(
            timestamp: DateTime(2024, 1, 15 + i, 10, 0),
            animalMood: _findMoodById('wise_owl'), // Same mood for all
          );
        });

        final focusSessions = List.generate(5, (i) {
          return {
            'dateTime': DateTime(2024, 1, 15 + i, 14, 0),
            'durationMinutes': 60, // Same focus for all
          };
        });

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.weeklyCorrelation, 0.0); // Should be exactly 0
      });
    });

    group('Top Focus Moods', () {
      test('should return top 3 moods by average focus minutes', () {
        final checkins = [
          // Energetic Rabbit: 2 sessions, 80 + 100 = 90 avg
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 10, 0),
            animalMood: _findMoodById('energetic_rabbit'),
          ),
          CheckinEntry(
            timestamp: DateTime(2024, 1, 16, 10, 0),
            animalMood: _findMoodById('energetic_rabbit'),
          ),
          // Curious Cat: 1 session, 70 avg
          CheckinEntry(
            timestamp: DateTime(2024, 1, 17, 10, 0),
            animalMood: _findMoodById('curious_cat'),
          ),
          // Calm Turtle: 2 sessions, 20 + 40 = 30 avg
          CheckinEntry(
            timestamp: DateTime(2024, 1, 18, 10, 0),
            animalMood: _findMoodById('calm_turtle'),
          ),
          CheckinEntry(
            timestamp: DateTime(2024, 1, 19, 10, 0),
            animalMood: _findMoodById('calm_turtle'),
          ),
        ];

        final focusSessions = [
          {'dateTime': DateTime(2024, 1, 15, 14, 0), 'durationMinutes': 80},
          {'dateTime': DateTime(2024, 1, 16, 14, 0), 'durationMinutes': 100},
          {'dateTime': DateTime(2024, 1, 17, 14, 0), 'durationMinutes': 70},
          {'dateTime': DateTime(2024, 1, 18, 14, 0), 'durationMinutes': 20},
          {'dateTime': DateTime(2024, 1, 19, 14, 0), 'durationMinutes': 40},
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.topFocusMoods.length, 3);
        expect(result.topFocusMoods[0], 'Energetic Rabbit'); // Highest avg: 90
        expect(result.topFocusMoods[1], 'Curious Cat'); // Second: 70
        expect(result.topFocusMoods[2], 'Calm Turtle'); // Third: 30
      });

      test('should handle tie-breaker alphabetically', () {
        final checkins = [
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 10, 0),
            animalMood: _findMoodById('wise_owl'),
          ),
          CheckinEntry(
            timestamp: DateTime(2024, 1, 16, 10, 0),
            animalMood: _findMoodById('curious_cat'),
          ),
        ];

        final focusSessions = [
          {'dateTime': DateTime(2024, 1, 15, 14, 0), 'durationMinutes': 60}, // Same avg
          {'dateTime': DateTime(2024, 1, 16, 14, 0), 'durationMinutes': 60}, // Same avg
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.topFocusMoods.length, 2);
        expect(result.topFocusMoods[0], 'Curious Cat'); // Alphabetically first
        expect(result.topFocusMoods[1], 'Wise Owl');
      });

      test('should return fewer than 3 moods if less data available', () {
        final checkins = [
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 10, 0),
            animalMood: _findMoodById('energetic_rabbit'),
          ),
        ];

        final focusSessions = [
          {'dateTime': DateTime(2024, 1, 15, 14, 0), 'durationMinutes': 60},
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.topFocusMoods.length, 1);
        expect(result.topFocusMoods[0], 'Energetic Rabbit');
      });

      test('should return empty list when no mood-focus pairs exist', () {
        final result = MoodFocusInsightsService.computeInsights(
          checkins: [],
          focusSessions: [],
        );

        expect(result.topFocusMoods, isEmpty);
      });
    });

    group('Edge Cases', () {
      test('should handle empty inputs gracefully', () {
        final result = MoodFocusInsightsService.computeInsights(
          checkins: [],
          focusSessions: [],
        );

        expect(result.dailyPairs, isEmpty);
        expect(result.weeklyCorrelation, isNull);
        expect(result.topFocusMoods, isEmpty);
      });

      test('should handle multiple checkins per day correctly', () {
        final checkins = [
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 8, 0),
            animalMood: _findMoodById('energetic_rabbit'), // 9.0
          ),
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 12, 0),
            animalMood: _findMoodById('calm_turtle'), // 3.0
          ),
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 18, 0),
            animalMood: _findMoodById('curious_cat'), // 8.0
          ),
        ];

        final focusSessions = [
          {'dateTime': DateTime(2024, 1, 15, 14, 0), 'durationMinutes': 60},
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.dailyPairs.length, 1);
        // Should average all three moods: (9.0 + 3.0 + 8.0) / 3 = 6.67
        expect(result.dailyPairs[0].moodScore, closeTo(6.67, 0.01));
      });

      test('should handle multiple focus sessions per day correctly', () {
        final checkins = [
          CheckinEntry(
            timestamp: DateTime(2024, 1, 15, 10, 0),
            animalMood: _findMoodById('wise_owl'),
          ),
        ];

        final focusSessions = [
          {'dateTime': DateTime(2024, 1, 15, 9, 0), 'durationMinutes': 25},
          {'dateTime': DateTime(2024, 1, 15, 14, 0), 'durationMinutes': 45},
          {'dateTime': DateTime(2024, 1, 15, 19, 0), 'durationMinutes': 30},
        ];

        final result = MoodFocusInsightsService.computeInsights(
          checkins: checkins,
          focusSessions: focusSessions,
        );

        expect(result.dailyPairs.length, 1);
        expect(result.dailyPairs[0].focusMinutes, 100); // 25 + 45 + 30
      });
    });
  });
}

// Helper function to find mood by ID
AnimalMood _findMoodById(String id) {
  return AnimalMood.allMoods.firstWhere((mood) => mood.id == id);
}
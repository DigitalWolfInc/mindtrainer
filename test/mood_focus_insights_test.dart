import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/insights/mood_focus_insights.dart';
import 'package:mindtrainer/core/session_tags.dart';

void main() {
  group('Mood Focus Insights', () {
    
    group('Daily Mood-Focus Linkage', () {
      test('should handle no mood data', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 30,
            tags: ['focus'],
            note: null,
            id: 'session_1',
          ),
        ];
        final moods = <MoodEntry>[];
        
        final result = MoodFocusInsights.computeDailyMoodFocus(sessions, moods);
        
        expect(result.length, 1);
        expect(result.first.day, DateTime(2024, 1, 15));
        expect(result.first.moodMedian, null);
        expect(result.first.sessionCount, 1);
        expect(result.first.totalDuration, Duration(minutes: 30));
        expect(result.first.avgDuration, Duration(minutes: 30));
      });
      
      test('should handle single mood per day', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 45,
            tags: ['focus'],
            note: null,
            id: 'session_1',
          ),
        ];
        final moods = [
          MoodEntry(DateTime(2024, 1, 15, 8, 0), 4),
        ];
        
        final result = MoodFocusInsights.computeDailyMoodFocus(sessions, moods);
        
        expect(result.length, 1);
        expect(result.first.moodMedian, 4.0);
        expect(result.first.sessionCount, 1);
        expect(result.first.totalDuration, Duration(minutes: 45));
      });
      
      test('should calculate median for multiple moods per day', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 30,
            tags: ['focus'],
            note: null,
            id: 'session_1',
          ),
        ];
        final moods = [
          MoodEntry(DateTime(2024, 1, 15, 8, 0), 3),
          MoodEntry(DateTime(2024, 1, 15, 12, 0), 5),
          MoodEntry(DateTime(2024, 1, 15, 18, 0), 4),
        ];
        
        final result = MoodFocusInsights.computeDailyMoodFocus(sessions, moods);
        
        expect(result.length, 1);
        expect(result.first.moodMedian, 4.0); // Median of [3, 4, 5]
      });
      
      test('should allocate sessions to completion day', () {
        // Session starts late on Jan 14, completes early on Jan 15
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 14, 23, 30),
            durationMinutes: 60, // Ends at 00:30 on Jan 15
            tags: ['focus'],
            note: null,
            id: 'session_1',
          ),
        ];
        final moods = <MoodEntry>[];
        
        final result = MoodFocusInsights.computeDailyMoodFocus(sessions, moods);
        
        expect(result.length, 1);
        expect(result.first.day, DateTime(2024, 1, 15)); // Allocated to completion day
      });
      
      test('should handle multiple sessions per day', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 9, 0),
            durationMinutes: 25,
            tags: ['focus'],
            note: null,
            id: 'session_1',
          ),
          Session(
            dateTime: DateTime(2024, 1, 15, 14, 0),
            durationMinutes: 35,
            tags: ['deep-work'],
            note: null,
            id: 'session_2',
          ),
        ];
        final moods = <MoodEntry>[];
        
        final result = MoodFocusInsights.computeDailyMoodFocus(sessions, moods);
        
        expect(result.length, 1);
        expect(result.first.sessionCount, 2);
        expect(result.first.totalDuration, Duration(minutes: 60));
        expect(result.first.avgDuration, Duration(minutes: 30)); // 60/2
      });
    });
    
    group('Pearson Correlation', () {
      test('should return null for insufficient data (n < 2)', () {
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 4.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 30),
            avgDuration: Duration(minutes: 30),
          ),
        ];
        
        final correlation = MoodFocusInsights.pearsonMoodVsTotalDuration(rows);
        
        expect(correlation, null);
      });
      
      test('should calculate positive correlation', () {
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 2.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 20),
            avgDuration: Duration(minutes: 20),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: 4.0,
            sessionCount: 2,
            totalDuration: Duration(minutes: 60),
            avgDuration: Duration(minutes: 30),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 17),
            moodMedian: 5.0,
            sessionCount: 3,
            totalDuration: Duration(minutes: 90),
            avgDuration: Duration(minutes: 30),
          ),
        ];
        
        final correlation = MoodFocusInsights.pearsonMoodVsTotalDuration(rows);
        
        expect(correlation, isNotNull);
        expect(correlation!, greaterThan(0.8)); // Strong positive correlation
      });
      
      test('should calculate negative correlation', () {
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 5.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 20),
            avgDuration: Duration(minutes: 20),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: 3.0,
            sessionCount: 2,
            totalDuration: Duration(minutes: 60),
            avgDuration: Duration(minutes: 30),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 17),
            moodMedian: 1.0,
            sessionCount: 3,
            totalDuration: Duration(minutes: 90),
            avgDuration: Duration(minutes: 30),
          ),
        ];
        
        final correlation = MoodFocusInsights.pearsonMoodVsTotalDuration(rows);
        
        expect(correlation, isNotNull);
        expect(correlation!, lessThan(-0.8)); // Strong negative correlation
      });
      
      test('should return zero correlation for no relationship', () {
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 3.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 30),
            avgDuration: Duration(minutes: 30),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: 3.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 30),
            avgDuration: Duration(minutes: 30),
          ),
        ];
        
        final correlation = MoodFocusInsights.pearsonMoodVsTotalDuration(rows);
        
        expect(correlation, null); // Returns null when variance is zero
      });
      
      test('should handle correlation clamping', () {
        // Test with data that could produce correlation outside [-1, 1] due to floating point precision
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 1.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 10),
            avgDuration: Duration(minutes: 10),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: 5.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 100),
            avgDuration: Duration(minutes: 100),
          ),
        ];
        
        final correlation = MoodFocusInsights.pearsonMoodVsTotalDuration(rows);
        
        expect(correlation, isNotNull);
        expect(correlation!, greaterThanOrEqualTo(-1.0));
        expect(correlation!, lessThanOrEqualTo(1.0));
      });
    });
    
    group('Mood Bucket Summaries', () {
      test('should create summaries for all mood buckets', () {
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 2.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 20),
            avgDuration: Duration(minutes: 20),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: 4.0,
            sessionCount: 2,
            totalDuration: Duration(minutes: 60),
            avgDuration: Duration(minutes: 30),
          ),
        ];
        
        final summaries = MoodFocusInsights.summarizeByMoodBucket(rows);
        
        expect(summaries.length, 5); // Buckets 1-5
        
        // Check mood bucket 2 (has data)
        final bucket2 = summaries.firstWhere((s) => s.mood == 2);
        expect(bucket2.avgTotalMinutes, 20.0);
        expect(bucket2.avgSessionsPerDay, 1.0);
        expect(bucket2.goalAttainmentRate, null);
        
        // Check mood bucket 4 (has data)
        final bucket4 = summaries.firstWhere((s) => s.mood == 4);
        expect(bucket4.avgTotalMinutes, 60.0);
        expect(bucket4.avgSessionsPerDay, 2.0);
        
        // Check empty bucket
        final bucket1 = summaries.firstWhere((s) => s.mood == 1);
        expect(bucket1.avgTotalMinutes, 0.0);
        expect(bucket1.avgSessionsPerDay, 0.0);
      });
      
      test('should calculate goal attainment rate when provided', () {
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 3.0,
            sessionCount: 1,
            totalDuration: Duration(minutes: 30),
            avgDuration: Duration(minutes: 30),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: 3.0,
            sessionCount: 2,
            totalDuration: Duration(minutes: 60),
            avgDuration: Duration(minutes: 30),
          ),
        ];
        
        // Mock goal attainment: first day 0.5, second day 1.0
        double goalAttainmentForDay(DateTime day) {
          return day == DateTime(2024, 1, 15) ? 0.5 : 1.0;
        }
        
        final summaries = MoodFocusInsights.summarizeByMoodBucket(
          rows, 
          goalAttainmentForDay: goalAttainmentForDay,
        );
        
        final bucket3 = summaries.firstWhere((s) => s.mood == 3);
        expect(bucket3.goalAttainmentRate, 0.75); // Average of 0.5 and 1.0
      });
      
      test('should handle mood rounding to nearest bucket', () {
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: 2.4,
            sessionCount: 1,
            totalDuration: Duration(minutes: 30),
            avgDuration: Duration(minutes: 30),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: 2.6,
            sessionCount: 1,
            totalDuration: Duration(minutes: 40),
            avgDuration: Duration(minutes: 40),
          ),
        ];
        
        final summaries = MoodFocusInsights.summarizeByMoodBucket(rows);
        
        // 2.4 rounds to 2, 2.6 rounds to 3
        final bucket2 = summaries.firstWhere((s) => s.mood == 2);
        final bucket3 = summaries.firstWhere((s) => s.mood == 3);
        
        expect(bucket2.avgTotalMinutes, 30.0);
        expect(bucket3.avgTotalMinutes, 40.0);
      });
    });
    
    group('Tag Associations', () {
      test('should identify tags associated with above-median days', () {
        final sessions = [
          // High-duration day with "focus" tag
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 90,
            tags: ['focus'],
            note: null,
            id: 'session_1',
          ),
          // Low-duration day with "review" tag
          Session(
            dateTime: DateTime(2024, 1, 16, 10, 0),
            durationMinutes: 20,
            tags: ['review'],
            note: null,
            id: 'session_2',
          ),
          // Another high-duration day with "focus" tag
          Session(
            dateTime: DateTime(2024, 1, 17, 10, 0),
            durationMinutes: 80,
            tags: ['focus'],
            note: null,
            id: 'session_3',
          ),
        ];
        
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 90),
            avgDuration: Duration(minutes: 90),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 20),
            avgDuration: Duration(minutes: 20),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 17),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 80),
            avgDuration: Duration(minutes: 80),
          ),
        ];
        
        final result = MoodFocusInsights.analyzeTagAssociations(sessions, rows);
        
        // "focus" should be in topPositive (associated with high-duration days)
        expect(result.topPositive.isNotEmpty, true);
        expect(result.topPositive.first.tag, 'focus');
        expect(result.topPositive.first.lift, greaterThan(0));
        expect(result.topPositive.first.days, 2);
        
        // "review" should be in topNegative (associated with low-duration days)
        expect(result.topNegative.isNotEmpty, true);
        expect(result.topNegative.first.tag, 'review');
        expect(result.topNegative.first.lift, lessThan(0));
        expect(result.topNegative.first.days, 1);
      });
      
      test('should handle tie-breaking alphabetically', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 90,
            tags: ['zebra', 'alpha'],
            note: null,
            id: 'session_1',
          ),
          Session(
            dateTime: DateTime(2024, 1, 16, 10, 0),
            durationMinutes: 90,
            tags: ['zebra', 'alpha'],
            note: null,
            id: 'session_2',
          ),
          Session(
            dateTime: DateTime(2024, 1, 17, 10, 0),
            durationMinutes: 20,
            tags: [],
            note: null,
            id: 'session_3',
          ),
        ];
        
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 90),
            avgDuration: Duration(minutes: 90),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 90),
            avgDuration: Duration(minutes: 90),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 17),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 20),
            avgDuration: Duration(minutes: 20),
          ),
        ];
        
        final result = MoodFocusInsights.analyzeTagAssociations(sessions, rows);
        
        // Both tags should have same lift, so alphabetical order should apply
        expect(result.topPositive.length, 2);
        expect(result.topPositive.first.tag, 'alpha'); // Comes first alphabetically
        expect(result.topPositive.last.tag, 'zebra');
      });
      
      test('should handle empty inputs', () {
        final sessions = <Session>[];
        final rows = <DailyMoodFocus>[];
        
        final result = MoodFocusInsights.analyzeTagAssociations(sessions, rows);
        
        expect(result.topPositive, isEmpty);
        expect(result.topNegative, isEmpty);
      });
      
      test('should require minimum support for tag analysis', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 90,
            tags: ['rare-tag'],
            note: null,
            id: 'session_1',
          ),
          Session(
            dateTime: DateTime(2024, 1, 16, 10, 0),
            durationMinutes: 20,
            tags: [],
            note: null,
            id: 'session_2',
          ),
        ];
        
        final rows = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 90),
            avgDuration: Duration(minutes: 90),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            moodMedian: null,
            sessionCount: 1,
            totalDuration: Duration(minutes: 20),
            avgDuration: Duration(minutes: 20),
          ),
        ];
        
        final result = MoodFocusInsights.analyzeTagAssociations(sessions, rows);
        
        // "rare-tag" appears only 1 day with high duration, should be in topPositive
        expect(result.topPositive.isNotEmpty, true);
        expect(result.topPositive.first.tag, 'rare-tag');
        expect(result.topNegative, isEmpty);
      });
    });
    
    group('Keyword Uplift', () {
      test('should calculate uplift for matching keywords', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 60,
            tags: [],
            note: 'Working on algorithms today', // Contains "algorithm"
            id: 'session_1',
          ),
          Session(
            dateTime: DateTime(2024, 1, 16, 10, 0),
            durationMinutes: 30,
            tags: [],
            note: 'Simple review session',
            id: 'session_2',
          ),
          Session(
            dateTime: DateTime(2024, 1, 17, 10, 0),
            durationMinutes: 90,
            tags: [],
            note: 'Deep algorithm implementation', // Contains "algorithm"
            id: 'session_3',
          ),
        ];
        
        final keywords = ['algorithm', 'missing-word'];
        final result = MoodFocusInsights.keywordUplift(sessions, keywords);
        
        expect(result.containsKey('algorithm'), true);
        expect(result.containsKey('missing-word'), true);
        
        // Baseline: (60 + 30 + 90) / 3 = 60 minutes
        // Algorithm sessions: (60 + 90) / 2 = 75 minutes
        // Uplift: ((75 - 60) / 60) * 100 = 25%
        expect(result['algorithm'], closeTo(25.0, 0.1));
        expect(result['missing-word'], 0.0);
      });
      
      test('should handle case-insensitive matching', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 60,
            tags: [],
            note: 'Working on ALGORITHMS today',
            id: 'session_1',
          ),
          Session(
            dateTime: DateTime(2024, 1, 16, 10, 0),
            durationMinutes: 30,
            tags: [],
            note: 'Simple review session',
            id: 'session_2',
          ),
        ];
        
        final keywords = ['algorithm'];
        final result = MoodFocusInsights.keywordUplift(sessions, keywords);
        
        // Should match "ALGORITHMS" case-insensitively
        expect(result['algorithm'], greaterThan(0));
      });
      
      test('should handle empty inputs gracefully', () {
        final sessions = <Session>[];
        final keywords = ['test'];
        final result = MoodFocusInsights.keywordUplift(sessions, keywords);
        
        expect(result['test'], 0.0);
      });
      
      test('should handle sessions without notes', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 60,
            tags: [],
            note: null,
            id: 'session_1',
          ),
        ];
        
        final keywords = ['test'];
        final result = MoodFocusInsights.keywordUplift(sessions, keywords);
        
        expect(result['test'], 0.0);
      });
      
      test('should handle no matching sessions', () {
        final sessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 60,
            tags: [],
            note: 'No matching content here',
            id: 'session_1',
          ),
        ];
        
        final keywords = ['nonexistent'];
        final result = MoodFocusInsights.keywordUplift(sessions, keywords);
        
        expect(result['nonexistent'], 0.0);
      });
    });
    
    group('Stability & Performance', () {
      test('should not modify input collections', () {
        final originalSessions = [
          Session(
            dateTime: DateTime(2024, 1, 15, 10, 0),
            durationMinutes: 30,
            tags: ['focus'],
            note: 'test note',
            id: 'session_1',
          ),
        ];
        final originalMoods = [
          MoodEntry(DateTime(2024, 1, 15, 8, 0), 4),
        ];
        
        final sessionsCopy = List.from(originalSessions);
        final moodsCopy = List.from(originalMoods);
        
        // Run all insight functions
        final dailyResult = MoodFocusInsights.computeDailyMoodFocus(originalSessions, originalMoods);
        MoodFocusInsights.pearsonMoodVsTotalDuration(dailyResult);
        MoodFocusInsights.summarizeByMoodBucket(dailyResult);
        MoodFocusInsights.analyzeTagAssociations(originalSessions, dailyResult);
        MoodFocusInsights.keywordUplift(originalSessions, ['test']);
        
        // Verify original collections unchanged
        expect(originalSessions.length, sessionsCopy.length);
        expect(originalMoods.length, moodsCopy.length);
        expect(originalSessions.first.id, sessionsCopy.first.id);
        expect(originalMoods.first.score, moodsCopy.first.score);
      });
      
      test('should handle large datasets efficiently', () {
        // Generate 1000 sessions and moods
        final sessions = List.generate(1000, (i) {
          return Session(
            dateTime: DateTime(2024, 1, 1).add(Duration(hours: i)),
            durationMinutes: 30 + (i % 60),
            tags: i % 3 == 0 ? ['focus'] : (i % 3 == 1 ? ['review'] : []),
            note: i % 5 == 0 ? 'session note $i' : null,
            id: 'session_$i',
          );
        });
        
        final moods = List.generate(1000, (i) {
          return MoodEntry(
            DateTime(2024, 1, 1).add(Duration(hours: i)),
            1 + (i % 5),
          );
        });
        
        final stopwatch = Stopwatch()..start();
        
        final dailyResult = MoodFocusInsights.computeDailyMoodFocus(sessions, moods);
        final correlation = MoodFocusInsights.pearsonMoodVsTotalDuration(dailyResult);
        final buckets = MoodFocusInsights.summarizeByMoodBucket(dailyResult);
        final associations = MoodFocusInsights.analyzeTagAssociations(sessions, dailyResult);
        final keywords = MoodFocusInsights.keywordUplift(sessions, ['session', 'test']);
        
        stopwatch.stop();
        
        // Verify results are reasonable
        expect(dailyResult.length, greaterThan(0));
        expect(buckets.length, 5);
        expect(associations.topPositive.length, lessThanOrEqualTo(5));
        expect(keywords.containsKey('session'), true);
        
        // Performance should be reasonable (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Should be fast
      });
    });
  });
}
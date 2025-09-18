import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/focus_session/domain/insights_service.dart';
import 'package:mindtrainer/features/focus_session/domain/focus_session_insights.dart';

void main() {
  group('FocusSessionInsightsService', () {
    test('should return empty insights when no sessions exist', () {
      final insights = FocusSessionInsightsService.calculateInsights([]);
      
      expect(insights.rolling7DayTotalMinutes, 0);
      expect(insights.rolling7DayAvgMinutes, 0.0);
      expect(insights.rolling30DayTotalMinutes, 0);
      expect(insights.rolling30DayAvgMinutes, 0.0);
      expect(insights.currentStreak, 0);
      expect(insights.bestDay, isNull);
      expect(insights.bestDayMinutes, 0);
      expect(insights.longestSessionMinutes, 0);
    });

    test('should calculate rolling windows correctly', () {
      final today = DateTime(2024, 1, 15);
      final sessions = [
        // Today: 30 minutes
        {'dateTime': today.add(const Duration(hours: 10)), 'durationMinutes': 20},
        {'dateTime': today.add(const Duration(hours: 15)), 'durationMinutes': 10},
        
        // Yesterday: 25 minutes
        {'dateTime': today.subtract(const Duration(days: 1, hours: -12)), 'durationMinutes': 25},
        
        // 2 days ago: 15 minutes
        {'dateTime': today.subtract(const Duration(days: 2, hours: -14)), 'durationMinutes': 15},
        
        // 8 days ago: 40 minutes (outside 7-day window, inside 30-day)
        {'dateTime': today.subtract(const Duration(days: 8, hours: -10)), 'durationMinutes': 40},
        
        // 31 days ago: 50 minutes (outside both windows)
        {'dateTime': today.subtract(const Duration(days: 31, hours: -8)), 'durationMinutes': 50},
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: today);
      
      // 7-day window: today(30) + yesterday(25) + 2days(15) + 4 empty days = 70 minutes / 7 days
      expect(insights.rolling7DayTotalMinutes, 70);
      expect(insights.rolling7DayAvgMinutes, 10.0);
      
      // 30-day window: includes 8 days ago session = 70 + 40 = 110 minutes / 30 days
      expect(insights.rolling30DayTotalMinutes, 110);
      expect(insights.rolling30DayAvgMinutes, closeTo(3.67, 0.01));
    });

    test('should handle gaps in rolling windows correctly', () {
      final today = DateTime(2024, 1, 15);
      final sessions = [
        // Only sessions on day 1 and day 6, nothing in between
        {'dateTime': today, 'durationMinutes': 30},
        {'dateTime': today.subtract(const Duration(days: 5)), 'durationMinutes': 20},
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: today);
      
      // 7-day window should include all 7 days even with gaps
      expect(insights.rolling7DayTotalMinutes, 50);
      expect(insights.rolling7DayAvgMinutes, closeTo(7.14, 0.01)); // 50/7
    });

    test('should calculate current streak correctly', () {
      final today = DateTime(2024, 1, 15);
      final sessions = [
        // Today: has session
        {'dateTime': today, 'durationMinutes': 20},
        
        // Yesterday: has session
        {'dateTime': today.subtract(const Duration(days: 1)), 'durationMinutes': 25},
        
        // 2 days ago: has session
        {'dateTime': today.subtract(const Duration(days: 2)), 'durationMinutes': 15},
        
        // 3 days ago: NO session (gap)
        
        // 4 days ago: has session (shouldn't count due to gap)
        {'dateTime': today.subtract(const Duration(days: 4)), 'durationMinutes': 30},
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: today);
      
      // Streak should be 3 (today, yesterday, 2 days ago) then stop at gap
      expect(insights.currentStreak, 3);
    });

    test('should handle streak across month boundaries', () {
      final today = DateTime(2024, 2, 2); // February 2nd
      final sessions = [
        {'dateTime': DateTime(2024, 2, 2), 'durationMinutes': 20}, // Feb 2
        {'dateTime': DateTime(2024, 2, 1), 'durationMinutes': 25}, // Feb 1
        {'dateTime': DateTime(2024, 1, 31), 'durationMinutes': 15}, // Jan 31
        {'dateTime': DateTime(2024, 1, 30), 'durationMinutes': 30}, // Jan 30
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: today);
      
      expect(insights.currentStreak, 4);
    });

    test('should reset streak after zero-day gap', () {
      final today = DateTime(2024, 1, 15);
      final sessions = [
        // Today: has session
        {'dateTime': today, 'durationMinutes': 20},
        
        // Yesterday: NO session (gap)
        
        // 2 days ago: has session (shouldn't count)
        {'dateTime': today.subtract(const Duration(days: 2)), 'durationMinutes': 25},
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: today);
      
      expect(insights.currentStreak, 1); // Only today counts
    });

    test('should find best day with tie-break logic', () {
      final sessions = [
        {'dateTime': DateTime(2024, 1, 10, 9, 0), 'durationMinutes': 25},
        {'dateTime': DateTime(2024, 1, 10, 15, 0), 'durationMinutes': 25}, // Jan 10: 50 total
        
        {'dateTime': DateTime(2024, 1, 12, 10, 0), 'durationMinutes': 30},
        {'dateTime': DateTime(2024, 1, 12, 16, 0), 'durationMinutes': 20}, // Jan 12: 50 total (tie)
        
        {'dateTime': DateTime(2024, 1, 8, 14, 0), 'durationMinutes': 30}, // Jan 8: 30 total
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions);
      
      // Tie-break should pick earliest date (Jan 10)
      expect(insights.bestDay, DateTime(2024, 1, 10));
      expect(insights.bestDayMinutes, 50);
    });

    test('should find longest single session', () {
      final sessions = [
        {'dateTime': DateTime(2024, 1, 10), 'durationMinutes': 25},
        {'dateTime': DateTime(2024, 1, 11), 'durationMinutes': 45}, // Longest
        {'dateTime': DateTime(2024, 1, 12), 'durationMinutes': 30},
        {'dateTime': DateTime(2024, 1, 13), 'durationMinutes': 45}, // Tie for longest
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions);
      
      expect(insights.longestSessionMinutes, 45);
    });

    test('should handle multiple sessions on same day for best day calculation', () {
      final sessions = [
        {'dateTime': DateTime(2024, 1, 10, 9, 0), 'durationMinutes': 20},
        {'dateTime': DateTime(2024, 1, 10, 12, 0), 'durationMinutes': 15},
        {'dateTime': DateTime(2024, 1, 10, 18, 0), 'durationMinutes': 25}, // Jan 10: 60 total
        
        {'dateTime': DateTime(2024, 1, 12, 10, 0), 'durationMinutes': 45}, // Jan 12: 45 total
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions);
      
      expect(insights.bestDay, DateTime(2024, 1, 10));
      expect(insights.bestDayMinutes, 60);
      expect(insights.longestSessionMinutes, 45); // Single longest session
    });

    test('should handle consecutive days correctly', () {
      final today = DateTime(2024, 1, 15);
      final sessions = [
        {'dateTime': DateTime(2024, 1, 15, 10, 0), 'durationMinutes': 20}, // Today
        {'dateTime': DateTime(2024, 1, 14, 10, 0), 'durationMinutes': 25}, // Yesterday
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: today);
      
      // Should count both consecutive days  
      expect(insights.currentStreak, 2);
      expect(insights.rolling7DayTotalMinutes, 45);
    });

    test('should handle sessions at exact day boundaries', () {
      final sessions = [
        {'dateTime': DateTime(2024, 1, 15, 0, 0, 0), 'durationMinutes': 20}, // Start of day
        {'dateTime': DateTime(2024, 1, 15, 23, 59, 59), 'durationMinutes': 25}, // End of day
        {'dateTime': DateTime(2024, 1, 14, 23, 59, 59), 'durationMinutes': 15}, // End of previous day
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: DateTime(2024, 1, 15));
      
      // Both Jan 15 sessions should be grouped together
      expect(insights.bestDay, DateTime(2024, 1, 15));
      expect(insights.bestDayMinutes, 45); // 20 + 25
      expect(insights.currentStreak, 2); // Jan 15 and Jan 14
    });

    test('should handle out-of-range sessions correctly', () {
      final today = DateTime(2024, 6, 15);
      final sessions = [
        {'dateTime': today, 'durationMinutes': 30},
        
        // Way in the past - outside 30-day window
        {'dateTime': DateTime(2023, 1, 1), 'durationMinutes': 100},
        
        // Future session (shouldn't happen but test robustness)
        {'dateTime': today.add(const Duration(days: 5)), 'durationMinutes': 25},
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: today);
      
      // Should only count today's session for rolling windows
      expect(insights.rolling7DayTotalMinutes, 30);
      expect(insights.rolling30DayTotalMinutes, 30);
      expect(insights.currentStreak, 1); // Only today
      expect(insights.longestSessionMinutes, 100); // Longest overall, regardless of date
    });

    test('should handle zero-minute sessions', () {
      final sessions = [
        {'dateTime': DateTime(2024, 1, 15), 'durationMinutes': 0}, // Zero duration (today)
        {'dateTime': DateTime(2024, 1, 14), 'durationMinutes': 25}, // Yesterday  
        {'dateTime': DateTime(2024, 1, 13), 'durationMinutes': 0}, // Zero duration (day before yesterday)
      ];

      final insights = FocusSessionInsightsService.calculateInsights(sessions, currentDate: DateTime(2024, 1, 15));
      
      // Zero-minute sessions should still count as "having a session" for streak
      expect(insights.currentStreak, 3);
      expect(insights.rolling7DayTotalMinutes, 25); // Only non-zero durations count for totals
      expect(insights.longestSessionMinutes, 25);
      expect(insights.bestDayMinutes, 25); // Best day is Jan 14 with 25 minutes
    });
  });
}
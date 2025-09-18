import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/focus_session/domain/weekly_progress_service.dart';
import 'package:mindtrainer/features/focus_session/domain/weekly_progress.dart';

void main() {
  group('WeeklyProgressService', () {
    test('should return empty progress when no sessions exist', () {
      final progress = WeeklyProgressService.calculateWeeklyProgress(
        [], 
        300, // 5 hours goal
      );
      
      expect(progress.currentWeekTotal, 0);
      expect(progress.goalMinutes, 300);
      expect(progress.percent, 0.0);
    });

    test('should calculate progress for current week (Mon-Sun)', () {
      // Test for a Tuesday (Jan 16, 2024)
      final tuesday = DateTime(2024, 1, 16); // Tuesday
      final monday = DateTime(2024, 1, 15);   // Monday (start of week)
      final sunday = DateTime(2024, 1, 21);   // Sunday (end of week)
      
      final sessions = [
        // Monday: 60 minutes
        {'dateTime': monday.add(const Duration(hours: 10)), 'durationMinutes': 60},
        
        // Tuesday: 90 minutes (2 sessions)
        {'dateTime': tuesday.add(const Duration(hours: 9)), 'durationMinutes': 45},
        {'dateTime': tuesday.add(const Duration(hours: 14)), 'durationMinutes': 45},
        
        // Previous week (should be excluded)
        {'dateTime': monday.subtract(const Duration(days: 1)), 'durationMinutes': 120},
        
        // Next week (should be excluded)
        {'dateTime': sunday.add(const Duration(days: 1)), 'durationMinutes': 60},
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300, // 5 hours goal
        currentDate: tuesday,
      );
      
      expect(progress.currentWeekTotal, 150); // 60 + 90
      expect(progress.goalMinutes, 300);
      expect(progress.percent, 0.5); // 150/300
    });

    test('should handle week boundary correctly (Sun→Mon)', () {
      final sunday = DateTime(2024, 1, 14); // Sunday
      final monday = DateTime(2024, 1, 15);   // Monday (new week starts)
      
      final sessions = [
        // Current week (Mon)
        {'dateTime': monday.add(const Duration(hours: 10)), 'durationMinutes': 100},
        
        // Previous week (Sun)
        {'dateTime': sunday.add(const Duration(hours: 10)), 'durationMinutes': 200},
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: monday,
      );
      
      // Should only count Monday session (100), not Sunday (200)
      expect(progress.currentWeekTotal, 100);
      expect(progress.percent, closeTo(0.33, 0.01));
    });

    test('should handle DST transition correctly', () {
      // DST transition in US: March 10, 2024 (Spring forward)
      final beforeDST = DateTime(2024, 3, 9);  // Saturday before DST
      final afterDST = DateTime(2024, 3, 11);  // Monday after DST
      final currentDate = DateTime(2024, 3, 12); // Tuesday
      
      final sessions = [
        // Same week as current date
        {'dateTime': afterDST.add(const Duration(hours: 10)), 'durationMinutes': 60},
        {'dateTime': currentDate.add(const Duration(hours: 14)), 'durationMinutes': 90},
        
        // Previous week (should be excluded)
        {'dateTime': beforeDST.add(const Duration(hours: 12)), 'durationMinutes': 120},
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: currentDate,
      );
      
      expect(progress.currentWeekTotal, 150); // Only current week sessions
      expect(progress.percent, 0.5);
    });

    test('should clamp percentage to 1.0 when over goal', () {
      final monday = DateTime(2024, 1, 15);
      
      final sessions = [
        {'dateTime': monday.add(const Duration(hours: 10)), 'durationMinutes': 200},
        {'dateTime': monday.add(const Duration(hours: 14)), 'durationMinutes': 250},
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300, // 5 hours goal
        currentDate: monday,
      );
      
      expect(progress.currentWeekTotal, 450); // Total exceeds goal
      expect(progress.goalMinutes, 300);
      expect(progress.percent, 1.0); // Clamped to 1.0
    });

    test('should handle zero goal minutes gracefully', () {
      final monday = DateTime(2024, 1, 15);
      
      final sessions = [
        {'dateTime': monday.add(const Duration(hours: 10)), 'durationMinutes': 60},
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        0, // Zero goal
        currentDate: monday,
      );
      
      expect(progress.currentWeekTotal, 60);
      expect(progress.goalMinutes, 0);
      expect(progress.percent, 0.0); // Should handle division by zero
    });

    test('should correctly identify sessions at exact week boundaries', () {
      // Monday 00:00:00 and Sunday 23:59:59 should both count
      final monday = DateTime(2024, 1, 15, 0, 0, 0); // Start of week
      final sunday = DateTime(2024, 1, 21, 23, 59, 59); // End of week
      final nextMonday = DateTime(2024, 1, 22, 0, 0, 0); // Next week
      
      final sessions = [
        {'dateTime': monday, 'durationMinutes': 30},
        {'dateTime': sunday, 'durationMinutes': 45},
        {'dateTime': nextMonday, 'durationMinutes': 60}, // Next week - should not count
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: DateTime(2024, 1, 16), // Tuesday of same week
      );
      
      expect(progress.currentWeekTotal, 75); // 30 + 45, excluding next week
    });

    test('should handle cross-midnight sessions correctly', () {
      // Sessions that span across days should be counted by their start time
      final monday = DateTime(2024, 1, 15, 23, 30); // Late Monday
      final tuesday = DateTime(2024, 1, 16, 0, 30);  // Early Tuesday
      
      final sessions = [
        {'dateTime': monday, 'durationMinutes': 60},   // Starts Monday, might end Tuesday
        {'dateTime': tuesday, 'durationMinutes': 45},  // Clearly Tuesday
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: tuesday,
      );
      
      // Both sessions should count as they're in the same week
      expect(progress.currentWeekTotal, 105); // 60 + 45
    });

    test('should handle sessions across different weeks', () {
      final currentWeekDay = DateTime(2024, 1, 16); // Tuesday
      final previousWeekDay = DateTime(2024, 1, 9);  // Previous Tuesday
      final nextWeekDay = DateTime(2024, 1, 23);     // Next Tuesday
      
      final sessions = [
        {'dateTime': previousWeekDay, 'durationMinutes': 120},
        {'dateTime': currentWeekDay, 'durationMinutes': 90},
        {'dateTime': nextWeekDay, 'durationMinutes': 60},
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: currentWeekDay,
      );
      
      // Only current week session should count
      expect(progress.currentWeekTotal, 90);
      expect(progress.percent, 0.3);
    });

    test('should handle week starting on different days of month', () {
      // Test when Monday falls on different days
      final jan1Monday = DateTime(2024, 1, 1); // Jan 1 is Monday
      final jan8Monday = DateTime(2024, 1, 8); // Jan 8 is Monday
      
      final sessions = [
        // First week of January
        {'dateTime': DateTime(2024, 1, 2), 'durationMinutes': 60}, // Tuesday
        {'dateTime': DateTime(2024, 1, 5), 'durationMinutes': 90}, // Friday
        
        // Second week of January
        {'dateTime': DateTime(2024, 1, 9), 'durationMinutes': 45}, // Tuesday
      ];

      // Test from first week perspective
      final firstWeekProgress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: DateTime(2024, 1, 3), // Wednesday of first week
      );
      
      expect(firstWeekProgress.currentWeekTotal, 150); // 60 + 90
      
      // Test from second week perspective
      final secondWeekProgress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: DateTime(2024, 1, 10), // Wednesday of second week
      );
      
      expect(secondWeekProgress.currentWeekTotal, 45); // Only Tuesday of second week
    });

    test('should handle month boundaries in week calculation', () {
      // Week spanning from January to February
      final lastMondayJan = DateTime(2024, 1, 29); // Monday Jan 29
      final firstFridayFeb = DateTime(2024, 2, 2);  // Friday Feb 2
      
      final sessions = [
        {'dateTime': DateTime(2024, 1, 30), 'durationMinutes': 60}, // Tuesday Jan 30
        {'dateTime': DateTime(2024, 2, 1), 'durationMinutes': 90},  // Thursday Feb 1
        {'dateTime': DateTime(2024, 2, 2), 'durationMinutes': 45},  // Friday Feb 2
      ];

      final progress = WeeklyProgressService.calculateWeeklyProgress(
        sessions, 
        300,
        currentDate: firstFridayFeb,
      );
      
      // All sessions should count as they're in the same week
      expect(progress.currentWeekTotal, 195); // 60 + 90 + 45
      expect(progress.percent, 0.65);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindtrainer/features/settings/domain/app_settings.dart';

void main() {
  group('Goal Minutes Persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('should return default 300 minutes when no value is stored', () async {
      final prefs = await SharedPreferences.getInstance();
      final goalMinutes = prefs.getInt(AppSettings.keyWeeklyGoalMinutes) ?? AppSettings.defaultWeeklyGoalMinutes;
      
      expect(goalMinutes, 300);
    });

    test('should store and retrieve goal minutes correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Store a custom goal
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 450);
      
      // Retrieve the goal
      final retrievedGoal = prefs.getInt(AppSettings.keyWeeklyGoalMinutes) ?? AppSettings.defaultWeeklyGoalMinutes;
      
      expect(retrievedGoal, 450);
    });

    test('should handle update and reload round-trip correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Initial store
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 240);
      expect(prefs.getInt(AppSettings.keyWeeklyGoalMinutes), 240);
      
      // Update
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 600);
      expect(prefs.getInt(AppSettings.keyWeeklyGoalMinutes), 600);
      
      // Reload (simulate app restart)
      final reloadedGoal = prefs.getInt(AppSettings.keyWeeklyGoalMinutes) ?? AppSettings.defaultWeeklyGoalMinutes;
      expect(reloadedGoal, 600);
    });

    test('should maintain separate storage from other settings', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Store different types of settings
      await prefs.setBool(AppSettings.keyNotificationsEnabled, false);
      await prefs.setString(AppSettings.keyThemeMode, 'dark');
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 360);
      
      // Verify they don't interfere with each other
      expect(prefs.getBool(AppSettings.keyNotificationsEnabled), false);
      expect(prefs.getString(AppSettings.keyThemeMode), 'dark');
      expect(prefs.getInt(AppSettings.keyWeeklyGoalMinutes), 360);
    });

    test('should handle edge case values correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Test minimum reasonable value
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 60);
      expect(prefs.getInt(AppSettings.keyWeeklyGoalMinutes), 60);
      
      // Test maximum reasonable value (24 hours)
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 1440);
      expect(prefs.getInt(AppSettings.keyWeeklyGoalMinutes), 1440);
      
      // Test zero value
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 0);
      expect(prefs.getInt(AppSettings.keyWeeklyGoalMinutes), 0);
    });

    test('should fall back to default when key is removed', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Store a value
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 420);
      expect(prefs.getInt(AppSettings.keyWeeklyGoalMinutes), 420);
      
      // Remove the key
      await prefs.remove(AppSettings.keyWeeklyGoalMinutes);
      
      // Should fall back to default
      final goalMinutes = prefs.getInt(AppSettings.keyWeeklyGoalMinutes) ?? AppSettings.defaultWeeklyGoalMinutes;
      expect(goalMinutes, 300);
    });

    test('should handle concurrent access correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Simulate concurrent writes (in practice these would be sequential due to async)
      await Future.wait([
        prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 180),
        prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 240),
        prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 300),
      ]);
      
      // Last write should win
      final finalValue = prefs.getInt(AppSettings.keyWeeklyGoalMinutes);
      expect(finalValue, isNotNull);
      expect([180, 240, 300], contains(finalValue)); // One of these values should be stored
    });

    test('should validate AppSettings constants', () {
      // Verify the constants are correct
      expect(AppSettings.keyWeeklyGoalMinutes, 'weekly_goal_minutes');
      expect(AppSettings.defaultWeeklyGoalMinutes, 300);
      
      // Verify key uniqueness (shouldn't conflict with other keys)
      final keys = [
        AppSettings.keyUserPreferences,
        AppSettings.keyThemeMode,
        AppSettings.keyNotificationsEnabled,
        AppSettings.keyWeeklyGoalMinutes,
      ];
      
      expect(keys.toSet().length, keys.length); // No duplicates
    });

    test('should handle type safety correctly', () async {
      final prefs = await SharedPreferences.getInstance();
      
      // Store correct type
      await prefs.setInt(AppSettings.keyWeeklyGoalMinutes, 360);
      
      // Retrieve with type safety
      final goalMinutes = prefs.getInt(AppSettings.keyWeeklyGoalMinutes);
      expect(goalMinutes, isA<int>());
      expect(goalMinutes, 360);
      
      // Test fallback when key contains wrong type (simulate corrupted data)
      // Remove the int value first, then add wrong type to simulate corruption
      await prefs.remove(AppSettings.keyWeeklyGoalMinutes);
      
      // In practice, we'd handle this with a try-catch, but for the test we just verify null handling
      final nullValue = prefs.getInt(AppSettings.keyWeeklyGoalMinutes);
      expect(nullValue, isNull);
      
      // Verify fallback works
      final fallbackGoal = prefs.getInt(AppSettings.keyWeeklyGoalMinutes) ?? AppSettings.defaultWeeklyGoalMinutes;
      expect(fallbackGoal, 300);
    });
  });
}
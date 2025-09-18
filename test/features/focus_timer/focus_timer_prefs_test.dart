import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/features/focus_timer/services/focus_timer_prefs.dart';

void main() {
  group('FocusTimerPrefs', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FocusTimerPrefs.resetForTesting();
    });
    
    test('should return default duration when no preference saved', () async {
      final prefs = FocusTimerPrefs.instance;
      final duration = await prefs.getLastDuration();
      
      expect(duration.inSeconds, equals(1500)); // 25 minutes
    });
    
    test('should save and load last duration correctly', () async {
      final prefs = FocusTimerPrefs.instance;
      const testDuration = Duration(minutes: 10);
      
      await prefs.setLastDuration(testDuration);
      final loadedDuration = await prefs.getLastDuration();
      
      expect(loadedDuration, equals(testDuration));
    });
    
    test('should enforce minimum duration when saving', () async {
      final prefs = FocusTimerPrefs.instance;
      const shortDuration = Duration(seconds: 30);
      
      await prefs.setLastDuration(shortDuration);
      final loadedDuration = await prefs.getLastDuration();
      
      expect(loadedDuration.inSeconds, equals(60)); // Minimum 1 minute
    });
    
    test('should provide standard duration options', () {
      final durations = FocusTimerPrefs.standardDurations;
      
      expect(durations.length, equals(4));
      expect(durations, contains(const Duration(minutes: 5)));
      expect(durations, contains(const Duration(minutes: 10)));
      expect(durations, contains(const Duration(minutes: 20)));
      expect(durations, contains(const Duration(minutes: 25)));
    });
    
    test('should validate duration correctly', () {
      expect(FocusTimerPrefs.isValidDuration(const Duration(seconds: 30)), isFalse);
      expect(FocusTimerPrefs.isValidDuration(const Duration(seconds: 60)), isTrue);
      expect(FocusTimerPrefs.isValidDuration(const Duration(minutes: 5)), isTrue);
    });
    
    test('should cache duration after first load', () async {
      final prefs = FocusTimerPrefs.instance;
      const testDuration = Duration(minutes: 15);
      
      await prefs.setLastDuration(testDuration);
      
      // First load
      final duration1 = await prefs.getLastDuration();
      
      // Second load should use cache
      final duration2 = await prefs.getLastDuration();
      
      expect(duration1, equals(testDuration));
      expect(duration2, equals(testDuration));
    });
  });
}
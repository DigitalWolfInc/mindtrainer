import 'package:flutter_test/flutter_test.dart';
import '../../../lib/domain/focus/focus_stats.dart';

void main() {
  group('FocusStats Domain Model', () {
    test('zero constant should have correct values', () {
      expect(FocusStats.zero.totalMinutes, equals(0));
      expect(FocusStats.zero.sessionCount, equals(0));
      expect(FocusStats.zero.averageMinutes, equals(0));
    });
    
    test('averageMinutes should compute correctly', () {
      const stats = FocusStats(totalMinutes: 150, sessionCount: 6);
      expect(stats.averageMinutes, equals(25)); // 150 / 6 = 25
    });
    
    test('averageMinutes should return 0 for no sessions', () {
      const stats = FocusStats(totalMinutes: 0, sessionCount: 0);
      expect(stats.averageMinutes, equals(0));
    });
    
    test('averageMinutes should round to nearest integer', () {
      const stats = FocusStats(totalMinutes: 100, sessionCount: 3);
      expect(stats.averageMinutes, equals(33)); // 100 / 3 = 33.333... -> 33
    });
    
    test('addSession should enforce minimum 1 minute', () {
      const stats = FocusStats.zero;
      final updated = stats.addSession(const Duration(seconds: 30));
      
      expect(updated.totalMinutes, equals(1));
      expect(updated.sessionCount, equals(1));
      expect(updated.averageMinutes, equals(1));
    });
    
    test('addSession should round to nearest minute', () {
      const stats = FocusStats.zero;
      final updated = stats.addSession(const Duration(seconds: 90)); // 1.5 minutes
      
      expect(updated.totalMinutes, equals(2)); // Rounded to 2
      expect(updated.sessionCount, equals(1));
      expect(updated.averageMinutes, equals(2));
    });
    
    test('addSession should accumulate correctly', () {
      const stats = FocusStats(totalMinutes: 25, sessionCount: 1);
      final updated = stats.addSession(const Duration(minutes: 35));
      
      expect(updated.totalMinutes, equals(60));
      expect(updated.sessionCount, equals(2));
      expect(updated.averageMinutes, equals(30));
    });
    
    test('addSession with exact minute boundary', () {
      const stats = FocusStats.zero;
      final updated = stats.addSession(const Duration(minutes: 25, seconds: 0));
      
      expect(updated.totalMinutes, equals(25));
      expect(updated.sessionCount, equals(1));
      expect(updated.averageMinutes, equals(25));
    });
    
    test('reset should return zero state', () {
      const stats = FocusStats(totalMinutes: 100, sessionCount: 4);
      final reset = stats.reset();
      
      expect(reset.totalMinutes, equals(0));
      expect(reset.sessionCount, equals(0));
      expect(reset.averageMinutes, equals(0));
    });
    
    test('equality should work correctly', () {
      const stats1 = FocusStats(totalMinutes: 50, sessionCount: 2);
      const stats2 = FocusStats(totalMinutes: 50, sessionCount: 2);
      const stats3 = FocusStats(totalMinutes: 60, sessionCount: 2);
      
      expect(stats1, equals(stats2));
      expect(stats1, isNot(equals(stats3)));
    });
    
    test('hashCode should be consistent', () {
      const stats1 = FocusStats(totalMinutes: 50, sessionCount: 2);
      const stats2 = FocusStats(totalMinutes: 50, sessionCount: 2);
      
      expect(stats1.hashCode, equals(stats2.hashCode));
    });
    
    test('toString should include key info', () {
      const stats = FocusStats(totalMinutes: 75, sessionCount: 3);
      final string = stats.toString();
      
      expect(string, contains('totalMinutes: 75'));
      expect(string, contains('sessionCount: 3'));
      expect(string, contains('averageMinutes: 25'));
    });
    
    test('stress test with many sessions', () {
      var stats = FocusStats.zero;
      
      // Add 100 sessions of varying lengths
      for (int i = 1; i <= 100; i++) {
        stats = stats.addSession(Duration(minutes: i));
      }
      
      expect(stats.sessionCount, equals(100));
      expect(stats.totalMinutes, equals(5050)); // Sum of 1 to 100
      expect(stats.averageMinutes, equals(51)); // 5050 / 100 = 50.5 -> 51
    });
  });
}
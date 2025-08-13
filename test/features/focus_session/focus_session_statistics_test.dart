import 'package:flutter_test/flutter_test.dart';
import '../../../lib/features/focus_session/domain/focus_session_statistics.dart';

void main() {
  group('FocusSessionStatistics', () {
    test('empty statistics should have zero values', () {
      final stats = FocusSessionStatistics.empty();
      
      expect(stats.totalFocusTimeMinutes, equals(0));
      expect(stats.averageSessionLength, equals(0.0));
      expect(stats.completedSessionsCount, equals(0));
    });
    
    test('should serialize to and from JSON correctly', () {
      const stats = FocusSessionStatistics(
        totalFocusTimeMinutes: 150,
        averageSessionLength: 25.0,
        completedSessionsCount: 6,
      );
      
      final json = stats.toJson();
      final restored = FocusSessionStatistics.fromJson(json);
      
      expect(restored.totalFocusTimeMinutes, equals(150));
      expect(restored.averageSessionLength, equals(25.0));
      expect(restored.completedSessionsCount, equals(6));
    });
    
    test('should handle invalid JSON gracefully', () {
      final stats = FocusSessionStatistics.fromJson({});
      
      expect(stats.totalFocusTimeMinutes, equals(0));
      expect(stats.averageSessionLength, equals(0.0));
      expect(stats.completedSessionsCount, equals(0));
    });
    
    test('should add session correctly for first session', () {
      final stats = FocusSessionStatistics.empty();
      final updated = stats.addSession(25);
      
      expect(updated.totalFocusTimeMinutes, equals(25));
      expect(updated.averageSessionLength, equals(25.0));
      expect(updated.completedSessionsCount, equals(1));
    });
    
    test('should add session correctly for multiple sessions', () {
      const stats = FocusSessionStatistics(
        totalFocusTimeMinutes: 50,
        averageSessionLength: 25.0,
        completedSessionsCount: 2,
      );
      
      final updated = stats.addSession(30);
      
      expect(updated.totalFocusTimeMinutes, equals(80));
      expect(updated.averageSessionLength, equals(80.0 / 3));
      expect(updated.completedSessionsCount, equals(3));
    });
    
    test('should calculate average correctly with varying session lengths', () {
      final stats = FocusSessionStatistics.empty();
      final after1 = stats.addSession(10);
      final after2 = after1.addSession(20);
      final after3 = after2.addSession(30);
      
      expect(after3.totalFocusTimeMinutes, equals(60));
      expect(after3.averageSessionLength, equals(20.0));
      expect(after3.completedSessionsCount, equals(3));
    });
    
    test('should reset statistics correctly', () {
      const stats = FocusSessionStatistics(
        totalFocusTimeMinutes: 120,
        averageSessionLength: 30.0,
        completedSessionsCount: 4,
      );
      
      final reset = stats.reset();
      
      expect(reset.totalFocusTimeMinutes, equals(0));
      expect(reset.averageSessionLength, equals(0.0));
      expect(reset.completedSessionsCount, equals(0));
    });
  });
}
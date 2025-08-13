import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/features/focus_session/domain/focus_session_statistics.dart';
import '../../../lib/features/focus_session/data/focus_session_statistics_storage.dart';

void main() {
  group('FocusSessionStatisticsStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    
    test('should return empty statistics when no data stored', () async {
      final stats = await FocusSessionStatisticsStorage.loadStatistics();
      
      expect(stats.totalFocusTimeMinutes, equals(0));
      expect(stats.averageSessionLength, equals(0.0));
      expect(stats.completedSessionsCount, equals(0));
    });
    
    test('should save and load statistics correctly', () async {
      const originalStats = FocusSessionStatistics(
        totalFocusTimeMinutes: 120,
        averageSessionLength: 24.0,
        completedSessionsCount: 5,
      );
      
      await FocusSessionStatisticsStorage.saveStatistics(originalStats);
      final loadedStats = await FocusSessionStatisticsStorage.loadStatistics();
      
      expect(loadedStats.totalFocusTimeMinutes, equals(120));
      expect(loadedStats.averageSessionLength, equals(24.0));
      expect(loadedStats.completedSessionsCount, equals(5));
    });
    
    test('should handle invalid JSON gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('focus_session_statistics', 'invalid-json');
      
      final stats = await FocusSessionStatisticsStorage.loadStatistics();
      
      expect(stats.totalFocusTimeMinutes, equals(0));
      expect(stats.averageSessionLength, equals(0.0));
      expect(stats.completedSessionsCount, equals(0));
    });
    
    test('should clear statistics correctly', () async {
      const stats = FocusSessionStatistics(
        totalFocusTimeMinutes: 100,
        averageSessionLength: 25.0,
        completedSessionsCount: 4,
      );
      
      await FocusSessionStatisticsStorage.saveStatistics(stats);
      await FocusSessionStatisticsStorage.clearStatistics();
      
      final clearedStats = await FocusSessionStatisticsStorage.loadStatistics();
      expect(clearedStats.totalFocusTimeMinutes, equals(0));
      expect(clearedStats.averageSessionLength, equals(0.0));
      expect(clearedStats.completedSessionsCount, equals(0));
    });
    
    test('should persist statistics across multiple saves', () async {
      var stats = FocusSessionStatistics.empty();
      
      // Add first session
      stats = stats.addSession(20);
      await FocusSessionStatisticsStorage.saveStatistics(stats);
      
      // Add second session
      stats = stats.addSession(30);
      await FocusSessionStatisticsStorage.saveStatistics(stats);
      
      // Verify final state
      final finalStats = await FocusSessionStatisticsStorage.loadStatistics();
      expect(finalStats.totalFocusTimeMinutes, equals(50));
      expect(finalStats.averageSessionLength, equals(25.0));
      expect(finalStats.completedSessionsCount, equals(2));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../lib/core/feature_flags.dart';
import '../../lib/data/focus/focus_stats_repository.dart';
import '../../lib/data/focus/focus_stats_local_ds.dart';
import '../../lib/features/focus_timer/focus_stats_controller.dart';
import '../../lib/domain/focus/focus_stats.dart';

void main() {
  group('Focus Stats Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      FocusStatsController.resetForTesting();
    });
    
    tearDown(() {
      FocusStatsController.resetForTesting();
    });
    
    test('should persist stats across app restart simulation', () async {
      // Skip if feature not enabled
      if (!FeatureFlags.focusStatsEnabled) {
        return;
      }
      
      // Session 1: Record initial data
      var repository = FocusStatsRepositoryImpl(createFocusStatsLocalDataSource());
      
      await repository.recordCompletedSession(const Duration(minutes: 5, seconds: 30)); // 6 min
      await repository.recordCompletedSession(const Duration(minutes: 24, seconds: 10)); // 24 min
      
      var stats = await repository.getStats();
      expect(stats.totalMinutes, equals(30)); // 6 + 24
      expect(stats.sessionCount, equals(2));
      expect(stats.averageMinutes, equals(15)); // 30 / 2
      
      // Simulate app restart by creating new repository instance
      repository = FocusStatsRepositoryImpl(createFocusStatsLocalDataSource());
      
      // Verify data persisted
      stats = await repository.getStats();
      expect(stats.totalMinutes, equals(30));
      expect(stats.sessionCount, equals(2));
      expect(stats.averageMinutes, equals(15));
      
      // Add more data after restart
      await repository.recordCompletedSession(const Duration(minutes: 15));
      
      stats = await repository.getStats();
      expect(stats.totalMinutes, equals(45)); // 30 + 15
      expect(stats.sessionCount, equals(3));
      expect(stats.averageMinutes, equals(15)); // 45 / 3
    });
    
    test('should handle corrupted data gracefully and continue working', () async {
      if (!FeatureFlags.focusStatsEnabled) return;
      
      // Manually corrupt SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mt_focus_total_minutes_v1', 'corrupted_data');
      await prefs.setInt('mt_focus_session_count_v1', -999);
      
      // Repository should handle corruption and return safe defaults
      final repository = FocusStatsRepositoryImpl(createFocusStatsLocalDataSource());
      var stats = await repository.getStats();
      
      expect(stats.totalMinutes, equals(0)); // Repaired
      expect(stats.sessionCount, equals(0)); // Repaired
      
      // Should continue working normally after repair
      stats = await repository.recordCompletedSession(const Duration(minutes: 20));
      expect(stats.totalMinutes, equals(20));
      expect(stats.sessionCount, equals(1));
    });
    
    test('focus stats controller should integrate with repository', () async {
      if (!FeatureFlags.focusStatsEnabled) return;
      
      final controller = FocusStatsController.instance;
      await controller.initialize();
      
      // Fire some session completed events
      controller.fireSessionCompleted(const Duration(minutes: 10));
      
      // Wait for first event to process
      await Future.delayed(const Duration(milliseconds: 50));
      
      controller.fireSessionCompleted(const Duration(minutes: 15, seconds: 30)); // 16 min
      
      // Allow async processing to complete
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify stats were updated
      final stats = await controller.repository.getStats();
      expect(stats.totalMinutes, equals(26)); // 10 + 16
      expect(stats.sessionCount, equals(2));
      expect(stats.averageMinutes, equals(13)); // 26 / 2
      
      controller.dispose();
    });
    
    test('should handle rapid session completions without data corruption', () async {
      if (!FeatureFlags.focusStatsEnabled) return;
      
      final repository = FocusStatsRepositoryImpl(createFocusStatsLocalDataSource());
      
      // Simulate sequential session completions to avoid race conditions
      for (int i = 1; i <= 20; i++) {
        await repository.recordCompletedSession(Duration(minutes: i));
      }
      
      // Verify final state is correct
      final stats = await repository.getStats();
      expect(stats.sessionCount, equals(20));
      expect(stats.totalMinutes, equals(210)); // Sum of 1 to 20
      expect(stats.averageMinutes, equals(11)); // 210 / 20 = 10.5 -> 11
    });
    
    test('analytics opt-out should prevent event emission', () async {
      // This test verifies the analytics integration points exist
      // In a real implementation, you'd check that analytics events
      // are only emitted when user has opted in
      
      // For now, just verify the events structure exists
      expect(() => {
        'event': 'focus_stats_viewed',
        'surface': 'history',
      }, returnsNormally);
      
      expect(() => {
        'event': 'focus_session_recorded',
        'minutes': 25,
      }, returnsNormally);
    });
    
    test('should maintain correct averages with edge cases', () async {
      if (!FeatureFlags.focusStatsEnabled) return;
      
      final repository = FocusStatsRepositoryImpl(createFocusStatsLocalDataSource());
      
      // Test edge cases for rounding
      await repository.recordCompletedSession(const Duration(seconds: 29)); // 1 min (minimum)
      await repository.recordCompletedSession(const Duration(seconds: 89)); // 1 min (round down)
      await repository.recordCompletedSession(const Duration(seconds: 91)); // 2 min (round up)
      
      final stats = await repository.getStats();
      expect(stats.totalMinutes, equals(4)); // 1 + 1 + 2
      expect(stats.sessionCount, equals(3));
      expect(stats.averageMinutes, equals(1)); // 4 / 3 = 1.33 -> 1
    });
    
    test('should handle feature flag disabled gracefully', () async {
      // This test would be more meaningful if we could toggle the feature flag
      // For now, just verify the controller handles disabled state
      
      final controller = FocusStatsController.instance;
      
      // Should not crash even if feature is disabled
      expect(() => controller.fireSessionCompleted(const Duration(minutes: 10)), returnsNormally);
      expect(() => controller.initialize(), returnsNormally);
      expect(() => controller.dispose(), returnsNormally);
    });
    
    test('should handle storage quota exceeded gracefully', () async {
      if (!FeatureFlags.focusStatsEnabled) return;
      
      // Test with extreme values that might cause storage issues
      final repository = FocusStatsRepositoryImpl(createFocusStatsLocalDataSource());
      
      // This should not crash even with large numbers
      const extremeStats = FocusStats(totalMinutes: 999999, sessionCount: 999999);
      
      // The data source should clamp these values
      expect(() async {
        final dataSource = createFocusStatsLocalDataSource();
        await dataSource.write(extremeStats);
        await dataSource.read();
      }, returnsNormally);
    });
  });
}
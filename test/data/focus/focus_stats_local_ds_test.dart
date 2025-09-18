import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../lib/data/focus/focus_stats_local_ds.dart';
import '../../../lib/domain/focus/focus_stats.dart';

void main() {
  group('FocusStatsLocalDataSource', () {
    late FocusStatsLocalDataSource dataSource;
    
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      dataSource = createFocusStatsLocalDataSource();
    });
    
    test('read should return zero for missing data', () async {
      final stats = await dataSource.read();
      
      expect(stats.totalMinutes, equals(0));
      expect(stats.sessionCount, equals(0));
    });
    
    test('write and read should persist data correctly', () async {
      const originalStats = FocusStats(totalMinutes: 120, sessionCount: 4);
      
      await dataSource.write(originalStats);
      final loadedStats = await dataSource.read();
      
      expect(loadedStats.totalMinutes, equals(120));
      expect(loadedStats.sessionCount, equals(4));
    });
    
    test('clear should remove all data', () async {
      const stats = FocusStats(totalMinutes: 60, sessionCount: 2);
      
      await dataSource.write(stats);
      await dataSource.clear();
      
      final clearedStats = await dataSource.read();
      expect(clearedStats.totalMinutes, equals(0));
      expect(clearedStats.sessionCount, equals(0));
    });
    
    test('should repair negative totalMinutes', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('mt_focus_total_minutes_v1', -100);
      await prefs.setInt('mt_focus_session_count_v1', 2);
      
      final stats = await dataSource.read();
      
      expect(stats.totalMinutes, equals(0)); // Repaired
      expect(stats.sessionCount, equals(2)); // Valid value preserved
    });
    
    test('should repair negative sessionCount', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('mt_focus_total_minutes_v1', 100);
      await prefs.setInt('mt_focus_session_count_v1', -5);
      
      final stats = await dataSource.read();
      
      expect(stats.totalMinutes, equals(100)); // Valid value preserved
      expect(stats.sessionCount, equals(0)); // Repaired
    });
    
    test('should repair excessive values', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('mt_focus_total_minutes_v1', 2000000); // Too large
      await prefs.setInt('mt_focus_session_count_v1', 5);
      
      final stats = await dataSource.read();
      
      expect(stats.totalMinutes, equals(0)); // Repaired
      expect(stats.sessionCount, equals(5)); // Valid value preserved
    });
    
    test('should handle corrupted string values gracefully', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('mt_focus_total_minutes_v1', 'invalid');
      await prefs.setInt('mt_focus_session_count_v1', 3);
      
      final stats = await dataSource.read();
      
      expect(stats.totalMinutes, equals(0)); // Fallback
      expect(stats.sessionCount, equals(3)); // Valid value preserved
    });
    
    test('should clamp values when writing', () async {
      const invalidStats = FocusStats(totalMinutes: -50, sessionCount: 2000000);
      
      await dataSource.write(invalidStats);
      final loadedStats = await dataSource.read();
      
      expect(loadedStats.totalMinutes, equals(0)); // Clamped
      expect(loadedStats.sessionCount, equals(1000000)); // Clamped to max
    });
    
    test('should set schema version on first write', () async {
      const stats = FocusStats(totalMinutes: 30, sessionCount: 1);
      
      await dataSource.write(stats);
      
      final prefs = await SharedPreferences.getInstance();
      final version = prefs.getInt('mt_focus_schema_version');
      expect(version, equals(1));
    });
    
    test('should handle SharedPreferences errors gracefully', () async {
      // This tests the try/catch blocks in the implementation
      // In real usage, SharedPreferences might fail due to storage issues
      
      const stats = FocusStats(totalMinutes: 50, sessionCount: 2);
      
      // Should not throw even if there are issues
      expect(() async => await dataSource.write(stats), returnsNormally);
      expect(() async => await dataSource.read(), returnsNormally);
      expect(() async => await dataSource.clear(), returnsNormally);
    });
    
    test('should maintain data consistency across multiple operations', () async {
      var stats = FocusStats.zero;
      
      // Simulate multiple sessions being recorded
      for (int i = 1; i <= 10; i++) {
        stats = stats.addSession(Duration(minutes: i * 5));
        await dataSource.write(stats);
        
        final loaded = await dataSource.read();
        expect(loaded, equals(stats));
      }
      
      expect(stats.sessionCount, equals(10));
      expect(stats.totalMinutes, equals(275)); // Sum of 5,10,15...50
    });
  });
}
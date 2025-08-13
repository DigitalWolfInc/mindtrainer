import 'package:flutter_test/flutter_test.dart';
import '../../../lib/data/focus/focus_stats_repository.dart';
import '../../../lib/data/focus/focus_stats_local_ds.dart';
import '../../../lib/domain/focus/focus_stats.dart';

// Mock data source for testing
class MockFocusStatsLocalDataSource implements FocusStatsLocalDataSource {
  FocusStats _stats = FocusStats.zero;
  bool _shouldThrow = false;
  
  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }
  
  @override
  Future<FocusStats> read() async {
    if (_shouldThrow) throw Exception('Mock error');
    return _stats;
  }
  
  @override
  Future<void> write(FocusStats stats) async {
    if (_shouldThrow) throw Exception('Mock error');
    _stats = stats;
  }
  
  @override
  Future<void> clear() async {
    if (_shouldThrow) throw Exception('Mock error');
    _stats = FocusStats.zero;
  }
}

void main() {
  group('FocusStatsRepository', () {
    late FocusStatsRepository repository;
    late MockFocusStatsLocalDataSource mockDataSource;
    
    setUp(() {
      mockDataSource = MockFocusStatsLocalDataSource();
      repository = FocusStatsRepositoryImpl(mockDataSource);
    });
    
    test('getStats should return current stats', () async {
      // Pre-populate with some data
      await mockDataSource.write(const FocusStats(totalMinutes: 60, sessionCount: 3));
      
      final stats = await repository.getStats();
      
      expect(stats.totalMinutes, equals(60));
      expect(stats.sessionCount, equals(3));
      expect(stats.averageMinutes, equals(20));
    });
    
    test('recordCompletedSession should update stats correctly', () async {
      final duration = const Duration(minutes: 25, seconds: 30);
      
      final updatedStats = await repository.recordCompletedSession(duration);
      
      expect(updatedStats.totalMinutes, equals(26)); // Rounded from 25.5
      expect(updatedStats.sessionCount, equals(1));
      expect(updatedStats.averageMinutes, equals(26));
    });
    
    test('recordCompletedSession should accumulate correctly', () async {
      // Record first session
      await repository.recordCompletedSession(const Duration(minutes: 20));
      
      // Record second session
      final updatedStats = await repository.recordCompletedSession(const Duration(minutes: 30));
      
      expect(updatedStats.totalMinutes, equals(50));
      expect(updatedStats.sessionCount, equals(2));
      expect(updatedStats.averageMinutes, equals(25));
    });
    
    test('recordCompletedSession should enforce minimum 1 minute', () async {
      final updatedStats = await repository.recordCompletedSession(const Duration(seconds: 30));
      
      expect(updatedStats.totalMinutes, equals(1));
      expect(updatedStats.sessionCount, equals(1));
      expect(updatedStats.averageMinutes, equals(1));
    });
    
    test('recordCompletedSession should round correctly', () async {
      // Test various rounding scenarios
      final testCases = [
        (Duration(seconds: 89), 1),   // 1.48 min -> 1 min
        (Duration(seconds: 90), 2),   // 1.5 min -> 2 min
        (Duration(seconds: 91), 2),   // 1.52 min -> 2 min
        (Duration(minutes: 2, seconds: 29), 2), // 2.48 min -> 2 min
        (Duration(minutes: 2, seconds: 30), 3), // 2.5 min -> 3 min
      ];
      
      for (final (duration, expectedMinutes) in testCases) {
        mockDataSource.clear(); // Reset for each test
        final stats = await repository.recordCompletedSession(duration);
        expect(stats.totalMinutes, equals(expectedMinutes), 
               reason: 'Duration $duration should round to $expectedMinutes minutes');
      }
    });
    
    test('resetStats should clear all data', () async {
      // Add some data first
      await repository.recordCompletedSession(const Duration(minutes: 30));
      
      await repository.resetStats();
      
      final stats = await repository.getStats();
      expect(stats.totalMinutes, equals(0));
      expect(stats.sessionCount, equals(0));
    });
    
    test('should handle data source errors gracefully in getStats', () async {
      mockDataSource.setShouldThrow(true);
      
      // Should throw since repository doesn't catch read errors
      expect(() => repository.getStats(), throwsException);
    });
    
    test('should handle data source errors gracefully in recordCompletedSession', () async {
      mockDataSource.setShouldThrow(true);
      
      // Should throw since repository doesn't catch write errors
      expect(() => repository.recordCompletedSession(const Duration(minutes: 25)), throwsException);
    });
    
    test('should handle data source errors gracefully in resetStats', () async {
      mockDataSource.setShouldThrow(true);
      
      // Should throw since repository doesn't catch clear errors
      expect(() => repository.resetStats(), throwsException);
    });
    
    test('repository should maintain data consistency', () async {
      // Record multiple sessions and verify consistency
      final sessions = [
        Duration(minutes: 10),
        Duration(minutes: 15, seconds: 30), // 16 minutes rounded
        Duration(minutes: 25),
        Duration(seconds: 45), // 1 minute minimum
        Duration(minutes: 30, seconds: 29), // 30 minutes rounded
      ];
      
      var expectedTotal = 0;
      for (int i = 0; i < sessions.length; i++) {
        final stats = await repository.recordCompletedSession(sessions[i]);
        
        // Calculate expected total manually
        final minutes = sessions[i].inSeconds < 60 ? 1 : (sessions[i].inSeconds / 60.0).round();
        expectedTotal += minutes;
        
        expect(stats.sessionCount, equals(i + 1));
        expect(stats.totalMinutes, equals(expectedTotal));
        expect(stats.averageMinutes, equals((expectedTotal / (i + 1)).round()));
      }
      
      // Final verification
      final finalStats = await repository.getStats();
      expect(finalStats.sessionCount, equals(5));
      expect(finalStats.totalMinutes, equals(82)); // 10+16+25+1+30
      expect(finalStats.averageMinutes, equals(16)); // 82/5 = 16.4 -> 16
    });
  });
}
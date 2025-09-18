import 'dart:async';
import '../../domain/focus/focus_stats.dart';
import 'focus_stats_local_ds.dart';

/// Public repository interface for focus statistics
abstract class FocusStatsRepository {
  Future<FocusStats> getStats();
  Future<FocusStats> recordCompletedSession(Duration duration);
  Future<void> resetStats();
}

/// Implementation using local data source
class FocusStatsRepositoryImpl implements FocusStatsRepository {
  final FocusStatsLocalDataSource _dataSource;
  
  const FocusStatsRepositoryImpl(this._dataSource);
  
  @override
  Future<FocusStats> getStats() async {
    return await _dataSource.read();
  }
  
  @override
  Future<FocusStats> recordCompletedSession(Duration duration) async {
    final currentStats = await _dataSource.read();
    final updatedStats = currentStats.addSession(duration);
    await _dataSource.write(updatedStats);
    return updatedStats;
  }
  
  @override
  Future<void> resetStats() async {
    await _dataSource.clear();
  }
}
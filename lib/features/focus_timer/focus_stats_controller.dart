import 'dart:async';
import '../../core/feature_flags.dart';
import '../../data/focus/focus_stats_repository.dart';
import '../../data/focus/focus_stats_local_ds.dart';
import 'focus_session_completed_event.dart';
import '../../support/logger.dart';

/// Controller that listens for focus session completion events
/// and updates focus statistics when feature flag is enabled
class FocusStatsController {
  static FocusStatsController? _instance;
  final FocusStatsRepository _repository;
  final StreamController<FocusSessionCompleted> _eventController;
  StreamSubscription<FocusSessionCompleted>? _subscription;
  
  FocusStatsController._(this._repository, this._eventController);
  
  /// Get singleton instance
  static FocusStatsController get instance {
    _instance ??= FocusStatsController._(
      FocusStatsRepositoryImpl(createFocusStatsLocalDataSource()),
      StreamController<FocusSessionCompleted>.broadcast(),
    );
    return _instance!;
  }
  
  /// Initialize the controller and start listening for events
  Future<void> initialize() async {
    if (!FeatureFlags.focusStatsEnabled) {
      Log.debug('FocusStatsController: feature disabled, not initializing');
      return;
    }
    
    _subscription?.cancel();
    _subscription = _eventController.stream.listen(_handleSessionCompleted);
    Log.debug('FocusStatsController: initialized and listening');
  }
  
  /// Dispose the controller
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    Log.debug('FocusStatsController: disposed');
  }
  
  /// Fire a session completed event
  void fireSessionCompleted(Duration duration) {
    if (!FeatureFlags.focusStatsEnabled) return;
    
    _eventController.add(FocusSessionCompleted(duration));
  }
  
  /// Handle session completed event
  Future<void> _handleSessionCompleted(FocusSessionCompleted event) async {
    try {
      final updatedStats = await _repository.recordCompletedSession(event.duration);
      Log.debug('FocusStats updated: $updatedStats');
    } catch (e) {
      Log.debug('Failed to record focus session: $e');
      // Don't throw - allow session completion to succeed
    }
  }
  
  /// Get repository instance for UI access
  FocusStatsRepository get repository => _repository;
  
  /// Reset instance for testing
  static void resetForTesting() {
    _instance?._subscription?.cancel();
    _instance = null;
  }
}
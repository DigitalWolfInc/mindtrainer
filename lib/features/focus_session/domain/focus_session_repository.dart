import 'focus_session_state.dart';
import 'focus_session_statistics.dart';

abstract class FocusSessionRepository {
  Future<FocusSessionState?> loadActiveSession();
  Future<void> saveActiveSession(FocusSessionState state);
  Future<void> clearActiveSession();
  
  Future<void> saveCompletedSession({
    required DateTime completedAt,
    required int durationMinutes,
    List<String>? tags,
    String? note,
  });
  
  Future<FocusSessionStatistics> loadStatistics();
  Future<void> saveStatistics(FocusSessionStatistics statistics);
  Future<void> clearStatistics();
}
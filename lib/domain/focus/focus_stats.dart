/// Pure domain model for focus session statistics
/// Follows immutable pattern with computed averages
class FocusStats {
  /// Total focus time in minutes (>= 0)
  final int totalMinutes;
  
  /// Number of completed sessions (>= 0)
  final int sessionCount;
  
  const FocusStats({
    required this.totalMinutes,
    required this.sessionCount,
  });
  
  /// Computed average session length in minutes
  /// Returns 0 if no sessions completed
  int get averageMinutes => sessionCount == 0 ? 0 : (totalMinutes / sessionCount).round();
  
  /// Zero state constant
  static const zero = FocusStats(totalMinutes: 0, sessionCount: 0);
  
  /// Create new stats with additional session
  /// Ensures minimum 1 minute per session
  FocusStats addSession(Duration duration) {
    final minutes = _roundMinutes(duration);
    return FocusStats(
      totalMinutes: totalMinutes + minutes,
      sessionCount: sessionCount + 1,
    );
  }
  
  /// Reset to zero state
  FocusStats reset() => zero;
  
  /// Round duration to nearest minute, minimum 1
  static int _roundMinutes(Duration duration) {
    final seconds = duration.inSeconds;
    if (seconds < 60) return 1; // minimum 1 minute
    return (seconds / 60.0).round();
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FocusStats &&
          runtimeType == other.runtimeType &&
          totalMinutes == other.totalMinutes &&
          sessionCount == other.sessionCount;
  
  @override
  int get hashCode => totalMinutes.hashCode ^ sessionCount.hashCode;
  
  @override
  String toString() => 'FocusStats(totalMinutes: $totalMinutes, sessionCount: $sessionCount, averageMinutes: $averageMinutes)';
}
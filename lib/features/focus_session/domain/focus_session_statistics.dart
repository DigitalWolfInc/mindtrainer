class FocusSessionStatistics {
  final int totalFocusTimeMinutes;
  final double averageSessionLength;
  final int completedSessionsCount;

  const FocusSessionStatistics({
    required this.totalFocusTimeMinutes,
    required this.averageSessionLength,
    required this.completedSessionsCount,
  });

  factory FocusSessionStatistics.empty() {
    return const FocusSessionStatistics(
      totalFocusTimeMinutes: 0,
      averageSessionLength: 0.0,
      completedSessionsCount: 0,
    );
  }

  factory FocusSessionStatistics.fromJson(Map<String, dynamic> json) {
    return FocusSessionStatistics(
      totalFocusTimeMinutes: json['totalFocusTimeMinutes'] ?? 0,
      averageSessionLength: (json['averageSessionLength'] ?? 0.0).toDouble(),
      completedSessionsCount: json['completedSessionsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalFocusTimeMinutes': totalFocusTimeMinutes,
      'averageSessionLength': averageSessionLength,
      'completedSessionsCount': completedSessionsCount,
    };
  }

  FocusSessionStatistics addSession(int sessionDurationMinutes) {
    final newTotalTime = totalFocusTimeMinutes + sessionDurationMinutes;
    final newCount = completedSessionsCount + 1;
    final newAverage = newTotalTime / newCount;
    
    return FocusSessionStatistics(
      totalFocusTimeMinutes: newTotalTime,
      averageSessionLength: newAverage,
      completedSessionsCount: newCount,
    );
  }

  FocusSessionStatistics reset() {
    return FocusSessionStatistics.empty();
  }
}
class FocusSessionInsights {
  final int rolling7DayTotalMinutes;
  final double rolling7DayAvgMinutes;
  final int rolling30DayTotalMinutes;
  final double rolling30DayAvgMinutes;
  final int currentStreak;
  final DateTime? bestDay;
  final int bestDayMinutes;
  final int longestSessionMinutes;

  const FocusSessionInsights({
    required this.rolling7DayTotalMinutes,
    required this.rolling7DayAvgMinutes,
    required this.rolling30DayTotalMinutes,
    required this.rolling30DayAvgMinutes,
    required this.currentStreak,
    this.bestDay,
    required this.bestDayMinutes,
    required this.longestSessionMinutes,
  });

  factory FocusSessionInsights.empty() {
    return const FocusSessionInsights(
      rolling7DayTotalMinutes: 0,
      rolling7DayAvgMinutes: 0.0,
      rolling30DayTotalMinutes: 0,
      rolling30DayAvgMinutes: 0.0,
      currentStreak: 0,
      bestDay: null,
      bestDayMinutes: 0,
      longestSessionMinutes: 0,
    );
  }
}
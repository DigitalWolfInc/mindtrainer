class WeeklyProgress {
  final int currentWeekTotal;
  final int goalMinutes;
  final double percent;

  const WeeklyProgress({
    required this.currentWeekTotal,
    required this.goalMinutes,
    required this.percent,
  });

  factory WeeklyProgress.empty() {
    return const WeeklyProgress(
      currentWeekTotal: 0,
      goalMinutes: 300,
      percent: 0.0,
    );
  }

  factory WeeklyProgress.fromTotalAndGoal({
    required int currentWeekTotal,
    required int goalMinutes,
  }) {
    final percent = goalMinutes > 0 ? (currentWeekTotal / goalMinutes).clamp(0.0, 1.0) : 0.0;
    
    return WeeklyProgress(
      currentWeekTotal: currentWeekTotal,
      goalMinutes: goalMinutes,
      percent: percent,
    );
  }
}
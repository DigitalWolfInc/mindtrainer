import 'focus_session_insights.dart';

class FocusSessionInsightsService {
  static FocusSessionInsights calculateInsights(
    List<Map<String, dynamic>> sessions, {
    DateTime? currentDate,
  }) {
    if (sessions.isEmpty) {
      return FocusSessionInsights.empty();
    }

    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6)); // Include today
    final thirtyDaysAgo = today.subtract(const Duration(days: 29)); // Include today

    // Group sessions by date for rolling calculations
    final dailyTotals = <DateTime, int>{};
    final daysWithSessions = <DateTime>{}; // Track days that have any sessions (including zero-minute)
    int longestSessionMinutes = 0;
    DateTime? bestDay;
    int bestDayMinutes = 0;

    for (final session in sessions) {
      final dateTime = session['dateTime'] as DateTime;
      final minutes = session['durationMinutes'] as int;
      final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      // Track longest single session
      if (minutes > longestSessionMinutes) {
        longestSessionMinutes = minutes;
      }

      // Group by date for daily totals
      dailyTotals[sessionDate] = (dailyTotals[sessionDate] ?? 0) + minutes;
      daysWithSessions.add(sessionDate); // Track that this day has sessions

      // Track best day (use earliest date in case of tie)
      final dayTotal = dailyTotals[sessionDate]!;
      if (dayTotal > bestDayMinutes || 
          (dayTotal == bestDayMinutes && (bestDay == null || sessionDate.isBefore(bestDay!)))) {
        bestDay = sessionDate;
        bestDayMinutes = dayTotal;
      }
    }

    // Calculate rolling windows
    final rolling7Day = _calculateRollingWindow(dailyTotals, sevenDaysAgo, today);
    final rolling30Day = _calculateRollingWindow(dailyTotals, thirtyDaysAgo, today);

    // Calculate current streak
    final currentStreak = _calculateCurrentStreak(daysWithSessions, today);

    return FocusSessionInsights(
      rolling7DayTotalMinutes: rolling7Day.total,
      rolling7DayAvgMinutes: rolling7Day.average,
      rolling30DayTotalMinutes: rolling30Day.total,
      rolling30DayAvgMinutes: rolling30Day.average,
      currentStreak: currentStreak,
      bestDay: bestDay,
      bestDayMinutes: bestDayMinutes,
      longestSessionMinutes: longestSessionMinutes,
    );
  }

  static _RollingWindowResult _calculateRollingWindow(
    Map<DateTime, int> dailyTotals,
    DateTime startDate,
    DateTime endDate,
  ) {
    int total = 0;
    int daysInWindow = endDate.difference(startDate).inDays + 1; // Include both start and end

    for (int i = 0; i < daysInWindow; i++) {
      final date = startDate.add(Duration(days: i));
      total += dailyTotals[date] ?? 0;
    }

    final average = daysInWindow > 0 ? total / daysInWindow : 0.0;
    return _RollingWindowResult(total: total, average: average);
  }

  static int _calculateCurrentStreak(Set<DateTime> daysWithSessions, DateTime today) {
    int streak = 0;
    DateTime currentDate = today;

    while (true) {
      final hasSession = daysWithSessions.contains(currentDate);
      if (!hasSession) {
        break;
      }
      streak++;
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}

class _RollingWindowResult {
  final int total;
  final double average;

  const _RollingWindowResult({
    required this.total,
    required this.average,
  });
}
import 'weekly_progress.dart';

class WeeklyProgressService {
  static WeeklyProgress calculateWeeklyProgress(
    List<Map<String, dynamic>> sessions,
    int goalMinutes, {
    DateTime? currentDate,
  }) {
    final now = currentDate ?? DateTime.now();
    final weekBounds = _getWeekBounds(now);
    
    int totalMinutes = 0;
    
    for (final session in sessions) {
      final sessionDateTime = session['dateTime'] as DateTime;
      final durationMinutes = session['durationMinutes'] as int;
      
      // Check if session falls within this week (Mon-Sun)
      if (_isDateInWeek(sessionDateTime, weekBounds)) {
        totalMinutes += durationMinutes;
      }
    }
    
    return WeeklyProgress.fromTotalAndGoal(
      currentWeekTotal: totalMinutes,
      goalMinutes: goalMinutes,
    );
  }

  static _WeekBounds _getWeekBounds(DateTime date) {
    // Week starts on Monday (weekday 1)
    final daysSinceMonday = (date.weekday - DateTime.monday) % 7;
    final mondayOfWeek = date.subtract(Duration(days: daysSinceMonday));
    final mondayStart = DateTime(mondayOfWeek.year, mondayOfWeek.month, mondayOfWeek.day);
    final sundayEnd = mondayStart.add(const Duration(days: 7)).subtract(const Duration(microseconds: 1));
    
    return _WeekBounds(start: mondayStart, end: sundayEnd);
  }

  static bool _isDateInWeek(DateTime sessionDate, _WeekBounds weekBounds) {
    return sessionDate.isAfter(weekBounds.start.subtract(const Duration(microseconds: 1))) &&
           sessionDate.isBefore(weekBounds.end.add(const Duration(microseconds: 1)));
  }
}

class _WeekBounds {
  final DateTime start;
  final DateTime end;

  const _WeekBounds({
    required this.start,
    required this.end,
  });
}
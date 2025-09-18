/// Seed Dataset for Reproducible Testing
/// 
/// Provides deterministic test data for 14-day periods with realistic
/// focus session patterns, mood progressions, and coaching conversation examples.

import 'package:mindtrainer/core/coach/conversational_coach.dart';
import 'package:mindtrainer/core/insights/mood_focus_insights.dart';

/// Generate 14 days of focus sessions with specified minute totals
/// Pattern: [0, 12, 25, 40, 0, 55, 80, 30, 15, 0, 45, 60, 75, 20]
List<FakeSession> seedSessions({DateTime? startDate}) {
  final start = startDate ?? DateTime(2024, 1, 15);
  final sessionMinutes = [0, 12, 25, 40, 0, 55, 80, 30, 15, 0, 45, 60, 75, 20];
  
  final sessions = <FakeSession>[];
  
  for (int day = 0; day < 14; day++) {
    final dayMinutes = sessionMinutes[day];
    if (dayMinutes > 0) {
      // Create 1-3 sessions per day to reach the target minutes
      final sessionDate = start.add(Duration(days: day));
      
      if (dayMinutes <= 30) {
        // Single session
        sessions.add(FakeSession(
          dateTime: sessionDate.add(const Duration(hours: 10)),
          durationMinutes: dayMinutes,
        ));
      } else if (dayMinutes <= 60) {
        // Two sessions
        sessions.add(FakeSession(
          dateTime: sessionDate.add(const Duration(hours: 9)),
          durationMinutes: dayMinutes ~/ 2,
        ));
        sessions.add(FakeSession(
          dateTime: sessionDate.add(const Duration(hours: 16)),
          durationMinutes: dayMinutes - (dayMinutes ~/ 2),
        ));
      } else {
        // Three sessions for high-activity days
        sessions.add(FakeSession(
          dateTime: sessionDate.add(const Duration(hours: 8)),
          durationMinutes: dayMinutes ~/ 3,
        ));
        sessions.add(FakeSession(
          dateTime: sessionDate.add(const Duration(hours: 13)),
          durationMinutes: dayMinutes ~/ 3,
        ));
        sessions.add(FakeSession(
          dateTime: sessionDate.add(const Duration(hours: 18)),
          durationMinutes: dayMinutes - 2 * (dayMinutes ~/ 3),
        ));
      }
    }
  }
  
  return sessions;
}

/// Generate 14 days of mood data (1-5 scale)  
/// Pattern: [2, 2, 3, 3, 2, 4, 5, 3, 2, 2, 3, 4, 5, 3]
List<DailyMoodFocus> seedMoods({DateTime? startDate}) {
  final start = startDate ?? DateTime(2024, 1, 15);
  final sessionMinutes = [0, 12, 25, 40, 0, 55, 80, 30, 15, 0, 45, 60, 75, 20];
  final moodScores = [2, 2, 3, 3, 2, 4, 5, 3, 2, 2, 3, 4, 5, 3];
  
  final moods = <DailyMoodFocus>[];
  
  for (int day = 0; day < 14; day++) {
    final dayDate = start.add(Duration(days: day));
    final dayMinutes = sessionMinutes[day];
    final sessionCount = dayMinutes > 0 ? (dayMinutes > 60 ? 3 : dayMinutes > 30 ? 2 : 1) : 0;
    
    moods.add(DailyMoodFocus(
      day: dayDate,
      sessionCount: sessionCount,
      totalDuration: Duration(minutes: dayMinutes),
      avgDuration: sessionCount > 0 ? Duration(minutes: dayMinutes ~/ sessionCount) : Duration.zero,
    ));
  }
  
  return moods;
}

/// Generate realistic user snapshot for testing
UserSnapshot seedSnapshot({DateTime? now}) {
  return UserSnapshot(
    now: now ?? DateTime(2024, 1, 22, 14, 30), // Week 2 of seed data
    weeklyGoalMinutes: 150,
    currentStreakDays: 6,
    bestDayMinutes: 96,
    badges: ['Owl', 'Wolf'],
  );
}

/// Example coaching conversation replies for each phase
Map<String, String> seedCoachReplies() {
  return {
    'open': 'I feel overwhelmed and like nothing works.',
    'reflect': 'Heart racing, can\'t focus, everyone expects me to be perfect.',
    'reframe': 'Maybe not every time. Last week I handled it.',
    'plan': 'I can do a 3-minute reset.',
  };
}

/// Fake session for testing
class FakeSession {
  final DateTime dateTime;
  final int durationMinutes;
  
  FakeSession({required this.dateTime, required this.durationMinutes});
}

/// Fixed clock for deterministic testing
class FixedClock implements Clock {
  final DateTime _fixedTime;
  
  const FixedClock(this._fixedTime);
  
  @override
  DateTime now() => _fixedTime;
}

/// Fake history source using seed sessions
class FakeHistorySource implements HistorySource {
  final List<FakeSession> _sessions;
  
  FakeHistorySource(this._sessions);
  
  @override
  Iterable<dynamic> sessions({DateTime? from, DateTime? to}) {
    return _sessions.where((session) {
      if (from != null && session.dateTime.isBefore(from)) return false;
      if (to != null && session.dateTime.isAfter(to)) return false;
      return true;
    });
  }
}

/// Fake profile source with seed snapshot  
class FakeProfileSource implements ProfileSource {
  UserSnapshot _snapshot;
  
  FakeProfileSource(this._snapshot);
  
  @override
  UserSnapshot snapshot() => _snapshot;
  
  void updateSnapshot(UserSnapshot newSnapshot) {
    _snapshot = newSnapshot;
  }
}

/// Fake journal sink for capturing entries
class FakeJournalSink implements JournalSink {
  final List<JournalEntry> entries = [];
  
  @override
  void append(JournalEntry entry) {
    entries.add(entry);
  }
}
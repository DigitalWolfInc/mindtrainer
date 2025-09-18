import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/coach/conversational_coach.dart';
import 'package:mindtrainer/core/coach/coach_events.dart';
import 'package:mindtrainer/core/coach/coach_filters.dart';
import 'package:mindtrainer/core/insights/coach_bridging.dart';
import 'package:mindtrainer/core/insights/mood_focus_insights.dart';

/// Fake implementations for testing coach integration

class FakeProfileSourceWithEvent implements ProfileSource {
  UserSnapshot _snapshot;
  
  FakeProfileSourceWithEvent(this._snapshot);
  
  @override
  UserSnapshot snapshot() => _snapshot;
  
  void updateSnapshot(UserSnapshot newSnapshot) {
    _snapshot = newSnapshot;
  }
}

class FakeHistorySourceWithEvent implements HistorySource {
  final List<dynamic> _sessions;
  
  FakeHistorySourceWithEvent(this._sessions);
  
  @override
  Iterable<dynamic> sessions({DateTime? from, DateTime? to}) {
    return _sessions.where((session) {
      final sessionDate = (session as dynamic).dateTime as DateTime;
      if (from != null && sessionDate.isBefore(from)) return false;
      if (to != null && sessionDate.isAfter(to)) return false;
      return true;
    });
  }
}

class FakeJournalSinkWithEvent implements JournalSink {
  final List<JournalEntry> entries = [];
  
  @override
  void append(JournalEntry entry) {
    entries.add(entry);
  }
}

class FakeSession {
  final DateTime dateTime;
  final int durationMinutes;
  
  FakeSession({required this.dateTime, required this.durationMinutes});
}

void main() {
  group('Coach Integration Tests', () {
    late FakeProfileSourceWithEvent profileSource;
    late FakeHistorySourceWithEvent historySource;
    late FakeJournalSinkWithEvent journalSink;
    late List<CoachEvent> capturedEvents;
    late ConversationalCoach coach;
    
    /// Helper to create user snapshot with defaults
    UserSnapshot createSnapshot({
      DateTime? now,
      int weeklyGoalMinutes = 150,
      int currentStreakDays = 0,
      int bestDayMinutes = 0,
      List<String> badges = const [],
    }) {
      return UserSnapshot(
        now: now ?? DateTime(2024, 1, 15, 10, 0),
        weeklyGoalMinutes: weeklyGoalMinutes,
        currentStreakDays: currentStreakDays,
        bestDayMinutes: bestDayMinutes,
        badges: badges,
      );
    }
    
    setUp(() {
      profileSource = FakeProfileSourceWithEvent(createSnapshot());
      historySource = FakeHistorySourceWithEvent([]);
      journalSink = FakeJournalSinkWithEvent();
      capturedEvents = [];
      
      coach = ConversationalCoach(
        profile: profileSource,
        history: historySource,
        journal: journalSink,
        eventSink: (event) => capturedEvents.add(event),
      );
    });
    
    group('Event Emission', () {
      test('should emit event on user reply with stable promptId', () {
        coach.next(); // Initial prompt
        coach.next(userReply: "I'm feeling stressed today");
        
        expect(capturedEvents.length, 1);
        
        final event = capturedEvents.first;
        expect(event.phase, 'stabilize');
        expect(event.promptId, matches(RegExp(r'stabilize_\d+'))); // Format: phase_index
        expect(event.at, profileSource.snapshot().now);
        expect(event.tags, isNotEmpty); // Should suggest tags from "stressed"
        
        // PromptId should be deterministic for same date
        capturedEvents.clear();
        final coach2 = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: FakeJournalSinkWithEvent(),
          eventSink: (event) => capturedEvents.add(event),
        );
        
        coach2.next(); // Initial prompt
        coach2.next(userReply: "Different reply");
        
        expect(capturedEvents.first.promptId, event.promptId); // Same date = same promptId
      });
      
      test('should include guidance in events when available', () {
        // Progress through phases to get to reframe where guidance is generated
        coach.next(); // stabilize
        coach.next(userReply: "I'm feeling overwhelmed"); // should advance due to richness
        coach.next(userReply: "Everything always goes wrong"); // reflect -> reframe with distortion
        
        // Find reframe event with guidance
        final reframeEvents = capturedEvents.where((e) => e.phase == 'reframe').toList();
        expect(reframeEvents.length, greaterThan(0));
        
        final reframeEvent = reframeEvents.first;
        expect(reframeEvent.guidance, isNotNull);
        expect(reframeEvent.guidance, contains('all-or-nothing')); // Should detect distortion
        expect(reframeEvent.outcome, CoachOutcome.reframed);
      });
      
      test('should truncate long guidance to 200 characters', () {
        final longGuidance = 'A' * 250; // 250 characters
        
        final event = CoachEvent.create(
          at: DateTime.now(),
          phase: 'reframe',
          promptId: 'test_0',
          guidance: longGuidance,
        );
        
        expect(event.guidance!.length, 200);
        expect(event.guidance, endsWith('...'));
      });
      
      test('should limit tags to 6 items', () {
        final manyTags = List.generate(10, (i) => 'tag$i');
        
        final event = CoachEvent.create(
          at: DateTime.now(),
          phase: 'open',
          promptId: 'test_0',
          tags: manyTags,
        );
        
        expect(event.tags.length, 6);
        expect(event.tags, manyTags.take(6).toList());
      });
    });
    
    group('Tag Suggestion Coverage', () {
      test('should suggest anxiety tags for anxiety keywords', () {
        coach.next(); // Initial prompt
        coach.next(userReply: "I'm feeling very anxious and worried about everything");
        
        final event = capturedEvents.first;
        expect(event.tags, contains('anxiety'));
        expect(event.tags, contains('overwhelm')); // "everything" should trigger overwhelm
      });
      
      test('should suggest sleep tags for sleep keywords', () {
        coach.next();
        coach.next(userReply: "I couldn't sleep last night and I'm exhausted");
        
        final event = capturedEvents.first;
        expect(event.tags, contains('sleep'));
        expect(event.tags, contains('low_energy')); // "exhausted" should trigger low_energy
      });
      
      test('should suggest gratitude tags for gratitude keywords', () {
        coach.next();
        coach.next(userReply: "I'm feeling grateful and thankful for today");
        
        final event = capturedEvents.first;
        expect(event.tags, contains('gratitude'));
      });
      
      test('should suggest focus restart tags for focus keywords', () {
        coach.next();
        coach.next(userReply: "I need to restart my focus and concentration");
        
        final event = capturedEvents.first;
        expect(event.tags, contains('focus_restart'));
      });
      
      test('should return empty tags for non-matching content', () {
        coach.next();
        coach.next(userReply: "Just a regular day with nothing special");
        
        final event = capturedEvents.first;
        expect(event.tags, isEmpty);
      });
      
      test('should deduplicate and sort tags deterministically', () {
        coach.next();
        coach.next(userReply: "I'm anxious and panicking about my panic attacks");
        
        final event = capturedEvents.first;
        expect(event.tags, contains('anxiety'));
        expect(event.tags, contains('panic'));
        expect(event.tags.length, lessThanOrEqualTo(2)); // Should dedupe overlapping detection
        
        // Tags should be sorted for deterministic output
        final sortedTags = List<String>.from(event.tags)..sort();
        expect(event.tags, sortedTags);
      });
    });
    
    group('Export/Import Roundtrip', () {
      test('should roundtrip through JSON serialization', () {
        final originalEvent = CoachEvent.create(
          at: DateTime(2024, 1, 15, 14, 30),
          phase: 'reframe',
          promptId: 'reframe_2',
          guidance: 'This is guidance with "quotes" and, commas',
          outcome: CoachOutcome.reframed,
          tags: ['anxiety', 'gratitude'],
        );
        
        // Convert to map and back
        final map = originalEvent.toMap();
        final restoredEvent = CoachEvent.fromMap(map);
        
        expect(restoredEvent.at, originalEvent.at);
        expect(restoredEvent.phase, originalEvent.phase);
        expect(restoredEvent.promptId, originalEvent.promptId);
        expect(restoredEvent.guidance, originalEvent.guidance);
        expect(restoredEvent.outcome, originalEvent.outcome);
        expect(restoredEvent.tags, originalEvent.tags);
      });
      
      test('should roundtrip through CSV serialization', () {
        final originalEvent = CoachEvent.create(
          at: DateTime(2024, 1, 15, 14, 30),
          phase: 'plan',
          promptId: 'plan_1',
          guidance: 'CSV test with "embedded quotes" and, commas\nand newlines',
          outcome: CoachOutcome.planned,
          tags: ['self_compassion', 'focus_restart'],
        );
        
        // Convert to CSV and back
        final csvRow = originalEvent.toCsvRow();
        final restoredEvent = CoachEvent.fromCsvRow(csvRow);
        
        expect(restoredEvent.at, originalEvent.at);
        expect(restoredEvent.phase, originalEvent.phase);
        expect(restoredEvent.promptId, originalEvent.promptId);
        expect(restoredEvent.guidance, originalEvent.guidance);
        expect(restoredEvent.outcome, originalEvent.outcome);
        expect(restoredEvent.tags, originalEvent.tags);
      });
      
      test('should handle empty fields in CSV', () {
        final originalEvent = CoachEvent.create(
          at: DateTime(2024, 1, 15, 14, 30),
          phase: 'open',
          promptId: 'open_0',
          guidance: null,
          outcome: null,
          tags: [],
        );
        
        final csvRow = originalEvent.toCsvRow();
        final restoredEvent = CoachEvent.fromCsvRow(csvRow);
        
        expect(restoredEvent.guidance, isNull);
        expect(restoredEvent.outcome, isNull);
        expect(restoredEvent.tags, isEmpty);
      });
      
      test('should handle multi-tag CSV serialization', () {
        final originalEvent = CoachEvent.create(
          at: DateTime(2024, 1, 15, 14, 30),
          phase: 'close',
          promptId: 'close_0',
          tags: ['anxiety', 'gratitude', 'sleep', 'low_energy'],
        );
        
        final csvRow = originalEvent.toCsvRow();
        expect(csvRow, contains('anxiety;gratitude;sleep;low_energy'));
        
        final restoredEvent = CoachEvent.fromCsvRow(csvRow);
        expect(restoredEvent.tags, originalEvent.tags);
      });
    });
    
    group('Coach Activity Summarization', () {
      test('should correctly count per-day activities and order top tags', () {
        final day1 = DateTime(2024, 1, 15);
        final day2 = DateTime(2024, 1, 16);
        
        final events = [
          // Day 1: 2 entries, 1 reframe, 1 plan, anxiety + gratitude tags
          CoachEvent.create(
            at: day1.add(const Duration(hours: 9)),
            phase: 'open',
            promptId: 'open_0',
            tags: ['anxiety', 'overwhelm'],
          ),
          CoachEvent.create(
            at: day1.add(const Duration(hours: 10)),
            phase: 'reframe',
            promptId: 'reframe_0',
            outcome: CoachOutcome.reframed,
            tags: ['anxiety', 'gratitude'], // anxiety appears twice
          ),
          CoachEvent.create(
            at: day1.add(const Duration(hours: 11)),
            phase: 'plan',
            promptId: 'plan_0',
            outcome: CoachOutcome.planned,
            tags: ['gratitude'],
          ),
          
          // Day 2: 1 entry, 0 reframes, 0 plans
          CoachEvent.create(
            at: day2.add(const Duration(hours: 14)),
            phase: 'stabilize',
            promptId: 'stabilize_1',
            tags: ['sleep'],
          ),
        ];
        
        final summaries = summarizeCoachActivity(events);
        
        expect(summaries.length, 2);
        
        final day1Summary = summaries.firstWhere((s) => s.day.day == 15);
        expect(day1Summary.journalingEntries, 3);
        expect(day1Summary.reframes, 1);
        expect(day1Summary.plansCommitted, 1);
        expect(day1Summary.topTags.first, 'anxiety'); // Most frequent tag
        expect(day1Summary.topTags, contains('gratitude'));
        expect(day1Summary.topTags, contains('overwhelm'));
        
        final day2Summary = summaries.firstWhere((s) => s.day.day == 16);
        expect(day2Summary.journalingEntries, 1);
        expect(day2Summary.reframes, 0);
        expect(day2Summary.plansCommitted, 0);
        expect(day2Summary.topTags, ['sleep']);
      });
      
      test('should handle empty events gracefully', () {
        final summaries = summarizeCoachActivity([]);
        expect(summaries, isEmpty);
      });
      
      test('should sort summaries by day', () {
        final events = [
          CoachEvent.create(
            at: DateTime(2024, 1, 20, 9, 0),
            phase: 'open',
            promptId: 'open_0',
          ),
          CoachEvent.create(
            at: DateTime(2024, 1, 15, 10, 0),
            phase: 'open', 
            promptId: 'open_0',
          ),
        ];
        
        final summaries = summarizeCoachActivity(events);
        expect(summaries.length, 2);
        expect(summaries.first.day.day, 15); // Earlier date first
        expect(summaries.last.day.day, 20);
      });
    });
    
    group('Plans vs Focus Correlation', () {
      test('should compute positive correlation when plans correlate with focus', () {
        final coachDays = [
          CoachDaySummary(
            day: DateTime(2024, 1, 15),
            journalingEntries: 3,
            reframes: 1,
            plansCommitted: 2, // High planning
            topTags: ['anxiety'],
          ),
          CoachDaySummary(
            day: DateTime(2024, 1, 16),
            journalingEntries: 1,
            reframes: 0,
            plansCommitted: 0, // Low planning
            topTags: [],
          ),
          CoachDaySummary(
            day: DateTime(2024, 1, 17),
            journalingEntries: 2,
            reframes: 1,
            plansCommitted: 3, // High planning
            topTags: ['gratitude'],
          ),
        ];
        
        final moodFocusDays = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            sessionCount: 2,
            totalDuration: const Duration(minutes: 60), // High focus
            avgDuration: const Duration(minutes: 30),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            sessionCount: 1,
            totalDuration: const Duration(minutes: 10), // Low focus
            avgDuration: const Duration(minutes: 10),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 17),
            sessionCount: 3,
            totalDuration: const Duration(minutes: 90), // High focus
            avgDuration: const Duration(minutes: 30),
          ),
        ];
        
        final correlation = correlationPlansVsFocusMinutes(coachDays, moodFocusDays);
        
        expect(correlation, isNotNull);
        expect(correlation!, greaterThan(0.5)); // Strong positive correlation
      });
      
      test('should handle zero correlation case', () {
        final coachDays = [
          CoachDaySummary(
            day: DateTime(2024, 1, 15),
            journalingEntries: 1,
            reframes: 0,
            plansCommitted: 2, // High planning
            topTags: [],
          ),
          CoachDaySummary(
            day: DateTime(2024, 1, 16),
            journalingEntries: 1,
            reframes: 0,
            plansCommitted: 1, // Low planning
            topTags: [],
          ),
          CoachDaySummary(
            day: DateTime(2024, 1, 17),
            journalingEntries: 1,
            reframes: 0,
            plansCommitted: 2, // High planning again
            topTags: [],
          ),
        ];
        
        final moodFocusDays = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            sessionCount: 1,
            totalDuration: const Duration(minutes: 30), // Low focus with high planning
            avgDuration: const Duration(minutes: 30),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 16),
            sessionCount: 1,
            totalDuration: const Duration(minutes: 60), // High focus with low planning
            avgDuration: const Duration(minutes: 60),
          ),
          DailyMoodFocus(
            day: DateTime(2024, 1, 17),
            sessionCount: 1,
            totalDuration: const Duration(minutes: 30), // Low focus with high planning again
            avgDuration: const Duration(minutes: 30),
          ),
        ];
        
        final correlation = correlationPlansVsFocusMinutes(coachDays, moodFocusDays);
        expect(correlation, isNotNull);
        expect(correlation!.abs(), lessThan(0.1)); // Near zero
      });
      
      test('should return null for insufficient data', () {
        final coachDays = [
          CoachDaySummary(
            day: DateTime(2024, 1, 15),
            journalingEntries: 1,
            reframes: 0,
            plansCommitted: 1,
            topTags: [],
          ),
        ];
        
        final moodFocusDays = [
          DailyMoodFocus(
            day: DateTime(2024, 1, 15),
            sessionCount: 1,
            totalDuration: const Duration(minutes: 30),
            avgDuration: const Duration(minutes: 30),
          ),
        ];
        
        // Only 1 data point
        final correlation = correlationPlansVsFocusMinutes(coachDays, moodFocusDays);
        expect(correlation, isNull);
      });
      
      test('should clamp correlation to [-1, 1] range', () {
        // Edge case that might produce values outside [-1, 1] due to floating point precision
        final coachDays = [
          CoachDaySummary(day: DateTime(2024, 1, 15), journalingEntries: 1, reframes: 0, plansCommitted: 100, topTags: []),
          CoachDaySummary(day: DateTime(2024, 1, 16), journalingEntries: 1, reframes: 0, plansCommitted: 0, topTags: []),
        ];
        
        final moodFocusDays = [
          DailyMoodFocus(day: DateTime(2024, 1, 15), sessionCount: 1, totalDuration: const Duration(minutes: 1000), avgDuration: const Duration(minutes: 1000)),
          DailyMoodFocus(day: DateTime(2024, 1, 16), sessionCount: 1, totalDuration: const Duration(minutes: 1), avgDuration: const Duration(minutes: 1)),
        ];
        
        final correlation = correlationPlansVsFocusMinutes(coachDays, moodFocusDays);
        expect(correlation, isNotNull);
        expect(correlation!, greaterThanOrEqualTo(-1.0));
        expect(correlation!, lessThanOrEqualTo(1.0));
      });
    });
    
    group('Coach Event Filters', () {
      late List<CoachEvent> testEvents;
      
      setUp(() {
        testEvents = [
          CoachEvent.create(
            at: DateTime(2024, 1, 15, 9, 0),
            phase: 'stabilize',
            promptId: 'stabilize_0',
            guidance: 'Initial guidance',
            tags: ['anxiety', 'sleep'],
          ),
          CoachEvent.create(
            at: DateTime(2024, 1, 16, 14, 0),
            phase: 'reframe',
            promptId: 'reframe_1',
            guidance: 'Reframe guidance with specific content',
            outcome: CoachOutcome.reframed,
            tags: ['gratitude'],
          ),
          CoachEvent.create(
            at: DateTime(2024, 1, 17, 11, 0),
            phase: 'plan',
            promptId: 'plan_0',
            guidance: 'Need to reframe my approach to planning',
            tags: ['anxiety', 'focus_restart'],
          ),
        ];
      });
      
      test('should filter by tags (any matching)', () {
        final filter = CoachFilter(tagsAny: ['anxiety']);
        final filtered = filterCoachEvents(testEvents, filter);
        
        expect(filtered.length, 2); // Events with 'anxiety' tag
        expect(filtered.first.tags, contains('anxiety'));
        expect(filtered.last.tags, contains('anxiety'));
      });
      
      test('should filter by date range only', () {
        final filter = CoachFilter(
          from: DateTime(2024, 1, 16),
          to: DateTime(2024, 1, 16),
        );
        final filtered = filterCoachEvents(testEvents, filter);
        
        expect(filtered.length, 1);
        expect(filtered.first.at.day, 16);
      });
      
      test('should filter by text query only', () {
        final filter = CoachFilter(textQuery: 'reframe');
        final filtered = filterCoachEvents(testEvents, filter);
        
        expect(filtered.length, 2); // One matches guidance text, one matches promptId
        expect(filtered.any((e) => e.guidance?.contains('Reframe') ?? false), true);
        expect(filtered.any((e) => e.promptId.contains('reframe')), true);
      });
      
      test('should apply combined filters with AND logic', () {
        final filter = CoachFilter(
          tagsAny: ['anxiety'],
          from: DateTime(2024, 1, 17),
          textQuery: 'plan',
        );
        final filtered = filterCoachEvents(testEvents, filter);
        
        expect(filtered.length, 1); // Only last event matches all criteria
        expect(filtered.first.tags, contains('anxiety'));
        expect(filtered.first.at.day, 17);
        expect(filtered.first.promptId, contains('plan'));
      });
      
      test('should handle case-insensitive text search', () {
        final filter = CoachFilter(textQuery: 'REFRAME');
        final filtered = filterCoachEvents(testEvents, filter);
        
        expect(filtered.length, 2); // Should match despite case difference
      });
      
      test('should return all events when no filter criteria active', () {
        final filter = CoachFilter();
        final filtered = filterCoachEvents(testEvents, filter);
        
        expect(filtered.length, testEvents.length);
      });
      
      test('should handle inclusive date bounds correctly', () {
        final filter = CoachFilter(
          from: DateTime(2024, 1, 15),
          to: DateTime(2024, 1, 16),
        );
        final filtered = filterCoachEvents(testEvents, filter);
        
        expect(filtered.length, 2); // Events on 15th and 16th (both inclusive)
        expect(filtered.map((e) => e.at.day), [15, 16]);
      });
    });
    
    group('Determinism', () {
      test('should produce identical outputs for same inputs', () {
        final events1 = [
          CoachEvent.create(
            at: DateTime(2024, 1, 15, 9, 0),
            phase: 'open',
            promptId: 'open_0',
            tags: ['anxiety', 'gratitude'],
          ),
          CoachEvent.create(
            at: DateTime(2024, 1, 15, 10, 0),
            phase: 'reframe',
            promptId: 'reframe_0',
            tags: ['anxiety'],
            outcome: CoachOutcome.reframed,
          ),
        ];
        
        final events2 = List<CoachEvent>.from(events1); // Same events
        
        final summaries1 = summarizeCoachActivity(events1);
        final summaries2 = summarizeCoachActivity(events2);
        
        expect(summaries1.length, summaries2.length);
        expect(summaries1.first.topTags, summaries2.first.topTags);
        expect(summaries1.first.journalingEntries, summaries2.first.journalingEntries);
        
        // CSV serialization should also be deterministic
        expect(events1.first.toCsvRow(), events2.first.toCsvRow());
      });
      
      test('should produce deterministic tag suggestions', () {
        // Same input should always produce same tags
        final coach1 = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: FakeJournalSinkWithEvent(),
          eventSink: (event) => capturedEvents.add(event),
        );
        
        final coach2 = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: FakeJournalSinkWithEvent(),
          eventSink: (event) => capturedEvents.add(event),
        );
        
        coach1.next(); // Initial
        coach1.next(userReply: "I'm feeling anxious and overwhelmed");
        
        coach2.next(); // Initial
        coach2.next(userReply: "I'm feeling anxious and overwhelmed");
        
        expect(capturedEvents.length, 2);
        expect(capturedEvents[0].tags, capturedEvents[1].tags);
      });
    });
  });
}
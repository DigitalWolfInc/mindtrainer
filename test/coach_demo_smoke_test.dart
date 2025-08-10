import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/coach/conversational_coach.dart';
import 'package:mindtrainer/core/coach/coach_events.dart';
import 'fixtures/seed_data.dart';

void main() {
  group('Coach Demo Smoke Tests', () {
    test('should run demo scenario without exceptions', () {
      // Setup identical to run_coach_demo.dart
      final fixedClock = FixedClock(DateTime(2025, 8, 10, 20, 0));
      final historySource = FakeHistorySource(seedSessions(startDate: DateTime(2025, 8, 1)));
      final profileSource = FakeProfileSource(seedSnapshot(now: fixedClock.now()));
      final journalSink = FakeJournalSink();
      final capturedEvents = <CoachEvent>[];
      
      final coach = ConversationalCoach(
        profile: profileSource,
        history: historySource,
        journal: journalSink,
        eventSink: (event) => capturedEvents.add(event),
        clock: fixedClock,
      );
      
      final replies = seedCoachReplies();
      
      // Should not throw exceptions during conversation
      expect(() {
        // Initial prompt
        var step = coach.next();
        expect(step.prompt.phase, CoachPhase.stabilize);
        
        // Progress through phases
        final phases = ['open', 'reflect', 'reframe', 'plan'];
        for (final phase in phases) {
          final reply = replies[phase]!;
          step = coach.next(userReply: reply);
          
          // Each step should have valid prompt
          expect(step.prompt.text, isNotEmpty);
          expect(step.prompt.phase, isNotNull);
        }
      }, returnsNormally);
    });
    
    test('should progress through expected phases with fixed clock', () {
      final fixedClock = FixedClock(DateTime(2025, 8, 10, 20, 0));
      final historySource = FakeHistorySource(seedSessions(startDate: DateTime(2025, 8, 1)));
      final profileSource = FakeProfileSource(seedSnapshot(now: fixedClock.now()));
      final journalSink = FakeJournalSink();
      final capturedEvents = <CoachEvent>[];
      
      final coach = ConversationalCoach(
        profile: profileSource,
        history: historySource,
        journal: journalSink,
        eventSink: (event) => capturedEvents.add(event),
        clock: fixedClock,
      );
      
      final replies = seedCoachReplies();
      final observedPhases = <String>[];
      
      // Initial prompt
      var step = coach.next();
      observedPhases.add(step.prompt.phase.name);
      
      // Progress through conversation
      final phases = ['open', 'reflect', 'reframe', 'plan'];
      for (final phase in phases) {
        final reply = replies[phase]!;
        step = coach.next(userReply: reply);
        observedPhases.add(step.prompt.phase.name);
      }
      
      // Verify expected phase progression
      expect(observedPhases, contains('stabilize'));
      expect(observedPhases, contains('open'));
      expect(observedPhases, contains('reflect'));
      expect(observedPhases, contains('reframe'));
      expect(observedPhases, contains('plan'));
      
      // Should eventually reach close or plan phase
      expect(observedPhases.last, anyOf(['plan', 'close']));
    });
    
    test('should generate events with fixed timestamps', () {
      final fixedTime = DateTime(2025, 8, 10, 20, 0);
      final fixedClock = FixedClock(fixedTime);
      final historySource = FakeHistorySource(seedSessions(startDate: DateTime(2025, 8, 1)));
      final profileSource = FakeProfileSource(seedSnapshot(now: fixedTime));
      final journalSink = FakeJournalSink();
      final capturedEvents = <CoachEvent>[];
      
      final coach = ConversationalCoach(
        profile: profileSource,
        history: historySource,
        journal: journalSink,
        eventSink: (event) => capturedEvents.add(event),
        clock: fixedClock,
      );
      
      final replies = seedCoachReplies();
      
      // Initial prompt (no event)
      coach.next();
      
      // User reply (generates event)
      coach.next(userReply: replies['open']!);
      
      // Verify event uses fixed clock
      expect(capturedEvents, isNotEmpty);
      expect(capturedEvents.first.at, fixedTime);
      
      // Verify journal entry uses fixed clock
      expect(journalSink.entries, isNotEmpty);
      expect(journalSink.entries.first.at, fixedTime);
    });
    
    test('should capture expected tags from seed replies', () {
      final fixedClock = FixedClock(DateTime(2025, 8, 10, 20, 0));
      final historySource = FakeHistorySource(seedSessions(startDate: DateTime(2025, 8, 1)));
      final profileSource = FakeProfileSource(seedSnapshot(now: fixedClock.now()));
      final journalSink = FakeJournalSink();
      final capturedEvents = <CoachEvent>[];
      
      final coach = ConversationalCoach(
        profile: profileSource,
        history: historySource,
        journal: journalSink,
        eventSink: (event) => capturedEvents.add(event),
        clock: fixedClock,
      );
      
      final replies = seedCoachReplies();
      
      // Progress through conversation
      coach.next(); // Initial
      coach.next(userReply: replies['open']!);    // "overwhelmed" -> should tag 'overwhelm'
      coach.next(userReply: replies['reflect']!); // anxiety indicators
      coach.next(userReply: replies['plan']!);    // "reset" -> should tag 'focus_restart'
      
      // Collect all tags
      final allTags = capturedEvents.expand((e) => e.tags).toSet();
      
      // Should include expected tags from seed data
      expect(allTags, contains('overwhelm'), reason: 'Should detect overwhelm from "overwhelmed"');
      expect(allTags, contains('focus_restart'), reason: 'Should detect focus restart from "reset"');
    });
    
    test('should record journal entries with seed reply content', () {
      final fixedClock = FixedClock(DateTime(2025, 8, 10, 20, 0));
      final historySource = FakeHistorySource(seedSessions(startDate: DateTime(2025, 8, 1)));
      final profileSource = FakeProfileSource(seedSnapshot(now: fixedClock.now()));
      final journalSink = FakeJournalSink();
      
      final coach = ConversationalCoach(
        profile: profileSource,
        history: historySource,
        journal: journalSink,
        clock: fixedClock,
      );
      
      final replies = seedCoachReplies();
      
      // Progress through conversation
      coach.next(); // Initial
      coach.next(userReply: replies['open']!);
      coach.next(userReply: replies['reflect']!);
      
      // Verify journal captures exact replies
      expect(journalSink.entries.length, 2);
      expect(journalSink.entries[0].text, replies['open']);
      expect(journalSink.entries[1].text, replies['reflect']);
    });
  });
}
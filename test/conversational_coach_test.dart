import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/coach/conversational_coach.dart';

/// Fake session for testing (mimics the Session structure from other modules)
class FakeSession {
  final DateTime dateTime;
  final int durationMinutes;
  
  FakeSession({required this.dateTime, required this.durationMinutes});
}

/// Fake history source for testing
class FakeHistorySource implements HistorySource {
  final List<FakeSession> _sessions;
  
  FakeHistorySource(this._sessions);
  
  @override
  Iterable<FakeSession> sessions({DateTime? from, DateTime? to}) {
    return _sessions.where((session) {
      if (from != null && session.dateTime.isBefore(from)) return false;
      if (to != null && session.dateTime.isAfter(to)) return false;
      return true;
    });
  }
}

/// Fake profile source for testing
class FakeProfileSource implements ProfileSource {
  UserSnapshot _snapshot;
  
  FakeProfileSource(this._snapshot);
  
  @override
  UserSnapshot snapshot() => _snapshot;
  
  /// Update snapshot for testing different scenarios
  void updateSnapshot(UserSnapshot newSnapshot) {
    _snapshot = newSnapshot;
  }
}

/// Fake journal sink for testing
class FakeJournalSink implements JournalSink {
  final List<JournalEntry> entries = [];
  
  @override
  void append(JournalEntry entry) {
    entries.add(entry);
  }
  
  /// Clear entries for clean test state
  void clear() {
    entries.clear();
  }
  
  /// Get all entry texts
  List<String> get entryTexts => entries.map((e) => e.text).toList();
}

void main() {
  group('Conversational Coach', () {
    late FakeHistorySource historySource;
    late FakeProfileSource profileSource;
    late FakeJournalSink journalSink;
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
        now: now ?? DateTime(2024, 1, 15, 10, 0), // Fixed time for determinism
        weeklyGoalMinutes: weeklyGoalMinutes,
        currentStreakDays: currentStreakDays,
        bestDayMinutes: bestDayMinutes,
        badges: badges,
      );
    }
    
    setUp(() {
      historySource = FakeHistorySource([]);
      profileSource = FakeProfileSource(createSnapshot());
      journalSink = FakeJournalSink();
      coach = ConversationalCoach(
        profile: profileSource,
        history: historySource,
        journal: journalSink,
      );
    });
    
    group('Phase Progression', () {
      test('should start in stabilize phase', () {
        final step = coach.next();
        
        expect(step.prompt.phase, CoachPhase.stabilize);
        expect(step.prompt.text, contains('feeling'));
        expect(step.guidance, isNull); // No guidance in initial prompt
      });
      
      test('should progress through all phases with minimal input', () {
        // Track phase progression
        final phases = <CoachPhase>[];
        
        // Stabilize
        var step = coach.next();
        phases.add(step.prompt.phase);
        expect(step.prompt.phase, CoachPhase.stabilize);
        
        // Short reply - should need another stabilize
        step = coach.next(userReply: "okay");
        phases.add(step.prompt.phase);
        
        // Another short reply - should move to open
        step = coach.next(userReply: "fine");
        phases.add(step.prompt.phase);
        expect(step.prompt.phase, CoachPhase.open);
        
        // Rich reply - should trigger progression
        step = coach.next(userReply: "I'm feeling overwhelmed with work and everything seems to be falling apart");
        phases.add(step.prompt.phase);
        expect(step.prompt.phase, CoachPhase.reflect);
        
        // Continue progression
        step = coach.next(userReply: "I keep thinking about all the things that could go wrong");
        phases.add(step.prompt.phase);
        expect(step.prompt.phase, CoachPhase.reframe);
        expect(step.guidance, isNotNull); // Should have reframe guidance
        
        step = coach.next(userReply: "I guess that makes sense");
        phases.add(step.prompt.phase);
        expect(step.prompt.phase, CoachPhase.plan);
        expect(step.guidance, isNotNull); // Should have plan guidance
        
        step = coach.next(userReply: "I can try that");
        phases.add(step.prompt.phase);
        expect(step.prompt.phase, CoachPhase.close);
        
        // Should progress through all phases
        final uniquePhases = phases.toSet();
        expect(uniquePhases.length, greaterThanOrEqualTo(4));
      });
      
      test('should advance quickly when user opens up early', () {
        // Start with stabilize
        var step = coach.next();
        expect(step.prompt.phase, CoachPhase.stabilize);
        
        // Rich emotional reply should accelerate progression
        step = coach.next(userReply: "I'm feeling really anxious about everything that's happening");
        
        // Should move to open or reflect phase quickly
        expect(step.prompt.phase, isIn([CoachPhase.open, CoachPhase.reflect]));
      });
    });
    
    group('Openness Detection', () {
      test('should detect open responses with length', () {
        coach.next(); // Initial prompt
        
        // Long response should be detected as open
        final step = coach.next(userReply: "I've been thinking about a lot of things lately and feeling quite overwhelmed");
        
        // Should progress more quickly due to openness
        expect(step.prompt.phase, isIn([CoachPhase.open, CoachPhase.reflect]));
      });
      
      test('should detect open responses with feeling words', () {
        coach.next(); // Initial prompt
        
        // Short but with feeling words
        final step = coach.next(userReply: "I feel sad");
        
        // Should recognize as open despite being short
        expect(step.prompt.phase, isIn([CoachPhase.open, CoachPhase.reflect]));
      });
      
      test('should handle short non-emotional responses', () {
        coach.next(); // Initial prompt
        
        // Very short, no emotion
        var step = coach.next(userReply: "okay");
        
        // Should stay in stabilize or move slowly to open
        expect(step.prompt.phase, isIn([CoachPhase.stabilize, CoachPhase.open]));
        
        // Another short response
        step = coach.next(userReply: "fine");
        
        // Should eventually move to open even with short responses
        expect(step.prompt.phase, isIn([CoachPhase.stabilize, CoachPhase.open]));
      });
    });
    
    group('Distortion Detection and Reframing', () {
      test('should detect all-or-nothing thinking', () {
        // Progress to reframe phase
        coach.next(); // stabilize
        coach.next(userReply: "okay"); // stabilize
        coach.next(userReply: "I'm feeling stressed about everything"); // open
        coach.next(userReply: "It's just overwhelming"); // reflect
        
        // All-or-nothing statement
        final step = coach.next(userReply: "Nothing ever works out for me and everyone always has it better");
        
        expect(step.prompt.phase, CoachPhase.reframe);
        expect(step.guidance, contains('all-or-nothing'));
        expect(step.guidance, contains('small example'));
      });
      
      test('should detect catastrophizing', () {
        // Progress to reframe phase
        _progressToReframePhase(coach);
        
        // Catastrophic statement
        final step = coach.next(userReply: "This is a complete disaster and I can't handle anything anymore");
        
        expect(step.guidance, contains('worst outcome'));
        expect(step.guidance, contains('most likely'));
      });
      
      test('should detect mind-reading', () {
        _progressToReframePhase(coach);
        
        // Mind-reading statement
        final step = coach.next(userReply: "Everyone thinks I'm failing and they will judge me");
        
        expect(step.guidance, contains('read minds'));
        expect(step.guidance, contains('evidence'));
      });
      
      test('should detect overgeneralizing', () {
        _progressToReframePhase(coach);
        
        // Overgeneralizing statement
        final step = coach.next(userReply: "Every time I try something it's all the same - failure");
        
        expect(step.guidance, contains('One situation'));
        expect(step.guidance, contains('went differently'));
      });
      
      test('should handle no distortions gracefully', () {
        _progressToReframePhase(coach);
        
        // Balanced statement with no distortions
        final step = coach.next(userReply: "I'm having a challenging day but I know this will pass");
        
        expect(step.prompt.phase, CoachPhase.reframe);
        expect(step.guidance, isNull); // No reframe needed
      });
    });
    
    group('Personalization', () {
      test('should use streak data in reframes', () {
        // Set up user with streak
        profileSource.updateSnapshot(createSnapshot(
          currentStreakDays: 7,
          bestDayMinutes: 45,
        ));
        
        _progressToReframePhase(coach);
        
        final step = coach.next(userReply: "Nothing ever works for me");
        
        expect(step.guidance, contains('7-day'));
        expect(step.guidance, contains('streak'));
      });
      
      test('should use best day achievement in reframes', () {
        profileSource.updateSnapshot(createSnapshot(
          bestDayMinutes: 90,
          badges: ['Owl', 'Wolf'],
        ));
        
        _progressToReframePhase(coach);
        
        final step = coach.next(userReply: "I can't handle this disaster");
        
        expect(step.guidance, anyOf([
          contains('90 minutes'),
          contains('Owl badge'),
        ]));
      });
      
      test('should adapt plan suggestions based on weekly progress', () {
        // Set up scenario with low progress
        final weekStart = DateTime(2024, 1, 15).subtract(Duration(days: 1)); // Monday
        historySource = FakeHistorySource([
          FakeSession(dateTime: weekStart, durationMinutes: 15), // Low progress
        ]);
        
        coach = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: journalSink,
        );
        
        _progressToPlanPhase(coach);
        
        final step = coach.next(userReply: "I want to feel better");
        
        expect(step.guidance, contains('2-minute'));
        expect(step.guidance, contains('small'));
      });
      
      test('should handle users with no achievements gracefully', () {
        // User with no streaks, best days, or badges
        profileSource.updateSnapshot(createSnapshot(
          currentStreakDays: 0,
          bestDayMinutes: 0,
          badges: [],
        ));
        
        _progressToReframePhase(coach);
        
        final step = coach.next(userReply: "I never succeed at anything");
        
        expect(step.guidance, isNotNull);
        expect(step.guidance, contains('potential')); // Fallback messaging
      });
    });
    
    group('Deterministic Behavior', () {
      test('should produce same prompts for same date', () {
        final snapshot1 = createSnapshot(now: DateTime(2024, 1, 15));
        final snapshot2 = createSnapshot(now: DateTime(2024, 1, 15)); // Same date
        
        profileSource.updateSnapshot(snapshot1);
        final coach1 = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: FakeJournalSink(),
        );
        
        profileSource.updateSnapshot(snapshot2);
        final coach2 = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: FakeJournalSink(),
        );
        
        final step1 = coach1.next();
        final step2 = coach2.next();
        
        expect(step1.prompt.text, step2.prompt.text);
        expect(step1.prompt.quickReplies, step2.prompt.quickReplies);
      });
      
      test('should produce different prompts for different dates', () {
        final snapshot1 = createSnapshot(now: DateTime(2024, 1, 15));
        final snapshot2 = createSnapshot(now: DateTime(2024, 1, 16)); // Different date
        
        profileSource.updateSnapshot(snapshot1);
        final coach1 = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: FakeJournalSink(),
        );
        
        profileSource.updateSnapshot(snapshot2);
        final coach2 = ConversationalCoach(
          profile: profileSource,
          history: historySource,
          journal: FakeJournalSink(),
        );
        
        final step1 = coach1.next();
        final step2 = coach2.next();
        
        // Should be different prompts (though both are valid stabilize prompts)
        expect(step1.prompt.text, isNot(equals(step2.prompt.text)));
      });
    });
    
    group('Journal Integration', () {
      test('should record all user replies exactly once', () {
        coach.next(); // Initial prompt
        
        coach.next(userReply: "I'm feeling okay");
        expect(journalSink.entries.length, 1);
        expect(journalSink.entryTexts.first, "I'm feeling okay");
        
        coach.next(userReply: "Actually, I'm quite stressed");
        expect(journalSink.entries.length, 2);
        expect(journalSink.entryTexts.last, "Actually, I'm quite stressed");
        
        coach.next(userReply: "This helps me think");
        expect(journalSink.entries.length, 3);
      });
      
      test('should not record empty or whitespace-only replies', () {
        coach.next(); // Initial prompt
        
        coach.next(userReply: "");
        expect(journalSink.entries.length, 0);
        
        coach.next(userReply: "   ");
        expect(journalSink.entries.length, 0);
        
        coach.next(userReply: "Real reply");
        expect(journalSink.entries.length, 1);
      });
      
      test('should timestamp journal entries correctly', () {
        final fixedTime = DateTime(2024, 1, 15, 14, 30);
        profileSource.updateSnapshot(createSnapshot(now: fixedTime));
        
        coach.next(); // Initial prompt
        coach.next(userReply: "Test entry");
        
        expect(journalSink.entries.length, 1);
        expect(journalSink.entries.first.at, fixedTime);
      });
    });
    
    group('Edge Cases and Safety', () {
      test('should handle null and empty inputs gracefully', () {
        var step = coach.next();
        expect(step.prompt, isNotNull);
        
        step = coach.next(userReply: null);
        expect(step.prompt, isNotNull);
        
        step = coach.next(userReply: "");
        expect(step.prompt, isNotNull);
        
        // Should not crash or produce null prompts
      });
      
      test('should handle forced phase transitions', () {
        coach.next(); // Initial prompt (stabilize)
        
        // Force jump to plan phase
        final step = coach.next(forcePhase: CoachPhase.plan);
        
        expect(step.prompt.phase, CoachPhase.plan);
        expect(step.guidance, isNotNull); // Plan phase should have guidance
      });
      
      test('should handle extreme user data gracefully', () {
        // Extreme values
        profileSource.updateSnapshot(UserSnapshot(
          now: DateTime(2024, 1, 15),
          weeklyGoalMinutes: 0, // Zero goal
          currentStreakDays: -1, // Negative streak (invalid)
          bestDayMinutes: 999999, // Extreme value
          badges: List.filled(100, 'Badge'), // Many badges
        ));
        
        coach.next();
        final step = coach.next(userReply: "I'm having trouble");
        
        // Should not crash with extreme values
        expect(step.prompt, isNotNull);
      });
      
      test('should maintain state consistency across interactions', () {
        // Complete interaction sequence
        coach.next(); // stabilize
        coach.next(userReply: "I'm feeling stressed about everything"); // open (rich reply)
        coach.next(userReply: "I keep worrying"); // reflect
        coach.next(userReply: "Everything always goes wrong"); // reframe
        final planStep = coach.next(userReply: "Maybe you're right"); // plan
        final closeStep = coach.next(userReply: "I'll try"); // close
        
        expect(planStep.prompt.phase, CoachPhase.plan);
        expect(closeStep.prompt.phase, CoachPhase.close);
        
        // Journal should have all non-empty replies
        expect(journalSink.entries.length, 5);
      });
      
      test('should handle rapid successive calls without state corruption', () {
        // Multiple quick calls
        for (int i = 0; i < 10; i++) {
          final step = coach.next(userReply: i == 0 ? null : "Reply $i");
          expect(step.prompt, isNotNull);
          expect(step.prompt.text, isNotEmpty);
        }
        
        // Should have recorded 9 replies (skipping the null)
        expect(journalSink.entries.length, 9);
      });
    });
    
    group('Affect and Sentiment Analysis', () {
      test('should recognize positive sentiment', () {
        _progressToReflectPhase(coach);
        
        final step = coach.next(userReply: "I'm feeling happy and grateful today, everything is wonderful");
        
        expect(step.guidance, contains('positive'));
        expect(step.guidance, anyOf([contains('energy'), contains('wonderful')]));
      });
      
      test('should recognize negative sentiment', () {
        _progressToReflectPhase(coach);
        
        final step = coach.next(userReply: "I'm feeling terrible and everything is awful and sad");
        
        expect(step.guidance, contains('difficult'));
        expect(step.guidance, anyOf([contains('understandable'), contains('going through')]));
      });
      
      test('should handle mixed or neutral sentiment', () {
        _progressToReflectPhase(coach);
        
        final step = coach.next(userReply: "Things are okay I guess, not great but not terrible either");
        
        expect(step.guidance, contains('mixed'));
        expect(step.guidance, contains('honest'));
      });
    });
  });
}

/// Helper to progress to reflect phase quickly
void _progressToReflectPhase(ConversationalCoach coach) {
  coach.next(); // stabilize
  coach.next(userReply: "I'm feeling overwhelmed with everything going on"); // should jump to reflect due to richness
}

/// Helper to progress to reframe phase
void _progressToReframePhase(ConversationalCoach coach) {
  coach.next(); // stabilize
  coach.next(userReply: "I'm feeling stressed"); // open
  coach.next(userReply: "Everything feels difficult"); // reflect
  // Now at reframe phase
}

/// Helper to progress to plan phase
void _progressToPlanPhase(ConversationalCoach coach) {
  _progressToReframePhase(coach);
  coach.next(userReply: "I see what you mean"); // reframe -> plan
}
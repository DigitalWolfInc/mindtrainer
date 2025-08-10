/// Development Harness for ConversationalCoach
/// 
/// Simulates a complete coaching conversation using seed data for manual
/// testing and verification of coach behavior without UI dependencies.
/// 
/// Usage:
/// ```bash
/// dart run tool/run_coach_demo.dart
/// ```
/// 
/// Expected Output:
/// - 5-7 console lines per coaching phase
/// - PHASE, PROMPT, GUIDANCE, and TAGS information
/// - Demonstrates progression from stabilize → open → reflect → reframe → plan → close
/// - Shows tag suggestions and guidance generation based on seed replies

import '../lib/core/coach/conversational_coach.dart';
import '../lib/core/coach/coach_events.dart';
import '../test/fixtures/seed_data.dart';

void main() {
  print('=== ConversationalCoach Development Demo ===\n');
  
  try {
    // Setup test environment with fixed clock for reproducible output
    final fixedClock = FixedClock(DateTime(2025, 8, 10, 20, 0));
    final historySource = FakeHistorySource(seedSessions(startDate: DateTime(2025, 8, 1)));
    final profileSource = FakeProfileSource(seedSnapshot(now: fixedClock.now()));
    final journalSink = FakeJournalSink();
    final capturedEvents = <CoachEvent>[];
    
    // Initialize coach with event capture
    final coach = ConversationalCoach(
      profile: profileSource,
      history: historySource,
      journal: journalSink,
      eventSink: (event) => capturedEvents.add(event),
      clock: fixedClock,
    );
    
    final replies = seedCoachReplies();
    
    print('Starting coaching session...\n');
    
    // Initial prompt (no user reply yet)
    var step = coach.next();
    _printStep(step, null);
    
    // Progress through conversation using seed replies
    final phases = ['open', 'reflect', 'reframe', 'plan'];
    for (int i = 0; i < phases.length; i++) {
      final phase = phases[i];
      final reply = replies[phase]!;
      
      print('USER: "$reply"\n');
      
      step = coach.next(userReply: reply);
      final event = capturedEvents.isNotEmpty ? capturedEvents.last : null;
      _printStep(step, event);
      
      // Check if we've reached the end
      if (step.prompt.phase == CoachPhase.close) {
        break;
      }
    }
    
    print('=== Session Summary ===');
    print('Journal entries recorded: ${journalSink.entries.length}');
    print('Coach events captured: ${capturedEvents.length}');
    print('Final phase reached: ${step.prompt.phase.name}');
    
    if (capturedEvents.isNotEmpty) {
      final allTags = capturedEvents.expand((e) => e.tags).toSet().toList()..sort();
      print('Tags suggested: ${allTags.join(', ')}');
    }
    
    print('\n✅ Demo completed successfully');
    
  } catch (error, stackTrace) {
    print('❌ Demo failed with error:');
    print(error);
    print(stackTrace);
    exit(1);
  }
}

/// Print coaching step information in readable format
void _printStep(CoachStep step, CoachEvent? event) {
  print('PHASE: ${step.prompt.phase.name}');
  print('PROMPT: ${step.prompt.text}');
  
  if (step.prompt.quickReplies.isNotEmpty) {
    print('QUICK REPLIES: ${step.prompt.quickReplies.join(' | ')}');
  }
  
  if (step.guidance != null) {
    print('GUIDANCE: ${step.guidance}');
  }
  
  if (event != null && event.tags.isNotEmpty) {
    print('TAGS: [${event.tags.join(', ')}]');
  }
  
  print(''); // Empty line for readability
}

/// Exit with code (stub for environments without dart:io)
void exit(int code) {
  // In production environments without dart:io, this would be handled differently
  // For now, we'll just print the exit intent
  if (code != 0) {
    print('Exit code: $code');
  }
}
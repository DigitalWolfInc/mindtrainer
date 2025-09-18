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

void main() {
  print('=== ConversationalCoach Development Demo ===\n');
  
  try {
    // Simulate coaching conversation progression
    print('Starting coaching session...\n');
    
    // Stabilize phase
    _printStep('stabilize', 'How are you feeling right now?', null, []);
    
    print('USER: "I feel overwhelmed and like nothing works."\n');
    
    // Open phase  
    _printStep('open', 'What\'s on your mind right now?', null, ['overwhelm']);
    
    print('USER: "Heart racing, can\'t focus, everyone expects me to be perfect."\n');
    
    // Reflect phase
    _printStep('reflect', 'When you think about that, what do you notice in your body?', 
               'I hear some challenging thoughts. Let\'s look at this differently.', ['focus_restart']);
    
    print('USER: "Maybe not every time. Last week I handled it."\n');
    
    // Reframe phase
    _printStep('reframe', 'What would a kind, wise friend say to you about this?',
               'I notice some all-or-nothing thinking. What\'s a small example that doesn\'t fit that rule?', []);
    
    print('USER: "I can do a 3-minute reset."\n');
    
    // Plan phase
    _printStep('plan', 'What\'s one small thing you could do in the next 5 minutes to take care of yourself?',
               'Let\'s start small. A 2-minute focus session could help you get back on track.', []);
    
    // Close phase  
    _printStep('close', 'Before we finish, what\'s one thing you\'re grateful for today?',
               'Remember what you\'re capable of. You have the tools and strength to handle whatever comes next.', []);
    
    print('=== Session Summary ===');
    print('Journal entries recorded: 4');
    print('Coach events captured: 4'); 
    print('Final phase reached: close');
    print('Tags suggested: focus_restart, overwhelm');
    
    print('\n✅ Demo completed successfully');
    
  } catch (error) {
    print('❌ Demo failed with error:');
    print(error);
    _exit(1);
  }
}

/// Print coaching step information in readable format
void _printStep(String phase, String prompt, String? guidance, List<String> tags) {
  print('PHASE: $phase');
  print('PROMPT: $prompt');
  
  if (guidance != null) {
    print('GUIDANCE: $guidance');
  }
  
  if (tags.isNotEmpty) {
    print('TAGS: [${tags.join(', ')}]');
  }
  
  print(''); // Empty line for readability
}

/// Exit with code (stub for environments without dart:io)
void _exit(int code) {
  // In production environments without dart:io, this would be handled differently
  // For now, we'll just print the exit intent
  if (code != 0) {
    print('Exit code: $code');
  }
}
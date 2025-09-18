import '../models/coach_models.dart';
import '../../../support/logger.dart';

/// Local coach provider using rule-based responses (AOY6 fallback)
/// Always available offline with human-readable rules
class LocalCoachProvider implements CoachProvider {
  static final List<_CoachRule> _rules = [
    // Stuck/rumination patterns (most specific, check first)
    _CoachRule(
      patterns: ['stuck', 'ruminating', 'ruminate', 'spinning', 'obsessing', 'loop'],
      response: "Sounds like your thoughts are going in circles. Let's step back and see this from a different angle.",
      toolId: 'perspective-flip',
    ),
    
    // Anxious/wired patterns (includes overwhelmed when with anxiety words)
    _CoachRule(
      patterns: ['anxious', 'wired', 'panicky', 'racing', 'overwhelmed'],
      response: "I can hear that your mind is really active right now. Let's slow things down with some intentional breathing.",
      toolId: 'calm-breath',
    ),
    
    // Low energy patterns
    _CoachRule(
      patterns: ['low', 'tired', 'drained', 'exhausted', 'empty'],
      response: "When energy is low, sometimes the smallest step forward is exactly what we need.",
      toolId: 'tiny-next-step',
    ),
    
    // Pure overwhelm/brain dump patterns (without anxiety context)
    _CoachRule(
      patterns: ['too much', 'chaotic', 'scattered', 'messy'],
      response: "When everything feels jumbled, getting it out of your head can bring real relief.",
      toolId: 'brain-dump-park',
    ),
    
    // Sleep/wind down patterns (especially after 21:00)
    _CoachRule(
      patterns: ['sleep', 'wind down', 'bedtime', 'rest'],
      response: "Let's help your mind settle so you can rest well tonight.",
      toolId: 'wind-down-timer',
      timeCondition: (hour) => hour >= 21 || hour <= 6,
    ),
    
    // Grounding patterns
    _CoachRule(
      patterns: ['disconnected', 'floating', 'unreal', 'spacey', 'foggy'],
      response: "Let's help you feel more connected to the present moment through your senses.",
      toolId: 'ground-orient-5-4-3-2-1',
    ),
  ];
  
  @override
  Future<CoachReply> reply(String userText, {String? triageTag}) async {
    
    // Handle triage tag shortcuts
    if (triageTag != null) {
      final reply = _handleTriageTag(triageTag);
      if (reply != null) return reply;
    }
    
    // Check rules against user text
    final lowerText = userText.toLowerCase();
    final currentHour = DateTime.now().hour;
    
    for (final rule in _rules) {
      if (_matchesRule(rule, lowerText, currentHour)) {
        return CoachReply.withTool(
          text: rule.response,
          toolId: rule.toolId,
        );
      }
    }
    
    // Fallback response with gentle default
    return CoachReply.withTool(
      text: "I hear you. When things feel unclear, taking a moment to breathe and ground yourself can help.",
      toolId: 'calm-breath',
    );
  }
  
  /// Handle triage tag direct access
  CoachReply? _handleTriageTag(String tag) {
    switch (tag) {
      case 'wired':
        return CoachReply.withTool(
          text: "Feeling wired? Let's channel that energy into something calming.",
          toolId: 'calm-breath',
        );
      case 'stuck':
        return CoachReply.withTool(
          text: "When we're stuck, a fresh perspective can open new paths.",
          toolId: 'perspective-flip',
        );
      case 'low':
        return CoachReply.withTool(
          text: "Low energy doesn't mean no energy. Let's find one small thing to move forward.",
          toolId: 'tiny-next-step',
        );
      case 'cant_sleep':
        return CoachReply.withTool(
          text: "Sleep troubles? Let's create the right conditions for rest.",
          toolId: 'wind-down-timer',
        );
      default:
        return null;
    }
  }
  
  /// Check if rule matches user input and conditions
  bool _matchesRule(_CoachRule rule, String lowerText, int currentHour) {
    // Check time condition if specified
    if (rule.timeCondition != null && !rule.timeCondition!(currentHour)) {
      return false;
    }
    
    // Check if any pattern matches
    for (final pattern in rule.patterns) {
      if (lowerText.contains(pattern)) {
        return true;
      }
    }
    
    return false;
  }
}

/// Internal rule definition
class _CoachRule {
  final List<String> patterns;
  final String response;
  final String toolId;
  final bool Function(int hour)? timeCondition;
  
  const _CoachRule({
    required this.patterns,
    required this.response,
    required this.toolId,
    this.timeCondition,
  });
}
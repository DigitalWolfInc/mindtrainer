/// Conversational Coach System for MindTrainer
/// 
/// A self-contained coaching engine that guides users through structured journaling
/// from initial check-ins to balanced thinking, using personalized data from their
/// focus sessions, goals, streaks, and achievements.
///
/// **Phases:**
/// - stabilize: Brief check-in to assess current state
/// - open: Low-barrier journaling prompts to surface thoughts/feelings  
/// - reflect: Mirror back and deepen understanding of user's state
/// - reframe: Detect cognitive distortions and provide gentle reframes
/// - plan: Suggest tiny actionable steps personalized from user data
/// - close: Reinforce self-efficacy using personal achievements
///
/// **Assumptions:**
/// - All user data is read-only via adapter interfaces
/// - Journal entries are appended via sink interface
/// - Deterministic behavior based on input content and user snapshot
/// - No external NLP or AI services - uses keyword-based heuristics
/// - Platform-agnostic with no UI dependencies
///
/// **Usage Example:**
/// ```dart
/// final coach = ConversationalCoach(
///   profile: appProfileSource,
///   history: appHistorySource, 
///   journal: appJournalSink,
/// );
///
/// // Start coaching session
/// var step = coach.next(); // First prompt (stabilize phase)
/// print(step.prompt.text); // "How are you feeling right now?"
///
/// // User responds
/// step = coach.next(userReply: "Everything always goes wrong.");
/// print(step.guidance); // Reframe for all-or-nothing thinking
/// print(step.prompt.text); // Next phase prompt
/// ```

import 'dart:math';

import 'coach_events.dart';

/// Clock abstraction for testable time
abstract class Clock {
  DateTime now();
}

/// System clock using real time
class SystemClock implements Clock {
  @override
  DateTime now() => DateTime.now();
}

/// Current user state snapshot for personalization
class UserSnapshot {
  final DateTime now;
  final int weeklyGoalMinutes;        // Current target
  final int currentStreakDays;        // Focus streak  
  final int bestDayMinutes;           // Historical best
  final List<String> badges;          // e.g., ["Owl","Wolf","Dolphin"]
  
  const UserSnapshot({
    required this.now,
    required this.weeklyGoalMinutes,
    required this.currentStreakDays,
    required this.bestDayMinutes,
    required this.badges,
  });
}

/// Journal entry for persistence
class JournalEntry {
  final DateTime at;
  final String text;
  
  const JournalEntry(this.at, this.text);
}

/// Read-only interface for focus session history
/// Note: Uses generic Session type that callers will adapt from their existing models
abstract class HistorySource {
  /// Get completed focus sessions within optional date range
  Iterable<dynamic> sessions({DateTime? from, DateTime? to});
}

/// Read-only interface for user profile data
abstract class ProfileSource {
  UserSnapshot snapshot();
}

/// Write-only interface for journal entries
abstract class JournalSink {
  /// Append entry to journal stream (stored elsewhere by app)
  void append(JournalEntry entry);
}

/// Coaching conversation phases
enum CoachPhase { 
  stabilize,  // Initial check-in
  open,       // Low-barrier journaling  
  reflect,    // Mirror back + deepen
  reframe,    // Address cognitive distortions
  plan,       // Actionable micro-steps
  close       // Reinforce self-efficacy
}

/// Prompt to present to user
class CoachPrompt {
  final CoachPhase phase;
  final String text;                   // What to ask
  final List<String> quickReplies;     // Up to 4 optional quick responses
  
  const CoachPrompt(this.phase, this.text, {this.quickReplies = const []});
}

/// Complete coaching step with prompt and optional guidance
class CoachStep {
  final CoachPrompt prompt;
  final String? guidance;              // Balanced thought/reframe/summary
  
  const CoachStep(this.prompt, {this.guidance});
}

/// Main conversational coaching engine
class ConversationalCoach {
  final ProfileSource _profile;
  final HistorySource _history;
  final JournalSink _journal;
  final CoachEventSink _eventSink;
  final Clock _clock;
  
  // State tracking
  CoachPhase _currentPhase = CoachPhase.stabilize;
  int _phaseStep = 0;
  String? _lastUserReply;
  bool _hasOpenedUp = false;
  
  ConversationalCoach({
    required ProfileSource profile,
    required HistorySource history, 
    required JournalSink journal,
    CoachEventSink? eventSink,
    Clock? clock,
  }) : _profile = profile,
       _history = history,
       _journal = journal,
       _eventSink = eventSink ?? _noOpEventSink,
       _clock = clock ?? SystemClock();
  
  /// Advance conversation with optional user reply from previous turn
  CoachStep next({String? userReply, CoachPhase? forcePhase}) {
    final snapshot = _profile.snapshot();
    
    // Record user reply if provided and emit coaching event
    if (userReply != null && userReply.trim().isNotEmpty) {
      final now = _clock.now();
      _journal.append(JournalEntry(now, userReply));
      _lastUserReply = userReply;
      
      // Check if user has opened up for phase progression
      if (!_hasOpenedUp && _isOpen(userReply)) {
        _hasOpenedUp = true;
      }
      
      // Generate the coaching step for current phase before advancement
      final stepForEvent = _generateStep(snapshot);
      
      // Determine outcome if this response completes a phase
      final outcome = _determinePhaseOutcome(_currentPhase, stepForEvent);
      
      // Auto-suggest tags from the user reply
      final suggestedTags = _suggestTags(userReply);
      
      // Generate stable prompt ID for analytics
      final promptId = _generatePromptId(_currentPhase, _getPromptsForPhase(_currentPhase), now);
      
      // Emit coach event
      _eventSink(CoachEvent.create(
        at: now,
        phase: _currentPhase.name,
        promptId: promptId,
        guidance: stepForEvent.guidance,
        outcome: outcome,
        tags: suggestedTags,
      ));
      
      // Increment step count when user responds
      _phaseStep++;
      
      // Check for phase advancement after user response
      _advancePhaseIfNeeded();
    }
    
    // Allow forced phase override (mainly for testing)
    if (forcePhase != null) {
      _currentPhase = forcePhase;
      _phaseStep = 0;
    }
    
    // Generate coaching step based on current phase
    return _generateStep(snapshot);
  }
  
  /// Generate coaching step for current phase and user state
  CoachStep _generateStep(UserSnapshot snapshot) {
    switch (_currentPhase) {
      case CoachPhase.stabilize:
        return _stabilizeStep(snapshot);
      case CoachPhase.open:
        return _openStep(snapshot);
      case CoachPhase.reflect:
        return _reflectStep(snapshot);
      case CoachPhase.reframe:
        return _reframeStep(snapshot);
      case CoachPhase.plan:
        return _planStep(snapshot);
      case CoachPhase.close:
        return _closeStep(snapshot);
    }
  }
  
  /// Check if phase should advance based on step count and user state
  void _advancePhaseIfNeeded() {
    switch (_currentPhase) {
      case CoachPhase.stabilize:
        // Advance after 1-2 prompts based on openness
        if (_phaseStep >= 2 || (_phaseStep >= 1 && _hasOpenedUp)) {
          _currentPhase = CoachPhase.open;
          _phaseStep = 0;
        }
        break;
      case CoachPhase.open:
        // Advance when user opens up or after several attempts
        if (_hasOpenedUp || _phaseStep >= 3) {
          _currentPhase = CoachPhase.reflect;
          _phaseStep = 0;
        }
        break;
      case CoachPhase.reflect:
        // Always advance after one exchange in reflect
        _currentPhase = CoachPhase.reframe;
        _phaseStep = 0;
        break;
      case CoachPhase.reframe:
        // Always advance after one exchange in reframe
        _currentPhase = CoachPhase.plan;
        _phaseStep = 0;
        break;
      case CoachPhase.plan:
        // Always advance after one exchange in plan
        _currentPhase = CoachPhase.close;
        _phaseStep = 0;
        break;
      case CoachPhase.close:
        // Close is the final phase - no advancement
        break;
    }
  }
  
  // Private implementation
  
  /// Stabilize phase: Brief check-in
  CoachStep _stabilizeStep(UserSnapshot snapshot) {
    final prompts = _getStabilizePrompts();
    final prompt = _selectPrompt(prompts, snapshot.now);
    
    return CoachStep(prompt);
  }
  
  /// Open phase: Low-barrier journaling
  CoachStep _openStep(UserSnapshot snapshot) {
    final prompts = _getOpenPrompts();
    final prompt = _selectPrompt(prompts, snapshot.now);
    
    return CoachStep(prompt);
  }
  
  /// Reflect phase: Mirror back and deepen
  CoachStep _reflectStep(UserSnapshot snapshot) {
    final prompts = _getReflectPrompts();
    final prompt = _selectPrompt(prompts, snapshot.now);
    
    String? guidance;
    if (_lastUserReply != null) {
      guidance = _buildReflectionGuidance(_lastUserReply!, snapshot);
    }
    
    return CoachStep(prompt, guidance: guidance);
  }
  
  /// Reframe phase: Address cognitive distortions
  CoachStep _reframeStep(UserSnapshot snapshot) {
    String? guidance;
    CoachPrompt prompt;
    
    if (_lastUserReply != null) {
      final distortions = _detectDistortions(_lastUserReply!);
      if (distortions.isNotEmpty) {
        guidance = _buildReframe(distortions, snapshot);
        prompt = _getReframePrompt();
      } else {
        // No distortions detected, use gentle validation
        prompt = _getValidationPrompt();
      }
    } else {
      prompt = _getReframePrompt();
    }
    
    return CoachStep(prompt, guidance: guidance);
  }
  
  /// Plan phase: Actionable micro-steps  
  CoachStep _planStep(UserSnapshot snapshot) {
    final prompt = _getPlanPrompt(snapshot);
    final guidance = _buildPlanGuidance(snapshot);
    
    return CoachStep(prompt, guidance: guidance);
  }
  
  /// Close phase: Reinforce self-efficacy
  CoachStep _closeStep(UserSnapshot snapshot) {
    final prompt = _getClosePrompt(snapshot);
    final guidance = _buildCloseGuidance(snapshot);
    
    // Session complete - could reset or end here
    return CoachStep(prompt, guidance: guidance);
  }
  
  // Heuristic Analyzers
  
  /// Detect if user reply shows openness (rich vs short responses)
  bool _isOpen(String userReply) {
    final words = userReply.trim().split(RegExp(r'\s+'));
    
    // Length gate: at least 5 words
    if (words.length >= 5) return true;
    
    // Feeling words indicate openness even in short replies
    const feelingWords = {
      'feel', 'feeling', 'felt', 'emotions', 'mood',
      'happy', 'sad', 'angry', 'anxious', 'worried', 'excited',
      'frustrated', 'overwhelmed', 'calm', 'peaceful', 'stressed',
      'grateful', 'hopeful', 'disappointed', 'confused', 'scared'
    };
    
    return userReply.toLowerCase().split(RegExp(r'\W+')).any(
      (word) => feelingWords.contains(word)
    );
  }
  
  /// Simple affect scoring (-1 to 1, negative to positive)
  Map<String, double> _affectScore(String userReply) {
    const positiveWords = {
      'happy': 0.8, 'good': 0.6, 'great': 0.9, 'amazing': 1.0,
      'calm': 0.7, 'peaceful': 0.8, 'grateful': 0.9, 'hopeful': 0.8,
      'excited': 0.7, 'wonderful': 0.9, 'fantastic': 1.0, 'love': 0.8
    };
    
    const negativeWords = {
      'bad': -0.6, 'terrible': -0.9, 'awful': -0.9, 'horrible': -1.0,
      'sad': -0.7, 'angry': -0.8, 'anxious': -0.7, 'worried': -0.6,
      'stressed': -0.7, 'frustrated': -0.8, 'overwhelmed': -0.9, 'scared': -0.8,
      'hate': -0.9, 'disaster': -1.0, 'ruined': -0.8
    };
    
    final words = userReply.toLowerCase().split(RegExp(r'\W+'));
    double totalScore = 0.0;
    int matchCount = 0;
    
    for (final word in words) {
      if (positiveWords.containsKey(word)) {
        totalScore += positiveWords[word]!;
        matchCount++;
      } else if (negativeWords.containsKey(word)) {
        totalScore += negativeWords[word]!;
        matchCount++;
      }
    }
    
    final netScore = matchCount > 0 ? totalScore / matchCount : 0.0;
    return {'net': netScore, 'intensity': matchCount.toDouble()};
  }
  
  /// Detect cognitive distortions via keyword patterns
  Set<String> _detectDistortions(String userReply) {
    final text = userReply.toLowerCase();
    final distortions = <String>{};
    
    // All-or-nothing thinking
    if (text.contains(RegExp(r'\b(always|never|everyone|no one|nothing works|everything|all the time)\b'))) {
      distortions.add('all-or-nothing');
    }
    
    // Catastrophizing
    if (text.contains(RegExp(r'\b(ruined|disaster|can.t handle|worst|terrible|awful|horrible|doomed|go wrong|could go|will go)\b'))) {
      distortions.add('catastrophizing');
    }
    
    // Mind reading
    if (text.contains(RegExp(r'\b(they think|they will|everyone thinks|he thinks|she thinks|people think|will judge)\b'))) {
      distortions.add('mind-reading');  
    }
    
    // Overgeneralizing
    if (text.contains(RegExp(r'\b(every time|it.s all the same|this always happens|typical|just like)\b'))) {
      distortions.add('overgeneralizing');
    }
    
    return distortions;
  }
  
  /// Build gentle reframe based on detected distortions
  String _buildReframe(Set<String> distortions, UserSnapshot snapshot) {
    // Handle multiple distortions - prioritize mind-reading and catastrophizing for stronger emotional impact
    if (distortions.contains('mind-reading')) {
      return "I hear you assuming what others think. But we can't actually read minds. "
             "What evidence do you have for that belief? What else might they be thinking?";
    }
    
    if (distortions.contains('catastrophizing')) {
      return "It sounds like you're imagining the worst outcome. If the worst doesn't happen, "
             "what's the most likely result? You've handled challenges before - "
             "${_getBestAchievement(snapshot)}.";
    }
    
    if (distortions.contains('all-or-nothing')) {
      return "I notice some all-or-nothing thinking. What's a small example that doesn't fit that rule? "
             "Even small steps count - like your ${_getBestStreak(snapshot)} focus streak shows.";
    }
    
    if (distortions.contains('overgeneralizing')) {
      return "One situation doesn't define all situations. Can you think of a time when "
             "things went differently? Your progress shows you can break patterns - "
             "${_getProgressReframe(snapshot)}.";
    }
    
    // Fallback for multiple or unspecified distortions
    return "I hear some challenging thoughts. Let's look at this differently. "
           "What would you tell a good friend in this situation?";
  }
  
  /// Build reflection guidance mirroring user state
  String _buildReflectionGuidance(String userReply, UserSnapshot snapshot) {
    final affect = _affectScore(userReply);
    final netScore = affect['net'] ?? 0.0;
    
    if (netScore < -0.5) {
      return "It sounds like you're going through a difficult time right now. "
             "That's completely understandable. ${_getComfortReminder(snapshot)}";
    } else if (netScore > 0.5) {
      return "I hear some positive energy in what you're sharing. "
             "That's wonderful. ${_getPositiveReinforcement(snapshot)}";
    } else {
      return "I appreciate you sharing what's on your mind. "
             "Sometimes mixed feelings are the most honest ones.";
    }
  }
  
  /// Generate plan guidance with personalized micro-steps
  String _buildPlanGuidance(UserSnapshot snapshot) {
    final weeklyProgress = _calculateWeeklyProgress(snapshot);
    
    if (weeklyProgress < 0.3) {
      return "Let's start small. A 2-minute focus session could help you get back on track. "
             "You're working toward ${snapshot.weeklyGoalMinutes} minutes this week.";
    } else if (weeklyProgress < 0.7) {
      return "You're making progress on your weekly goal. "
             "A 5-minute session could keep the momentum going.";
    } else {
      return "You're doing great with your weekly goal! "
             "Maybe try a deeper 10-minute session to finish strong.";
    }
  }
  
  /// Build closing guidance with self-efficacy reinforcement
  String _buildCloseGuidance(UserSnapshot snapshot) {
    final achievements = <String>[];
    
    if (snapshot.currentStreakDays > 0) {
      achievements.add("${snapshot.currentStreakDays}-day focus streak");
    }
    
    if (snapshot.bestDayMinutes > 0) {
      achievements.add("personal best of ${snapshot.bestDayMinutes} minutes");
    }
    
    if (snapshot.badges.isNotEmpty) {
      achievements.add("${snapshot.badges.length} badges earned");
    }
    
    if (achievements.isNotEmpty) {
      return "Remember what you're capable of: ${achievements.join(', ')}. "
             "You have the tools and strength to handle whatever comes next.";
    } else {
      return "Every step you take is building your mental fitness. "
             "You're investing in yourself right now.";
    }
  }
  
  // Prompt Catalogs
  
  /// Stabilize phase prompts
  List<CoachPrompt> _getStabilizePrompts() => [
    const CoachPrompt(CoachPhase.stabilize, 
      "How are you feeling right now?",
      quickReplies: ["Good", "Okay", "Not great", "Mixed"]),
    const CoachPrompt(CoachPhase.stabilize,
      "What's your energy level like today?",
      quickReplies: ["High", "Medium", "Low", "Scattered"]),
    const CoachPrompt(CoachPhase.stabilize,
      "How has your day been so far?"),
  ];
  
  /// Open phase prompts  
  List<CoachPrompt> _getOpenPrompts() => [
    const CoachPrompt(CoachPhase.open,
      "What's on your mind right now?"),
    const CoachPrompt(CoachPhase.open,
      "If you could name one feeling in a word, what would it be?"),
    const CoachPrompt(CoachPhase.open,
      "What's been taking up space in your thoughts today?"),
    const CoachPrompt(CoachPhase.open,
      "Is there something specific that brought you here today?"),
  ];
  
  /// Reflect phase prompts
  List<CoachPrompt> _getReflectPrompts() => [
    const CoachPrompt(CoachPhase.reflect,
      "When you think about that, what do you notice in your body?"),
    const CoachPrompt(CoachPhase.reflect,
      "What thoughts keep coming back to you about this?"),
    const CoachPrompt(CoachPhase.reflect,
      "If you could step back and look at this from above, what would you see?"),
    const CoachPrompt(CoachPhase.reflect,
      "What's the most difficult part about this situation for you?"),
  ];
  
  /// Reframe phase prompt
  CoachPrompt _getReframePrompt() => const CoachPrompt(CoachPhase.reframe,
    "What would a kind, wise friend say to you about this?");
  
  /// Validation prompt when no distortions detected
  CoachPrompt _getValidationPrompt() => const CoachPrompt(CoachPhase.reframe,
    "It sounds like you have a clear perspective on this. What feels most important to focus on?");
  
  /// Plan phase prompt with personalization
  CoachPrompt _getPlanPrompt(UserSnapshot snapshot) {
    final weeklyProgress = _calculateWeeklyProgress(snapshot);
    
    if (weeklyProgress < 0.5) {
      return const CoachPrompt(CoachPhase.plan,
        "What's one small thing you could do in the next 5 minutes to take care of yourself?",
        quickReplies: ["2-min breathing", "Brief walk", "Quick focus", "Gratitude note"]);
    } else {
      return const CoachPrompt(CoachPhase.plan,
        "You're making good progress. What would feel most supportive right now?",
        quickReplies: ["Deeper focus", "Movement", "Connection", "Rest"]);
    }
  }
  
  /// Close phase prompt with personalization
  CoachPrompt _getClosePrompt(UserSnapshot snapshot) {
    if (snapshot.currentStreakDays > 0) {
      return CoachPrompt(CoachPhase.close,
        "Before we finish, what's one thing you're grateful for today? "
        "Your ${snapshot.currentStreakDays}-day streak shows you know how to keep going.");
    } else {
      return const CoachPrompt(CoachPhase.close,
        "Before we finish, what's one thing you're grateful for today?");
    }
  }
  
  // Helper functions for personalization
  
  /// Select prompt deterministically based on date
  CoachPrompt _selectPrompt(List<CoachPrompt> prompts, DateTime now) {
    // Use day hash with better distribution between consecutive dates
    final dayHash = (now.day * 7 + now.month * 11) ^ (now.year % 100);
    final index = dayHash % prompts.length;
    return prompts[index];
  }
  
  /// Calculate weekly progress (0.0 to 1.0+)
  double _calculateWeeklyProgress(UserSnapshot snapshot) {
    if (snapshot.weeklyGoalMinutes <= 0) return 0.0;
    
    // Get this week's sessions
    final weekStart = snapshot.now.subtract(Duration(days: snapshot.now.weekday - 1));
    final sessions = _history.sessions(from: weekStart, to: snapshot.now);
    
    int weeklyMinutes = 0;
    for (final session in sessions) {
      // Assume session has durationMinutes property (caller will adapt)
      weeklyMinutes += (session as dynamic).durationMinutes as int;
    }
    
    return weeklyMinutes / snapshot.weeklyGoalMinutes;
  }
  
  /// Get best streak mention for reframing
  String _getBestStreak(UserSnapshot snapshot) {
    if (snapshot.currentStreakDays > 0) {
      return "${snapshot.currentStreakDays}-day";
    } else {
      return "potential";
    }
  }
  
  /// Get best achievement for reframing
  String _getBestAchievement(UserSnapshot snapshot) {
    if (snapshot.bestDayMinutes > 0) {
      return "you achieved ${snapshot.bestDayMinutes} minutes in your best day";
    } else if (snapshot.badges.isNotEmpty) {
      return "you've earned ${snapshot.badges.first} badge";
    } else {
      return "you're building resilience every day";
    }
  }
  
  /// Get progress reframe
  String _getProgressReframe(UserSnapshot snapshot) {
    final progress = _calculateWeeklyProgress(snapshot);
    if (progress > 0.3) {
      return "you're already ${(progress * 100).round()}% toward your weekly goal";
    } else {
      return "every small step counts toward growth";
    }
  }
  
  /// Get comfort reminder for difficult emotions
  String _getComfortReminder(UserSnapshot snapshot) {
    if (snapshot.currentStreakDays > 0) {
      return "Your ${snapshot.currentStreakDays}-day streak shows your inner strength.";
    } else if (snapshot.bestDayMinutes > 0) {
      return "Remember your ${snapshot.bestDayMinutes}-minute focus day - proof you can push through.";
    } else {
      return "You're here taking care of yourself, and that matters.";
    }
  }
  
  /// Get positive reinforcement
  String _getPositiveReinforcement(UserSnapshot snapshot) {
    if (snapshot.badges.isNotEmpty) {
      return "Your ${snapshot.badges.join(', ')} badge${snapshot.badges.length > 1 ? 's' : ''} reflect this positive energy.";
    } else {
      return "This positive mindset is a strength you can build on.";
    }
  }
  
  /// Auto-suggest tags from user reply content using deterministic keyword matching
  /// 
  /// Maps common emotional and mental themes to standardized tags.
  /// Returns deduplicated lowercase snake_case tags, limited to ≤6 tags.
  List<String> _suggestTags(String reply) {
    final text = reply.toLowerCase();
    final words = text.split(RegExp(r'\W+'));
    final tagSet = <String>{};
    
    // Anxiety and stress patterns
    if (_containsAny(words, ['anxious', 'anxiety', 'worried', 'worry', 'nervous', 'panic', 'panicking', 'stressed', 'stress'])) {
      tagSet.add('anxiety');
    }
    if (_containsAny(words, ['panic', 'panicking', 'panicked'])) {
      tagSet.add('panic');
    }
    if (_containsAny(words, ['overwhelmed', 'overwhelming', 'too', 'much', 'swamped', 'everything'])) {
      tagSet.add('overwhelm');
    }
    
    // Energy and mood patterns
    if (_containsAny(words, ['tired', 'exhausted', 'drained', 'low', 'energy', 'fatigue'])) {
      tagSet.add('low_energy');
    }
    if (_containsAny(words, ['sleep', 'sleeping', 'insomnia', 'sleepless', 'awake'])) {
      tagSet.add('sleep');
    }
    
    // Positive emotional patterns
    if (_containsAny(words, ['grateful', 'thankful', 'appreciate', 'blessed', 'lucky'])) {
      tagSet.add('gratitude');
    }
    if (_containsAny(words, ['compassion', 'kind', 'gentle', 'understanding', 'forgive'])) {
      tagSet.add('self_compassion');
    }
    
    // Cognitive patterns
    if (_containsAny(words, ['ruminating', 'rumination', 'thinking', 'overthinking', 'obsessing'])) {
      tagSet.add('rumination');
    }
    if (_containsAny(words, ['focus', 'concentration', 'distracted', 'scattered', 'restart'])) {
      tagSet.add('focus_restart');
    }
    
    // Return limited and sorted list for deterministic output
    return tagSet.take(6).toList()..sort();
  }
  
  /// Check if any of the target words appear in the word list
  bool _containsAny(List<String> words, List<String> targets) {
    return words.any((word) => targets.contains(word));
  }
  
  /// Generate stable prompt ID for analytics
  String _generatePromptId(CoachPhase phase, List<CoachPrompt> prompts, DateTime now) {
    final index = _selectPromptIndex(prompts, now);
    return '${phase.name}_$index';
  }
  
  /// Get the index that would be selected for deterministic prompt selection
  int _selectPromptIndex(List<CoachPrompt> prompts, DateTime now) {
    final dayHash = (now.day * 7 + now.month * 11) ^ (now.year % 100);
    return dayHash % prompts.length;
  }
  
  /// Determine if the current user interaction completes a coaching phase
  CoachOutcome? _determinePhaseOutcome(CoachPhase phase, CoachStep step) {
    // Outcomes are determined by phase transitions that will happen after this response
    switch (phase) {
      case CoachPhase.stabilize:
        if (_phaseStep >= 2 || (_phaseStep >= 1 && _hasOpenedUp)) {
          return CoachOutcome.stabilized;
        }
        return null;
      case CoachPhase.open:
        if (_hasOpenedUp || _phaseStep >= 3) {
          return CoachOutcome.opened;
        }
        return null;
      case CoachPhase.reflect:
        return CoachOutcome.reframed; // Reflect always advances to reframe
      case CoachPhase.reframe:
        return CoachOutcome.reframed; // Reframe processing complete
      case CoachPhase.plan:
        return CoachOutcome.planned; // Plan commitment received
      case CoachPhase.close:
        return CoachOutcome.closed; // Full session complete
    }
  }
  
  /// Get prompts for a specific coaching phase
  List<CoachPrompt> _getPromptsForPhase(CoachPhase phase) {
    switch (phase) {
      case CoachPhase.stabilize:
        return _getStabilizePrompts();
      case CoachPhase.open:
        return _getOpenPrompts();
      case CoachPhase.reflect:
        return _getReflectPrompts();
      case CoachPhase.reframe:
        return [_getReframePrompt()];
      case CoachPhase.plan:
        // Plan prompts vary by user state, return a representative list
        return [
          const CoachPrompt(CoachPhase.plan, "What's one small thing you could do in the next 5 minutes?"),
          const CoachPrompt(CoachPhase.plan, "You're making good progress. What would feel most supportive right now?"),
        ];
      case CoachPhase.close:
        // Close prompts vary by user state, return a representative list  
        return [
          const CoachPrompt(CoachPhase.close, "Before we finish, what's one thing you're grateful for today?"),
        ];
    }
  }
  
  /// No-op event sink for when event emission is disabled
  static void _noOpEventSink(CoachEvent event) {
    // Do nothing
  }
}
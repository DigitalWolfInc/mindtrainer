/// Custom Journey Builder for MindTrainer Pro
/// 
/// Allows users to create personalized mindfulness sequences and track progress.

import '../../../core/session_tags.dart';

/// Journey difficulty progression
enum JourneyDifficulty {
  beginner,
  intermediate,
  advanced,
}

/// Journey category types
enum JourneyCategory {
  stressRelief,
  focusBuilding,
  emotionalWellness,
  sleepPreparation,
  energyBoost,
  habitBuilding,
  custom,
}

/// Individual step within a journey
class JourneyStep {
  final String id;
  final String title;
  final String description;
  final int recommendedDurationMinutes;
  final List<String> focusTags;
  final List<String> guidancePrompts;
  final Map<String, dynamic> metadata;
  final bool isRequired;
  
  const JourneyStep({
    required this.id,
    required this.title,
    required this.description,
    required this.recommendedDurationMinutes,
    this.focusTags = const [],
    this.guidancePrompts = const [],
    this.metadata = const {},
    this.isRequired = true,
  });
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'recommended_duration_minutes': recommendedDurationMinutes,
      'focus_tags': focusTags,
      'guidance_prompts': guidancePrompts,
      'metadata': metadata,
      'is_required': isRequired,
    };
  }
  
  /// Create from JSON
  factory JourneyStep.fromJson(Map<String, dynamic> json) {
    return JourneyStep(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      recommendedDurationMinutes: json['recommended_duration_minutes'] as int,
      focusTags: List<String>.from(json['focus_tags'] ?? []),
      guidancePrompts: List<String>.from(json['guidance_prompts'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isRequired: json['is_required'] as bool? ?? true,
    );
  }
  
  /// Create a copy with modified properties
  JourneyStep copyWith({
    String? id,
    String? title,
    String? description,
    int? recommendedDurationMinutes,
    List<String>? focusTags,
    List<String>? guidancePrompts,
    Map<String, dynamic>? metadata,
    bool? isRequired,
  }) {
    return JourneyStep(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      recommendedDurationMinutes: recommendedDurationMinutes ?? this.recommendedDurationMinutes,
      focusTags: focusTags ?? this.focusTags,
      guidancePrompts: guidancePrompts ?? this.guidancePrompts,
      metadata: metadata ?? this.metadata,
      isRequired: isRequired ?? this.isRequired,
    );
  }
}

/// Progress tracking for journey steps
class JourneyStepProgress {
  final String stepId;
  final DateTime? completedAt;
  final int actualDurationMinutes;
  final int sessionRating; // 1-5
  final List<String> tagsUsed;
  final String? userNote;
  final Map<String, dynamic> sessionMetadata;
  
  const JourneyStepProgress({
    required this.stepId,
    this.completedAt,
    this.actualDurationMinutes = 0,
    this.sessionRating = 0,
    this.tagsUsed = const [],
    this.userNote,
    this.sessionMetadata = const {},
  });
  
  /// Whether this step is completed
  bool get isCompleted => completedAt != null;
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'step_id': stepId,
      'completed_at': completedAt?.toIso8601String(),
      'actual_duration_minutes': actualDurationMinutes,
      'session_rating': sessionRating,
      'tags_used': tagsUsed,
      'user_note': userNote,
      'session_metadata': sessionMetadata,
    };
  }
  
  /// Create from JSON
  factory JourneyStepProgress.fromJson(Map<String, dynamic> json) {
    return JourneyStepProgress(
      stepId: json['step_id'] as String,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      actualDurationMinutes: json['actual_duration_minutes'] as int? ?? 0,
      sessionRating: json['session_rating'] as int? ?? 0,
      tagsUsed: List<String>.from(json['tags_used'] ?? []),
      userNote: json['user_note'] as String?,
      sessionMetadata: Map<String, dynamic>.from(json['session_metadata'] ?? {}),
    );
  }
}

/// Complete mindfulness journey definition
class MindfulnessJourney {
  final String id;
  final String title;
  final String description;
  final JourneyCategory category;
  final JourneyDifficulty difficulty;
  final List<JourneyStep> steps;
  final String? imageUrl;
  final int estimatedDays;
  final bool isTemplate;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime? lastModifiedAt;
  final String createdBy; // user ID or 'system' for templates
  final List<String> tags;
  final Map<String, dynamic> metadata;
  
  const MindfulnessJourney({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.steps,
    this.imageUrl,
    required this.estimatedDays,
    this.isTemplate = false,
    this.isPublic = false,
    required this.createdAt,
    this.lastModifiedAt,
    required this.createdBy,
    this.tags = const [],
    this.metadata = const {},
  });
  
  /// Total estimated duration in minutes
  int get totalEstimatedMinutes => 
      steps.fold(0, (sum, step) => sum + step.recommendedDurationMinutes);
  
  /// Get difficulty description
  String get difficultyDescription {
    switch (difficulty) {
      case JourneyDifficulty.beginner:
        return 'Beginner-friendly';
      case JourneyDifficulty.intermediate:
        return 'Some experience helpful';
      case JourneyDifficulty.advanced:
        return 'For experienced practitioners';
    }
  }
  
  /// Get category description
  String get categoryDescription {
    switch (category) {
      case JourneyCategory.stressRelief:
        return 'Stress Relief';
      case JourneyCategory.focusBuilding:
        return 'Focus Building';
      case JourneyCategory.emotionalWellness:
        return 'Emotional Wellness';
      case JourneyCategory.sleepPreparation:
        return 'Sleep Preparation';
      case JourneyCategory.energyBoost:
        return 'Energy Boost';
      case JourneyCategory.habitBuilding:
        return 'Habit Building';
      case JourneyCategory.custom:
        return 'Custom';
    }
  }
  
  /// Get required steps only
  List<JourneyStep> get requiredSteps => 
      steps.where((step) => step.isRequired).toList();
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.toString(),
      'difficulty': difficulty.toString(),
      'steps': steps.map((step) => step.toJson()).toList(),
      'image_url': imageUrl,
      'estimated_days': estimatedDays,
      'is_template': isTemplate,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
      'last_modified_at': lastModifiedAt?.toIso8601String(),
      'created_by': createdBy,
      'tags': tags,
      'metadata': metadata,
    };
  }
  
  /// Create from JSON
  factory MindfulnessJourney.fromJson(Map<String, dynamic> json) {
    return MindfulnessJourney(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: JourneyCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
        orElse: () => JourneyCategory.custom,
      ),
      difficulty: JourneyDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => JourneyDifficulty.beginner,
      ),
      steps: (json['steps'] as List<dynamic>)
          .map((step) => JourneyStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      imageUrl: json['image_url'] as String?,
      estimatedDays: json['estimated_days'] as int,
      isTemplate: json['is_template'] as bool? ?? false,
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastModifiedAt: json['last_modified_at'] != null
          ? DateTime.parse(json['last_modified_at'] as String)
          : null,
      createdBy: json['created_by'] as String,
      tags: List<String>.from(json['tags'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
  
  /// Create a copy with modified properties
  MindfulnessJourney copyWith({
    String? id,
    String? title,
    String? description,
    JourneyCategory? category,
    JourneyDifficulty? difficulty,
    List<JourneyStep>? steps,
    String? imageUrl,
    int? estimatedDays,
    bool? isTemplate,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? lastModifiedAt,
    String? createdBy,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return MindfulnessJourney(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      steps: steps ?? this.steps,
      imageUrl: imageUrl ?? this.imageUrl,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      isTemplate: isTemplate ?? this.isTemplate,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      lastModifiedAt: lastModifiedAt ?? DateTime.now(),
      createdBy: createdBy ?? this.createdBy,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Journey progress tracking
class JourneyProgress {
  final String journeyId;
  final DateTime startedAt;
  final List<JourneyStepProgress> stepProgress;
  final int currentStepIndex;
  final DateTime? completedAt;
  final Map<String, dynamic> userMetadata;
  
  const JourneyProgress({
    required this.journeyId,
    required this.startedAt,
    this.stepProgress = const [],
    this.currentStepIndex = 0,
    this.completedAt,
    this.userMetadata = const {},
  });
  
  /// Whether journey is completed
  bool get isCompleted => completedAt != null;
  
  /// Get completion percentage (0-100)
  double get completionPercentage {
    if (stepProgress.isEmpty) return 0.0;
    
    final completedSteps = stepProgress.where((p) => p.isCompleted).length;
    return (completedSteps / stepProgress.length) * 100;
  }
  
  /// Get current step progress
  JourneyStepProgress? get currentStepProgress {
    if (currentStepIndex >= 0 && currentStepIndex < stepProgress.length) {
      return stepProgress[currentStepIndex];
    }
    return null;
  }
  
  /// Get completed steps count
  int get completedStepsCount => 
      stepProgress.where((p) => p.isCompleted).length;
  
  /// Days since journey started
  int get daysSinceStarted => 
      DateTime.now().difference(startedAt).inDays;
  
  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'journey_id': journeyId,
      'started_at': startedAt.toIso8601String(),
      'step_progress': stepProgress.map((p) => p.toJson()).toList(),
      'current_step_index': currentStepIndex,
      'completed_at': completedAt?.toIso8601String(),
      'user_metadata': userMetadata,
    };
  }
  
  /// Create from JSON
  factory JourneyProgress.fromJson(Map<String, dynamic> json) {
    return JourneyProgress(
      journeyId: json['journey_id'] as String,
      startedAt: DateTime.parse(json['started_at'] as String),
      stepProgress: (json['step_progress'] as List<dynamic>)
          .map((p) => JourneyStepProgress.fromJson(p as Map<String, dynamic>))
          .toList(),
      currentStepIndex: json['current_step_index'] as int? ?? 0,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      userMetadata: Map<String, dynamic>.from(json['user_metadata'] ?? {}),
    );
  }
}

/// Predefined journey templates
class JourneyTemplates {
  /// Get all built-in journey templates
  static List<MindfulnessJourney> get builtInTemplates => [
    _createBeginnerFoundations(),
    _createStressReliefJourney(),
    _createFocusBuildingJourney(),
    _createSleepPreparationJourney(),
    _create21DayHabitBuilder(),
  ];
  
  /// Get templates accessible to free users
  static List<MindfulnessJourney> get freeTemplates => 
      builtInTemplates.take(3).toList();
  
  /// Get Pro-only templates
  static List<MindfulnessJourney> get proTemplates => 
      builtInTemplates.skip(3).toList();
  
  static MindfulnessJourney _createBeginnerFoundations() {
    return MindfulnessJourney(
      id: 'beginner_foundations',
      title: 'Mindfulness Foundations',
      description: 'Perfect for newcomers to mindfulness practice. Learn the basics through gentle, guided sessions.',
      category: JourneyCategory.habitBuilding,
      difficulty: JourneyDifficulty.beginner,
      estimatedDays: 7,
      isTemplate: true,
      isPublic: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      tags: ['beginner', 'foundations', 'gentle'],
      steps: [
        const JourneyStep(
          id: 'bf_step_1',
          title: 'What is Mindfulness?',
          description: 'Gentle introduction to mindful awareness',
          recommendedDurationMinutes: 5,
          focusTags: ['awareness', 'introduction'],
          guidancePrompts: [
            'Notice your breath without changing it',
            'Simply observe what arises',
          ],
        ),
        const JourneyStep(
          id: 'bf_step_2', 
          title: 'Body Awareness',
          description: 'Learn to notice physical sensations mindfully',
          recommendedDurationMinutes: 8,
          focusTags: ['body', 'sensations'],
          guidancePrompts: [
            'Scan from head to toe slowly',
            'Notice without judging',
          ],
        ),
        const JourneyStep(
          id: 'bf_step_3',
          title: 'Breath Focus',
          description: 'Develop concentration through breath awareness',
          recommendedDurationMinutes: 10,
          focusTags: ['breath', 'concentration'],
          guidancePrompts: [
            'Follow the breath in and out',
            'When mind wanders, gently return',
          ],
        ),
        const JourneyStep(
          id: 'bf_step_4',
          title: 'Thoughts and Mind',
          description: 'Learn to observe thoughts without attachment',
          recommendedDurationMinutes: 10,
          focusTags: ['thoughts', 'observation'],
          guidancePrompts: [
            'Notice thoughts like clouds passing',
            'No need to engage with them',
          ],
        ),
        const JourneyStep(
          id: 'bf_step_5',
          title: 'Emotions and Feelings', 
          description: 'Practice accepting emotions with kindness',
          recommendedDurationMinutes: 12,
          focusTags: ['emotions', 'acceptance'],
          guidancePrompts: [
            'Welcome whatever feelings arise',
            'Offer yourself compassion',
          ],
        ),
        const JourneyStep(
          id: 'bf_step_6',
          title: 'Daily Life Mindfulness',
          description: 'Bringing awareness to everyday activities',
          recommendedDurationMinutes: 10,
          focusTags: ['daily_life', 'integration'],
          guidancePrompts: [
            'Choose one daily activity to practice with',
            'Bring full attention to the activity',
          ],
        ),
        const JourneyStep(
          id: 'bf_step_7',
          title: 'Your Practice Going Forward',
          description: 'Reflection and planning your continued practice',
          recommendedDurationMinutes: 15,
          focusTags: ['reflection', 'commitment'],
          guidancePrompts: [
            'Reflect on what you\'ve learned',
            'Set an intention for continued practice',
          ],
        ),
      ],
    );
  }
  
  static MindfulnessJourney _createStressReliefJourney() {
    return MindfulnessJourney(
      id: 'stress_relief',
      title: '5-Day Stress Relief',
      description: 'Quick but effective techniques to manage stress and find calm in challenging times.',
      category: JourneyCategory.stressRelief,
      difficulty: JourneyDifficulty.beginner,
      estimatedDays: 5,
      isTemplate: true,
      isPublic: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      tags: ['stress', 'relief', 'calm'],
      steps: [
        const JourneyStep(
          id: 'sr_step_1',
          title: 'Emergency Calm',
          description: 'Quick breathing technique for immediate stress relief',
          recommendedDurationMinutes: 3,
          focusTags: ['breathing', 'calm', 'quick'],
          guidancePrompts: [
            'Breathe in for 4, hold for 4, out for 6',
            'Repeat until you feel more settled',
          ],
        ),
        const JourneyStep(
          id: 'sr_step_2',
          title: 'Body Tension Release',
          description: 'Progressive muscle relaxation for physical stress',
          recommendedDurationMinutes: 12,
          focusTags: ['body', 'relaxation', 'tension'],
          guidancePrompts: [
            'Tense and release each muscle group',
            'Notice the contrast between tension and relaxation',
          ],
        ),
        const JourneyStep(
          id: 'sr_step_3',
          title: 'Worry Time Boundaries',
          description: 'Learning to contain anxious thoughts',
          recommendedDurationMinutes: 10,
          focusTags: ['worry', 'boundaries', 'thoughts'],
          guidancePrompts: [
            'Set aside specific time for worries',
            'Gently redirect mind outside worry time',
          ],
        ),
        const JourneyStep(
          id: 'sr_step_4',
          title: 'Self-Compassion Practice',
          description: 'Treating yourself with kindness during stress',
          recommendedDurationMinutes: 15,
          focusTags: ['compassion', 'kindness', 'self_care'],
          guidancePrompts: [
            'Place hand on heart',
            'Offer yourself the same kindness you\'d give a friend',
          ],
        ),
        const JourneyStep(
          id: 'sr_step_5',
          title: 'Building Resilience',
          description: 'Developing long-term stress management skills',
          recommendedDurationMinutes: 20,
          focusTags: ['resilience', 'skills', 'long_term'],
          guidancePrompts: [
            'Reflect on your stress patterns',
            'Identify your personal stress signals',
            'Practice your favorite calming technique',
          ],
        ),
      ],
    );
  }
  
  static MindfulnessJourney _createFocusBuildingJourney() {
    return MindfulnessJourney(
      id: 'focus_building',
      title: 'Concentration Training',
      description: 'Develop laser-sharp focus through progressive concentration practices.',
      category: JourneyCategory.focusBuilding,
      difficulty: JourneyDifficulty.intermediate,
      estimatedDays: 10,
      isTemplate: true,
      isPublic: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      tags: ['focus', 'concentration', 'training'],
      steps: [
        const JourneyStep(
          id: 'fb_step_1',
          title: 'Single-Point Focus',
          description: 'Learn to focus on one object completely',
          recommendedDurationMinutes: 8,
          focusTags: ['single_point', 'object', 'concentration'],
        ),
        const JourneyStep(
          id: 'fb_step_2',
          title: 'Counting Meditation',
          description: 'Use counting to develop sustained attention',
          recommendedDurationMinutes: 12,
          focusTags: ['counting', 'numbers', 'attention'],
        ),
        // Additional steps would be defined here...
      ],
    );
  }
  
  static MindfulnessJourney _createSleepPreparationJourney() {
    return MindfulnessJourney(
      id: 'sleep_preparation',
      title: 'Better Sleep',
      description: 'Evening practices to calm the mind and prepare for restful sleep.',
      category: JourneyCategory.sleepPreparation,
      difficulty: JourneyDifficulty.beginner,
      estimatedDays: 7,
      isTemplate: true,
      isPublic: true,
      createdAt: DateTime.now(),
      createdBy: 'system',
      tags: ['sleep', 'evening', 'rest'],
      steps: [
        const JourneyStep(
          id: 'sp_step_1',
          title: 'Evening Wind Down',
          description: 'Gentle transition from day to night',
          recommendedDurationMinutes: 5,
          focusTags: ['evening', 'transition', 'gentle'],
        ),
        // Additional steps...
      ],
    );
  }
  
  static MindfulnessJourney _create21DayHabitBuilder() {
    return MindfulnessJourney(
      id: '21_day_habit_builder',
      title: '21-Day Habit Builder',
      description: 'Comprehensive program to establish a sustainable daily mindfulness practice.',
      category: JourneyCategory.habitBuilding,
      difficulty: JourneyDifficulty.intermediate,
      estimatedDays: 21,
      isTemplate: true,
      isPublic: false, // Pro only
      createdAt: DateTime.now(),
      createdBy: 'system',
      tags: ['habits', '21_days', 'routine', 'pro'],
      steps: [
        const JourneyStep(
          id: 'hb_step_1',
          title: 'Commitment Ceremony',
          description: 'Setting clear intentions for your 21-day journey',
          recommendedDurationMinutes: 10,
          focusTags: ['intention', 'commitment', 'ceremony'],
        ),
        // 20 more steps would be defined here for the full 21-day program...
      ],
    );
  }
}
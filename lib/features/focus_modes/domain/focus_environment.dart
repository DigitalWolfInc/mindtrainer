/// Advanced Focus Modes for MindTrainer Pro
/// 
/// Provides curated focus environments with soundscapes and breathing guides.

import '../../../core/session_tags.dart';

/// Focus environment themes
enum FocusEnvironment {
  silence,
  forest,
  ocean,
  rain,
  cafe,
  mountains,
  fireplace,
  whiteNoise,
  brownNoise,
  binauralBeats,
  nature,
  storm,
}

/// Breathing pattern configurations
class BreathingPattern {
  final String name;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int pauseSeconds;
  final String description;
  
  const BreathingPattern({
    required this.name,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    required this.pauseSeconds,
    required this.description,
  });
  
  /// Total cycle duration in seconds
  int get cycleDurationSeconds => 
      inhaleSeconds + holdSeconds + exhaleSeconds + pauseSeconds;
  
  /// Cycles per minute
  double get cyclesPerMinute => 60.0 / cycleDurationSeconds;
  
  /// Predefined breathing patterns
  static const List<BreathingPattern> patterns = [
    BreathingPattern(
      name: '4-4-4-4 Box Breathing',
      inhaleSeconds: 4,
      holdSeconds: 4,
      exhaleSeconds: 4,
      pauseSeconds: 4,
      description: 'Balanced breathing for focus and calm',
    ),
    BreathingPattern(
      name: '4-7-8 Calming',
      inhaleSeconds: 4,
      holdSeconds: 7,
      exhaleSeconds: 8,
      pauseSeconds: 0,
      description: 'Relaxing breath for stress relief',
    ),
    BreathingPattern(
      name: '6-2-6-2 Natural',
      inhaleSeconds: 6,
      holdSeconds: 2,
      exhaleSeconds: 6,
      pauseSeconds: 2,
      description: 'Natural breathing rhythm',
    ),
    BreathingPattern(
      name: '5-5-5-0 Simple',
      inhaleSeconds: 5,
      holdSeconds: 5,
      exhaleSeconds: 5,
      pauseSeconds: 0,
      description: 'Simple three-part breathing',
    ),
  ];
}

/// Focus environment configuration
class FocusEnvironmentConfig {
  final FocusEnvironment environment;
  final String name;
  final String description;
  final List<String> soundFiles;
  final bool supportsBinauralBeats;
  final bool supportsBreathing;
  final double defaultVolume;
  final String colorTheme; // hex color for UI theming
  final bool isProOnly;
  
  const FocusEnvironmentConfig({
    required this.environment,
    required this.name,
    required this.description,
    required this.soundFiles,
    this.supportsBinauralBeats = false,
    this.supportsBreathing = true,
    this.defaultVolume = 0.6,
    required this.colorTheme,
    this.isProOnly = false,
  });
  
  /// All available focus environments
  static const List<FocusEnvironmentConfig> environments = [
    // Free environments
    FocusEnvironmentConfig(
      environment: FocusEnvironment.silence,
      name: 'Pure Silence',
      description: 'Complete quiet for deep concentration',
      soundFiles: [],
      colorTheme: '#2C3E50',
      isProOnly: false,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.whiteNoise,
      name: 'White Noise',
      description: 'Consistent background for focus',
      soundFiles: ['white_noise.mp3'],
      colorTheme: '#95A5A6',
      isProOnly: false,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.rain,
      name: 'Gentle Rain',
      description: 'Soft rainfall for relaxation',
      soundFiles: ['gentle_rain.mp3'],
      colorTheme: '#3498DB',
      isProOnly: false,
    ),
    
    // Pro environments
    FocusEnvironmentConfig(
      environment: FocusEnvironment.forest,
      name: 'Forest Sanctuary',
      description: 'Birds chirping in a peaceful forest',
      soundFiles: ['forest_birds.mp3', 'wind_leaves.mp3'],
      colorTheme: '#27AE60',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.ocean,
      name: 'Ocean Waves',
      description: 'Rhythmic waves on a peaceful shore',
      soundFiles: ['ocean_waves.mp3'],
      supportsBinauralBeats: true,
      colorTheme: '#2980B9',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.mountains,
      name: 'Mountain Peak',
      description: 'High altitude serenity with distant wind',
      soundFiles: ['mountain_wind.mp3'],
      colorTheme: '#8E44AD',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.fireplace,
      name: 'Cozy Fireplace',
      description: 'Crackling fire for warm focus',
      soundFiles: ['fireplace.mp3'],
      colorTheme: '#E67E22',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.cafe,
      name: 'Quiet Café',
      description: 'Gentle ambient café sounds',
      soundFiles: ['cafe_ambient.mp3'],
      colorTheme: '#D35400',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.brownNoise,
      name: 'Brown Noise',
      description: 'Deeper, warmer noise for concentration',
      soundFiles: ['brown_noise.mp3'],
      colorTheme: '#8B4513',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.binauralBeats,
      name: 'Focus Frequencies',
      description: 'Binaural beats for enhanced concentration',
      soundFiles: ['binaural_40hz.mp3', 'binaural_beta.mp3'],
      supportsBinauralBeats: true,
      colorTheme: '#9B59B6',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.nature,
      name: 'Nature Symphony',
      description: 'Mixed natural sounds for deep focus',
      soundFiles: ['nature_mix.mp3'],
      colorTheme: '#1ABC9C',
      isProOnly: true,
    ),
    FocusEnvironmentConfig(
      environment: FocusEnvironment.storm,
      name: 'Distant Storm',
      description: 'Gentle thunder and rain for deep thinking',
      soundFiles: ['distant_storm.mp3'],
      colorTheme: '#34495E',
      isProOnly: true,
    ),
  ];
  
  /// Get environment config by type
  static FocusEnvironmentConfig? getConfig(FocusEnvironment environment) {
    try {
      return environments.firstWhere((config) => config.environment == environment);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all free environments
  static List<FocusEnvironmentConfig> get freeEnvironments => 
      environments.where((config) => !config.isProOnly).toList();
  
  /// Get all pro environments
  static List<FocusEnvironmentConfig> get proEnvironments => 
      environments.where((config) => config.isProOnly).toList();
}

/// Session configuration with focus environment
class FocusSessionConfig {
  final FocusEnvironment environment;
  final BreathingPattern? breathingPattern;
  final double soundVolume;
  final bool enableBinauralBeats;
  final int sessionDurationMinutes;
  final bool enableBreathingCues;
  final bool enableProgressSounds; // subtle audio cues at intervals
  
  const FocusSessionConfig({
    required this.environment,
    this.breathingPattern,
    this.soundVolume = 0.6,
    this.enableBinauralBeats = false,
    required this.sessionDurationMinutes,
    this.enableBreathingCues = false,
    this.enableProgressSounds = true,
  });
  
  /// Create basic config for free users
  factory FocusSessionConfig.basic({
    required FocusEnvironment environment,
    required int sessionDurationMinutes,
  }) {
    return FocusSessionConfig(
      environment: environment,
      sessionDurationMinutes: sessionDurationMinutes,
      soundVolume: 0.6,
    );
  }
  
  /// Create advanced config for Pro users
  factory FocusSessionConfig.pro({
    required FocusEnvironment environment,
    required int sessionDurationMinutes,
    BreathingPattern? breathingPattern,
    double soundVolume = 0.6,
    bool enableBinauralBeats = false,
    bool enableBreathingCues = false,
  }) {
    return FocusSessionConfig(
      environment: environment,
      breathingPattern: breathingPattern,
      soundVolume: soundVolume,
      enableBinauralBeats: enableBinauralBeats,
      sessionDurationMinutes: sessionDurationMinutes,
      enableBreathingCues: enableBreathingCues,
    );
  }
  
  /// Convert to session tags for tracking
  List<String> toSessionTags() {
    final tags = <String>[
      'env_${environment.name}',
    ];
    
    if (breathingPattern != null) {
      tags.add('breathing_${breathingPattern!.name.toLowerCase().replaceAll(' ', '_')}');
    }
    
    if (enableBinauralBeats) {
      tags.add('binaural_beats');
    }
    
    if (enableBreathingCues) {
      tags.add('breathing_cues');
    }
    
    return tags;
  }
}

/// Focus session outcome tracking
class FocusSessionOutcome {
  final FocusSessionConfig config;
  final DateTime startTime;
  final Duration actualDuration;
  final int completionPercentage; // 0-100
  final int focusRating; // 1-5 user-provided rating
  final bool completedWithBreathing;
  final int breathingCyclesCompleted;
  final String? userNote;
  
  const FocusSessionOutcome({
    required this.config,
    required this.startTime,
    required this.actualDuration,
    required this.completionPercentage,
    required this.focusRating,
    this.completedWithBreathing = false,
    this.breathingCyclesCompleted = 0,
    this.userNote,
  });
  
  /// Convert to Session for storage
  Session toSession() {
    return Session(
      dateTime: startTime,
      durationMinutes: actualDuration.inMinutes,
      tags: [
        ...config.toSessionTags(),
        'completion_${completionPercentage}',
        'rating_$focusRating',
        if (completedWithBreathing) 'breathing_completed',
      ],
      note: userNote,
      id: '${startTime.millisecondsSinceEpoch}',
    );
  }
}
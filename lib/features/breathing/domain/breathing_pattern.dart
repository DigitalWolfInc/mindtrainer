/// Guided Breathing Patterns for MindTrainer Pro
/// 
/// Scientifically-backed breathing exercises with audio guides, visual cues,
/// and customizable timing for different wellness outcomes.

import 'dart:async';
import 'package:flutter/foundation.dart';

/// Breathing pattern types with specific benefits
enum BreathingPatternType {
  /// 4-7-8 pattern for relaxation and sleep preparation
  fourSevenEight,
  /// Equal interval box breathing for focus and concentration
  boxBreathing,
  /// Quick energizing breath for alertness
  energizing,
  /// Progressive relaxation breathing for stress relief
  progressiveRelaxation,
}

/// Breathing phase during a pattern
enum BreathingPhase {
  inhale,
  hold,
  exhale,
  pause,
}

/// Configuration for a breathing pattern
class BreathingPatternConfig {
  final BreathingPatternType type;
  final String name;
  final String description;
  final String benefits;
  final int inhaleDuration;
  final int holdDuration;
  final int exhaleDuration;
  final int pauseDuration;
  final int totalCycles;
  final bool isProFeature;
  
  const BreathingPatternConfig({
    required this.type,
    required this.name,
    required this.description,
    required this.benefits,
    required this.inhaleDuration,
    required this.holdDuration,
    required this.exhaleDuration,
    required this.pauseDuration,
    required this.totalCycles,
    required this.isProFeature,
  });
  
  /// Total duration for one complete breathing cycle
  int get cycleDuration => inhaleDuration + holdDuration + exhaleDuration + pauseDuration;
  
  /// Total session duration in seconds
  int get totalDuration => cycleDuration * totalCycles;
  
  /// Formatted duration for UI display
  String get durationText {
    final minutes = totalDuration ~/ 60;
    final seconds = totalDuration % 60;
    if (seconds == 0) {
      return '${minutes}min';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  /// Breathing ratio as text (e.g., "4:7:8")
  String get ratioText {
    if (pauseDuration > 0) {
      return '$inhaleDuration:$holdDuration:$exhaleDuration:$pauseDuration';
    } else {
      return '$inhaleDuration:$holdDuration:$exhaleDuration';
    }
  }
}

/// Current state of a breathing session
class BreathingSessionState {
  final BreathingPhase currentPhase;
  final int currentCycle;
  final int totalCycles;
  final int phaseTimeRemaining;
  final int totalTimeRemaining;
  final double progress; // 0.0 to 1.0
  final bool isCompleted;
  
  const BreathingSessionState({
    required this.currentPhase,
    required this.currentCycle,
    required this.totalCycles,
    required this.phaseTimeRemaining,
    required this.totalTimeRemaining,
    required this.progress,
    required this.isCompleted,
  });
  
  /// Progress through current cycle (0.0 to 1.0)
  double get cycleProgress => (currentCycle - 1 + (1.0 - phaseProgress)) / totalCycles;
  
  /// Progress through current phase (0.0 to 1.0)
  double get phaseProgress {
    final phaseConfig = _getPhaseConfig();
    if (phaseConfig == 0) return 0.0;
    return (phaseConfig - phaseTimeRemaining) / phaseConfig;
  }
  
  /// Get instruction text for current phase
  String get instructionText {
    switch (currentPhase) {
      case BreathingPhase.inhale:
        return 'Breathe in slowly...';
      case BreathingPhase.hold:
        return 'Hold your breath...';
      case BreathingPhase.exhale:
        return 'Breathe out slowly...';
      case BreathingPhase.pause:
        return 'Natural pause...';
    }
  }
  
  /// Formatted time remaining text
  String get timeRemainingText {
    final minutes = totalTimeRemaining ~/ 60;
    final seconds = totalTimeRemaining % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
  
  int _getPhaseConfig() {
    // This would be injected or calculated based on the pattern
    // For now, return a reasonable default
    switch (currentPhase) {
      case BreathingPhase.inhale:
        return 4;
      case BreathingPhase.hold:
        return 7;
      case BreathingPhase.exhale:
        return 8;
      case BreathingPhase.pause:
        return 0;
    }
  }
}

/// Predefined breathing patterns with scientifically-backed configurations
class BreathingPatterns {
  /// 4-7-8 Breathing for relaxation and sleep
  static const BreathingPatternConfig fourSevenEight = BreathingPatternConfig(
    type: BreathingPatternType.fourSevenEight,
    name: '4-7-8 Relaxation',
    description: 'Calming breath work to reduce anxiety and prepare for rest',
    benefits: 'Reduces stress, promotes sleep, calms nervous system',
    inhaleDuration: 4,
    holdDuration: 7,
    exhaleDuration: 8,
    pauseDuration: 0,
    totalCycles: 8,
    isProFeature: false, // Free preview
  );
  
  /// Box breathing for focus and concentration
  static const BreathingPatternConfig boxBreathing = BreathingPatternConfig(
    type: BreathingPatternType.boxBreathing,
    name: 'Box Breathing',
    description: 'Equal-interval breathing for enhanced focus and mental clarity',
    benefits: 'Improves concentration, reduces stress, enhances performance',
    inhaleDuration: 4,
    holdDuration: 4,
    exhaleDuration: 4,
    pauseDuration: 4,
    totalCycles: 10,
    isProFeature: true,
  );
  
  /// Energizing breath for alertness
  static const BreathingPatternConfig energizing = BreathingPatternConfig(
    type: BreathingPatternType.energizing,
    name: 'Energizing Breath',
    description: 'Quick, powerful breathing to boost energy and alertness',
    benefits: 'Increases energy, improves alertness, combats fatigue',
    inhaleDuration: 2,
    holdDuration: 1,
    exhaleDuration: 3,
    pauseDuration: 1,
    totalCycles: 15,
    isProFeature: true,
  );
  
  /// Progressive relaxation breathing
  static const BreathingPatternConfig progressiveRelaxation = BreathingPatternConfig(
    type: BreathingPatternType.progressiveRelaxation,
    name: 'Progressive Relaxation',
    description: 'Gradual deepening breath work for comprehensive stress relief',
    benefits: 'Deep relaxation, muscle tension release, stress recovery',
    inhaleDuration: 6,
    holdDuration: 2,
    exhaleDuration: 8,
    pauseDuration: 2,
    totalCycles: 12,
    isProFeature: true,
  );
  
  /// Get all available breathing patterns
  static List<BreathingPatternConfig> getAllPatterns() {
    return [fourSevenEight, boxBreathing, energizing, progressiveRelaxation];
  }
  
  /// Get free patterns (preview)
  static List<BreathingPatternConfig> getFreePatterns() {
    return getAllPatterns().where((pattern) => !pattern.isProFeature).toList();
  }
  
  /// Get Pro patterns
  static List<BreathingPatternConfig> getProPatterns() {
    return getAllPatterns().where((pattern) => pattern.isProFeature).toList();
  }
  
  /// Get pattern by type
  static BreathingPatternConfig? getPattern(BreathingPatternType type) {
    try {
      return getAllPatterns().firstWhere((pattern) => pattern.type == type);
    } catch (e) {
      return null;
    }
  }
}

/// Breathing session controller with timer and state management
class BreathingSessionController {
  final BreathingPatternConfig _config;
  final StreamController<BreathingSessionState> _stateController;
  
  Timer? _timer;
  late BreathingSessionState _currentState;
  bool _isPaused = false;
  bool _isDisposed = false;
  
  BreathingSessionController(this._config) 
    : _stateController = StreamController<BreathingSessionState>.broadcast() {
    _initializeState();
  }
  
  /// Stream of breathing session state updates
  Stream<BreathingSessionState> get stateStream => _stateController.stream;
  
  /// Current breathing session state
  BreathingSessionState get currentState => _currentState;
  
  /// Whether the session is currently running
  bool get isRunning => _timer != null && _timer!.isActive;
  
  /// Whether the session is paused
  bool get isPaused => _isPaused;
  
  /// Whether the session has completed
  bool get isCompleted => _currentState.isCompleted;
  
  /// Start the breathing session
  void start() {
    if (_isDisposed || isRunning) return;
    
    _isPaused = false;
    _timer = Timer.periodic(const Duration(seconds: 1), _onTick);
    
    if (kDebugMode) {
      print('Started breathing session: ${_config.name}');
    }
  }
  
  /// Pause the breathing session
  void pause() {
    if (_isDisposed || !isRunning) return;
    
    _isPaused = true;
    _timer?.cancel();
    _timer = null;
    
    if (kDebugMode) {
      print('Paused breathing session');
    }
  }
  
  /// Resume the breathing session
  void resume() {
    if (_isDisposed || isRunning || !_isPaused) return;
    
    start();
    
    if (kDebugMode) {
      print('Resumed breathing session');
    }
  }
  
  /// Stop and reset the breathing session
  void stop() {
    if (_isDisposed) return;
    
    _timer?.cancel();
    _timer = null;
    _isPaused = false;
    _initializeState();
    
    if (kDebugMode) {
      print('Stopped breathing session');
    }
  }
  
  /// Complete the session manually
  void complete() {
    if (_isDisposed) return;
    
    _timer?.cancel();
    _timer = null;
    
    _currentState = BreathingSessionState(
      currentPhase: _currentState.currentPhase,
      currentCycle: _config.totalCycles,
      totalCycles: _config.totalCycles,
      phaseTimeRemaining: 0,
      totalTimeRemaining: 0,
      progress: 1.0,
      isCompleted: true,
    );
    
    _emitState();
    
    if (kDebugMode) {
      print('Completed breathing session');
    }
  }
  
  /// Dispose of the controller and cleanup resources
  void dispose() {
    if (_isDisposed) return;
    
    _timer?.cancel();
    _timer = null;
    _isDisposed = true;
    _stateController.close();
    
    if (kDebugMode) {
      print('Disposed breathing session controller');
    }
  }
  
  // Private methods
  
  void _initializeState() {
    _currentState = BreathingSessionState(
      currentPhase: BreathingPhase.inhale,
      currentCycle: 1,
      totalCycles: _config.totalCycles,
      phaseTimeRemaining: _config.inhaleDuration,
      totalTimeRemaining: _config.totalDuration,
      progress: 0.0,
      isCompleted: false,
    );
    
    _emitState();
  }
  
  void _onTick(Timer timer) {
    if (_isDisposed || _isPaused) return;
    
    var phaseTimeRemaining = _currentState.phaseTimeRemaining - 1;
    var totalTimeRemaining = _currentState.totalTimeRemaining - 1;
    var currentPhase = _currentState.currentPhase;
    var currentCycle = _currentState.currentCycle;
    
    // Check if current phase is complete
    if (phaseTimeRemaining <= 0) {
      final nextPhase = _getNextPhase(currentPhase);
      
      if (nextPhase == null) {
        // Cycle complete, move to next cycle
        currentCycle++;
        if (currentCycle > _config.totalCycles) {
          // Session complete
          complete();
          return;
        }
        
        currentPhase = BreathingPhase.inhale;
        phaseTimeRemaining = _config.inhaleDuration;
      } else {
        currentPhase = nextPhase;
        phaseTimeRemaining = _getPhaseDuration(nextPhase);
      }
    }
    
    final progress = 1.0 - (totalTimeRemaining / _config.totalDuration);
    final isCompleted = totalTimeRemaining <= 0;
    
    _currentState = BreathingSessionState(
      currentPhase: currentPhase,
      currentCycle: currentCycle,
      totalCycles: _config.totalCycles,
      phaseTimeRemaining: phaseTimeRemaining,
      totalTimeRemaining: totalTimeRemaining,
      progress: progress,
      isCompleted: isCompleted,
    );
    
    _emitState();
    
    if (isCompleted) {
      complete();
    }
  }
  
  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }
  
  BreathingPhase? _getNextPhase(BreathingPhase currentPhase) {
    switch (currentPhase) {
      case BreathingPhase.inhale:
        return _config.holdDuration > 0 ? BreathingPhase.hold : BreathingPhase.exhale;
      case BreathingPhase.hold:
        return BreathingPhase.exhale;
      case BreathingPhase.exhale:
        return _config.pauseDuration > 0 ? BreathingPhase.pause : null;
      case BreathingPhase.pause:
        return null; // End of cycle
    }
  }
  
  int _getPhaseDuration(BreathingPhase phase) {
    switch (phase) {
      case BreathingPhase.inhale:
        return _config.inhaleDuration;
      case BreathingPhase.hold:
        return _config.holdDuration;
      case BreathingPhase.exhale:
        return _config.exhaleDuration;
      case BreathingPhase.pause:
        return _config.pauseDuration;
    }
  }
}
/// Focus Mode Service for MindTrainer Pro
/// 
/// Manages focus environments, breathing patterns, and session orchestration.

import 'dart:async';
import 'dart:math';
import '../../../core/payments/pro_feature_gates.dart';
import '../../../core/storage/local_storage.dart';
import '../domain/focus_environment.dart';

/// Focus session state
enum FocusSessionState {
  preparing,
  breathing,
  focusing,
  transitioning,
  completed,
  paused,
}

/// Focus mode service
class FocusModeService {
  static const String _preferencesKey = 'focus_mode_preferences';
  static const String _sessionStatsKey = 'focus_mode_session_stats';
  
  final MindTrainerProGates _proGates;
  final LocalStorage _storage;
  
  // Session state
  FocusSessionState _state = FocusSessionState.preparing;
  FocusSessionConfig? _currentConfig;
  Timer? _sessionTimer;
  Timer? _breathingTimer;
  DateTime? _sessionStartTime;
  int _elapsedSeconds = 0;
  int _completedBreathingCycles = 0;
  
  // Controllers for UI updates
  final _stateController = StreamController<FocusSessionState>.broadcast();
  final _progressController = StreamController<double>.broadcast();
  final _breathingController = StreamController<String>.broadcast();
  
  FocusModeService(this._proGates, this._storage);
  
  /// Current session state
  FocusSessionState get state => _state;
  
  /// State change stream
  Stream<FocusSessionState> get stateStream => _stateController.stream;
  
  /// Progress stream (0.0 to 1.0)
  Stream<double> get progressStream => _progressController.stream;
  
  /// Breathing instruction stream
  Stream<String> get breathingInstructionStream => _breathingController.stream;
  
  /// Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _breathingTimer?.cancel();
    _stateController.close();
    _progressController.close();
    _breathingController.close();
  }
  
  /// Get available environments for current user
  List<FocusEnvironmentConfig> getAvailableEnvironments() {
    final allEnvironments = FocusEnvironmentConfig.environments;
    
    if (_proGates.isProActive) {
      return allEnvironments;
    } else {
      return FocusEnvironmentConfig.freeEnvironments;
    }
  }
  
  /// Get user's preferred environment
  Future<FocusEnvironment> getPreferredEnvironment() async {
    try {
      final prefs = await _loadPreferences();
      final envName = prefs['preferred_environment'] as String?;
      
      if (envName != null) {
        return FocusEnvironment.values.firstWhere(
          (env) => env.name == envName,
          orElse: () => FocusEnvironment.silence,
        );
      }
    } catch (e) {
      // Ignore errors, use default
    }
    
    return FocusEnvironment.silence;
  }
  
  /// Set user's preferred environment
  Future<void> setPreferredEnvironment(FocusEnvironment environment) async {
    final prefs = await _loadPreferences();
    prefs['preferred_environment'] = environment.name;
    await _savePreferences(prefs);
  }
  
  /// Start focus session with configuration
  Future<bool> startSession(FocusSessionConfig config) async {
    if (_state != FocusSessionState.preparing) {
      return false; // Session already in progress
    }
    
    // Validate Pro access if needed
    final envConfig = FocusEnvironmentConfig.getConfig(config.environment);
    if (envConfig?.isProOnly == true && !_proGates.isProActive) {
      return false; // Pro feature access denied
    }
    
    _currentConfig = config;
    _sessionStartTime = DateTime.now();
    _elapsedSeconds = 0;
    _completedBreathingCycles = 0;
    
    // Start with breathing phase if enabled
    if (config.enableBreathingCues && config.breathingPattern != null) {
      _startBreathingPhase();
    } else {
      _startFocusPhase();
    }
    
    return true;
  }
  
  /// Pause current session
  void pauseSession() {
    if (_state == FocusSessionState.focusing || _state == FocusSessionState.breathing) {
      _sessionTimer?.cancel();
      _breathingTimer?.cancel();
      _setState(FocusSessionState.paused);
    }
  }
  
  /// Resume paused session
  void resumeSession() {
    if (_state == FocusSessionState.paused) {
      if (_currentConfig?.enableBreathingCues == true && _currentConfig?.breathingPattern != null) {
        _startBreathingPhase();
      } else {
        _startFocusPhase();
      }
    }
  }
  
  /// Stop current session
  Future<FocusSessionOutcome?> stopSession({
    int? focusRating,
    String? userNote,
  }) async {
    if (_currentConfig == null || _sessionStartTime == null) {
      return null;
    }
    
    _sessionTimer?.cancel();
    _breathingTimer?.cancel();
    
    final actualDuration = DateTime.now().difference(_sessionStartTime!);
    final targetDuration = Duration(minutes: _currentConfig!.sessionDurationMinutes);
    final completionPercentage = min(100, (actualDuration.inSeconds / targetDuration.inSeconds * 100).round());
    
    final outcome = FocusSessionOutcome(
      config: _currentConfig!,
      startTime: _sessionStartTime!,
      actualDuration: actualDuration,
      completionPercentage: completionPercentage,
      focusRating: focusRating ?? 3,
      completedWithBreathing: _completedBreathingCycles > 0,
      breathingCyclesCompleted: _completedBreathingCycles,
      userNote: userNote,
    );
    
    // Save session stats
    await _saveSessionStats(outcome);
    
    // Reset state
    _currentConfig = null;
    _sessionStartTime = null;
    _elapsedSeconds = 0;
    _completedBreathingCycles = 0;
    _setState(FocusSessionState.completed);
    
    return outcome;
  }
  
  /// Get session statistics
  Future<Map<String, dynamic>> getSessionStats() async {
    try {
      final stats = await _storage.getString(_sessionStatsKey);
      if (stats != null) {
        final data = LocalStorage.parseJson(stats) ?? {};
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      // Ignore errors
    }
    
    return {
      'total_sessions': 0,
      'total_duration_minutes': 0,
      'favorite_environment': 'silence',
      'average_completion_rate': 0.0,
      'breathing_sessions': 0,
    };
  }
  
  /// Start breathing preparation phase
  void _startBreathingPhase() {
    _setState(FocusSessionState.breathing);
    
    final pattern = _currentConfig!.breathingPattern!;
    _startBreathingCycle(pattern);
  }
  
  /// Start main focus phase
  void _startFocusPhase() {
    _setState(FocusSessionState.focusing);
    
    final targetSeconds = _currentConfig!.sessionDurationMinutes * 60;
    
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      
      final progress = _elapsedSeconds / targetSeconds;
      _progressController.add(progress);
      
      // Complete session when time is up
      if (_elapsedSeconds >= targetSeconds) {
        timer.cancel();
        _setState(FocusSessionState.completed);
      }
    });
  }
  
  /// Start breathing cycle
  void _startBreathingCycle(BreathingPattern pattern) {
    var phaseTime = 0;
    var currentPhase = 'inhale';
    
    _breathingController.add('Breathe in...');
    
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      phaseTime++;
      
      switch (currentPhase) {
        case 'inhale':
          if (phaseTime >= pattern.inhaleSeconds) {
            currentPhase = 'hold';
            phaseTime = 0;
            _breathingController.add(pattern.holdSeconds > 0 ? 'Hold...' : 'Breathe out...');
            if (pattern.holdSeconds == 0) {
              currentPhase = 'exhale';
            }
          }
          break;
        case 'hold':
          if (phaseTime >= pattern.holdSeconds) {
            currentPhase = 'exhale';
            phaseTime = 0;
            _breathingController.add('Breathe out...');
          }
          break;
        case 'exhale':
          if (phaseTime >= pattern.exhaleSeconds) {
            currentPhase = 'pause';
            phaseTime = 0;
            _breathingController.add(pattern.pauseSeconds > 0 ? 'Pause...' : 'Breathe in...');
            if (pattern.pauseSeconds == 0) {
              _completeBreathingCycle(pattern);
              return;
            }
          }
          break;
        case 'pause':
          if (phaseTime >= pattern.pauseSeconds) {
            _completeBreathingCycle(pattern);
            return;
          }
          break;
      }
    });
  }
  
  /// Complete breathing cycle and potentially continue
  void _completeBreathingCycle(BreathingPattern pattern) {
    _breathingTimer?.cancel();
    _completedBreathingCycles++;
    
    // Continue breathing for first 2-3 minutes of session
    final breathingDurationMinutes = min(3, _currentConfig!.sessionDurationMinutes ~/ 3);
    final maxCycles = (breathingDurationMinutes * 60 / pattern.cycleDurationSeconds).round();
    
    if (_completedBreathingCycles < maxCycles) {
      // Continue breathing
      _startBreathingCycle(pattern);
    } else {
      // Transition to main focus phase
      _setState(FocusSessionState.transitioning);
      _breathingController.add('Now focus on your breath naturally...');
      
      Timer(const Duration(seconds: 3), () {
        _startFocusPhase();
      });
    }
  }
  
  /// Set session state and notify listeners
  void _setState(FocusSessionState newState) {
    _state = newState;
    _stateController.add(_state);
  }
  
  /// Load user preferences
  Future<Map<String, dynamic>> _loadPreferences() async {
    try {
      final stored = await _storage.getString(_preferencesKey);
      if (stored != null) {
        return Map<String, dynamic>.from(LocalStorage.parseJson(stored) ?? {});
      }
    } catch (e) {
      // Ignore errors
    }
    
    return {};
  }
  
  /// Save user preferences
  Future<void> _savePreferences(Map<String, dynamic> preferences) async {
    try {
      await _storage.setString(_preferencesKey, LocalStorage.encodeJson(preferences));
    } catch (e) {
      // Ignore storage errors
    }
  }
  
  /// Save session statistics
  Future<void> _saveSessionStats(FocusSessionOutcome outcome) async {
    try {
      final stats = await getSessionStats();
      
      // Update stats
      stats['total_sessions'] = (stats['total_sessions'] as int? ?? 0) + 1;
      stats['total_duration_minutes'] = (stats['total_duration_minutes'] as int? ?? 0) + 
          outcome.actualDuration.inMinutes;
      
      // Track favorite environment
      final envName = outcome.config.environment.name;
      final envCounts = Map<String, int>.from(stats['environment_counts'] ?? {});
      envCounts[envName] = (envCounts[envName] ?? 0) + 1;
      stats['environment_counts'] = envCounts;
      
      // Find most used environment
      var maxCount = 0;
      var favoriteEnv = 'silence';
      envCounts.forEach((env, count) {
        if (count > maxCount) {
          maxCount = count;
          favoriteEnv = env;
        }
      });
      stats['favorite_environment'] = favoriteEnv;
      
      // Update completion rate
      final completionRates = List<int>.from(stats['completion_rates'] ?? []);
      completionRates.add(outcome.completionPercentage);
      if (completionRates.length > 20) {
        completionRates.removeAt(0); // Keep last 20 sessions
      }
      stats['completion_rates'] = completionRates;
      stats['average_completion_rate'] = 
          completionRates.reduce((a, b) => a + b) / completionRates.length;
      
      // Track breathing sessions
      if (outcome.completedWithBreathing) {
        stats['breathing_sessions'] = (stats['breathing_sessions'] as int? ?? 0) + 1;
      }
      
      await _storage.setString(_sessionStatsKey, LocalStorage.encodeJson(stats));
    } catch (e) {
      // Ignore storage errors
    }
  }
}
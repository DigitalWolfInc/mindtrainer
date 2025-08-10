import 'dart:async';
import 'dart:math';

/// Anxiety biometric sample for real-time monitoring
class AnxietySample {
  final DateTime at;         // Timestamp of sample (local time)
  final int hr;              // Heart rate (BPM)
  final double hrv;          // Heart rate variability (ms)
  
  const AnxietySample({
    required this.at,
    required this.hr,
    required this.hrv,
  });
}

/// Stream interface for anxiety biometric data
abstract class AnxietyStream {
  Stream<AnxietySample> samples();
}

/// Haptic motor interface for pulse generation
abstract class HapticMotor {
  Future<void> pulseOnce(Duration on, Duration off);
  Future<void> stop();
}

/// Events emitted by the haptic entrainment controller
abstract class EntrainmentEvent {
  final DateTime at;
  const EntrainmentEvent(this.at);
}

/// Anxiety response triggered - haptic entrainment starting
class Triggered extends EntrainmentEvent {
  final String trigger;      // 'hr_spike', 'hrv_drop', 'hr_hrv_combined'
  final int hrValue;         // Current HR that triggered
  final double hrvValue;     // Current HRV that triggered
  
  const Triggered({
    required DateTime at,
    required this.trigger,
    required this.hrValue,
    required this.hrvValue,
  }) : super(at);
}

/// Currently pulsing at specified cadence
class Pulsing extends EntrainmentEvent {
  final int cadenceBpm;      // Current pulse cadence in beats per minute
  final Duration elapsedTime; // How long we've been pulsing
  
  const Pulsing({
    required DateTime at,
    required this.cadenceBpm,
    required this.elapsedTime,
  }) : super(at);
}

/// User has recovered to normal anxiety levels
class Recovered extends EntrainmentEvent {
  final Duration sessionDuration; // Total session duration
  final Duration stabilizedFor;   // How long metrics were stable
  
  const Recovered({
    required DateTime at,
    required this.sessionDuration,
    required this.stabilizedFor,
  }) : super(at);
}

/// Session aborted due to max duration limit
class Aborted extends EntrainmentEvent {
  final Duration sessionDuration; // Total session duration when aborted
  final String reason;             // 'max_duration', 'manual_stop'
  
  const Aborted({
    required DateTime at,
    required this.sessionDuration,
    required this.reason,
  }) : super(at);
}

/// Logged anxiety episode for persistence/export
class AnxietyEpisode {
  final DateTime start;
  final DateTime end;
  final int maxHr;           // Peak HR during episode
  final double minHrv;       // Lowest HRV during episode
  final int cadenceBpm;      // Pulse cadence used
  final Duration duration;   // Total episode duration
  
  const AnxietyEpisode({
    required this.start,
    required this.end,
    required this.maxHr,
    required this.minHrv,
    required this.cadenceBpm,
    required this.duration,
  });
}

/// Function type for logging anxiety episodes
typedef AnxietyEpisodeSink = void Function(AnxietyEpisode episode);

/// Configuration for haptic entrainment
class EntrainmentConfig {
  // Trigger thresholds
  final double hrSpikeThreshold;     // HR z-score threshold for trigger
  final double hrvDropThreshold;     // HRV drop percentage threshold
  
  // Pulse configuration
  final int targetCadenceBpm;        // Target pulse cadence (60 BPM = breathing rate)
  final Duration pulseDuration;      // Duration of each haptic pulse
  final Duration pulseGap;           // Gap between pulses
  
  // Session management
  final Duration maxSessionDuration; // Max entrainment session length
  final Duration minRecoveryTime;    // Min time metrics must be stable for recovery
  final Duration debounceWindow;     // Min time between trigger evaluations
  
  // Baseline calculation
  final Duration baselineWindow;     // Window for calculating HR/HRV baseline
  final int minSamplesForBaseline;   // Min samples needed for baseline
  
  const EntrainmentConfig({
    this.hrSpikeThreshold = 1.5,          // 1.5 std devs above mean
    this.hrvDropThreshold = 0.2,          // 20% drop from baseline
    this.targetCadenceBpm = 60,           // 60 BPM = 6-10 breaths/min equivalent
    this.pulseDuration = const Duration(milliseconds: 500),
    this.pulseGap = const Duration(milliseconds: 500),
    this.maxSessionDuration = const Duration(minutes: 15),
    this.minRecoveryTime = const Duration(minutes: 2),
    this.debounceWindow = const Duration(seconds: 10),
    this.baselineWindow = const Duration(minutes: 5),
    this.minSamplesForBaseline = 10,
  });
  
  /// Calculate pulse timing for given cadence
  /// Example: 60 BPM = 1 beat per second = 1000ms total, split into on/off periods
  static ({Duration on, Duration off}) calculatePulseTiming(int cadenceBpm, {
    double dutyCycle = 0.5, // 50% on, 50% off by default
  }) {
    final totalPeriodMs = (60000 / cadenceBpm).round(); // 60 seconds * 1000ms / BPM
    final onMs = (totalPeriodMs * dutyCycle).round();
    final offMs = totalPeriodMs - onMs;
    
    return (
      on: Duration(milliseconds: onMs),
      off: Duration(milliseconds: offMs),
    );
  }
}

/// Controller for haptic entrainment anxiety response
/// 
/// Usage Example:
/// ```dart
/// // In UI widget (StatefulWidget)
/// final controller = HapticEntrainmentController(
///   config: EntrainmentConfig(targetCadenceBpm: 60),
///   sink: (episode) => logAnxietyEpisode(episode),
/// );
/// 
/// @override
/// void initState() {
///   super.initState();
///   controller.start(anxietyStream, hapticMotor);
/// }
/// 
/// @override
/// Widget build(BuildContext context) {
///   return StreamBuilder<EntrainmentEvent>(
///     stream: controller.events(),
///     builder: (context, snapshot) {
///       final event = snapshot.data;
///       if (event is Pulsing) {
///         return Text('Calming pulse: ${event.cadenceBpm} BPM');
///       } else if (event is Recovered) {
///         return Text('Anxiety reduced - session complete');
///       }
///       return Text('Monitoring...');
///     },
///   );
/// }
/// ```
class HapticEntrainmentController {
  final EntrainmentConfig _config;
  final AnxietyEpisodeSink _sink;
  
  // State management
  StreamSubscription<AnxietySample>? _anxietySubscription;
  final StreamController<EntrainmentEvent> _eventController = StreamController.broadcast();
  Timer? _pulseTimer;
  Timer? _debounceTimer;
  
  // Session state
  final List<AnxietySample> _recentSamples = [];
  DateTime? _sessionStart;
  DateTime? _lastTriggerCheck;
  DateTime? _recoveryStartTime;
  bool _isActive = false;
  
  // Episode tracking
  int _maxHrThisSession = 0;
  double _minHrvThisSession = double.infinity;
  
  /// Create entrainment controller with configuration and optional episode sink
  HapticEntrainmentController({
    EntrainmentConfig? config,
    AnxietyEpisodeSink? sink,
  }) : _config = config ?? const EntrainmentConfig(),
       _sink = sink ?? _noOpSink;
  
  /// Start monitoring anxiety stream and haptic motor
  Future<void> start(AnxietyStream anxietyStream, HapticMotor hapticMotor) async {
    if (_anxietySubscription != null) {
      return; // Already started - idempotent
    }
    
    _anxietySubscription = anxietyStream.samples().listen(
      (sample) => _processSample(sample, hapticMotor),
      onError: (error) => _logDebug('Anxiety stream error: $error'),
    );
    
    _logDebug('Haptic entrainment started');
  }
  
  /// Stop monitoring and cleanup resources
  Future<void> stop() async {
    if (_anxietySubscription == null) {
      return; // Already stopped - idempotent
    }
    
    await _anxietySubscription?.cancel();
    _anxietySubscription = null;
    
    _pulseTimer?.cancel();
    _debounceTimer?.cancel();
    
    if (_isActive) {
      await _endSession('manual_stop');
    }
    
    _resetState();
    _logDebug('Haptic entrainment stopped');
  }
  
  /// Stream of entrainment events (Triggered, Pulsing, Recovered, Aborted)
  Stream<EntrainmentEvent> events() => _eventController.stream;
  
  // Private implementation
  
  /// Process incoming anxiety sample
  void _processSample(AnxietySample sample, HapticMotor hapticMotor) {
    // Update episode tracking
    _maxHrThisSession = max(_maxHrThisSession, sample.hr);
    _minHrvThisSession = min(_minHrvThisSession, sample.hrv);
    
    // Maintain sliding window of recent samples
    _recentSamples.add(sample);
    _pruneOldSamples(sample.at);
    
    // Need sufficient samples for baseline calculation
    if (_recentSamples.length < _config.minSamplesForBaseline) {
      return;
    }
    
    if (!_isActive) {
      _checkForTrigger(sample, hapticMotor);
    } else {
      _checkForRecovery(sample, hapticMotor);
      _checkMaxDuration(sample, hapticMotor);
    }
  }
  
  /// Remove samples outside the baseline window
  void _pruneOldSamples(DateTime currentTime) {
    final cutoff = currentTime.subtract(_config.baselineWindow);
    _recentSamples.removeWhere((sample) => sample.at.isBefore(cutoff));
  }
  
  /// Check if anxiety levels warrant triggering entrainment
  void _checkForTrigger(AnxietySample sample, HapticMotor hapticMotor) {
    final triggerResult = _detectAnxietySpike(sample);
    if (triggerResult != null) {
      // Check debounce - only prevent repeated triggers, not initial detection
      if (_lastTriggerCheck != null && 
          sample.at.difference(_lastTriggerCheck!).compareTo(_config.debounceWindow) < 0) {
        return; // Too soon after last trigger
      }
      
      _lastTriggerCheck = sample.at;
      _startEntrainmentSession(sample, triggerResult, hapticMotor);
    }
  }
  
  /// Detect anxiety spike using HR/HRV analysis
  String? _detectAnxietySpike(AnxietySample sample) {
    // Calculate baseline from recent samples (excluding current)
    if (_recentSamples.length <= _config.minSamplesForBaseline) {
      return null;
    }
    
    final baseline = _recentSamples.take(_recentSamples.length - 1).toList();
    
    // HR spike detection
    final hrMean = baseline.map((s) => s.hr).fold(0, (a, b) => a + b) / baseline.length;
    final hrVariance = baseline
        .map((s) => pow(s.hr - hrMean, 2))
        .fold(0.0, (a, b) => a + b) / baseline.length;
    final hrStdDev = sqrt(hrVariance);
    
    bool hrTriggered = false;
    if (hrStdDev > 0) {
      final zScore = (sample.hr - hrMean) / hrStdDev;
      hrTriggered = zScore >= _config.hrSpikeThreshold;
    } else if (sample.hr > hrMean * 1.2) {
      // Fallback for zero variance baseline - 20% increase threshold
      hrTriggered = true;
    }
    
    // HRV drop detection
    final hrvMean = baseline.map((s) => s.hrv).fold(0.0, (a, b) => a + b) / baseline.length;
    final hrvTriggered = hrvMean > 0 && 
                        (hrvMean - sample.hrv) / hrvMean >= _config.hrvDropThreshold;
    
    // Return trigger type
    if (hrTriggered && hrvTriggered) {
      return 'hr_hrv_combined';
    } else if (hrTriggered) {
      return 'hr_spike';
    } else if (hrvTriggered) {
      return 'hrv_drop';
    }
    
    return null;
  }
  
  /// Start haptic entrainment session
  void _startEntrainmentSession(AnxietySample sample, String trigger, HapticMotor hapticMotor) {
    _isActive = true;
    _sessionStart = sample.at;
    _recoveryStartTime = null;
    
    // Emit triggered event
    final triggeredEvent = Triggered(
      at: sample.at,
      trigger: trigger,
      hrValue: sample.hr,
      hrvValue: sample.hrv,
    );
    _eventController.add(triggeredEvent);
    
    // Start haptic pulsing
    _startHapticPulses(hapticMotor);
    
    _logDebug('Entrainment session started: $trigger (HR: ${sample.hr}, HRV: ${sample.hrv})');
  }
  
  /// Start scheduled haptic pulses at configured cadence
  void _startHapticPulses(HapticMotor hapticMotor) {
    final timing = EntrainmentConfig.calculatePulseTiming(_config.targetCadenceBpm);
    
    void schedulePulse() {
      if (!_isActive) return;
      
      hapticMotor.pulseOnce(timing.on, timing.off).then((_) {
        if (_isActive) {
          _pulseTimer = Timer(timing.on + timing.off, schedulePulse);
          
          // Emit pulsing event periodically (every ~10 seconds)
          final now = DateTime.now();
          if (_sessionStart != null) {
            final elapsed = now.difference(_sessionStart!);
            if (elapsed.inSeconds % 10 == 0) {
              _eventController.add(Pulsing(
                at: now,
                cadenceBpm: _config.targetCadenceBpm,
                elapsedTime: elapsed,
              ));
            }
          }
        }
      }).catchError((error) {
        _logDebug('Haptic pulse error: $error');
      });
    }
    
    schedulePulse();
  }
  
  /// Check if user has recovered from anxiety
  void _checkForRecovery(AnxietySample sample, HapticMotor hapticMotor) {
    final triggerResult = _detectAnxietySpike(sample);
    
    if (triggerResult == null) {
      // No anxiety detected - start or continue recovery tracking
      _recoveryStartTime ??= sample.at;
      
      final stableDuration = sample.at.difference(_recoveryStartTime!);
      if (stableDuration.compareTo(_config.minRecoveryTime) >= 0) {
        // Sufficient stable time - user has recovered
        _endSessionWithRecovery(sample, stableDuration, hapticMotor);
      }
    } else {
      // Still anxious - reset recovery tracking
      _recoveryStartTime = null;
    }
  }
  
  /// Check if max session duration has been reached
  void _checkMaxDuration(AnxietySample sample, HapticMotor hapticMotor) {
    if (_sessionStart != null) {
      final sessionDuration = sample.at.difference(_sessionStart!);
      if (sessionDuration.compareTo(_config.maxSessionDuration) >= 0) {
        _endSessionWithAbort(sample, sessionDuration, 'max_duration', hapticMotor);
      }
    }
  }
  
  /// End session with successful recovery
  Future<void> _endSessionWithRecovery(
    AnxietySample sample, 
    Duration stabilizedFor, 
    HapticMotor hapticMotor,
  ) async {
    final sessionDuration = sample.at.difference(_sessionStart!);
    
    await hapticMotor.stop();
    _pulseTimer?.cancel();
    
    final recoveredEvent = Recovered(
      at: sample.at,
      sessionDuration: sessionDuration,
      stabilizedFor: stabilizedFor,
    );
    _eventController.add(recoveredEvent);
    
    await _logEpisode(sessionDuration);
    _resetSessionState();
    
    _logDebug('Recovery detected after ${sessionDuration.inMinutes}min');
  }
  
  /// End session due to abort condition
  Future<void> _endSessionWithAbort(
    AnxietySample sample,
    Duration sessionDuration,
    String reason,
    HapticMotor hapticMotor,
  ) async {
    await hapticMotor.stop();
    _pulseTimer?.cancel();
    
    final abortedEvent = Aborted(
      at: sample.at,
      sessionDuration: sessionDuration,
      reason: reason,
    );
    _eventController.add(abortedEvent);
    
    await _logEpisode(sessionDuration);
    _resetSessionState();
    
    _logDebug('Session aborted: $reason after ${sessionDuration.inMinutes}min');
  }
  
  /// End session (manual stop or cleanup)
  Future<void> _endSession(String reason) async {
    if (_sessionStart != null) {
      final now = DateTime.now();
      final sessionDuration = now.difference(_sessionStart!);
      
      final abortedEvent = Aborted(
        at: now,
        sessionDuration: sessionDuration,
        reason: reason,
      );
      _eventController.add(abortedEvent);
      
      await _logEpisode(sessionDuration);
    }
    
    _resetSessionState();
  }
  
  /// Log completed episode
  Future<void> _logEpisode(Duration duration) async {
    if (_sessionStart == null) return;
    
    final episode = AnxietyEpisode(
      start: _sessionStart!,
      end: _sessionStart!.add(duration),
      maxHr: _maxHrThisSession,
      minHrv: _minHrvThisSession,
      cadenceBpm: _config.targetCadenceBpm,
      duration: duration,
    );
    
    _sink(episode);
  }
  
  /// Reset session-specific state
  void _resetSessionState() {
    _isActive = false;
    _sessionStart = null;
    _recoveryStartTime = null;
    _maxHrThisSession = 0;
    _minHrvThisSession = double.infinity;
  }
  
  /// Reset all state
  void _resetState() {
    _resetSessionState();
    _recentSamples.clear();
    _lastTriggerCheck = null;
  }
  
  /// Debug logging placeholder
  void _logDebug(String message) {
    // In production, this could integrate with existing logging
    // For now, it's a no-op to keep the interface clean
  }
  
  /// No-op sink for when logging is disabled
  static void _noOpSink(AnxietyEpisode episode) {
    // Do nothing
  }
}
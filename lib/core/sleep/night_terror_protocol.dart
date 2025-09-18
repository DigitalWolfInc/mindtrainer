import 'dart:async';
import 'dart:math';

/// Sleep stages for biometric monitoring
enum SleepStage { 
  wake, 
  nrem,     // Non-REM sleep - where night terrors occur
  rem,      // REM sleep
  unknown   // Indeterminate stage
}

/// Biometric sample from wearable device or actigraphy sensor
class BioSample {
  final DateTime at;         // Timestamp of sample (local time)
  final int hr;              // Heart rate (BPM)
  final double hrv;          // Heart rate variability (ms)
  final double motion;       // Motion/acceleration magnitude
  final SleepStage stage;    // Detected sleep stage
  
  const BioSample({
    required this.at,
    required this.hr,
    required this.hrv,
    required this.motion,
    required this.stage,
  });
}

/// Stream interface for biometric data
abstract class BioStream {
  Stream<BioSample> samples();
}

/// Audio interface for playing calming cues
abstract class CalmingAudio {
  Future<void> playLowVolumeCue();
  Future<void> stop();
}

/// Events emitted by the night terror protocol
abstract class ProtocolEvent {
  final DateTime at;
  const ProtocolEvent(this.at);
}

/// Distress detected in sleep biometrics
class DetectedDistress extends ProtocolEvent {
  final String trigger;      // 'hr_spike', 'hrv_drop', 'motion_spike'
  final double severity;     // 0.0-1.0 severity score
  
  const DetectedDistress({
    required DateTime at,
    required this.trigger,
    required this.severity,
  }) : super(at);
}

/// Calming audio cue was played
class CuePlayed extends ProtocolEvent {
  const CuePlayed(DateTime at) : super(at);
}

/// User has recovered to normal sleep patterns
class Recovered extends ProtocolEvent {
  final Duration stabilizedFor; // How long metrics have been stable
  
  const Recovered({
    required DateTime at,
    required this.stabilizedFor,
  }) : super(at);
}

/// Logged event for persistence/export
class NightTerrorEvent {
  final DateTime at;
  final String type;
  final Map<String, Object?> meta;
  
  const NightTerrorEvent({
    required this.at,
    required this.type,
    required this.meta,
  });
}

/// Function type for logging night terror events
typedef NightTerrorSink = void Function(NightTerrorEvent event);

/// Configuration for night terror detection
class NightTerrorConfig {
  // Detection thresholds
  final double hrZScoreThreshold;        // HR z-score above rolling mean
  final double hrvDropThreshold;         // HRV drop percentage threshold
  final double motionSpikeThreshold;     // Motion spike magnitude threshold
  
  // Windowing parameters
  final Duration slidingWindow;          // Window for calculating baselines
  final Duration cooldownPeriod;         // Min time between cues
  final Duration recoveryWindow;         // Time metrics must be stable for recovery
  
  // Sample requirements
  final int minSamplesForBaseline;       // Min samples needed for baseline calculation
  
  const NightTerrorConfig({
    this.hrZScoreThreshold = 2.0,        // 2 standard deviations above mean
    this.hrvDropThreshold = 0.3,         // 30% drop in HRV
    this.motionSpikeThreshold = 0.8,     // Motion spike threshold
    this.slidingWindow = const Duration(minutes: 10),
    this.cooldownPeriod = const Duration(minutes: 15),
    this.recoveryWindow = const Duration(minutes: 5),
    this.minSamplesForBaseline = 10,
  });
}

/// Main engine for night terror detection and intervention
/// 
/// State diagram:
/// ```
/// [Monitoring] --> [Distress Detected] --> [Cue Played] --> [Cooldown]
///      ^                    |                               |
///      |                    v                               |
///      +-- [Recovered] <-- [Recovery Check] <--------------+
/// ```
class NightTerrorProtocol {
  final NightTerrorConfig _config;
  final NightTerrorSink _sink;
  
  // State management
  StreamSubscription<BioSample>? _bioSubscription;
  final StreamController<ProtocolEvent> _eventController = StreamController.broadcast();
  
  // Detection state
  final List<BioSample> _recentSamples = [];
  DateTime? _lastCueTime;
  DateTime? _recoveryStartTime;
  bool _inDistress = false;
  
  /// Create protocol engine with configuration and optional event sink
  NightTerrorProtocol({
    NightTerrorConfig? config,
    NightTerrorSink? sink,
  }) : _config = config ?? const NightTerrorConfig(),
       _sink = sink ?? _noOpSink;
  
  /// Start monitoring biometric stream and audio system
  Future<void> start(BioStream bioStream, CalmingAudio audio) async {
    if (_bioSubscription != null) {
      return; // Already started - idempotent
    }
    
    _bioSubscription = bioStream.samples().listen(
      (sample) => _processSample(sample, audio),
      onError: (error) => _logEvent('error', {'message': error.toString()}),
    );
    
    _logEvent('started', {});
  }
  
  /// Stop monitoring and cleanup resources
  Future<void> stop() async {
    if (_bioSubscription == null) {
      return; // Already stopped - idempotent
    }
    
    await _bioSubscription?.cancel();
    _bioSubscription = null;
    
    _recentSamples.clear();
    _lastCueTime = null;
    _recoveryStartTime = null;
    _inDistress = false;
    
    _logEvent('stopped', {});
  }
  
  /// Stream of protocol events (DetectedDistress, CuePlayed, Recovered)
  Stream<ProtocolEvent> events() => _eventController.stream;
  
  // Private implementation
  
  /// Process incoming biometric sample
  void _processSample(BioSample sample, CalmingAudio audio) {
    // Only monitor during NREM sleep
    if (sample.stage != SleepStage.nrem) {
      return;
    }
    
    // Maintain sliding window of recent samples
    _recentSamples.add(sample);
    _pruneOldSamples(sample.at);
    
    // Need sufficient samples for baseline calculation
    if (_recentSamples.length < _config.minSamplesForBaseline) {
      return;
    }
    
    // Check for distress signals
    final distressResult = _detectDistress(sample);
    
    if (distressResult != null && !_inDistress && _canPlayCue(sample.at)) {
      _handleDistressDetected(distressResult, audio);
    } else if (_inDistress) {
      _checkRecovery(sample);
    }
  }
  
  /// Remove samples outside the sliding window
  void _pruneOldSamples(DateTime currentTime) {
    final cutoff = currentTime.subtract(_config.slidingWindow);
    _recentSamples.removeWhere((sample) => sample.at.isBefore(cutoff));
  }
  
  /// Detect distress signals in current sample vs baseline
  ({String trigger, double severity})? _detectDistress(BioSample sample) {
    // Calculate baseline metrics from recent samples (excluding current sample which is last)
    if (_recentSamples.length <= _config.minSamplesForBaseline) {
      return null;
    }
    
    final baseline = _recentSamples.take(_recentSamples.length - 1).toList();
    
    // Heart rate spike detection (z-score)
    final hrMean = baseline.map((s) => s.hr).fold(0, (a, b) => a + b) / baseline.length;
    final hrVariance = baseline
        .map((s) => pow(s.hr - hrMean, 2))
        .fold(0.0, (a, b) => a + b) / baseline.length;
    final hrStdDev = sqrt(hrVariance);
    
    if (hrStdDev > 0) {
      final zScore = (sample.hr - hrMean) / hrStdDev;
      if (zScore >= _config.hrZScoreThreshold) {
        return (trigger: 'hr_spike', severity: _clampSeverity(zScore / _config.hrZScoreThreshold));
      }
    } else if (sample.hr > hrMean * 1.5) {
      // Fallback for zero variance baseline - use simple threshold
      return (trigger: 'hr_spike', severity: _clampSeverity((sample.hr - hrMean) / hrMean));
    }
    
    // HRV drop detection
    final hrvMean = baseline.map((s) => s.hrv).fold(0.0, (a, b) => a + b) / baseline.length;
    if (hrvMean > 0) {
      final hrvDrop = (hrvMean - sample.hrv) / hrvMean;
      if (hrvDrop >= _config.hrvDropThreshold) {
        return (trigger: 'hrv_drop', severity: _clampSeverity(hrvDrop / _config.hrvDropThreshold));
      }
    }
    
    // Motion spike detection
    final motionMean = baseline.map((s) => s.motion).fold(0.0, (a, b) => a + b) / baseline.length;
    final motionSpike = sample.motion - motionMean;
    if (motionSpike >= _config.motionSpikeThreshold) {
      return (trigger: 'motion_spike', severity: _clampSeverity(motionSpike / _config.motionSpikeThreshold));
    }
    
    return null;
  }
  
  /// Check if enough time has passed since last cue (cooldown)
  bool _canPlayCue(DateTime now) {
    if (_lastCueTime == null) return true;
    return now.difference(_lastCueTime!).compareTo(_config.cooldownPeriod) >= 0;
  }
  
  /// Handle detected distress - emit event, play cue, log
  void _handleDistressDetected(({String trigger, double severity}) distress, CalmingAudio audio) {
    final now = DateTime.now();
    
    // Emit distress detected event
    final distressEvent = DetectedDistress(
      at: now,
      trigger: distress.trigger,
      severity: distress.severity,
    );
    _eventController.add(distressEvent);
    
    // Play calming audio cue
    audio.playLowVolumeCue().then((_) {
      final cueEvent = CuePlayed(now);
      _eventController.add(cueEvent);
      _logEvent('cue_played', {'trigger': distress.trigger, 'severity': distress.severity});
    }).catchError((error) {
      _logEvent('cue_failed', {'error': error.toString()});
    });
    
    // Update state
    _lastCueTime = now;
    _inDistress = true;
    _recoveryStartTime = null;
    
    // Log distress event
    _logEvent('distress_detected', {
      'trigger': distress.trigger,
      'severity': distress.severity,
    });
  }
  
  /// Check if user has recovered from distress
  void _checkRecovery(BioSample sample) {
    final distressResult = _detectDistress(sample);
    
    if (distressResult == null) {
      // No distress detected - start or continue recovery tracking
      _recoveryStartTime ??= sample.at;
      
      final stableDuration = sample.at.difference(_recoveryStartTime!);
      if (stableDuration.compareTo(_config.recoveryWindow) >= 0) {
        // Sufficient stable time - user has recovered
        final recoveredEvent = Recovered(
          at: sample.at,
          stabilizedFor: stableDuration,
        );
        _eventController.add(recoveredEvent);
        
        _inDistress = false;
        _recoveryStartTime = null;
        
        _logEvent('recovered', {'stabilized_for_seconds': stableDuration.inSeconds});
      }
    } else {
      // Still in distress - reset recovery tracking
      _recoveryStartTime = null;
    }
  }
  
  /// Clamp severity score to 0.0-1.0 range
  double _clampSeverity(double raw) => raw.clamp(0.0, 1.0);
  
  /// Log event to sink for persistence/export
  void _logEvent(String type, Map<String, Object?> meta) {
    _sink(NightTerrorEvent(
      at: DateTime.now(),
      type: type,
      meta: meta,
    ));
  }
  
  /// No-op sink for when logging is disabled
  static void _noOpSink(NightTerrorEvent event) {
    // Do nothing
  }
}
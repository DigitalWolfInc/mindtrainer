import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/anxiety/haptic_entrainment.dart';
import 'dart:async';

/// Fake anxiety stream for testing - plays scripted samples
class FakeAnxietyStream implements AnxietyStream {
  final List<AnxietySample> _scriptedSamples;
  final StreamController<AnxietySample> _controller = StreamController<AnxietySample>();
  
  FakeAnxietyStream(this._scriptedSamples);
  
  @override
  Stream<AnxietySample> samples() => _controller.stream;
  
  /// Play all scripted samples with optional delays
  Future<void> playScript({Duration delay = const Duration(milliseconds: 10)}) async {
    for (final sample in _scriptedSamples) {
      _controller.add(sample);
      if (delay.inMilliseconds > 0) {
        await Future.delayed(delay);
      }
    }
  }
  
  /// Add specific sample immediately
  void addSample(AnxietySample sample) {
    _controller.add(sample);
  }
  
  /// Close the stream
  void close() {
    _controller.close();
  }
}

/// Fake haptic motor for testing - records all method calls and timing
class FakeHapticMotor implements HapticMotor {
  final List<({String action, Duration? on, Duration? off, DateTime at})> callLog = [];
  bool _shouldFailPulse = false;
  
  /// Make next pulse call fail for error testing
  void simulatePulseFailure() {
    _shouldFailPulse = true;
  }
  
  @override
  Future<void> pulseOnce(Duration on, Duration off) async {
    callLog.add((action: 'pulseOnce', on: on, off: off, at: DateTime.now()));
    
    if (_shouldFailPulse) {
      _shouldFailPulse = false;
      throw Exception('Haptic motor failure');
    }
    
    // Simulate brief pulse execution time
    await Future.delayed(const Duration(milliseconds: 5));
  }
  
  @override
  Future<void> stop() async {
    callLog.add((action: 'stop', on: null, off: null, at: DateTime.now()));
  }
  
  /// Get all pulse calls
  List<({Duration on, Duration off, DateTime at})> get pulseCalls => 
    callLog.where((call) => call.action == 'pulseOnce')
           .map((call) => (on: call.on!, off: call.off!, at: call.at))
           .toList();
  
  /// Check if stop was called
  bool get wasStopCalled => callLog.any((call) => call.action == 'stop');
  
  /// Get number of pulse calls
  int get pulseCount => pulseCalls.length;
  
  /// Clear call log
  void reset() {
    callLog.clear();
  }
}

void main() {
  group('Haptic Entrainment Controller', () {
    late FakeAnxietyStream anxietyStream;
    late FakeHapticMotor hapticMotor;
    late HapticEntrainmentController controller;
    late List<AnxietyEpisode> loggedEpisodes;
    
    setUp(() {
      anxietyStream = FakeAnxietyStream([]);
      hapticMotor = FakeHapticMotor();
      loggedEpisodes = [];
      
      // Create controller with test configuration
      controller = HapticEntrainmentController(
        config: const EntrainmentConfig(
          hrSpikeThreshold: 1.5,
          hrvDropThreshold: 0.2,
          targetCadenceBpm: 60,
          maxSessionDuration: Duration(minutes: 5), // Shorter for tests
          minRecoveryTime: Duration(seconds: 30),   // Shorter for tests
          debounceWindow: Duration(seconds: 5),     // Shorter for tests
          baselineWindow: Duration(minutes: 2),     // Shorter for tests
          minSamplesForBaseline: 3,
        ),
        sink: (episode) => loggedEpisodes.add(episode),
      );
    });
    
    tearDown(() async {
      await controller.stop();
      anxietyStream.close();
    });
    
    /// Helper to create AnxietySample with default values
    AnxietySample createSample({
      DateTime? at,
      int hr = 70,
      double hrv = 50.0,
    }) {
      return AnxietySample(
        at: at ?? DateTime.now(),
        hr: hr,
        hrv: hrv,
      );
    }
    
    group('Basic Functionality', () {
      test('should start and stop idempotently', () async {
        // Multiple starts should not cause issues
        await controller.start(anxietyStream, hapticMotor);
        await controller.start(anxietyStream, hapticMotor);
        await controller.start(anxietyStream, hapticMotor);
        
        // Multiple stops should not cause issues
        await controller.stop();
        await controller.stop();
        await controller.stop();
        
        // Should not throw
        expect(true, true);
      });
    });
    
    group('HR Spike Triggers', () {
      test('should trigger on HR spike and start pulsing', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        controller.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline with normal HR
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70, // Normal baseline
          ));
          await Future.delayed(const Duration(milliseconds: 20));
        }
        
        // Send HR spike
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95, // Significant spike above baseline
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should trigger entrainment
        expect(events.length, greaterThanOrEqualTo(1));
        expect(events.first, isA<Triggered>());
        
        final triggered = events.first as Triggered;
        expect(triggered.trigger, 'hr_spike');
        expect(triggered.hrValue, 95);
        
        // Should start haptic pulses
        await Future.delayed(const Duration(milliseconds: 200));
        expect(hapticMotor.pulseCount, greaterThan(0));
      });
      
      test('should respect debounce window', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        controller.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // First spike
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Second spike within debounce window (should be ignored)
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 6)),
          hr: 100,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should only have one trigger event
        final triggerEvents = events.whereType<Triggered>();
        expect(triggerEvents.length, 1);
      });
    });
    
    group('HRV Drop Triggers', () {
      test('should trigger on HRV drop', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        controller.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline with normal HRV
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hrv: 50.0, // Normal baseline
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Send HRV drop (20%+ drop triggers)
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hrv: 35.0, // 30% drop from baseline
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(events.length, greaterThanOrEqualTo(1));
        expect(events.first, isA<Triggered>());
        
        final triggered = events.first as Triggered;
        expect(triggered.trigger, 'hrv_drop');
        expect(triggered.hrvValue, 35.0);
        
        expect(hapticMotor.pulseCount, greaterThan(0));
      });
    });
    
    group('Combined HR + HRV Triggers', () {
      test('should trigger on combined HR spike and HRV drop', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        controller.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
            hrv: 50.0,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Send combined spike + drop
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,   // HR spike
          hrv: 35.0, // HRV drop
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(events.first, isA<Triggered>());
        
        final triggered = events.first as Triggered;
        expect(triggered.trigger, 'hr_hrv_combined');
        expect(triggered.hrValue, 95);
        expect(triggered.hrvValue, 35.0);
      });
    });
    
    group('Pulse Cadence', () {
      test('should schedule pulses at expected cadence', () async {
        // Test pulse timing calculation
        final timing60 = EntrainmentConfig.calculatePulseTiming(60);
        expect(timing60.on.inMilliseconds, 500); // 50% of 1000ms
        expect(timing60.off.inMilliseconds, 500);
        
        final timing120 = EntrainmentConfig.calculatePulseTiming(120);
        expect(timing120.on.inMilliseconds, 250); // 50% of 500ms
        expect(timing120.off.inMilliseconds, 250);
        
        // Test with custom duty cycle
        final timing60_30 = EntrainmentConfig.calculatePulseTiming(60, dutyCycle: 0.3);
        expect(timing60_30.on.inMilliseconds, 300); // 30% of 1000ms
        expect(timing60_30.off.inMilliseconds, 700); // 70% of 1000ms
      });
      
      test('should use correct pulse timing in actual session', () async {
        final testController = HapticEntrainmentController(
          config: const EntrainmentConfig(
            targetCadenceBpm: 120, // 2 pulses per second for faster testing
            minSamplesForBaseline: 3,
          ),
        );
        
        await testController.start(anxietyStream, hapticMotor);
        
        final baseTime = DateTime.now();
        
        // Establish baseline and trigger
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,
        ));
        
        // Wait for pulse calls
        await Future.delayed(const Duration(milliseconds: 600));
        
        // Check pulse timing
        expect(hapticMotor.pulseCount, greaterThan(0));
        final firstPulse = hapticMotor.pulseCalls.first;
        expect(firstPulse.on.inMilliseconds, 250); // 120 BPM = 500ms total, 50% = 250ms
        expect(firstPulse.off.inMilliseconds, 250);
        
        await testController.stop();
      });
    });
    
    group('Recovery Detection', () {
      test('should detect recovery after sustained normalization', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        controller.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline and trigger
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Return to normal for recovery period (30 seconds in test config)
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: 6 + i * 8)), // 8 second intervals
            hr: 72, // Normal values
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should have Triggered and Recovered events
        final recoveryEvents = events.whereType<Recovered>();
        expect(recoveryEvents.length, 1);
        
        final recovery = recoveryEvents.first;
        expect(recovery.stabilizedFor.inSeconds, greaterThanOrEqualTo(30));
        expect(recovery.sessionDuration, greaterThan(Duration.zero));
        
        // Should stop haptic motor
        expect(hapticMotor.wasStopCalled, true);
        
        // Should log episode
        expect(loggedEpisodes.length, 1);
        expect(loggedEpisodes.first.maxHr, 95);
      });
      
      test('should reset recovery if anxiety returns', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        controller.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline and trigger
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Partial recovery
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 6)),
          hr: 72,
        ));
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Another anxiety spike (should reset recovery)
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 7)),
          hr: 98,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should not have recovery event yet
        final recoveryEvents = events.whereType<Recovered>();
        expect(recoveryEvents, isEmpty);
      });
    });
    
    group('Max Duration Abort', () {
      test('should abort session after max duration', () async {
        final shortController = HapticEntrainmentController(
          config: const EntrainmentConfig(
            maxSessionDuration: Duration(seconds: 2), // Very short for testing
            minSamplesForBaseline: 3,
          ),
          sink: (episode) => loggedEpisodes.add(episode),
        );
        
        await shortController.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        shortController.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline and trigger
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Continue with anxious values past max duration
        for (int i = 0; i < 3; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: 6 + i)),
            hr: 96, // Still anxious
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should have Triggered and Aborted events
        final abortedEvents = events.whereType<Aborted>();
        expect(abortedEvents.length, 1);
        
        final aborted = abortedEvents.first;
        expect(aborted.reason, 'max_duration');
        expect(aborted.sessionDuration.inSeconds, greaterThanOrEqualTo(2));
        
        expect(hapticMotor.wasStopCalled, true);
        expect(loggedEpisodes.length, 1);
        
        await shortController.stop();
      });
    });
    
    group('Event Stream Integrity', () {
      test('should maintain proper event ordering', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        controller.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Full cycle: baseline → trigger → recovery
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Recovery sequence
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: 6 + i * 8)),
            hr: 71,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Check event ordering
        expect(events.length, greaterThanOrEqualTo(2));
        expect(events.first, isA<Triggered>());
        expect(events.last, isA<Recovered>());
        
        // Check timestamps are ordered
        for (int i = 1; i < events.length; i++) {
          expect(events[i].at.isAfter(events[i-1].at) || 
                 events[i].at.isAtSameMomentAs(events[i-1].at), true);
        }
      });
    });
    
    group('Episode Logging', () {
      test('should log complete episode with correct metrics', () async {
        await controller.start(anxietyStream, hapticMotor);
        
        final baseTime = DateTime.now();
        
        // Baseline and trigger with varying HR/HRV
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
            hrv: 50.0,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Multiple anxious samples with different peaks
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,  // First spike
          hrv: 40.0,
        ));
        await Future.delayed(const Duration(milliseconds: 10));
        
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 6)),
          hr: 102, // Higher spike (should be max)
          hrv: 35.0, // Lower HRV (should be min)
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Recovery
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: 7 + i * 8)),
            hr: 71,
            hrv: 48.0,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Check logged episode
        expect(loggedEpisodes.length, 1);
        final episode = loggedEpisodes.first;
        
        expect(episode.maxHr, 102); // Highest HR during session
        expect(episode.minHrv, 35.0); // Lowest HRV during session
        expect(episode.cadenceBpm, 60); // From config
        expect(episode.duration, greaterThan(Duration(seconds: 30)));
        expect(episode.start.isBefore(episode.end), true);
      });
    });
    
    group('Error Handling', () {
      test('should handle haptic motor failures gracefully', () async {
        hapticMotor.simulatePulseFailure();
        await controller.start(anxietyStream, hapticMotor);
        
        final baseTime = DateTime.now();
        
        // Trigger entrainment
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 95,
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should not crash despite haptic failure
        expect(hapticMotor.pulseCount, greaterThan(0)); // At least attempted
      });
    });
    
    group('Configuration Edge Cases', () {
      test('should require minimum samples before trigger evaluation', () async {
        final strictController = HapticEntrainmentController(
          config: const EntrainmentConfig(minSamplesForBaseline: 10),
        );
        
        await strictController.start(anxietyStream, hapticMotor);
        
        final events = <EntrainmentEvent>[];
        strictController.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Send fewer samples than required
        for (int i = 0; i < 5; i++) {
          anxietyStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Try to trigger
        anxietyStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should not trigger due to insufficient baseline
        expect(events, isEmpty);
        expect(hapticMotor.pulseCount, 0);
        
        await strictController.stop();
      });
    });
  });
}
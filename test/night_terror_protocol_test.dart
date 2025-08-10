import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/sleep/night_terror_protocol.dart';
import 'dart:async';

/// Fake biometric stream for testing - plays scripted samples
class FakeBioStream implements BioStream {
  final List<BioSample> _scriptedSamples;
  final StreamController<BioSample> _controller = StreamController<BioSample>();
  
  FakeBioStream(this._scriptedSamples);
  
  @override
  Stream<BioSample> samples() => _controller.stream;
  
  /// Play all scripted samples with optional delays
  Future<void> playScript({Duration delay = const Duration(milliseconds: 10)}) async {
    for (final sample in _scriptedSamples) {
      _controller.add(sample);
      if (delay.inMilliseconds > 0) {
        await Future.delayed(delay);
      }
    }
  }
  
  /// Play specific sample immediately
  void addSample(BioSample sample) {
    _controller.add(sample);
  }
  
  /// Close the stream
  void close() {
    _controller.close();
  }
}

/// Fake calming audio for testing - records all method calls
class FakeAudio implements CalmingAudio {
  final List<String> callLog = [];
  bool _shouldFailPlayback = false;
  
  /// Make next playback call fail for error testing
  void simulatePlaybackFailure() {
    _shouldFailPlayback = true;
  }
  
  @override
  Future<void> playLowVolumeCue() async {
    callLog.add('playLowVolumeCue');
    if (_shouldFailPlayback) {
      _shouldFailPlayback = false;
      throw Exception('Audio playback failed');
    }
    // Simulate brief playback time
    await Future.delayed(const Duration(milliseconds: 50));
  }
  
  @override
  Future<void> stop() async {
    callLog.add('stop');
  }
  
  /// Check if play was called
  bool get wasPlayCalled => callLog.contains('playLowVolumeCue');
  
  /// Get number of play calls
  int get playCallCount => callLog.where((call) => call == 'playLowVolumeCue').length;
  
  /// Clear call log
  void reset() {
    callLog.clear();
  }
}

void main() {
  group('Night Terror Protocol', () {
    late FakeBioStream bioStream;
    late FakeAudio audio;
    late NightTerrorProtocol protocol;
    late List<NightTerrorEvent> loggedEvents;
    
    setUp(() {
      bioStream = FakeBioStream([]);
      audio = FakeAudio();
      loggedEvents = [];
      
      // Create protocol with test sink
      protocol = NightTerrorProtocol(
        config: const NightTerrorConfig(
          slidingWindow: Duration(minutes: 5),
          cooldownPeriod: Duration(minutes: 10),
          recoveryWindow: Duration(minutes: 2),
          minSamplesForBaseline: 3,
        ),
        sink: (event) => loggedEvents.add(event),
      );
    });
    
    tearDown(() async {
      await protocol.stop();
      bioStream.close();
    });
    
    /// Helper to create BioSample with default values
    BioSample createSample({
      DateTime? at,
      int hr = 70,
      double hrv = 50.0,
      double motion = 0.1,
      SleepStage stage = SleepStage.nrem,
    }) {
      return BioSample(
        at: at ?? DateTime.now(),
        hr: hr,
        hrv: hrv,
        motion: motion,
        stage: stage,
      );
    }
    
    group('Basic Functionality', () {
      test('should ignore samples when stage is not NREM', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        // Send samples in non-NREM stages
        bioStream.addSample(createSample(stage: SleepStage.wake, hr: 120)); // High HR
        bioStream.addSample(createSample(stage: SleepStage.rem, hr: 120));  // High HR
        bioStream.addSample(createSample(stage: SleepStage.unknown, hr: 120)); // High HR
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(events, isEmpty);
        expect(audio.wasPlayCalled, false);
        expect(loggedEvents.where((e) => e.type == 'distress_detected'), isEmpty);
      });
      
      test('should start and stop idempotently', () async {
        // Multiple starts should not cause issues
        await protocol.start(bioStream, audio);
        await protocol.start(bioStream, audio);
        await protocol.start(bioStream, audio);
        
        expect(loggedEvents.where((e) => e.type == 'started').length, 1);
        
        // Multiple stops should not cause issues
        await protocol.stop();
        await protocol.stop();
        await protocol.stop();
        
        expect(loggedEvents.where((e) => e.type == 'stopped').length, 1);
      });
    });
    
    group('Heart Rate Spike Detection', () {
      test('should detect distress on HR spike and play cue once', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline with normal HR
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70, // Normal baseline
          ));
          await Future.delayed(const Duration(milliseconds: 20));
        }
        
        // Send HR spike
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120, // Significant spike
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should detect distress and play cue
        expect(events.length, 2);
        expect(events[0], isA<DetectedDistress>());
        expect(events[1], isA<CuePlayed>());
        
        final distress = events[0] as DetectedDistress;
        expect(distress.trigger, 'hr_spike');
        expect(distress.severity, greaterThan(0.0));
        
        expect(audio.playCallCount, 1);
        expect(loggedEvents.where((e) => e.type == 'distress_detected').length, 1);
        expect(loggedEvents.where((e) => e.type == 'cue_played').length, 1);
      });
      
      test('should respect cooldown period - no second cue', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // First HR spike
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Second HR spike within cooldown (should be ignored)
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 6)),
          hr: 130,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should only have first distress detection
        final distressEvents = events.whereType<DetectedDistress>();
        expect(distressEvents.length, 1);
        expect(audio.playCallCount, 1);
      });
    });
    
    group('HRV Drop Detection', () {
      test('should detect distress on HRV drop', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline with normal HRV
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hrv: 50.0, // Normal baseline
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Send HRV drop (30%+ drop triggers distress)
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hrv: 30.0, // 40% drop from baseline of 50
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(events.length, 2);
        expect(events[0], isA<DetectedDistress>());
        
        final distress = events[0] as DetectedDistress;
        expect(distress.trigger, 'hrv_drop');
        expect(distress.severity, greaterThan(0.0));
        
        expect(audio.playCallCount, 1);
      });
    });
    
    group('Motion Spike Detection', () {
      test('should detect distress on motion spike', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline with low motion
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            motion: 0.1, // Low baseline motion
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Send motion spike
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          motion: 1.0, // Significant spike above baseline
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        expect(events.length, 2);
        expect(events[0], isA<DetectedDistress>());
        
        final distress = events[0] as DetectedDistress;
        expect(distress.trigger, 'motion_spike');
        expect(distress.severity, greaterThan(0.0));
        
        expect(audio.playCallCount, 1);
      });
    });
    
    group('Recovery Detection', () {
      test('should detect recovery after sustained normalization', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Trigger distress
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Return to normal values for recovery window duration (2 minutes in config)
        for (int i = 0; i < 10; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: 6 + i * 15)), // 15 second intervals
            hr: 72, // Normal values
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Should have DetectedDistress, CuePlayed, and Recovered
        await Future.delayed(const Duration(milliseconds: 100));
        
        final recoveryEvents = events.whereType<Recovered>();
        expect(recoveryEvents.length, 1);
        
        final recovery = recoveryEvents.first;
        expect(recovery.stabilizedFor.inMinutes, greaterThanOrEqualTo(2));
        
        expect(loggedEvents.where((e) => e.type == 'recovered').length, 1);
      });
      
      test('should reset recovery tracking if distress resumes', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Trigger distress
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Partial recovery (less than required window)
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 6)),
          hr: 72,
        ));
        await Future.delayed(const Duration(milliseconds: 10));
        
        // Another distress spike (should reset recovery)
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 7)),
          hr: 125,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should not have recovery event yet
        final recoveryEvents = events.whereType<Recovered>();
        expect(recoveryEvents, isEmpty);
      });
    });
    
    group('Event Ordering and Logging', () {
      test('should maintain correct event stream ordering', () async {
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Trigger distress
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Check event ordering
        expect(events.length, 2);
        expect(events[0], isA<DetectedDistress>());
        expect(events[1], isA<CuePlayed>());
        
        // Check that DetectedDistress comes before CuePlayed
        expect(events[0].at.isBefore(events[1].at) || events[0].at.isAtSameMomentAs(events[1].at), true);
      });
      
      test('should log exact events to sink', () async {
        await protocol.start(bioStream, audio);
        
        final baseTime = DateTime.now();
        
        // Establish baseline and trigger distress
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify logged events
        final startedEvents = loggedEvents.where((e) => e.type == 'started');
        final distressEvents = loggedEvents.where((e) => e.type == 'distress_detected');
        final cueEvents = loggedEvents.where((e) => e.type == 'cue_played');
        
        expect(startedEvents.length, 1);
        expect(distressEvents.length, 1);
        expect(cueEvents.length, 1);
        
        // Check distress event metadata
        final distressEvent = distressEvents.first;
        expect(distressEvent.meta['trigger'], 'hr_spike');
        expect(distressEvent.meta['severity'], isA<double>());
        expect(distressEvent.meta['severity'], greaterThan(0.0));
      });
    });
    
    group('Error Handling', () {
      test('should handle audio playback failures gracefully', () async {
        audio.simulatePlaybackFailure();
        await protocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        protocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Establish baseline and trigger distress
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Should still detect distress even if audio fails
        expect(events.whereType<DetectedDistress>().length, 1);
        
        // Should log audio failure
        final failureEvents = loggedEvents.where((e) => e.type == 'cue_failed');
        expect(failureEvents.length, 1);
      });
      
      test('should handle stream close safety', () async {
        await protocol.start(bioStream, audio);
        
        // Close stream while protocol is running
        bioStream.close();
        
        // Should not throw when stopping
        expect(() async => await protocol.stop(), returnsNormally);
      });
    });
    
    group('Configuration Edge Cases', () {
      test('should require minimum samples before detection', () async {
        // Use config with higher minimum samples requirement
        final strictProtocol = NightTerrorProtocol(
          config: const NightTerrorConfig(minSamplesForBaseline: 10),
          sink: (event) => loggedEvents.add(event),
        );
        
        await strictProtocol.start(bioStream, audio);
        
        final events = <ProtocolEvent>[];
        strictProtocol.events().listen(events.add);
        
        final baseTime = DateTime.now();
        
        // Send fewer samples than required minimum
        for (int i = 0; i < 5; i++) {
          bioStream.addSample(createSample(
            at: baseTime.add(Duration(seconds: i)),
            hr: 70,
          ));
          await Future.delayed(const Duration(milliseconds: 10));
        }
        
        // Send what would normally trigger distress
        bioStream.addSample(createSample(
          at: baseTime.add(const Duration(seconds: 5)),
          hr: 120,
        ));
        
        await Future.delayed(const Duration(milliseconds: 50));
        
        // Should not detect distress due to insufficient baseline
        expect(events, isEmpty);
        expect(audio.wasPlayCalled, false);
        
        await strictProtocol.stop();
      });
    });
  });
}
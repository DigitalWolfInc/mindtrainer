import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/analytics/engagement_analytics.dart';
import 'package:mindtrainer/core/storage/local_storage.dart';
import 'package:mindtrainer/features/breathing/domain/breathing_pattern.dart';
import 'package:mindtrainer/features/breathing/domain/breathing_service.dart';

/// Comprehensive tests for breathing patterns functionality
void main() {
  group('Breathing Patterns', () {
    group('BreathingPatternConfig', () {
      test('should calculate cycle duration correctly', () {
        const pattern = BreathingPatternConfig(
          type: BreathingPatternType.fourSevenEight,
          name: 'Test Pattern',
          description: 'Test',
          benefits: 'Test benefits',
          inhaleDuration: 4,
          holdDuration: 7,
          exhaleDuration: 8,
          pauseDuration: 2,
          totalCycles: 5,
          isProFeature: false,
        );
        
        expect(pattern.cycleDuration, equals(21)); // 4+7+8+2
        expect(pattern.totalDuration, equals(105)); // 21*5
      });
      
      test('should format duration text correctly', () {
        const shortPattern = BreathingPatternConfig(
          type: BreathingPatternType.boxBreathing,
          name: 'Short',
          description: 'Test',
          benefits: 'Test',
          inhaleDuration: 4,
          holdDuration: 4,
          exhaleDuration: 4,
          pauseDuration: 4,
          totalCycles: 2, // 32 seconds total
          isProFeature: true,
        );
        
        const longPattern = BreathingPatternConfig(
          type: BreathingPatternType.progressiveRelaxation,
          name: 'Long',
          description: 'Test',
          benefits: 'Test',
          inhaleDuration: 6,
          holdDuration: 2,
          exhaleDuration: 8,
          pauseDuration: 2,
          totalCycles: 10, // 180 seconds = 3 minutes
          isProFeature: true,
        );
        
        expect(shortPattern.durationText, equals('0:32'));
        expect(longPattern.durationText, equals('3min'));
      });
      
      test('should format ratio text correctly', () {
        const withPause = BreathingPatterns.boxBreathing;
        const withoutPause = BreathingPatterns.fourSevenEight;
        
        expect(withPause.ratioText, equals('4:4:4:4'));
        expect(withoutPause.ratioText, equals('4:7:8'));
      });
    });
    
    group('BreathingPatterns', () {
      test('should provide correct pattern configurations', () {
        expect(BreathingPatterns.fourSevenEight.type, BreathingPatternType.fourSevenEight);
        expect(BreathingPatterns.fourSevenEight.isProFeature, false);
        
        expect(BreathingPatterns.boxBreathing.type, BreathingPatternType.boxBreathing);
        expect(BreathingPatterns.boxBreathing.isProFeature, true);
        
        expect(BreathingPatterns.energizing.type, BreathingPatternType.energizing);
        expect(BreathingPatterns.energizing.isProFeature, true);
        
        expect(BreathingPatterns.progressiveRelaxation.type, BreathingPatternType.progressiveRelaxation);
        expect(BreathingPatterns.progressiveRelaxation.isProFeature, true);
      });
      
      test('should categorize patterns correctly', () {
        final allPatterns = BreathingPatterns.getAllPatterns();
        final freePatterns = BreathingPatterns.getFreePatterns();
        final proPatterns = BreathingPatterns.getProPatterns();
        
        expect(allPatterns.length, equals(4));
        expect(freePatterns.length, equals(1));
        expect(proPatterns.length, equals(3));
        
        expect(freePatterns.first.type, BreathingPatternType.fourSevenEight);
        expect(proPatterns.map((p) => p.type), containsAll([
          BreathingPatternType.boxBreathing,
          BreathingPatternType.energizing,
          BreathingPatternType.progressiveRelaxation,
        ]));
      });
      
      test('should find patterns by type', () {
        final pattern = BreathingPatterns.getPattern(BreathingPatternType.boxBreathing);
        expect(pattern?.name, equals('Box Breathing'));
        
        final nullPattern = BreathingPatterns.getPattern(null as dynamic);
        expect(nullPattern, isNull);
      });
    });
    
    group('BreathingSessionController', () {
      late BreathingSessionController controller;
      
      setUp(() {
        controller = BreathingSessionController(BreathingPatterns.fourSevenEight);
      });
      
      tearDown(() {
        controller.dispose();
      });
      
      test('should initialize with correct initial state', () {
        final state = controller.currentState;
        
        expect(state.currentPhase, BreathingPhase.inhale);
        expect(state.currentCycle, 1);
        expect(state.totalCycles, 8);
        expect(state.phaseTimeRemaining, 4);
        expect(state.progress, 0.0);
        expect(state.isCompleted, false);
      });
      
      test('should provide state stream', () {
        expect(controller.stateStream, isA<Stream<BreathingSessionState>>());
      });
      
      test('should handle start/pause/resume/stop correctly', () {
        expect(controller.isRunning, false);
        expect(controller.isPaused, false);
        
        controller.start();
        expect(controller.isRunning, true);
        expect(controller.isPaused, false);
        
        controller.pause();
        expect(controller.isRunning, false);
        expect(controller.isPaused, true);
        
        controller.resume();
        expect(controller.isRunning, true);
        expect(controller.isPaused, false);
        
        controller.stop();
        expect(controller.isRunning, false);
        expect(controller.isPaused, false);
      });
      
      test('should complete session manually', () {
        controller.complete();
        
        final state = controller.currentState;
        expect(state.isCompleted, true);
        expect(state.progress, 1.0);
        expect(state.totalTimeRemaining, 0);
        expect(controller.isRunning, false);
      });
      
      test('should handle multiple start calls safely', () {
        controller.start();
        final firstRunning = controller.isRunning;
        
        controller.start(); // Second call should be ignored
        expect(controller.isRunning, equals(firstRunning));
      });
      
      test('should handle dispose safely', () {
        controller.start();
        controller.dispose();
        
        expect(controller.isRunning, false);
        expect(() => controller.start(), returnsNormally);
      });
    });
    
    group('BreathingSessionState', () {
      test('should provide correct instruction text', () {
        const inhaleState = BreathingSessionState(
          currentPhase: BreathingPhase.inhale,
          currentCycle: 1,
          totalCycles: 5,
          phaseTimeRemaining: 3,
          totalTimeRemaining: 60,
          progress: 0.1,
          isCompleted: false,
        );
        
        const holdState = BreathingSessionState(
          currentPhase: BreathingPhase.hold,
          currentCycle: 1,
          totalCycles: 5,
          phaseTimeRemaining: 5,
          totalTimeRemaining: 55,
          progress: 0.2,
          isCompleted: false,
        );
        
        const exhaleState = BreathingSessionState(
          currentPhase: BreathingPhase.exhale,
          currentCycle: 1,
          totalCycles: 5,
          phaseTimeRemaining: 6,
          totalTimeRemaining: 45,
          progress: 0.3,
          isCompleted: false,
        );
        
        const pauseState = BreathingSessionState(
          currentPhase: BreathingPhase.pause,
          currentCycle: 1,
          totalCycles: 5,
          phaseTimeRemaining: 2,
          totalTimeRemaining: 35,
          progress: 0.4,
          isCompleted: false,
        );
        
        expect(inhaleState.instructionText, equals('Breathe in slowly...'));
        expect(holdState.instructionText, equals('Hold your breath...'));
        expect(exhaleState.instructionText, equals('Breathe out slowly...'));
        expect(pauseState.instructionText, equals('Natural pause...'));
      });
      
      test('should format time remaining correctly', () {
        const state1 = BreathingSessionState(
          currentPhase: BreathingPhase.inhale,
          currentCycle: 1,
          totalCycles: 5,
          phaseTimeRemaining: 3,
          totalTimeRemaining: 65, // 1:05
          progress: 0.1,
          isCompleted: false,
        );
        
        const state2 = BreathingSessionState(
          currentPhase: BreathingPhase.exhale,
          currentCycle: 3,
          totalCycles: 5,
          phaseTimeRemaining: 2,
          totalTimeRemaining: 8, // 0:08
          progress: 0.8,
          isCompleted: false,
        );
        
        expect(state1.timeRemainingText, equals('1:05'));
        expect(state2.timeRemainingText, equals('0:08'));
      });
    });
  });
  
  group('BreathingService', () {
    late MockProGates mockProGates;
    late MockAnalytics mockAnalytics;
    late MockStorage mockStorage;
    late BreathingService service;
    
    setUp(() {
      mockProGates = MockProGates();
      mockAnalytics = MockAnalytics();
      mockStorage = MockStorage();
      service = BreathingService(mockProGates, mockAnalytics, mockStorage);
    });
    
    tearDown(() async {
      await service.disposeAll();
    });
    
    group('Pattern Access Control', () {
      test('should allow access to free patterns for free users', () {
        mockProGates.setProStatus(false);
        
        final result = service.checkPatternAccess(BreathingPatternType.fourSevenEight);
        
        expect(result.canAccess, true);
        expect(result.requiresUpgrade, false);
        expect(result.pattern?.type, BreathingPatternType.fourSevenEight);
      });
      
      test('should block access to Pro patterns for free users', () {
        mockProGates.setProStatus(false);
        
        final result = service.checkPatternAccess(BreathingPatternType.boxBreathing);
        
        expect(result.canAccess, false);
        expect(result.requiresUpgrade, true);
        expect(result.pattern?.type, BreathingPatternType.boxBreathing);
      });
      
      test('should allow access to all patterns for Pro users', () {
        mockProGates.setProStatus(true);
        
        final freeResult = service.checkPatternAccess(BreathingPatternType.fourSevenEight);
        final proResult = service.checkPatternAccess(BreathingPatternType.boxBreathing);
        
        expect(freeResult.canAccess, true);
        expect(proResult.canAccess, true);
        expect(freeResult.requiresUpgrade, false);
        expect(proResult.requiresUpgrade, false);
      });
      
      test('should return not found for invalid pattern types', () {
        final result = service.checkPatternAccess(null as dynamic);
        expect(result.canAccess, false);
        expect(result.requiresUpgrade, false);
        expect(result.pattern, isNull);
      });
    });
    
    group('Pattern Lists', () {
      test('should return correct patterns for free users', () {
        mockProGates.setProStatus(false);
        
        final available = service.getAvailablePatterns();
        final locked = service.getLockedPatterns();
        
        expect(available.length, equals(1));
        expect(available.first.type, BreathingPatternType.fourSevenEight);
        expect(locked.length, equals(3));
        expect(locked.map((p) => p.type), containsAll([
          BreathingPatternType.boxBreathing,
          BreathingPatternType.energizing,
          BreathingPatternType.progressiveRelaxation,
        ]));
      });
      
      test('should return all patterns for Pro users', () {
        mockProGates.setProStatus(true);
        
        final available = service.getAvailablePatterns();
        final locked = service.getLockedPatterns();
        
        expect(available.length, equals(4));
        expect(locked.length, equals(0));
      });
    });
    
    group('Session Management', () {
      test('should create breathing session for allowed patterns', () async {
        mockProGates.setProStatus(false);
        
        final controller = await service.startBreathingSession(BreathingPatternType.fourSevenEight);
        
        expect(controller, isNotNull);
        expect(controller!.currentState.currentPhase, BreathingPhase.inhale);
        expect(mockAnalytics.trackedEvents.length, equals(1));
        expect(mockAnalytics.trackedEvents.first['action'], equals('started'));
      });
      
      test('should not create session for blocked patterns', () async {
        mockProGates.setProStatus(false);
        
        final controller = await service.startBreathingSession(BreathingPatternType.boxBreathing);
        
        expect(controller, isNull);
        expect(mockAnalytics.trackedEvents.length, equals(1));
        expect(mockAnalytics.trackedEvents.first['action'], equals('blocked'));
      });
      
      test('should track active sessions correctly', () async {
        mockProGates.setProStatus(true);
        
        final controller = await service.startBreathingSession(BreathingPatternType.boxBreathing);
        expect(controller, isNotNull);
        
        final activeController = service.getActiveSession(BreathingPatternType.boxBreathing);
        expect(activeController, equals(controller));
        
        final nonActiveController = service.getActiveSession(BreathingPatternType.energizing);
        expect(nonActiveController, isNull);
      });
      
      test('should complete sessions and record results', () async {
        mockProGates.setProStatus(true);
        
        final controller = await service.startBreathingSession(BreathingPatternType.boxBreathing);
        expect(controller, isNotNull);
        
        final result = BreathingSessionResult(
          patternType: BreathingPatternType.boxBreathing,
          startTime: DateTime.now().subtract(const Duration(minutes: 5)),
          endTime: DateTime.now(),
          totalCycles: 10,
          completedCycles: 8,
          wasCompleted: false,
          durationSeconds: 300,
        );
        
        await service.completeBreathingSession(BreathingPatternType.boxBreathing, result);
        
        // Should dispose controller
        final activeController = service.getActiveSession(BreathingPatternType.boxBreathing);
        expect(activeController, isNull);
        
        // Should track completion
        final completionEvents = mockAnalytics.trackedEvents
            .where((e) => e['action'] == 'completed')
            .toList();
        expect(completionEvents.length, equals(1));
        expect(completionEvents.first['completion_rate'], equals(0.8));
      });
    });
    
    group('Analytics and History', () {
      test('should track locked pattern views', () async {
        mockProGates.setProStatus(false);
        
        await service.trackLockedPatternView(BreathingPatternType.boxBreathing);
        
        expect(mockAnalytics.trackedEvents.length, equals(1));
        expect(mockAnalytics.trackedEvents.first['action'], equals('locked_viewed'));
        expect(mockAnalytics.trackedEvents.first['pattern_type'], equals('boxBreathing'));
      });
      
      test('should not track locked views for Pro users', () async {
        mockProGates.setProStatus(true);
        
        await service.trackLockedPatternView(BreathingPatternType.boxBreathing);
        
        expect(mockAnalytics.trackedEvents.length, equals(0));
      });
      
      test('should calculate breathing stats correctly', () async {
        // Mock session history
        mockStorage.setMockData('breathing_session_history', _createMockHistory());
        
        final stats = await service.getBreathingStats(limitDays: 30);
        
        expect(stats['total_sessions'], equals(3));
        expect(stats['completed_sessions'], equals(2));
        expect(stats['completion_rate'], closeTo(0.67, 0.01));
        expect(stats['favorite_pattern'], equals('boxBreathing'));
        expect(stats['streak_days'], greaterThanOrEqualTo(0));
      });
      
      test('should filter session history correctly', () async {
        mockStorage.setMockData('breathing_session_history', _createMockHistory());
        
        final allHistory = await service.getSessionHistory();
        final filteredHistory = await service.getSessionHistory(
          filterType: BreathingPatternType.boxBreathing,
        );
        
        expect(allHistory.length, equals(3));
        expect(filteredHistory.length, equals(2));
        expect(filteredHistory.every((h) => h.patternType == BreathingPatternType.boxBreathing), true);
      });
    });
  });
  
  group('BreathingSessionResult', () {
    test('should calculate completion rate correctly', () {
      final result = BreathingSessionResult(
        patternType: BreathingPatternType.boxBreathing,
        startTime: DateTime.now(),
        totalCycles: 10,
        completedCycles: 7,
        wasCompleted: false,
        durationSeconds: 300,
      );
      
      expect(result.completionRate, equals(0.7));
      expect(result.isSuccessful, false); // <75%
    });
    
    test('should calculate effectiveness score correctly', () {
      final completed = BreathingSessionResult(
        patternType: BreathingPatternType.boxBreathing,
        startTime: DateTime.now(),
        totalCycles: 10,
        completedCycles: 10,
        wasCompleted: true,
        durationSeconds: 300,
      );
      
      final mostlyCompleted = BreathingSessionResult(
        patternType: BreathingPatternType.boxBreathing,
        startTime: DateTime.now(),
        totalCycles: 10,
        completedCycles: 9,
        wasCompleted: false,
        durationSeconds: 270,
      );
      
      final halfCompleted = BreathingSessionResult(
        patternType: BreathingPatternType.boxBreathing,
        startTime: DateTime.now(),
        totalCycles: 10,
        completedCycles: 5,
        wasCompleted: false,
        durationSeconds: 150,
      );
      
      expect(completed.effectivenessScore, equals(100));
      expect(mostlyCompleted.effectivenessScore, equals(85));
      expect(halfCompleted.effectivenessScore, equals(50));
    });
  });
}

// Mock classes for testing

class MockProGates implements MindTrainerProGates {
  bool _isProActive = false;
  
  void setProStatus(bool isActive) {
    _isProActive = isActive;
  }
  
  @override
  bool get isProActive => _isProActive;
  
  @override
  int get dailySessionLimit => _isProActive ? -1 : 5;
  
  @override
  bool canStartSession(int currentSessionCount) {
    if (_isProActive) return true;
    return currentSessionCount < 5;
  }
  
  // Implement other required methods with defaults
  @override
  String get proStatus => _isProActive ? 'active' : 'inactive';
  
  @override
  bool get hasPurchasedPro => _isProActive;
  
  @override
  DateTime? get proExpiryDate => _isProActive ? DateTime.now().add(const Duration(days: 365)) : null;
  
  @override
  String? get activeSubscriptionId => _isProActive ? 'mock_subscription_id' : null;
}

class MockAnalytics implements EngagementAnalytics {
  final List<Map<String, dynamic>> trackedEvents = [];
  
  @override
  Future<void> trackProFeatureUsage(
    ProFeatureCategory feature, {
    required String action,
    Map<String, dynamic>? properties,
  }) async {
    trackedEvents.add({
      'feature': feature.name,
      'action': action,
      ...properties ?? {},
    });
  }
  
  // Implement other required methods with no-ops
  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> dispose() async {}
  
  @override
  Stream<EngagementAnalyticsEvent> get eventStream => const Stream.empty();
  
  @override
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {}
  
  @override
  Future<void> trackOnboardingStep(OnboardingStep step, {Map<String, dynamic>? properties}) async {}
  
  @override
  Future<void> trackPurchaseFunnelStep(PurchaseFunnelStep step, {Map<String, dynamic>? properties}) async {}
  
  @override
  Future<void> trackEngagementLevelChange(EngagementLevel fromLevel, EngagementLevel toLevel) async {}
  
  @override
  Future<void> setUserProperties(Map<String, dynamic> properties) async {}
  
  @override
  Future<void> trackPerformanceMetric(String metricName, double value, {String? unit, Map<String, dynamic>? properties}) async {}
  
  @override
  Future<FunnelAnalysis> analyzeOnboardingFunnel({DateTime? since}) async {
    return FunnelAnalysis(
      funnelName: 'onboarding',
      steps: [],
      stepCounts: {},
      conversionRates: {},
    );
  }
  
  @override
  Future<FunnelAnalysis> analyzePurchaseFunnel({DateTime? since}) async {
    return FunnelAnalysis(
      funnelName: 'purchase',
      steps: [],
      stepCounts: {},
      conversionRates: {},
    );
  }
  
  @override
  Future<Map<String, dynamic>> getProFeatureAnalytics({DateTime? since}) async {
    return {};
  }
  
  @override
  Future<Map<String, dynamic>> getPerformanceMetrics({DateTime? since}) async {
    return {};
  }
}

class MockStorage implements LocalStorage {
  final Map<String, String> _data = {};
  
  void setMockData(String key, String value) {
    _data[key] = value;
  }
  
  @override
  Future<String?> getString(String key) async {
    return _data[key];
  }
  
  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }
  
  @override
  Future<int?> getInt(String key) async {
    final value = _data[key];
    return value != null ? int.tryParse(value) : null;
  }
  
  @override
  Future<void> setInt(String key, int value) async {
    _data[key] = value.toString();
  }
  
  @override
  Future<bool?> getBool(String key) async {
    final value = _data[key];
    return value != null ? value.toLowerCase() == 'true' : null;
  }
  
  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value.toString();
  }
  
  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }
  
  @override
  Future<void> clear() async {
    _data.clear();
  }
}

String _createMockHistory() {
  final now = DateTime.now();
  final history = [
    {
      'patternType': 'boxBreathing',
      'startTime': now.subtract(const Duration(days: 1)).toIso8601String(),
      'totalCycles': 10,
      'completedCycles': 10,
      'wasCompleted': true,
      'durationSeconds': 400,
      'metadata': {},
    },
    {
      'patternType': 'boxBreathing',
      'startTime': now.subtract(const Duration(days: 2)).toIso8601String(),
      'totalCycles': 8,
      'completedCycles': 6,
      'wasCompleted': false,
      'durationSeconds': 240,
      'metadata': {},
    },
    {
      'patternType': 'fourSevenEight',
      'startTime': now.subtract(const Duration(days: 3)).toIso8601String(),
      'totalCycles': 8,
      'completedCycles': 8,
      'wasCompleted': true,
      'durationSeconds': 152,
      'metadata': {},
    },
  ];
  
  return json.encode(history);
}
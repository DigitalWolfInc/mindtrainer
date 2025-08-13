/// Tests for Focus Mode Service
/// 
/// Validates Pro gating, session management, and breathing pattern functionality.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/storage/local_storage.dart';
import 'package:mindtrainer/features/focus_modes/domain/focus_environment.dart';
import 'package:mindtrainer/features/focus_modes/application/focus_mode_service.dart';

class MockLocalStorage implements LocalStorage {
  final Map<String, String> _storage = {};
  
  @override
  Future<String?> getString(String key) async => _storage[key];
  
  @override
  Future<void> setString(String key, String value) async => _storage[key] = value;
  
  static Map<String, dynamic>? parseJson(String json) => {};
  static String encodeJson(Object obj) => '{}';
}

class MockProGates implements MindTrainerProGates {
  final bool _isProActive;
  
  MockProGates(this._isProActive);
  
  @override
  bool get isProActive => _isProActive;
  
  // Stub implementations for other required members
  @override
  bool get unlimitedDailySessions => _isProActive;
  @override
  int get dailySessionLimit => _isProActive ? -1 : 5;
  @override
  bool canStartSession(int todaysSessionCount) => _isProActive || todaysSessionCount < 5;
  @override
  bool get extendedCoachingPhases => _isProActive;
  @override
  bool isCoachPhaseAvailable(dynamic phase) => _isProActive;
  @override
  bool get advancedAnalytics => _isProActive;
  @override
  bool get moodFocusCorrelations => _isProActive;
  @override
  bool get tagAssociations => _isProActive;
  @override
  bool get keywordUplift => _isProActive;
  @override
  bool get extendedInsightsHistory => _isProActive;
  @override
  int get insightsHistoryDays => _isProActive ? -1 : 30;
  @override
  bool get dataExport => _isProActive;
  @override
  bool get dataImport => _isProActive;
  @override
  bool get dataPortability => _isProActive;
  @override
  bool get customGoals => _isProActive;
  @override
  bool get multipleGoals => _isProActive;
  @override
  bool get advancedGoalTracking => _isProActive;
  @override
  bool get adFree => _isProActive;
  @override
  bool get premiumThemes => _isProActive;
  @override
  bool get prioritySupport => _isProActive;
  @override
  bool get smartSessionScheduling => _isProActive;
  @override
  bool get voiceJournalInsights => _isProActive;
  @override
  bool get communityChallengePro => _isProActive;
  @override
  bool get advancedGoalTemplates => _isProActive;
  @override
  bool get environmentPresets => _isProActive;
  @override
  bool get biometricIntegration => _isProActive;
  @override
  bool get progressSharingExport => _isProActive;
  @override
  bool get cloudBackupSync => _isProActive;
  @override
  List<ProFeature> get availableFeatures => _isProActive ? ProFeature.values : [];
  @override
  List<ProFeature> get lockedFeatures => _isProActive ? [] : ProFeature.values;
}

void main() {
  group('Focus Mode Service', () {
    late MockLocalStorage mockStorage;
    late FocusModeService service;
    
    setUp(() {
      mockStorage = MockLocalStorage();
    });
    
    tearDown(() {
      service.dispose();
    });
    
    group('Pro Gating', () {
      test('Free user can only access free environments', () {
        final proGates = MockProGates(false);
        service = FocusModeService(proGates, mockStorage);
        
        final availableEnvironments = service.getAvailableEnvironments();
        
        // Should only have free environments
        expect(availableEnvironments.length, 3);
        expect(availableEnvironments.every((config) => !config.isProOnly), true);
        expect(availableEnvironments.map((e) => e.environment), containsAll([
          FocusEnvironment.silence,
          FocusEnvironment.whiteNoise,
          FocusEnvironment.rain,
        ]));
      });
      
      test('Pro user can access all environments', () {
        final proGates = MockProGates(true);
        service = FocusModeService(proGates, mockStorage);
        
        final availableEnvironments = service.getAvailableEnvironments();
        
        // Should have all environments
        expect(availableEnvironments.length, FocusEnvironmentConfig.environments.length);
        expect(availableEnvironments.any((config) => config.isProOnly), true);
      });
      
      test('Free user cannot start Pro environment session', () async {
        final proGates = MockProGates(false);
        service = FocusModeService(proGates, mockStorage);
        
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.forest, // Pro environment
          sessionDurationMinutes: 10,
        );
        
        final success = await service.startSession(config);
        expect(success, false);
      });
      
      test('Pro user can start Pro environment session', () async {
        final proGates = MockProGates(true);
        service = FocusModeService(proGates, mockStorage);
        
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest, // Pro environment
          sessionDurationMinutes: 10,
        );
        
        final success = await service.startSession(config);
        expect(success, true);
        expect(service.state, FocusSessionState.focusing);
      });
    });
    
    group('Session Management', () {
      test('Basic session starts in focusing state', () async {
        final proGates = MockProGates(false);
        service = FocusModeService(proGates, mockStorage);
        
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 5,
        );
        
        final success = await service.startSession(config);
        expect(success, true);
        expect(service.state, FocusSessionState.focusing);
      });
      
      test('Pro session with breathing starts in breathing state', () async {
        final proGates = MockProGates(true);
        service = FocusModeService(proGates, mockStorage);
        
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.ocean,
          sessionDurationMinutes: 10,
          breathingPattern: BreathingPattern.patterns.first,
          enableBreathingCues: true,
        );
        
        final success = await service.startSession(config);
        expect(success, true);
        expect(service.state, FocusSessionState.breathing);
      });
      
      test('Session can be paused and resumed', () async {
        final proGates = MockProGates(false);
        service = FocusModeService(proGates, mockStorage);
        
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.whiteNoise,
          sessionDurationMinutes: 5,
        );
        
        await service.startSession(config);
        expect(service.state, FocusSessionState.focusing);
        
        service.pauseSession();
        expect(service.state, FocusSessionState.paused);
        
        service.resumeSession();
        expect(service.state, FocusSessionState.focusing);
      });
      
      test('Cannot start session when one is already active', () async {
        final proGates = MockProGates(false);
        service = FocusModeService(proGates, mockStorage);
        
        final config1 = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 5,
        );
        
        final config2 = FocusSessionConfig.basic(
          environment: FocusEnvironment.rain,
          sessionDurationMinutes: 10,
        );
        
        final success1 = await service.startSession(config1);
        expect(success1, true);
        
        final success2 = await service.startSession(config2);
        expect(success2, false);
      });
      
      test('Session outcome is recorded correctly', () async {
        final proGates = MockProGates(true);
        service = FocusModeService(proGates, mockStorage);
        
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 5,
          breathingPattern: BreathingPattern.patterns.first,
          enableBreathingCues: true,
        );
        
        await service.startSession(config);
        
        // Wait a bit to simulate some session time
        await Future.delayed(const Duration(milliseconds: 100));
        
        final outcome = await service.stopSession(
          focusRating: 4,
          userNote: 'Great session!',
        );
        
        expect(outcome, isNotNull);
        expect(outcome!.config.environment, FocusEnvironment.forest);
        expect(outcome.focusRating, 4);
        expect(outcome.userNote, 'Great session!');
        expect(outcome.completionPercentage, greaterThan(0));
        expect(service.state, FocusSessionState.completed);
      });
    });
    
    group('Breathing Patterns', () {
      test('All breathing patterns have valid timing', () {
        for (final pattern in BreathingPattern.patterns) {
          expect(pattern.cycleDurationSeconds, greaterThan(0));
          expect(pattern.cyclesPerMinute, greaterThan(0));
          expect(pattern.cyclesPerMinute, lessThan(30)); // Reasonable upper limit
          expect(pattern.inhaleSeconds, greaterThan(0));
          expect(pattern.exhaleSeconds, greaterThan(0));
          // Hold and pause can be 0
          expect(pattern.holdSeconds, greaterThanOrEqualTo(0));
          expect(pattern.pauseSeconds, greaterThanOrEqualTo(0));
        }
      });
      
      test('Breathing session tracks cycles completed', () async {
        final proGates = MockProGates(true);
        service = FocusModeService(proGates, mockStorage);
        
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 1, // Short session for testing
          breathingPattern: BreathingPattern.patterns.first,
          enableBreathingCues: true,
        );
        
        await service.startSession(config);
        
        // Wait for breathing to complete
        await Future.delayed(const Duration(seconds: 5));
        
        final outcome = await service.stopSession(focusRating: 5);
        expect(outcome?.completedWithBreathing, true);
        expect(outcome?.breathingCyclesCompleted, greaterThan(0));
      });
    });
    
    group('Environment Configurations', () {
      test('All environments have valid configurations', () {
        for (final config in FocusEnvironmentConfig.environments) {
          expect(config.name.isNotEmpty, true);
          expect(config.description.isNotEmpty, true);
          expect(config.colorTheme.startsWith('#'), true);
          expect(config.colorTheme.length, 7); // #RRGGBB format
          expect(config.defaultVolume, inInclusiveRange(0.0, 1.0));
        }
      });
      
      test('Free environments are properly marked', () {
        final freeEnvironments = FocusEnvironmentConfig.freeEnvironments;
        expect(freeEnvironments.length, 3);
        expect(freeEnvironments.every((config) => !config.isProOnly), true);
      });
      
      test('Pro environments are properly marked', () {
        final proEnvironments = FocusEnvironmentConfig.proEnvironments;
        expect(proEnvironments.length, greaterThan(3));
        expect(proEnvironments.every((config) => config.isProOnly), true);
      });
      
      test('Environment lookup works correctly', () {
        final forestConfig = FocusEnvironmentConfig.getConfig(FocusEnvironment.forest);
        expect(forestConfig, isNotNull);
        expect(forestConfig!.environment, FocusEnvironment.forest);
        expect(forestConfig.name, 'Forest Sanctuary');
        
        final nonExistentConfig = FocusEnvironmentConfig.getConfig(FocusEnvironment.values.first);
        expect(nonExistentConfig, isNotNull); // First value should exist
      });
    });
    
    group('Session Configuration', () {
      test('Basic config has correct defaults', () {
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 10,
        );
        
        expect(config.environment, FocusEnvironment.silence);
        expect(config.sessionDurationMinutes, 10);
        expect(config.breathingPattern, isNull);
        expect(config.enableBinauralBeats, false);
        expect(config.enableBreathingCues, false);
        expect(config.soundVolume, 0.6);
      });
      
      test('Pro config supports all features', () {
        final pattern = BreathingPattern.patterns.first;
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.ocean,
          sessionDurationMinutes: 15,
          breathingPattern: pattern,
          enableBinauralBeats: true,
          enableBreathingCues: true,
          soundVolume: 0.8,
        );
        
        expect(config.environment, FocusEnvironment.ocean);
        expect(config.sessionDurationMinutes, 15);
        expect(config.breathingPattern, pattern);
        expect(config.enableBinauralBeats, true);
        expect(config.enableBreathingCues, true);
        expect(config.soundVolume, 0.8);
      });
      
      test('Session tags are generated correctly', () {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 10,
          breathingPattern: BreathingPattern.patterns.first,
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        final tags = config.toSessionTags();
        expect(tags, contains('env_forest'));
        expect(tags, contains('binaural_beats'));
        expect(tags, contains('breathing_cues'));
        expect(tags.any((tag) => tag.startsWith('breathing_')), true);
      });
    });
    
    group('Statistics and Preferences', () {
      test('Session stats are initialized correctly', () async {
        final proGates = MockProGates(false);
        service = FocusModeService(proGates, mockStorage);
        
        final stats = await service.getSessionStats();
        expect(stats['total_sessions'], 0);
        expect(stats['total_duration_minutes'], 0);
        expect(stats['favorite_environment'], 'silence');
        expect(stats['average_completion_rate'], 0.0);
        expect(stats['breathing_sessions'], 0);
      });
      
      test('Preferred environment can be set and retrieved', () async {
        final proGates = MockProGates(false);
        service = FocusModeService(proGates, mockStorage);
        
        // Default should be silence
        var preferred = await service.getPreferredEnvironment();
        expect(preferred, FocusEnvironment.silence);
        
        // Set new preference
        await service.setPreferredEnvironment(FocusEnvironment.rain);
        preferred = await service.getPreferredEnvironment();
        expect(preferred, FocusEnvironment.rain);
      });
    });
  });
}
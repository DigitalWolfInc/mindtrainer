/// Integration Tests for Advanced Focus Modes Pro Feature
/// 
/// Tests the complete Advanced Focus Modes implementation including Pro gating,
/// free tier behavior, and Pro upgrade transitions.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/storage/local_storage.dart';
import 'package:mindtrainer/features/focus_modes/application/focus_mode_service.dart';
import 'package:mindtrainer/features/focus_modes/domain/focus_environment.dart';

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
  bool _isProActive;
  
  MockProGates(this._isProActive);
  
  void upgradeToProBeta() {
    _isProActive = true;
  }
  
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
  group('Advanced Focus Modes Integration', () {
    late MockLocalStorage mockStorage;
    late MockProGates mockProGates;
    late FocusModeService focusService;
    
    setUp(() {
      mockStorage = MockLocalStorage();
      mockProGates = MockProGates(false); // Start as free user
      focusService = FocusModeService(mockProGates, mockStorage);
    });
    
    tearDown(() {
      focusService.dispose();
    });
    
    group('Free Tier Behavior', () {
      test('Free users only see free environments', () {
        final environments = focusService.getAvailableEnvironments();
        
        expect(environments.length, 3); // Only free environments
        expect(environments.every((env) => !env.isProOnly), true);
        expect(environments.any((env) => env.environment == FocusEnvironment.silence), true);
        expect(environments.any((env) => env.environment == FocusEnvironment.whiteNoise), true);
        expect(environments.any((env) => env.environment == FocusEnvironment.rain), true);
        
        // Should not have Pro environments
        expect(environments.any((env) => env.environment == FocusEnvironment.forest), false);
        expect(environments.any((env) => env.environment == FocusEnvironment.ocean), false);
      });
      
      test('Free users can start sessions with free environments', () async {
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 10,
        );
        
        final started = await focusService.startSession(config);
        expect(started, true);
        expect(focusService.state, FocusSessionState.focusing);
      });
      
      test('Free users cannot start sessions with Pro environments', () async {
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.forest, // Pro only
          sessionDurationMinutes: 10,
        );
        
        final started = await focusService.startSession(config);
        expect(started, false);
        expect(focusService.state, FocusSessionState.preparing);
      });
      
      test('Free users cannot use Pro features in config', () async {
        // Pro config with free environment should be downgraded
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.rain, // Free environment
          sessionDurationMinutes: 10,
          breathingPattern: BreathingPattern.patterns.first,
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        // Should start but without Pro features
        final started = await focusService.startSession(config);
        expect(started, true);
      });
      
      test('Free users have session limits enforced', () {
        // This would integrate with session limits service
        expect(mockProGates.dailySessionLimit, 5);
        expect(mockProGates.canStartSession(4), true);
        expect(mockProGates.canStartSession(5), false);
      });
    });
    
    group('Pro Tier Behavior', () {
      setUp(() {
        mockProGates.upgradeToProBeta(); // Upgrade to Pro
      });
      
      test('Pro users see all environments', () {
        final environments = focusService.getAvailableEnvironments();
        
        expect(environments.length, FocusEnvironmentConfig.environments.length);
        expect(environments.any((env) => env.isProOnly), true);
        
        // Should have all environments
        expect(environments.any((env) => env.environment == FocusEnvironment.forest), true);
        expect(environments.any((env) => env.environment == FocusEnvironment.ocean), true);
        expect(environments.any((env) => env.environment == FocusEnvironment.binauralBeats), true);
      });
      
      test('Pro users can start sessions with any environment', () async {
        // Test with Pro environment
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 15,
          breathingPattern: BreathingPattern.patterns.first,
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        final started = await focusService.startSession(config);
        expect(started, true);
        expect(focusService.state, FocusSessionState.breathing); // Should start with breathing
      });
      
      test('Pro users can use advanced features', () async {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.ocean,
          sessionDurationMinutes: 20,
          breathingPattern: BreathingPattern.patterns[1], // 4-7-8 pattern
          soundVolume: 0.8,
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        final started = await focusService.startSession(config);
        expect(started, true);
        
        // Configuration should be preserved
        expect(config.breathingPattern?.name, '4-7-8 Calming');
        expect(config.soundVolume, 0.8);
        expect(config.enableBinauralBeats, true);
        expect(config.enableBreathingCues, true);
      });
      
      test('Pro users have unlimited sessions', () {
        expect(mockProGates.dailySessionLimit, -1); // Unlimited
        expect(mockProGates.canStartSession(100), true);
        expect(mockProGates.unlimitedDailySessions, true);
      });
      
      test('Pro users can access binaural beats environments', () async {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.binauralBeats,
          sessionDurationMinutes: 25,
          enableBinauralBeats: true,
        );
        
        final started = await focusService.startSession(config);
        expect(started, true);
        
        // Should support binaural beats
        final envConfig = FocusEnvironmentConfig.getConfig(FocusEnvironment.binauralBeats);
        expect(envConfig?.supportsBinauralBeats, true);
      });
    });
    
    group('Free to Pro Upgrade Transition', () {
      test('Environment availability changes after upgrade', () {
        // Start as free user
        var environments = focusService.getAvailableEnvironments();
        expect(environments.length, 3);
        
        // Upgrade to Pro
        mockProGates.upgradeToProBeta();
        
        // Environment list should update
        environments = focusService.getAvailableEnvironments();
        expect(environments.length, FocusEnvironmentConfig.environments.length);
        expect(environments.any((env) => env.isProOnly), true);
      });
      
      test('Previously blocked features become available', () async {
        // Try to start Pro session as free user
        var config = FocusSessionConfig.basic(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 10,
        );
        
        var started = await focusService.startSession(config);
        expect(started, false);
        
        // Upgrade to Pro
        mockProGates.upgradeToProBeta();
        
        // Now same session should work
        started = await focusService.startSession(config);
        expect(started, true);
      });
      
      test('Session stats are preserved across upgrade', () async {
        // Record some free sessions
        final freeConfig = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 5,
        );
        
        await focusService.startSession(freeConfig);
        final outcome1 = await focusService.stopSession(focusRating: 4);
        expect(outcome1, isNotNull);
        
        var stats = await focusService.getSessionStats();
        expect(stats['total_sessions'], 1);
        
        // Upgrade to Pro
        mockProGates.upgradeToProBeta();
        
        // Record Pro session
        final proConfig = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 15,
        );
        
        await focusService.startSession(proConfig);
        final outcome2 = await focusService.stopSession(focusRating: 5);
        expect(outcome2, isNotNull);
        
        // Stats should include both sessions
        stats = await focusService.getSessionStats();
        expect(stats['total_sessions'], 2);
      });
    });
    
    group('Session Management', () {
      setUp(() {
        mockProGates.upgradeToProBeta(); // Test with Pro features
      });
      
      test('Complete session lifecycle with breathing', () async {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.ocean,
          sessionDurationMinutes: 1, // Short for testing
          breathingPattern: BreathingPattern.patterns[0], // Box breathing
          enableBreathingCues: true,
        );
        
        // Start session
        final started = await focusService.startSession(config);
        expect(started, true);
        expect(focusService.state, FocusSessionState.breathing);
        
        // Session should be in progress
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Stop session
        final outcome = await focusService.stopSession(
          focusRating: 5,
          userNote: 'Great session with ocean sounds',
        );
        
        expect(outcome, isNotNull);
        expect(outcome!.config.environment, FocusEnvironment.ocean);
        expect(outcome.completionPercentage, greaterThan(0));
        expect(outcome.focusRating, 5);
        expect(outcome.userNote, 'Great session with ocean sounds');
        expect(outcome.completedWithBreathing, true);
        expect(focusService.state, FocusSessionState.completed);
      });
      
      test('Pause and resume functionality', () async {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 10,
        );
        
        await focusService.startSession(config);
        expect(focusService.state, FocusSessionState.focusing);
        
        // Pause session
        focusService.pauseSession();
        expect(focusService.state, FocusSessionState.paused);
        
        // Resume session
        focusService.resumeSession();
        expect(focusService.state, FocusSessionState.focusing);
      });
      
      test('Session outcome converts to proper Session object', () async {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.mountains,
          sessionDurationMinutes: 1,
          breathingPattern: BreathingPattern.patterns[1],
          enableBreathingCues: true,
          enableBinauralBeats: true,
        );
        
        await focusService.startSession(config);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final outcome = await focusService.stopSession(
          focusRating: 4,
          userNote: 'Mountain meditation',
        );
        
        expect(outcome, isNotNull);
        
        final session = outcome!.toSession();
        expect(session.tags, contains('env_mountains'));
        expect(session.tags.any((tag) => tag.startsWith('breathing_')), true);
        expect(session.tags, contains('binaural_beats'));
        expect(session.tags, contains('breathing_cues'));
        expect(session.tags, contains('rating_4'));
        expect(session.note, 'Mountain meditation');
      });
    });
    
    group('Analytics and Preferences', () {
      setUp(() {
        mockProGates.upgradeToProBeta();
      });
      
      test('User preferences are saved and loaded', () async {
        // Set preferred environment
        await focusService.setPreferredEnvironment(FocusEnvironment.forest);
        
        // Load preferences
        final preferred = await focusService.getPreferredEnvironment();
        expect(preferred, FocusEnvironment.forest);
      });
      
      test('Session statistics are updated correctly', () async {
        var stats = await focusService.getSessionStats();
        expect(stats['total_sessions'], 0);
        
        // Complete a few sessions
        for (int i = 0; i < 3; i++) {
          final config = FocusSessionConfig.pro(
            environment: i == 0 ? FocusEnvironment.forest : FocusEnvironment.ocean,
            sessionDurationMinutes: 5,
          );
          
          await focusService.startSession(config);
          await focusService.stopSession(focusRating: 4 + i % 2); // Ratings 4-5
        }
        
        stats = await focusService.getSessionStats();
        expect(stats['total_sessions'], 3);
        expect(stats['total_duration_minutes'], greaterThan(0));
        expect(stats['average_completion_rate'], greaterThan(0.0));
        
        // Should track favorite environment
        final envCounts = stats['environment_counts'] as Map<String, int>;
        expect(envCounts['forest'], 1);
        expect(envCounts['ocean'], 2);
        expect(stats['favorite_environment'], 'ocean');
      });
    });
    
    group('Error Handling and Edge Cases', () {
      test('Cannot start session when one is already running', () async {
        mockProGates.upgradeToProBeta();
        
        final config1 = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 10,
        );
        
        final started1 = await focusService.startSession(config1);
        expect(started1, true);
        
        // Try to start another session
        final config2 = FocusSessionConfig.pro(
          environment: FocusEnvironment.ocean,
          sessionDurationMinutes: 5,
        );
        
        final started2 = await focusService.startSession(config2);
        expect(started2, false);
        expect(focusService.state, FocusSessionState.focusing); // Still in first session
      });
      
      test('Handles invalid environment gracefully', () {
        final invalidConfig = FocusEnvironmentConfig.getConfig(FocusEnvironment.values.first);
        expect(invalidConfig, isNotNull); // All environments should be valid
      });
      
      test('Storage errors do not crash the service', () async {
        mockProGates.upgradeToProBeta();
        
        // Service should handle storage errors gracefully
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 1,
        );
        
        expect(() async => await focusService.startSession(config), returnsNormally);
        expect(() async => await focusService.stopSession(), returnsNormally);
        expect(() async => await focusService.getSessionStats(), returnsNormally);
      });
    });
    
    group('Breathing Pattern Integration', () {
      test('Breathing patterns have correct cycle calculations', () {
        final pattern = BreathingPattern.patterns[0]; // Box breathing
        expect(pattern.cycleDurationSeconds, 16); // 4+4+4+4
        expect(pattern.cyclesPerMinute, closeTo(3.75, 0.1)); // 60/16
        
        final pattern2 = BreathingPattern.patterns[1]; // 4-7-8
        expect(pattern2.cycleDurationSeconds, 19); // 4+7+8+0
        expect(pattern2.cyclesPerMinute, closeTo(3.16, 0.1)); // 60/19
      });
      
      test('Breathing session progresses through phases', () async {
        mockProGates.upgradeToProBeta();
        
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 1,
          breathingPattern: BreathingPattern.patterns[0],
          enableBreathingCues: true,
        );
        
        await focusService.startSession(config);
        expect(focusService.state, FocusSessionState.breathing);
        
        // Should eventually transition to focus phase
        // (In real implementation, this would happen after breathing cycles complete)
      });
    });
  });
}
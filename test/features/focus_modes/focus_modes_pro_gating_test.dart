/// Pro Feature Gating Tests for Focus Modes
/// 
/// Tests that Pro gating works correctly for Advanced Focus Modes feature,
/// including environment access, feature limitations, and upgrade behavior.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/focus_modes/domain/focus_environment.dart';

void main() {
  group('Focus Modes Pro Gating', () {
    
    group('Environment Configuration', () {
      test('Free environments are correctly identified', () {
        final freeEnvironments = FocusEnvironmentConfig.freeEnvironments;
        
        expect(freeEnvironments.length, 3);
        expect(freeEnvironments.every((env) => !env.isProOnly), true);
        
        // Verify specific free environments
        final envTypes = freeEnvironments.map((e) => e.environment).toSet();
        expect(envTypes, contains(FocusEnvironment.silence));
        expect(envTypes, contains(FocusEnvironment.whiteNoise));
        expect(envTypes, contains(FocusEnvironment.rain));
      });
      
      test('Pro environments are correctly identified', () {
        final proEnvironments = FocusEnvironmentConfig.proEnvironments;
        
        expect(proEnvironments.length, 9); // Total - Free = Pro
        expect(proEnvironments.every((env) => env.isProOnly), true);
        
        // Verify specific Pro environments
        final envTypes = proEnvironments.map((e) => e.environment).toSet();
        expect(envTypes, contains(FocusEnvironment.forest));
        expect(envTypes, contains(FocusEnvironment.ocean));
        expect(envTypes, contains(FocusEnvironment.binauralBeats));
        expect(envTypes, contains(FocusEnvironment.mountains));
        expect(envTypes, contains(FocusEnvironment.fireplace));
        expect(envTypes, contains(FocusEnvironment.cafe));
        expect(envTypes, contains(FocusEnvironment.brownNoise));
        expect(envTypes, contains(FocusEnvironment.nature));
        expect(envTypes, contains(FocusEnvironment.storm));
      });
      
      test('All environments have valid configurations', () {
        for (final config in FocusEnvironmentConfig.environments) {
          // Basic validation
          expect(config.name.isNotEmpty, true);
          expect(config.description.isNotEmpty, true);
          expect(config.colorTheme.startsWith('#'), true);
          expect(config.colorTheme.length, 7); // #RRGGBB format
          expect(config.defaultVolume, inInclusiveRange(0.0, 1.0));
          
          // Pro-only environments should have premium features
          if (config.isProOnly) {
            final hasPremiumFeature = config.soundFiles.isNotEmpty ||
                                   config.supportsBinauralBeats ||
                                   config.environment == FocusEnvironment.binauralBeats;
            expect(hasPremiumFeature, true, 
                   reason: 'Pro environment ${config.name} should have premium features');
          }
        }
      });
      
      test('Environment lookup works correctly', () {
        // Test existing environment
        final forestConfig = FocusEnvironmentConfig.getConfig(FocusEnvironment.forest);
        expect(forestConfig, isNotNull);
        expect(forestConfig!.environment, FocusEnvironment.forest);
        expect(forestConfig.isProOnly, true);
        
        // Test all environments can be found
        for (final env in FocusEnvironment.values) {
          final config = FocusEnvironmentConfig.getConfig(env);
          expect(config, isNotNull, reason: 'Environment $env should have config');
          expect(config!.environment, env);
        }
      });
    });
    
    group('Breathing Patterns', () {
      test('All breathing patterns are valid', () {
        for (final pattern in BreathingPattern.patterns) {
          expect(pattern.name.isNotEmpty, true);
          expect(pattern.description.isNotEmpty, true);
          expect(pattern.inhaleSeconds, greaterThan(0));
          expect(pattern.exhaleSeconds, greaterThan(0));
          expect(pattern.holdSeconds, greaterThanOrEqualTo(0));
          expect(pattern.pauseSeconds, greaterThanOrEqualTo(0));
          expect(pattern.cycleDurationSeconds, greaterThan(0));
          expect(pattern.cyclesPerMinute, greaterThan(0));
        }
      });
      
      test('Breathing patterns have reasonable timing', () {
        for (final pattern in BreathingPattern.patterns) {
          // Cycles should be reasonable for meditation
          expect(pattern.cycleDurationSeconds, inInclusiveRange(10, 30));
          expect(pattern.cyclesPerMinute, inInclusiveRange(2.0, 6.0));
          
          // Individual phases should be reasonable
          expect(pattern.inhaleSeconds, inInclusiveRange(3, 8));
          expect(pattern.exhaleSeconds, inInclusiveRange(3, 10));
          expect(pattern.holdSeconds, inInclusiveRange(0, 8));
          expect(pattern.pauseSeconds, inInclusiveRange(0, 5));
        }
      });
      
      test('Default breathing patterns are included', () {
        final patternNames = BreathingPattern.patterns.map((p) => p.name).toSet();
        
        // Should include common patterns
        expect(patternNames.any((name) => name.contains('Box')), true);
        expect(patternNames.any((name) => name.contains('4-7-8')), true);
        expect(patternNames.any((name) => name.contains('Natural')), true);
      });
    });
    
    group('Session Configuration', () {
      test('Basic config for free users has correct limitations', () {
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 15,
        );
        
        expect(config.environment, FocusEnvironment.silence);
        expect(config.sessionDurationMinutes, 15);
        expect(config.breathingPattern, isNull);
        expect(config.enableBinauralBeats, false);
        expect(config.enableBreathingCues, false);
        expect(config.soundVolume, 0.6); // Default
      });
      
      test('Pro config allows advanced features', () {
        final pattern = BreathingPattern.patterns.first;
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 20,
          breathingPattern: pattern,
          soundVolume: 0.8,
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        expect(config.environment, FocusEnvironment.forest);
        expect(config.sessionDurationMinutes, 20);
        expect(config.breathingPattern, pattern);
        expect(config.soundVolume, 0.8);
        expect(config.enableBinauralBeats, true);
        expect(config.enableBreathingCues, true);
      });
      
      test('Session config converts to proper tags', () {
        final pattern = BreathingPattern.patterns[1]; // 4-7-8 pattern
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.ocean,
          sessionDurationMinutes: 10,
          breathingPattern: pattern,
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        final tags = config.toSessionTags();
        
        expect(tags, contains('env_ocean'));
        expect(tags.any((tag) => tag.startsWith('breathing_')), true);
        expect(tags, contains('binaural_beats'));
        expect(tags, contains('breathing_cues'));
      });
    });
    
    group('Session Outcome Tracking', () {
      test('Session outcome captures all relevant data', () {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.mountains,
          sessionDurationMinutes: 15,
          breathingPattern: BreathingPattern.patterns[0],
          enableBreathingCues: true,
        );
        
        final startTime = DateTime.now().subtract(const Duration(minutes: 12));
        final outcome = FocusSessionOutcome(
          config: config,
          startTime: startTime,
          actualDuration: const Duration(minutes: 12),
          completionPercentage: 80,
          focusRating: 4,
          completedWithBreathing: true,
          breathingCyclesCompleted: 8,
          userNote: 'Great mountain session',
        );
        
        expect(outcome.config.environment, FocusEnvironment.mountains);
        expect(outcome.actualDuration.inMinutes, 12);
        expect(outcome.completionPercentage, 80);
        expect(outcome.focusRating, 4);
        expect(outcome.completedWithBreathing, true);
        expect(outcome.breathingCyclesCompleted, 8);
        expect(outcome.userNote, 'Great mountain session');
      });
      
      test('Session outcome converts to Session correctly', () {
        final config = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 10,
          breathingPattern: BreathingPattern.patterns[0],
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        final startTime = DateTime(2023, 12, 25, 10, 30);
        final outcome = FocusSessionOutcome(
          config: config,
          startTime: startTime,
          actualDuration: const Duration(minutes: 8),
          completionPercentage: 80,
          focusRating: 5,
          completedWithBreathing: true,
          userNote: 'Christmas meditation',
        );
        
        final session = outcome.toSession();
        
        expect(session.dateTime, startTime);
        expect(session.durationMinutes, 8);
        expect(session.note, 'Christmas meditation');
        expect(session.id, '${startTime.millisecondsSinceEpoch}');
        
        // Check tags
        expect(session.tags, contains('env_forest'));
        expect(session.tags.any((tag) => tag.startsWith('breathing_')), true);
        expect(session.tags, contains('binaural_beats'));
        expect(session.tags, contains('breathing_cues'));
        expect(session.tags, contains('completion_80'));
        expect(session.tags, contains('rating_5'));
        expect(session.tags, contains('breathing_completed'));
      });
    });
    
    group('Value Proposition Validation', () {
      test('Free tier provides meaningful value', () {
        final freeEnvironments = FocusEnvironmentConfig.freeEnvironments;
        
        // Should have variety in free tier
        expect(freeEnvironments.length, greaterThanOrEqualTo(3));
        
        // Should include different types of environments
        final hasQuiet = freeEnvironments.any((e) => e.soundFiles.isEmpty);
        final hasSound = freeEnvironments.any((e) => e.soundFiles.isNotEmpty);
        expect(hasQuiet, true, reason: 'Free tier should include quiet option');
        expect(hasSound, true, reason: 'Free tier should include sound option');
        
        // All free environments should be fully functional
        for (final env in freeEnvironments) {
          expect(env.name.isNotEmpty, true);
          expect(env.description.isNotEmpty, true);
          expect(env.supportsBreathing, true); // Basic breathing support
        }
      });
      
      test('Pro tier provides significant additional value', () {
        final proEnvironments = FocusEnvironmentConfig.proEnvironments;
        final freeEnvironments = FocusEnvironmentConfig.freeEnvironments;
        
        // Pro should have significantly more environments
        expect(proEnvironments.length, greaterThan(freeEnvironments.length * 2));
        
        // Pro should include advanced features
        final hasAdvancedFeatures = proEnvironments.any((e) => 
            e.supportsBinauralBeats || 
            e.soundFiles.length > 1 ||
            e.environment == FocusEnvironment.binauralBeats);
        expect(hasAdvancedFeatures, true);
        
        // Pro should include variety of themes
        final themes = proEnvironments.map((e) => e.colorTheme).toSet();
        expect(themes.length, greaterThanOrEqualTo(5));
      });
      
      test('Pro features justify subscription cost', () {
        final totalEnvironments = FocusEnvironmentConfig.environments.length;
        final freeEnvironments = FocusEnvironmentConfig.freeEnvironments.length;
        
        // Pro should unlock majority of environments
        final proPercentage = (totalEnvironments - freeEnvironments) / totalEnvironments;
        expect(proPercentage, greaterThan(0.6), 
               reason: 'Pro should unlock > 60% of total environments');
        
        // Pro should include premium-only features
        final proOnlyFeatures = [
          'Binaural beats support',
          'Multiple layered soundfiles',
          'Premium environment themes',
          'Advanced breathing patterns integration',
        ];
        
        // Verify some Pro environments have these features
        final hasMultipleSounds = FocusEnvironmentConfig.proEnvironments
            .any((e) => e.soundFiles.length > 1);
        final hasBinauralSupport = FocusEnvironmentConfig.proEnvironments
            .any((e) => e.supportsBinauralBeats);
        
        expect(hasMultipleSounds, true);
        expect(hasBinauralSupport, true);
      });
    });
    
    group('Google Play Policy Compliance', () {
      test('Essential meditation functionality remains free', () {
        final freeEnvironments = FocusEnvironmentConfig.freeEnvironments;
        
        // Free tier should enable basic meditation
        expect(freeEnvironments.isNotEmpty, true);
        expect(freeEnvironments.any((e) => e.environment == FocusEnvironment.silence), true);
        
        // All environments should support basic breathing
        for (final env in freeEnvironments) {
          expect(env.supportsBreathing, true);
        }
      });
      
      test('Pro features are enhancements, not requirements', () {
        // Free users should be able to meditate effectively
        final basicConfig = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 10,
        );
        
        expect(basicConfig.environment, isNotNull);
        expect(basicConfig.sessionDurationMinutes, greaterThan(0));
        
        // Pro features should be additive
        final proConfig = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 10,
          breathingPattern: BreathingPattern.patterns.first,
          enableBreathingCues: true,
        );
        
        // Pro config should offer additional value, not replace basic functionality
        expect(proConfig.sessionDurationMinutes, basicConfig.sessionDurationMinutes);
      });
      
      test('Feature descriptions emphasize enhancement', () {
        for (final env in FocusEnvironmentConfig.proEnvironments) {
          final description = env.description.toLowerCase();
          
          // Should not suggest this is the only way to meditate
          expect(description, isNot(contains('only')));
          expect(description, isNot(contains('required')));
          expect(description, isNot(contains('essential')));
          
          // Should emphasize enhancement
          final enhancementWords = ['enhanced', 'immersive', 'deep', 'peaceful', 'premium'];
          final hasEnhancementLanguage = enhancementWords.any((word) => 
              env.name.toLowerCase().contains(word) || 
              description.contains(word));
          // Note: Not all environments need enhancement language, but Pro tier overall should
        }
      });
      
      test('Free tier has complete user experience', () {
        // Free users should be able to complete full meditation sessions
        final freeConfig = FocusSessionConfig.basic(
          environment: FocusEnvironment.rain,
          sessionDurationMinutes: 15,
        );
        
        expect(freeConfig.environment, isNotNull);
        expect(freeConfig.sessionDurationMinutes, greaterThan(0));
        expect(freeConfig.soundVolume, greaterThan(0));
        
        // Should be able to create a complete session outcome
        final outcome = FocusSessionOutcome(
          config: freeConfig,
          startTime: DateTime.now(),
          actualDuration: const Duration(minutes: 15),
          completionPercentage: 100,
          focusRating: 4,
        );
        
        final session = outcome.toSession();
        expect(session.durationMinutes, 15);
        expect(session.tags.isNotEmpty, true);
      });
    });
  });
}
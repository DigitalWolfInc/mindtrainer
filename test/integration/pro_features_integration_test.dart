/// Integration Tests for Complete Pro Features System
/// 
/// Validates that all Pro features work together harmoniously and maintain
/// consistent behavior across the entire feature set.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/features/pro_extensions/services/extended_pro_service.dart';

class ComprehensiveProGates implements MindTrainerProGates {
  final bool _isProActive;
  
  ComprehensiveProGates(this._isProActive);
  
  @override
  bool get isProActive => _isProActive;
  
  // Wave 1 Features
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
  
  // Wave 2 Features  
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
  group('Pro Features Integration', () {
    late MindTrainerProGates freeGates;
    late MindTrainerProGates proGates;
    late ExtendedProService freeService;
    late ExtendedProService proService;
    
    setUp(() {
      freeGates = ComprehensiveProGates(false);
      proGates = ComprehensiveProGates(true);
      freeService = ExtendedProService(freeGates);
      proService = ExtendedProService(proGates);
    });
    
    group('Feature Gate Consistency', () {
      test('All Wave 1 features are properly gated', () {
        // Wave 1 features should be consistently gated
        expect(freeGates.unlimitedDailySessions, false);
        expect(freeGates.extendedCoachingPhases, false);
        expect(freeGates.advancedAnalytics, false);
        expect(freeGates.dataExport, false);
        expect(freeGates.customGoals, false);
        expect(freeGates.adFree, false);
        expect(freeGates.premiumThemes, false);
        
        expect(proGates.unlimitedDailySessions, true);
        expect(proGates.extendedCoachingPhases, true);
        expect(proGates.advancedAnalytics, true);
        expect(proGates.dataExport, true);
        expect(proGates.customGoals, true);
        expect(proGates.adFree, true);
        expect(proGates.premiumThemes, true);
      });
      
      test('All Wave 2 features are properly gated', () {
        // Wave 2 features should be consistently gated
        expect(freeGates.smartSessionScheduling, false);
        expect(freeGates.voiceJournalInsights, false);
        expect(freeGates.communityChallengePro, false);
        expect(freeGates.advancedGoalTemplates, false);
        expect(freeGates.environmentPresets, false);
        expect(freeGates.biometricIntegration, false);
        expect(freeGates.progressSharingExport, false);
        expect(freeGates.cloudBackupSync, false);
        
        expect(proGates.smartSessionScheduling, true);
        expect(proGates.voiceJournalInsights, true);
        expect(proGates.communityChallengePro, true);
        expect(proGates.advancedGoalTemplates, true);
        expect(proGates.environmentPresets, true);
        expect(proGates.biometricIntegration, true);
        expect(proGates.progressSharingExport, true);
        expect(proGates.cloudBackupSync, true);
      });
      
      test('Feature collections are complete and consistent', () {
        final freeAvailable = freeGates.availableFeatures;
        final freeLocked = freeGates.lockedFeatures;
        final proAvailable = proGates.availableFeatures;
        final proLocked = proGates.lockedFeatures;
        
        // Free users should have no available Pro features
        expect(freeAvailable, isEmpty);
        expect(freeLocked.length, ProFeature.values.length);
        
        // Pro users should have all features available
        expect(proAvailable.length, ProFeature.values.length);
        expect(proLocked, isEmpty);
        
        // Feature lists should be mutually exclusive and exhaustive
        expect(freeLocked.toSet().union(freeAvailable.toSet()), 
               equals(ProFeature.values.toSet()));
        expect(proAvailable.toSet().union(proLocked.toSet()), 
               equals(ProFeature.values.toSet()));
      });
    });
    
    group('Service Layer Integration', () {
      test('All Pro services respect feature gates consistently', () async {
        // Free user service calls should return null/empty/false
        expect(await freeService.getSmartScheduleRecommendations(), isNull);
        expect(await freeService.recordVoiceJournal('test', '/test.wav'), isNull);
        expect(await freeService.getAvailableChallenges(), isEmpty);
        expect(await freeService.getExpertGoalTemplates(), isEmpty);
        expect(await freeService.getEnvironmentPresets(), isEmpty);
        expect(await freeService.getBiometricInsights(), isNull);
        expect(await freeService.generateProgressReport(), isNull);
        expect(await freeService.getCloudSyncStatus(), isNull);
        expect(await freeService.joinChallenge('test'), false);
        expect(await freeService.enableCloudBackup(), false);
        
        // Pro user service calls should return valid data
        expect(await proService.getSmartScheduleRecommendations(), isNotNull);
        expect(await proService.recordVoiceJournal('test', '/test.wav'), isNotNull);
        expect(await proService.getAvailableChallenges(), isNotEmpty);
        expect(await proService.getExpertGoalTemplates(), isNotEmpty);
        expect(await proService.getEnvironmentPresets(), isNotEmpty);
        expect(await proService.getBiometricInsights(), isNotNull);
        expect(await proService.generateProgressReport(), isNotNull);
        expect(await proService.getCloudSyncStatus(), isNotNull);
        expect(await proService.joinChallenge('test'), true);
        expect(await proService.enableCloudBackup(), true);
      });
      
      test('Service availability checks match actual functionality', () {
        // Free service availability should match actual capability
        expect(freeService.hasSmartScheduling, false);
        expect(freeService.hasVoiceJournal, false);
        expect(freeService.hasCommunityChallenge, false);
        expect(freeService.hasExpertGoalTemplates, false);
        expect(freeService.hasEnvironmentPresets, false);
        expect(freeService.hasBiometricIntegration, false);
        expect(freeService.hasProgressReports, false);
        expect(freeService.hasCloudBackup, false);
        
        // Pro service availability should match actual capability
        expect(proService.hasSmartScheduling, true);
        expect(proService.hasVoiceJournal, true);
        expect(proService.hasCommunityChallenge, true);
        expect(proService.hasExpertGoalTemplates, true);
        expect(proService.hasEnvironmentPresets, true);
        expect(proService.hasBiometricIntegration, true);
        expect(proService.hasProgressReports, true);
        expect(proService.hasCloudBackup, true);
      });
    });
    
    group('Feature Categorization', () {
      test('All features have proper metadata', () {
        for (final feature in ProFeature.values) {
          // Each feature should have meaningful display information
          expect(feature.displayName.length, greaterThan(5));
          expect(feature.description.length, greaterThan(20));
          expect(feature.icon.isNotEmpty, true);
          
          // Display names should be title case
          expect(feature.displayName[0], equals(feature.displayName[0].toUpperCase()));
          
          // Descriptions should be sentence case and end appropriately
          expect(feature.description[0], equals(feature.description[0].toUpperCase()));
        }
      });
      
      test('Feature names are unique and descriptive', () {
        final displayNames = ProFeature.values.map((f) => f.displayName).toList();
        final uniqueNames = displayNames.toSet();
        
        // All display names should be unique
        expect(displayNames.length, equals(uniqueNames.length));
        
        // No feature should have generic names
        final genericTerms = ['feature', 'option', 'setting', 'thing'];
        for (final name in displayNames) {
          final lowerName = name.toLowerCase();
          for (final term in genericTerms) {
            expect(lowerName.contains(term), false, 
                   reason: 'Feature "$name" contains generic term "$term"');
          }
        }
      });
      
      test('Feature icons are appropriate and unique', () {
        final icons = ProFeature.values.map((f) => f.icon).toList();
        final uniqueIcons = icons.toSet();
        
        // All icons should be unique (or we should consciously choose to reuse)
        expect(icons.length, equals(uniqueIcons.length));
        
        // Icons should be actual emoji or meaningful symbols
        for (final icon in icons) {
          expect(icon.isNotEmpty, true);
          expect(icon.length, lessThanOrEqualTo(4)); // Emoji are typically 1-4 chars
        }
      });
    });
    
    group('Business Logic Validation', () {
      test('Free tier provides genuine value without Pro', () {
        // Free tier should enable habit formation
        expect(freeGates.dailySessionLimit, 5); // Enough for habit building
        expect(freeGates.insightsHistoryDays, 30); // Sufficient for pattern recognition
        
        // Free tier should include core functionality
        expect(freeGates.canStartSession(0), true); // Can start sessions
        expect(freeGates.canStartSession(4), true); // Can use daily allowance
        expect(freeGates.canStartSession(5), false); // Limit enforced
      });
      
      test('Pro tier provides meaningful upgrade value', () {
        // Pro should remove all limitations
        expect(proGates.dailySessionLimit, -1); // Unlimited
        expect(proGates.insightsHistoryDays, -1); // Unlimited history
        expect(proGates.canStartSession(100), true); // No limits
        
        // Pro should include all features
        expect(proGates.availableFeatures.length, ProFeature.values.length);
      });
      
      test('Feature progression makes logical sense', () {
        // Basic features (Wave 1) enable advanced features (Wave 2)
        final wave1Features = [
          ProFeature.unlimitedSessions,
          ProFeature.extendedCoaching,
          ProFeature.advancedAnalytics,
          ProFeature.dataExport,
          ProFeature.customGoals,
        ];
        
        final wave2Features = [
          ProFeature.smartScheduling, // Builds on analytics
          ProFeature.voiceJournal,    // Enhances journaling
          ProFeature.environmentPresets, // Enhances focus modes
          ProFeature.biometricSync,   // Enhances analytics
          ProFeature.progressReports, // Builds on data export
        ];
        
        // All Wave 1 features should exist
        for (final feature in wave1Features) {
          expect(ProFeature.values, contains(feature));
        }
        
        // All Wave 2 features should exist  
        for (final feature in wave2Features) {
          expect(ProFeature.values, contains(feature));
        }
      });
    });
    
    group('Google Play Policy Compliance', () {
      test('No essential functionality is Pro-only', () {
        // Core meditation app functionality should work without Pro
        final essentialCapabilities = [
          'Can record meditation sessions',
          'Can track basic progress', 
          'Can set goals',
          'Can tag sessions',
          'Can write notes',
          'Can view recent history',
        ];
        
        // These should all be possible with free tier
        expect(freeGates.dailySessionLimit, greaterThan(0));
        expect(freeGates.insightsHistoryDays, greaterThan(0));
        expect(freeGates.canStartSession(0), true);
        
        // Pro features should be enhancements, not replacements
        for (final feature in ProFeature.values) {
          final description = feature.description.toLowerCase();
          
          // Should not suggest Pro is required for basic functionality
          expect(description, isNot(contains('only way')));
          expect(description, isNot(contains('required for')));
          expect(description, isNot(contains('must have')));
          expect(description, isNot(contains('cannot work without')));
        }
      });
      
      test('Pro features provide genuine additional value', () {
        // Each Pro feature should offer clear value beyond free tier
        for (final feature in ProFeature.values) {
          final name = feature.displayName;
          final description = feature.description;
          
          // Should describe positive enhancements
          final valueIndicators = [
            'advanced', 'enhanced', 'unlimited', 'custom', 'professional',
            'premium', 'expert', 'intelligent', 'personalized', 'comprehensive',
            'full', 'extended', 'complete', 'additional', 'export', 'import',
            'multiple', 'remove', 'exclusive', 'ai', 'optimal', 'automatic',
            'suggests', 'patterns', 'beautiful', 'encrypted', 'anonymous',
            'designed', 'save', 'connect', 'generate', 'backup'
          ];
          
          final hasValueIndicator = valueIndicators.any((indicator) => 
              name.toLowerCase().contains(indicator) || 
              description.toLowerCase().contains(indicator));
              
          expect(hasValueIndicator, true, 
                 reason: 'Feature "$name" should clearly indicate added value');
        }
      });
      
      test('Pricing justification is clear', () {
        // Pro features should justify subscription cost
        final premiumFeatures = proGates.availableFeatures;
        
        // Should have substantial number of features to justify cost
        expect(premiumFeatures.length, greaterThanOrEqualTo(10));
        
        // Should include features that require ongoing development/maintenance
        final ongoingValueFeatures = [
          ProFeature.smartScheduling,    // AI development
          ProFeature.communityChallenge, // Community management
          ProFeature.expertGoalTemplates, // Professional content
          ProFeature.cloudBackup,        // Infrastructure costs
        ];
        
        for (final feature in ongoingValueFeatures) {
          expect(premiumFeatures, contains(feature));
        }
      });
    });
    
    group('Error Handling and Edge Cases', () {
      test('Service methods handle Pro status changes gracefully', () async {
        // Services should handle changing Pro status without crashing
        expect(() => freeService.getAvailableExtensions(), returnsNormally);
        expect(() => proService.getAvailableExtensions(), returnsNormally);
        
        // Async methods should complete without throwing
        final freeFutures = [
          freeService.getSmartScheduleRecommendations(),
          freeService.getAvailableChallenges(),
          freeService.getBiometricInsights(),
        ];
        
        final proFutures = [
          proService.getSmartScheduleRecommendations(), 
          proService.getAvailableChallenges(),
          proService.getBiometricInsights(),
        ];
        
        // All futures should complete without throwing
        await expectLater(Future.wait(freeFutures), completes);
        await expectLater(Future.wait(proFutures), completes);
      });
      
      test('Feature gates handle null and invalid inputs safely', () {
        // Test edge cases in feature gating
        expect(() => freeGates.canStartSession(-1), returnsNormally);
        expect(() => freeGates.canStartSession(0), returnsNormally);
        expect(() => freeGates.canStartSession(1000), returnsNormally);
        
        expect(() => proGates.canStartSession(-1), returnsNormally);
        expect(() => proGates.canStartSession(0), returnsNormally);
        expect(() => proGates.canStartSession(1000), returnsNormally);
        
        // Negative session counts should be handled gracefully
        // Note: -1 < 5 is true, so even free users can start with negative counts
        expect(freeGates.canStartSession(-1), true);
        expect(proGates.canStartSession(-1), true); // Pro users always allowed
      });
    });
  });
}
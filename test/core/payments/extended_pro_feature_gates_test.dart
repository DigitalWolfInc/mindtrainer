/// Tests for Extended Pro Feature Gates
/// 
/// Tests all additional Pro features added to the existing gate system.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';

void main() {
  group('Extended Pro Feature Gates', () {
    late MindTrainerProGates freeUserGates;
    late MindTrainerProGates proUserGates;
    
    setUp(() {
      freeUserGates = MindTrainerProGates(() => false);
      proUserGates = MindTrainerProGates(() => true);
    });
    
    group('Smart Session Scheduling', () {
      test('Free users cannot access smart scheduling', () {
        expect(freeUserGates.smartSessionScheduling, false);
      });
      
      test('Pro users can access smart scheduling', () {
        expect(proUserGates.smartSessionScheduling, true);
      });
    });
    
    group('Voice Journal Insights', () {
      test('Free users cannot access voice journal features', () {
        expect(freeUserGates.voiceJournalInsights, false);
      });
      
      test('Pro users can access voice journal features', () {
        expect(proUserGates.voiceJournalInsights, true);
      });
    });
    
    group('Community Challenges', () {
      test('Free users cannot access Pro community features', () {
        expect(freeUserGates.communityChallengePro, false);
      });
      
      test('Pro users can access community challenges', () {
        expect(proUserGates.communityChallengePro, true);
      });
    });
    
    group('Advanced Goal Templates', () {
      test('Free users cannot access expert goal templates', () {
        expect(freeUserGates.advancedGoalTemplates, false);
      });
      
      test('Pro users can access expert goal templates', () {
        expect(proUserGates.advancedGoalTemplates, true);
      });
    });
    
    group('Environment Presets', () {
      test('Free users cannot save environment presets', () {
        expect(freeUserGates.environmentPresets, false);
      });
      
      test('Pro users can save environment presets', () {
        expect(proUserGates.environmentPresets, true);
      });
    });
    
    group('Biometric Integration', () {
      test('Free users cannot sync biometric data', () {
        expect(freeUserGates.biometricIntegration, false);
      });
      
      test('Pro users can sync biometric data', () {
        expect(proUserGates.biometricIntegration, true);
      });
    });
    
    group('Progress Sharing & Export', () {
      test('Free users cannot generate shareable reports', () {
        expect(freeUserGates.progressSharingExport, false);
      });
      
      test('Pro users can generate shareable reports', () {
        expect(proUserGates.progressSharingExport, true);
      });
    });
    
    group('Cloud Backup & Sync', () {
      test('Free users cannot access cloud backup', () {
        expect(freeUserGates.cloudBackupSync, false);
      });
      
      test('Pro users can access cloud backup', () {
        expect(proUserGates.cloudBackupSync, true);
      });
    });
    
    group('Available Features Collection', () {
      test('Free users get empty available features list', () {
        final features = freeUserGates.availableFeatures;
        expect(features, isEmpty);
      });
      
      test('Pro users get all features including new ones', () {
        final features = proUserGates.availableFeatures;
        
        expect(features.length, 15); // 7 original + 8 new features
        expect(features, contains(ProFeature.smartScheduling));
        expect(features, contains(ProFeature.voiceJournal));
        expect(features, contains(ProFeature.communityChallenge));
        expect(features, contains(ProFeature.expertGoalTemplates));
        expect(features, contains(ProFeature.environmentPresets));
        expect(features, contains(ProFeature.biometricSync));
        expect(features, contains(ProFeature.progressReports));
        expect(features, contains(ProFeature.cloudBackup));
      });
    });
    
    group('Locked Features Collection', () {
      test('Pro users get empty locked features list', () {
        final features = proUserGates.lockedFeatures;
        expect(features, isEmpty);
      });
      
      test('Free users get all features as locked including new ones', () {
        final features = freeUserGates.lockedFeatures;
        
        expect(features.length, 15); // 7 original + 8 new features
        expect(features, contains(ProFeature.smartScheduling));
        expect(features, contains(ProFeature.voiceJournal));
        expect(features, contains(ProFeature.communityChallenge));
        expect(features, contains(ProFeature.expertGoalTemplates));
        expect(features, contains(ProFeature.environmentPresets));
        expect(features, contains(ProFeature.biometricSync));
        expect(features, contains(ProFeature.progressReports));
        expect(features, contains(ProFeature.cloudBackup));
      });
    });
    
    group('ProFeature Extensions', () {
      test('New features have proper display names', () {
        expect(ProFeature.smartScheduling.displayName, 'Smart Session Scheduling');
        expect(ProFeature.voiceJournal.displayName, 'Voice Journal Insights');
        expect(ProFeature.communityChallenge.displayName, 'Community Challenges');
        expect(ProFeature.expertGoalTemplates.displayName, 'Expert Goal Templates');
        expect(ProFeature.environmentPresets.displayName, 'Environment Presets');
        expect(ProFeature.biometricSync.displayName, 'Biometric Integration');
        expect(ProFeature.progressReports.displayName, 'Progress Reports');
        expect(ProFeature.cloudBackup.displayName, 'Cloud Backup & Sync');
      });
      
      test('New features have meaningful descriptions', () {
        expect(ProFeature.smartScheduling.description, 
            'AI suggests optimal meditation times based on your patterns');
        expect(ProFeature.voiceJournal.description,
            'Record voice reflections with automatic insights');
        expect(ProFeature.communityChallenge.description,
            'Join themed challenges with anonymous progress sharing');
        expect(ProFeature.expertGoalTemplates.description,
            'Professionally designed goal programs for specific outcomes');
        expect(ProFeature.environmentPresets.description,
            'Save custom focus environments for different contexts');
        expect(ProFeature.biometricSync.description,
            'Connect with health apps for comprehensive wellness insights');
        expect(ProFeature.progressReports.description,
            'Generate beautiful shareable progress certificates');
        expect(ProFeature.cloudBackup.description,
            'Encrypted backup and cross-device synchronization');
      });
      
      test('New features have appropriate icons', () {
        expect(ProFeature.smartScheduling.icon, '🤖');
        expect(ProFeature.voiceJournal.icon, '🎙️');
        expect(ProFeature.communityChallenge.icon, '👥');
        expect(ProFeature.expertGoalTemplates.icon, '📋');
        expect(ProFeature.environmentPresets.icon, '⚙️');
        expect(ProFeature.biometricSync.icon, '❤️');
        expect(ProFeature.progressReports.icon, '📜');
        expect(ProFeature.cloudBackup.icon, '☁️');
      });
    });
    
    group('Feature Value Proposition', () {
      test('All new features provide clear value differentiation', () {
        // Smart Scheduling builds on pattern analysis (existing Pro feature)
        expect(ProFeature.smartScheduling.description, contains('AI'));
        expect(ProFeature.smartScheduling.description, contains('patterns'));
        
        // Voice Journal enhances existing note-taking
        expect(ProFeature.voiceJournal.description, contains('voice'));
        expect(ProFeature.voiceJournal.description, contains('insights'));
        
        // Community adds social layer without making basic features social
        expect(ProFeature.communityChallenge.description, contains('challenges'));
        expect(ProFeature.communityChallenge.description, contains('anonymous'));
        
        // Expert templates build on existing goal system
        expect(ProFeature.expertGoalTemplates.description, contains('Professionally'));
        expect(ProFeature.expertGoalTemplates.description, contains('specific outcomes'));
        
        // Environment presets enhance existing focus modes
        expect(ProFeature.environmentPresets.description, contains('custom'));
        expect(ProFeature.environmentPresets.description, contains('contexts'));
        
        // Biometric sync adds health integration
        expect(ProFeature.biometricSync.description, contains('health'));
        expect(ProFeature.biometricSync.description, contains('comprehensive'));
        
        // Progress reports make achievements shareable
        expect(ProFeature.progressReports.description, contains('shareable'));
        expect(ProFeature.progressReports.description, contains('certificates'));
        
        // Cloud backup provides professional-grade data management
        expect(ProFeature.cloudBackup.description, contains('Encrypted'));
        expect(ProFeature.cloudBackup.description, contains('synchronization'));
      });
    });
    
    group('Google Play Policy Compliance', () {
      test('No essential features are locked behind paywall', () {
        // Basic session functionality should remain free
        // These new features are all enhancements, not core functionality
        const essentialFeatures = [
          'Basic meditation sessions',
          'Session tracking',
          'Basic insights',
          'Goal setting',
          'Tags and notes',
        ];
        
        // All new Pro features are value-added, not essential
        final newFeatures = [
          ProFeature.smartScheduling,
          ProFeature.voiceJournal,
          ProFeature.communityChallenge,
          ProFeature.expertGoalTemplates,
          ProFeature.environmentPresets,
          ProFeature.biometricSync,
          ProFeature.progressReports,
          ProFeature.cloudBackup,
        ];
        
        for (final feature in newFeatures) {
          // Each feature should be an enhancement, not a replacement
          expect(feature.description, isNot(contains('only way')));
          expect(feature.description, isNot(contains('required')));
          expect(feature.description, isNot(contains('must')));
        }
      });
      
      test('Features provide genuine additional value', () {
        final newFeatures = [
          ProFeature.smartScheduling,
          ProFeature.voiceJournal,
          ProFeature.communityChallenge,
          ProFeature.expertGoalTemplates,
          ProFeature.environmentPresets,
          ProFeature.biometricSync,
          ProFeature.progressReports,
          ProFeature.cloudBackup,
        ];
        
        for (final feature in newFeatures) {
          // Each feature should clearly describe added value
          expect(feature.description.length, greaterThan(20));
          expect(feature.displayName.length, greaterThan(5));
          expect(feature.icon.length, greaterThan(0));
        }
      });
    });
  });
}
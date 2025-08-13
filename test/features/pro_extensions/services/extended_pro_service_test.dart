/// Tests for Extended Pro Service
/// 
/// Validates service layer behavior with proper Pro gating and feature access.

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/features/pro_extensions/services/extended_pro_service.dart';

class MockProGates implements MindTrainerProGates {
  final bool _isProActive;
  
  MockProGates(this._isProActive);
  
  @override
  bool get isProActive => _isProActive;
  
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
  List<ProFeature> get availableFeatures => _isProActive 
      ? ProFeature.values 
      : [];
  
  @override
  List<ProFeature> get lockedFeatures => _isProActive 
      ? [] 
      : ProFeature.values;
}

void main() {
  group('Extended Pro Service', () {
    late ExtendedProService freeService;
    late ExtendedProService proService;
    
    setUp(() {
      freeService = ExtendedProService(MockProGates(false));
      proService = ExtendedProService(MockProGates(true));
    });
    
    group('Smart Session Scheduling', () {
      test('Free users cannot get schedule recommendations', () async {
        final recommendations = await freeService.getSmartScheduleRecommendations();
        expect(recommendations, isNull);
        expect(freeService.hasSmartScheduling, false);
      });
      
      test('Pro users get schedule recommendations', () async {
        final recommendations = await proService.getSmartScheduleRecommendations();
        
        expect(recommendations, isNotNull);
        expect(recommendations!.isNotEmpty, true);
        expect(proService.hasSmartScheduling, true);
        
        // Validate recommendation structure
        final firstRec = recommendations.first;
        expect(firstRec.recommendedTime, isA<DateTime>());
        expect(firstRec.confidence, inInclusiveRange(0.0, 1.0));
        expect(firstRec.reason.isNotEmpty, true);
        expect(firstRec.estimatedQuality, isA<SessionQuality>());
      });
      
      test('Schedule recommendations can be customized', () async {
        final customDate = DateTime(2023, 12, 25);
        final recommendations = await proService.getSmartScheduleRecommendations(
          forDate: customDate,
          preferredDuration: 20,
        );
        
        expect(recommendations, isNotNull);
        expect(recommendations!.isNotEmpty, true);
      });
    });
    
    group('Voice Journal Insights', () {
      test('Free users cannot record voice journals', () async {
        final entry = await freeService.recordVoiceJournal('session1', '/path/audio.wav');
        expect(entry, isNull);
        expect(freeService.hasVoiceJournal, false);
      });
      
      test('Pro users can record voice journals', () async {
        final entry = await proService.recordVoiceJournal('session1', '/path/audio.wav');
        
        expect(entry, isNotNull);
        expect(proService.hasVoiceJournal, true);
        
        expect(entry!.sessionId, 'session1');
        expect(entry.audioFilePath, '/path/audio.wav');
        expect(entry.transcription.isNotEmpty, true);
        expect(entry.keywordInsights.isNotEmpty, true);
      });
      
      test('Free users cannot get voice insights', () async {
        final insights = await freeService.getVoiceInsights('session1');
        expect(insights, isNull);
      });
      
      test('Pro users get voice insights', () async {
        final insights = await proService.getVoiceInsights('session1');
        
        expect(insights, isNotNull);
        expect(insights!.isNotEmpty, true);
        
        final firstInsight = insights.first;
        expect(firstInsight.type, isA<InsightType>());
        expect(firstInsight.content.isNotEmpty, true);
        expect(firstInsight.confidence, inInclusiveRange(0.0, 1.0));
      });
    });
    
    group('Community Challenges', () {
      test('Free users get empty challenges list', () async {
        final challenges = await freeService.getAvailableChallenges();
        expect(challenges, isEmpty);
        expect(freeService.hasCommunityChallenge, false);
      });
      
      test('Pro users get available challenges', () async {
        final challenges = await proService.getAvailableChallenges();
        
        expect(challenges.isNotEmpty, true);
        expect(proService.hasCommunityChallenge, true);
        
        final firstChallenge = challenges.first;
        expect(firstChallenge.id.isNotEmpty, true);
        expect(firstChallenge.title.isNotEmpty, true);
        expect(firstChallenge.description.isNotEmpty, true);
        expect(firstChallenge.durationDays, greaterThan(0));
        expect(firstChallenge.participantCount, greaterThanOrEqualTo(0));
        expect(firstChallenge.category, isA<ChallengeCategory>());
      });
      
      test('Free users cannot join challenges', () async {
        final result = await freeService.joinChallenge('gratitude_21');
        expect(result, false);
      });
      
      test('Pro users can join challenges', () async {
        final result = await proService.joinChallenge('gratitude_21');
        expect(result, true);
      });
    });
    
    group('Expert Goal Templates', () {
      test('Free users get empty templates list', () async {
        final templates = await freeService.getExpertGoalTemplates();
        expect(templates, isEmpty);
        expect(freeService.hasExpertGoalTemplates, false);
      });
      
      test('Pro users get expert templates', () async {
        final templates = await proService.getExpertGoalTemplates();
        
        expect(templates.isNotEmpty, true);
        expect(proService.hasExpertGoalTemplates, true);
        
        final firstTemplate = templates.first;
        expect(firstTemplate.id.isNotEmpty, true);
        expect(firstTemplate.title.isNotEmpty, true);
        expect(firstTemplate.description.isNotEmpty, true);
        expect(firstTemplate.expertName.isNotEmpty, true);
        expect(firstTemplate.estimatedWeeks, greaterThan(0));
        expect(firstTemplate.milestones.isNotEmpty, true);
        expect(firstTemplate.targetOutcome.isNotEmpty, true);
      });
      
      test('Free users cannot apply expert templates', () async {
        final result = await freeService.applyExpertTemplate('better_sleep');
        expect(result, false);
      });
      
      test('Pro users can apply expert templates', () async {
        final result = await proService.applyExpertTemplate('better_sleep');
        expect(result, true);
      });
    });
    
    group('Environment Presets', () {
      test('Free users get empty presets list', () async {
        final presets = await freeService.getEnvironmentPresets();
        expect(presets, isEmpty);
        expect(freeService.hasEnvironmentPresets, false);
      });
      
      test('Pro users get environment presets', () async {
        final presets = await proService.getEnvironmentPresets();
        
        expect(presets.isNotEmpty, true);
        expect(proService.hasEnvironmentPresets, true);
        
        final firstPreset = presets.first;
        expect(firstPreset.id.isNotEmpty, true);
        expect(firstPreset.name.isNotEmpty, true);
        expect(firstPreset.description.isNotEmpty, true);
        expect(firstPreset.environmentId.isNotEmpty, true);
        expect(firstPreset.customSettings, isA<Map<String, dynamic>>());
      });
      
      test('Free users cannot save presets', () async {
        const preset = EnvironmentPreset(
          id: 'test',
          name: 'Test Preset',
          description: 'Test description',
          environmentId: 'forest',
          customSettings: {},
        );
        
        final result = await freeService.saveEnvironmentPreset(preset);
        expect(result, false);
      });
      
      test('Pro users can save presets', () async {
        const preset = EnvironmentPreset(
          id: 'test',
          name: 'Test Preset',
          description: 'Test description',
          environmentId: 'forest',
          customSettings: {'volume': 0.8},
        );
        
        final result = await proService.saveEnvironmentPreset(preset);
        expect(result, true);
      });
    });
    
    group('Biometric Integration', () {
      test('Free users cannot connect biometric sources', () async {
        final result = await freeService.connectBiometricSource(BiometricSourceType.healthKit);
        expect(result, false);
        expect(freeService.hasBiometricIntegration, false);
      });
      
      test('Pro users can connect biometric sources', () async {
        final result = await proService.connectBiometricSource(BiometricSourceType.healthKit);
        expect(result, true);
        expect(proService.hasBiometricIntegration, true);
      });
      
      test('Free users cannot get biometric insights', () async {
        final insights = await freeService.getBiometricInsights();
        expect(insights, isNull);
      });
      
      test('Pro users get biometric insights', () async {
        final insights = await proService.getBiometricInsights();
        
        expect(insights, isNotNull);
        expect(insights!.correlations, isA<Map<String, double>>());
        expect(insights.recommendations, isA<List<String>>());
        expect(insights.lastUpdated, isA<DateTime>());
        
        // Validate correlation values are in valid range
        for (final correlation in insights.correlations.values) {
          expect(correlation, inInclusiveRange(-1.0, 1.0));
        }
      });
    });
    
    group('Progress Reports', () {
      test('Free users cannot generate progress reports', () async {
        final report = await freeService.generateProgressReport();
        expect(report, isNull);
        expect(freeService.hasProgressReports, false);
      });
      
      test('Pro users can generate progress reports', () async {
        final report = await proService.generateProgressReport();
        
        expect(report, isNotNull);
        expect(proService.hasProgressReports, true);
        
        expect(report!.title.isNotEmpty, true);
        expect(report.period.isNotEmpty, true);
        expect(report.achievements, isA<List<Achievement>>());
        expect(report.statistics, isA<Map<String, String>>());
        expect(report.generatedAt, isA<DateTime>());
      });
      
      test('Progress reports support different styles', () async {
        final certificateReport = await proService.generateProgressReport(
          style: ReportStyle.certificate,
        );
        final summaryReport = await proService.generateProgressReport(
          style: ReportStyle.summary,
        );
        
        expect(certificateReport, isNotNull);
        expect(summaryReport, isNotNull);
      });
      
      test('Progress reports can specify date ranges', () async {
        final fromDate = DateTime.now().subtract(const Duration(days: 30));
        final toDate = DateTime.now();
        
        final report = await proService.generateProgressReport(
          fromDate: fromDate,
          toDate: toDate,
        );
        
        expect(report, isNotNull);
      });
    });
    
    group('Cloud Backup & Sync', () {
      test('Free users cannot enable cloud backup', () async {
        final result = await freeService.enableCloudBackup();
        expect(result, false);
        expect(freeService.hasCloudBackup, false);
      });
      
      test('Pro users can enable cloud backup', () async {
        final result = await proService.enableCloudBackup();
        expect(result, true);
        expect(proService.hasCloudBackup, true);
      });
      
      test('Free users cannot get sync status', () async {
        final status = await freeService.getCloudSyncStatus();
        expect(status, isNull);
      });
      
      test('Pro users get cloud sync status', () async {
        final status = await proService.getCloudSyncStatus();
        
        expect(status, isNotNull);
        expect(status!.isEnabled, isA<bool>());
        expect(status.sessionsSynced, greaterThanOrEqualTo(0));
        expect(status.syncedDevices, isA<List<String>>());
        expect(status.encryptionEnabled, true); // Should always be encrypted
      });
    });
    
    group('Available Extensions', () {
      test('Free users get empty extensions list', () {
        final extensions = freeService.getAvailableExtensions();
        expect(extensions, isEmpty);
      });
      
      test('Pro users get all available extensions', () {
        final extensions = proService.getAvailableExtensions();
        
        expect(extensions.length, ProExtension.values.length);
        expect(extensions, contains(ProExtension.smartScheduling));
        expect(extensions, contains(ProExtension.voiceJournal));
        expect(extensions, contains(ProExtension.communityChallenge));
        expect(extensions, contains(ProExtension.expertGoalTemplates));
        expect(extensions, contains(ProExtension.environmentPresets));
        expect(extensions, contains(ProExtension.biometricIntegration));
        expect(extensions, contains(ProExtension.progressReports));
        expect(extensions, contains(ProExtension.cloudBackup));
      });
    });
    
    group('Feature Integration', () {
      test('All Pro features maintain consistent gating behavior', () {
        // Verify that all feature checks return consistent results
        expect(freeService.hasSmartScheduling, false);
        expect(freeService.hasVoiceJournal, false);
        expect(freeService.hasCommunityChallenge, false);
        expect(freeService.hasExpertGoalTemplates, false);
        expect(freeService.hasEnvironmentPresets, false);
        expect(freeService.hasBiometricIntegration, false);
        expect(freeService.hasProgressReports, false);
        expect(freeService.hasCloudBackup, false);
        
        expect(proService.hasSmartScheduling, true);
        expect(proService.hasVoiceJournal, true);
        expect(proService.hasCommunityChallenge, true);
        expect(proService.hasExpertGoalTemplates, true);
        expect(proService.hasEnvironmentPresets, true);
        expect(proService.hasBiometricIntegration, true);
        expect(proService.hasProgressReports, true);
        expect(proService.hasCloudBackup, true);
      });
      
      test('Service properly handles async operations', () async {
        // All async methods should complete within reasonable time
        final futures = [
          proService.getSmartScheduleRecommendations(),
          proService.recordVoiceJournal('test', '/test.wav'),
          proService.getAvailableChallenges(),
          proService.getExpertGoalTemplates(),
          proService.getEnvironmentPresets(),
          proService.getBiometricInsights(),
          proService.generateProgressReport(),
          proService.getCloudSyncStatus(),
        ];
        
        final results = await Future.wait(futures);
        
        // All operations should complete successfully for Pro users
        expect(results.every((result) => result != null), true);
      });
    });
  });
}
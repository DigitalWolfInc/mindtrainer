/// Launch Readiness End-to-End Tests for MindTrainer Pro
/// 
/// Comprehensive testing of the complete Pro experience including:
/// - Free-tier onboarding and limitations
/// - Pro purchase flow and unlock behavior 
/// - Pro feature usage and expiration handling
/// - UI states and analytics integration

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/play_billing_pro_manager.dart';
import 'package:mindtrainer/core/payments/pro_catalog.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/payments/pro_status.dart';
import 'package:mindtrainer/core/payments/subscription_gateway.dart';
import 'package:mindtrainer/features/focus_modes/application/focus_mode_service.dart';
import 'package:mindtrainer/features/focus_modes/domain/focus_environment.dart';
import 'package:mindtrainer/core/storage/local_storage.dart';

class MockLocalStorage implements LocalStorage {
  final Map<String, String> _storage = {};
  
  @override
  Future<String?> getString(String key) async => _storage[key];
  
  @override
  Future<void> setString(String key, String value) async => _storage[key] = value;
}

void main() {
  group('Pro Launch Readiness Tests', () {
    late ProCatalog testCatalog;
    late PlayBillingProManager billingManager;
    late MindTrainerProGates proGates;
    late MockLocalStorage localStorage;
    late FocusModeService focusService;
    
    setUp(() async {
      testCatalog = ProCatalogFactory.createDefault();
      billingManager = PlayBillingProManager.fake(testCatalog);
      proGates = MindTrainerProGates.fromStatusCheck(() => billingManager.isProActive);
      localStorage = MockLocalStorage();
      focusService = FocusModeService(proGates, localStorage);
      
      await billingManager.initialize();
    });
    
    tearDown(() async {
      await billingManager.dispose();
    });
    
    group('Free-Tier Onboarding Experience', () {
      test('New user starts with proper free tier experience', () async {
        // Initially free user
        expect(billingManager.isProActive, false);
        expect(proGates.isProActive, false);
        
        // Free tier limitations are in place
        expect(proGates.dailySessionLimit, 5);
        expect(proGates.unlimitedDailySessions, false);
        expect(proGates.extendedCoachingPhases, false);
        expect(proGates.advancedAnalytics, false);
        expect(proGates.dataExport, false);
        expect(proGates.customGoals, false);
        expect(proGates.premiumThemes, false);
        expect(proGates.adFree, false);
        
        // Focus modes - free environments available
        final availableEnvironments = focusService.getAvailableEnvironments();
        expect(availableEnvironments.length, 3); // Only free environments
        expect(availableEnvironments.every((env) => !env.isProOnly), true);
        
        // Should have basic environments
        final envTypes = availableEnvironments.map((e) => e.environment).toSet();
        expect(envTypes, contains(FocusEnvironment.silence));
        expect(envTypes, contains(FocusEnvironment.whiteNoise));
        expect(envTypes, contains(FocusEnvironment.rain));
        
        // Pro environments not available
        expect(envTypes, isNot(contains(FocusEnvironment.forest)));
        expect(envTypes, isNot(contains(FocusEnvironment.ocean)));
        expect(envTypes, isNot(contains(FocusEnvironment.binauralBeats)));
      });
      
      test('Free user can complete basic focus sessions', () async {
        // User should be able to start sessions with free environments
        final config = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 10,
        );
        
        final started = await focusService.startSession(config);
        expect(started, true);
        expect(focusService.state, FocusSessionState.focusing);
        
        // Complete session
        final outcome = await focusService.stopSession(focusRating: 4);
        expect(outcome, isNotNull);
        expect(outcome!.config.environment, FocusEnvironment.silence);
        expect(focusService.state, FocusSessionState.completed);
      });
      
      test('Free user sees Pro environment restrictions', () async {
        // Attempting Pro environment should fail
        final proConfig = FocusSessionConfig.basic(
          environment: FocusEnvironment.forest, // Pro only
          sessionDurationMinutes: 10,
        );
        
        final started = await focusService.startSession(proConfig);
        expect(started, false);
        expect(focusService.state, FocusSessionState.preparing);
      });
      
      test('Session limits are enforced for free users', () {
        // Free user has 5 session limit
        expect(proGates.canStartSession(0), true);
        expect(proGates.canStartSession(4), true);
        expect(proGates.canStartSession(5), false);
        expect(proGates.canStartSession(10), false);
      });
    });
    
    group('Pro Purchase Flow', () {
      test('Complete purchase flow upgrades user to Pro', () async {
        // Track purchase events
        final purchaseEvents = <PurchaseEvent>[];
        final subscription = billingManager.purchaseEventStream.listen((event) {
          purchaseEvents.add(event);
        });
        
        // Initially free
        expect(billingManager.isProActive, false);
        
        // Purchase Pro monthly
        final result = await billingManager.purchasePlan('pro_monthly');
        expect(result.success, true);
        
        // Should now be Pro
        expect(billingManager.isProActive, true);
        expect(billingManager.currentStatus.tier, ProTier.pro);
        
        // Purchase events should be emitted
        expect(purchaseEvents.length, greaterThanOrEqualTo(2));
        expect(purchaseEvents.first.type, PurchaseEventType.started);
        expect(purchaseEvents.last.type, PurchaseEventType.completed);
        expect(purchaseEvents.last.productId, 'pro_monthly');
        
        await subscription.cancel();
      });
      
      test('Pro purchase unlocks all features immediately', () async {
        // Purchase Pro
        await billingManager.purchasePlan('pro_monthly');
        
        // All Pro features should be unlocked
        expect(proGates.unlimitedDailySessions, true);
        expect(proGates.dailySessionLimit, -1);
        expect(proGates.extendedCoachingPhases, true);
        expect(proGates.advancedAnalytics, true);
        expect(proGates.moodFocusCorrelations, true);
        expect(proGates.tagAssociations, true);
        expect(proGates.keywordUplift, true);
        expect(proGates.extendedInsightsHistory, true);
        expect(proGates.dataExport, true);
        expect(proGates.dataImport, true);
        expect(proGates.dataPortability, true);
        expect(proGates.customGoals, true);
        expect(proGates.multipleGoals, true);
        expect(proGates.advancedGoalTracking, true);
        expect(proGates.adFree, true);
        expect(proGates.premiumThemes, true);
        expect(proGates.prioritySupport, true);
        expect(proGates.smartSessionScheduling, true);
        expect(proGates.voiceJournalInsights, true);
        expect(proGates.communityChallengePro, true);
        expect(proGates.advancedGoalTemplates, true);
        expect(proGates.environmentPresets, true);
        expect(proGates.biometricIntegration, true);
        expect(proGates.progressSharingExport, true);
        expect(proGates.cloudBackupSync, true);
      });
      
      test('Pro purchase unlocks all focus environments', () async {
        // Purchase Pro
        await billingManager.purchasePlan('pro_yearly');
        
        // All environments should be available
        final environments = focusService.getAvailableEnvironments();
        expect(environments.length, FocusEnvironmentConfig.environments.length);
        
        // Should include Pro environments
        final envTypes = environments.map((e) => e.environment).toSet();
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
      
      test('Pro user can start sessions with advanced features', () async {
        await billingManager.purchasePlan('pro_monthly');
        
        // Pro session with advanced features
        final proConfig = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 20,
          breathingPattern: BreathingPattern.patterns[0], // Box breathing
          soundVolume: 0.8,
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        final started = await focusService.startSession(proConfig);
        expect(started, true);
        expect(focusService.state, FocusSessionState.breathing); // Starts with breathing
        
        await focusService.stopSession();
      });
      
      test('Cancelled purchase does not unlock Pro features', () async {
        final manager = PlayBillingProManager.fake(
          testCatalog,
          simulateUserCancel: true,
        );
        await manager.initialize();
        
        final gates = MindTrainerProGates.fromStatusCheck(() => manager.isProActive);
        
        final result = await manager.purchasePlan('pro_monthly');
        expect(result.success, false);
        expect(result.cancelled, true);
        
        // Should still be free
        expect(gates.isProActive, false);
        expect(gates.dailySessionLimit, 5);
        
        await manager.dispose();
      });
    });
    
    group('Pro Feature Usage', () {
      setUp(() async {
        // Start each test with Pro active
        await billingManager.purchasePlan('pro_monthly');
      });
      
      test('Pro user has unlimited session access', () {
        expect(proGates.unlimitedDailySessions, true);
        expect(proGates.canStartSession(0), true);
        expect(proGates.canStartSession(10), true);
        expect(proGates.canStartSession(100), true);
        expect(proGates.canStartSession(1000), true);
      });
      
      test('Pro user has extended insights history', () {
        expect(proGates.extendedInsightsHistory, true);
        expect(proGates.insightsHistoryDays, -1); // Unlimited
      });
      
      test('Pro user can use advanced coaching phases', () {
        expect(proGates.extendedCoachingPhases, true);
        
        // All coaching phases should be available
        expect(proGates.isCoachPhaseAvailable('stabilize'), true);
        expect(proGates.isCoachPhaseAvailable('open'), true);
        expect(proGates.isCoachPhaseAvailable('reflect'), true);
        expect(proGates.isCoachPhaseAvailable('reframe'), true);
        expect(proGates.isCoachPhaseAvailable('plan'), true);
        expect(proGates.isCoachPhaseAvailable('close'), true);
      });
      
      test('Pro session generates proper tags and analytics', () async {
        final proConfig = FocusSessionConfig.pro(
          environment: FocusEnvironment.ocean,
          sessionDurationMinutes: 15,
          breathingPattern: BreathingPattern.patterns[1], // 4-7-8
          enableBinauralBeats: true,
          enableBreathingCues: true,
        );
        
        await focusService.startSession(proConfig);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final outcome = await focusService.stopSession(focusRating: 5);
        expect(outcome, isNotNull);
        
        // Convert to session for tag analysis
        final session = outcome!.toSession();
        
        expect(session.tags, contains('env_ocean'));
        expect(session.tags.any((tag) => tag.startsWith('breathing_')), true);
        expect(session.tags, contains('binaural_beats'));
        expect(session.tags, contains('breathing_cues'));
        expect(session.tags, contains('rating_5'));
      });
    });
    
    group('Purchase Restoration and Renewal', () {
      test('Existing purchases are restored on app restart', () async {
        // Purchase first, then test restoration
        await billingManager.purchasePlan('pro_yearly');
        expect(billingManager.isProActive, true);
        
        // Restore purchases (should maintain Pro status)
        final restored = await billingManager.restorePurchases();
        expect(restored, true);
        expect(billingManager.isProActive, true);
        expect(billingManager.currentStatus.tier, ProTier.pro);
      });
      
      test('Pro status includes expiration information', () async {
        await billingManager.purchasePlan('pro_monthly');
        
        final status = billingManager.currentStatus;
        expect(status.isPro, true);
        expect(status.active, true);
        expect(status.expiresAt, isNotNull);
        expect(status.autoRenewing, true);
        
        // Monthly should expire in ~30 days
        final daysTillExpiry = status.expiresAt!.difference(DateTime.now()).inDays;
        expect(daysTillExpiry, inInclusiveRange(25, 35));
      });
    });
    
    group('Pro Catalog and Pricing', () {
      test('Catalog contains correct pricing and features', () {
        final catalog = billingManager.catalog;
        
        final monthlyPlan = catalog.findPlanById('pro_monthly');
        final yearlyPlan = catalog.findPlanById('pro_yearly');
        
        expect(monthlyPlan, isNotNull);
        expect(yearlyPlan, isNotNull);
        
        expect(monthlyPlan!.basePriceUsd, 9.99);
        expect(yearlyPlan!.basePriceUsd, 99.99);
        expect(yearlyPlan.bestValue, true);
        
        // Yearly should offer savings
        final savings = yearlyPlan.calculateSavings(monthlyPlan.basePriceUsd);
        expect(savings, greaterThan(15.0)); // At least $15 savings
        
        final savingsPercent = yearlyPlan.getSavingsPercentage(monthlyPlan.basePriceUsd);
        expect(savingsPercent, greaterThan(15)); // At least 15% savings
      });
      
      test('Plans include correct feature lists', () {
        final catalog = billingManager.catalog;
        
        for (final plan in catalog.plans) {
          expect(plan.features, isNotEmpty);
          expect(plan.features, contains('Unlimited focus sessions'));
          expect(plan.features, contains('Advanced insights and analytics'));
          expect(plan.features, contains('Data export and backup'));
          expect(plan.features, contains('AI coaching conversations'));
          expect(plan.features, contains('Premium themes'));
          expect(plan.features, contains('Ad-free experience'));
        }
        
        // Yearly should mention savings
        final yearlyPlan = catalog.yearlyPlan!;
        expect(yearlyPlan.features.any((f) => f.contains('free')), true);
      });
    });
    
    group('Error Handling and Edge Cases', () {
      test('Billing service unavailable handled gracefully', () async {
        final manager = PlayBillingProManager.fake(
          testCatalog,
          simulateConnectionFailure: true,
        );
        
        final initialized = await manager.initialize();
        expect(initialized, false);
        
        // Should still function with default catalog
        expect(manager.catalog.plans.length, 2);
        expect(manager.isProActive, false);
        
        await manager.dispose();
      });
      
      test('Network errors during purchase handled gracefully', () async {
        final manager = PlayBillingProManager.fake(
          testCatalog,
          simulatePurchaseFailure: true,
        );
        await manager.initialize();
        
        final result = await manager.purchasePlan('pro_monthly');
        expect(result.success, false);
        expect(result.error, isNotNull);
        expect(manager.isProActive, false);
        
        await manager.dispose();
      });
      
      test('Invalid product ID handled gracefully', () async {
        final result = await billingManager.purchasePlan('invalid_product_id');
        expect(result.success, false);
        expect(result.error, contains('not found'));
      });
    });
    
    group('Google Play Policy Compliance', () {
      test('Free tier provides substantial value', () {
        // Free tier should have meaningful functionality
        expect(proGates.canStartSession(4), true); // 5 sessions is generous
        
        final freeEnvironments = FocusEnvironmentConfig.freeEnvironments;
        expect(freeEnvironments.length, greaterThanOrEqualTo(3));
        
        // Free environments should include variety
        final hasQuiet = freeEnvironments.any((e) => e.soundFiles.isEmpty);
        final hasSound = freeEnvironments.any((e) => e.soundFiles.isNotEmpty);
        expect(hasQuiet, true);
        expect(hasSound, true);
      });
      
      test('Pro features are enhancements, not essential functionality', () {
        // Free users can complete full meditation sessions
        final basicConfig = FocusSessionConfig.basic(
          environment: FocusEnvironment.silence,
          sessionDurationMinutes: 10,
        );
        
        expect(basicConfig.environment, isNotNull);
        expect(basicConfig.sessionDurationMinutes, greaterThan(0));
        
        // Pro features add value but are not required
        final proConfig = FocusSessionConfig.pro(
          environment: FocusEnvironment.forest,
          sessionDurationMinutes: 10,
          breathingPattern: BreathingPattern.patterns.first,
        );
        
        // Pro enhances but doesn't replace basic functionality
        expect(proConfig.sessionDurationMinutes, basicConfig.sessionDurationMinutes);
        expect(proConfig.breathingPattern, isNotNull); // Enhancement
        expect(proConfig.enableBinauralBeats, false); // Optional enhancement
      });
      
      test('Feature descriptions emphasize enhancement language', () {
        final proEnvironments = FocusEnvironmentConfig.proEnvironments;
        
        for (final env in proEnvironments) {
          final description = env.description.toLowerCase();
          
          // Should not suggest this is the only way to meditate
          expect(description, isNot(contains('only')));
          expect(description, isNot(contains('required')));
          expect(description, isNot(contains('essential')));
        }
      });
    });
  });
}
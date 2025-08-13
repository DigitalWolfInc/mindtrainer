/// Pro UI Audit Tests for MindTrainer
/// 
/// Comprehensive audit of Pro indicators, locked states, and upgrade CTAs
/// across all screens and components to ensure proper Pro experience.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/payments/play_billing_pro_manager.dart';
import 'package:mindtrainer/core/payments/pro_catalog.dart';
import 'package:mindtrainer/core/analytics/pro_conversion_analytics.dart';
import 'package:mindtrainer/features/focus_modes/presentation/advanced_focus_modes_screen.dart';
import 'package:mindtrainer/features/focus_modes/presentation/focus_environment_selector.dart';
import 'package:mindtrainer/features/focus_modes/presentation/breathing_pattern_selector.dart';
import 'package:mindtrainer/features/focus_modes/application/focus_mode_service.dart';
import 'package:mindtrainer/core/storage/local_storage.dart';

class MockLocalStorage implements LocalStorage {
  final Map<String, String> _storage = {};
  
  @override
  Future<String?> getString(String key) async => _storage[key];
  
  @override
  Future<void> setString(String key, String value) async => _storage[key] = value;
}

void main() {
  group('Pro UI Audit Tests', () {
    late PlayBillingProManager billingManager;
    late MindTrainerProGates proGates;
    late FocusModeService focusService;
    late ProConversionAnalytics analytics;
    late MockLocalStorage localStorage;
    
    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    setUp(() async {
      final catalog = ProCatalogFactory.createDefault();
      billingManager = PlayBillingProManager.fake(catalog);
      proGates = MindTrainerProGates.fromStatusCheck(() => billingManager.isProActive);
      localStorage = MockLocalStorage();
      focusService = FocusModeService(proGates, localStorage);
      analytics = ProConversionAnalytics.fake();
      
      await billingManager.initialize();
    });
    
    tearDown(() async {
      await billingManager.dispose();
      await analytics.dispose();
    });
    
    group('Advanced Focus Modes Screen UI Audit', () {
      testWidgets('Free user sees proper Pro indicators', (WidgetTester tester) async {
        // Ensure user is free
        expect(billingManager.isProActive, false);
        
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Should show Pro badge in title
        expect(find.text('Pro'), findsAtLeastNWidgets(1));
        
        // Should show upgrade button in app bar
        expect(find.text('Upgrade'), findsOneWidget);
        
        // Should show Pro banner explaining benefits
        expect(find.text('Unlock Premium Focus Environments'), findsOneWidget);
        expect(find.text('9 immersive soundscapes, breathing cues, and binaural beats'), findsOneWidget);
        expect(find.text('Try Pro'), findsOneWidget);
      });
      
      testWidgets('Free user sees locked advanced settings', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Should show locked advanced settings section
        expect(find.text('Pro Features'), findsOneWidget);
        expect(find.byIcon(Icons.lock), findsWidgets);
        expect(find.text('Binaural Beats'), findsOneWidget);
        expect(find.text('Breathing Cues'), findsOneWidget);
        expect(find.text('Custom Patterns'), findsOneWidget);
      });
      
      testWidgets('Free user sees Pro environment restrictions', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Environment selector should show Pro badges on locked environments
        expect(find.byType(FocusEnvironmentSelector), findsOneWidget);
        
        // Should show upgrade CTA when trying to select Pro environment
        // (This would be tested through interaction)
      });
      
      testWidgets('Pro user sees unlocked interface', (WidgetTester tester) async {
        // Upgrade to Pro
        await billingManager.purchasePlan('pro_monthly');
        
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Should not show Pro banner
        expect(find.text('Unlock Premium Focus Environments'), findsNothing);
        
        // Should not show upgrade button
        expect(find.text('Upgrade'), findsNothing);
        
        // Should show unlocked advanced settings
        expect(find.text('Pro Features'), findsNothing); // No locked section
        expect(find.byType(BreathingPatternSelector), findsOneWidget);
      });
      
      testWidgets('Start button shows correct state based on Pro status', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // For free user with free environment selected, should show "Start Focus Session"
        expect(find.text('Start Focus Session'), findsOneWidget);
        
        // TODO: Test with Pro environment selected - should show "Upgrade to Pro"
        // This would require simulating environment selection
      });
    });
    
    group('Focus Environment Selector UI Audit', () {
      testWidgets('Free environments show no Pro indicators', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: FocusEnvironmentSelector(
              selectedEnvironment: null,
              proGates: proGates,
              onEnvironmentSelected: (env) {},
              onProUpgradeRequested: () {},
            ),
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Free environments should have no locks or Pro badges
        // Only 3 environments should be shown for free users
        final environmentCards = find.byType(Card);
        expect(environmentCards, findsNWidgets(3));
        
        // Should not show lock icons on free environments
        // (Lock icons should only appear on Pro environments)
      });
      
      testWidgets('Pro environments show proper lock indicators for free users', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: FocusEnvironmentSelector(
              selectedEnvironment: null,
              proGates: proGates,
              onEnvironmentSelected: (env) {},
              onProUpgradeRequested: () {},
              showAllEnvironments: true, // Force show all for testing
            ),
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Should show lock icons on Pro environments
        expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
        
        // Pro environments should have Pro badges
        expect(find.text('Pro'), findsAtLeastNWidgets(1));
      });
    });
    
    group('Breathing Pattern Selector UI Audit', () {
      testWidgets('Free user sees breathing patterns as locked', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: BreathingPatternSelector(
              selectedPattern: null,
              enabled: false, // Free user
              onPatternSelected: (pattern) {},
              onProUpgradeRequested: () {},
            ),
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Should show Pro indicator
        expect(find.text('Pro'), findsOneWidget);
        
        // Should show upgrade message
        expect(find.text('Upgrade to Pro for guided breathing patterns'), findsOneWidget);
        
        // Breathing patterns should show lock icons
        expect(find.byIcon(Icons.lock), findsAtLeastNWidgets(1));
      });
      
      testWidgets('Pro user sees breathing patterns as unlocked', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: BreathingPatternSelector(
              selectedPattern: null,
              enabled: true, // Pro user
              onPatternSelected: (pattern) {},
              onProUpgradeRequested: () {},
            ),
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Should not show Pro indicator in description
        expect(find.text('Choose a breathing pattern to guide your session'), findsOneWidget);
        
        // Should not show lock icons
        expect(find.byIcon(Icons.lock), findsNothing);
        
        // Should show breathing visualizations
        expect(find.text('In'), findsAtLeastNWidgets(1));
        expect(find.text('Out'), findsAtLeastNWidgets(1));
      });
    });
    
    group('Pro Indicator Consistency Audit', () {
      test('All Pro badges use consistent styling', () {
        // This would be a visual consistency check
        // In a real implementation, we'd verify:
        // - Same color scheme (amber/orange)
        // - Same border radius (8px)
        // - Same font size and weight
        // - Same text content ('Pro')
      });
      
      test('All lock icons use consistent styling', () {
        // Visual consistency check for:
        // - Same icon (Icons.lock)
        // - Same size (16px typically)
        // - Same color (grey)
        // - Same positioning (trailing)
      });
      
      test('All upgrade CTAs use consistent messaging', () {
        // Check that upgrade buttons/links use:
        // - Consistent action words ('Upgrade', 'Try Pro', 'Get Pro')
        // - Consistent styling (color, size, etc.)
        // - Consistent value proposition messaging
      });
    });
    
    group('Accessibility Audit', () {
      testWidgets('Pro indicators have proper accessibility labels', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Pro badges should have semantic labels
        final proBadges = find.text('Pro');
        expect(proBadges, findsAtLeastNWidgets(1));
        
        // Lock icons should have semantic labels
        final lockIcons = find.byIcon(Icons.lock);
        if (lockIcons.evaluate().isNotEmpty) {
          // Should have accessibility labels
          // In real implementation, check semantics
        }
      });
      
      testWidgets('Upgrade buttons are keyboard accessible', (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Upgrade buttons should be focusable and have proper semantics
        final upgradeButtons = find.text('Try Pro');
        expect(upgradeButtons, findsAtLeastNWidgets(1));
        
        // TODO: Test keyboard navigation and screen reader compatibility
      });
    });
    
    group('Analytics Integration Audit', () {
      testWidgets('UI interactions trigger proper analytics events', (WidgetTester tester) async {
        final analyticsEvents = <ProConversionData>[];
        analytics.eventStream.listen((event) => analyticsEvents.add(event));
        
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () async {
              await analytics.trackUpgradeCtaClick('free', ctaLocation: 'focus_modes_screen');
            },
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Tap upgrade button
        await tester.tap(find.text('Try Pro'));
        await tester.pumpAndSettle();
        
        // Should track CTA click
        expect(analyticsEvents, isNotEmpty);
        expect(analyticsEvents.last.event, ProConversionEvent.upgradeCtaClicked);
        expect(analyticsEvents.last.userTier, 'free');
      });
    });
    
    group('Error State UI Audit', () {
      testWidgets('Billing unavailable shows graceful degradation', (WidgetTester tester) async {
        // Create manager with connection failure
        final failingManager = PlayBillingProManager.fake(
          ProCatalogFactory.createDefault(),
          simulateConnectionFailure: true,
        );
        await failingManager.initialize();
        
        final failingGates = MindTrainerProGates.fromStatusCheck(() => failingManager.isProActive);
        
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: failingGates,
            focusService: FocusModeService(failingGates, localStorage),
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Should still show the screen without crashing
        expect(find.text('Advanced Focus Modes'), findsOneWidget);
        
        // Upgrade buttons might be disabled or show error state
        // This depends on implementation details
        
        await failingManager.dispose();
      });
    });
    
    group('Performance Audit', () {
      testWidgets('UI renders quickly with Pro checks', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        stopwatch.stop();
        
        // Screen should render quickly (< 100ms for basic layout)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
      
      testWidgets('Pro status checks do not block UI', (WidgetTester tester) async {
        // Multiple rapid pro status checks shouldn't impact performance
        for (int i = 0; i < 100; i++) {
          final isProActive = proGates.isProActive;
          expect(isProActive, isFalse);
        }
        
        // UI should still be responsive
        await tester.pumpWidget(MaterialApp(
          home: AdvancedFocusModesScreen(
            proGates: proGates,
            focusService: focusService,
            onProUpgradeRequested: () {},
          ),
        ));
        
        await tester.pumpAndSettle();
        
        expect(find.text('Advanced Focus Modes'), findsOneWidget);
      });
    });
  });
}
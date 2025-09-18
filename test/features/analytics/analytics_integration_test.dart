/// Integration tests for Analytics feature
/// Tests free→Pro transitions and end-to-end behavior

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/analytics/presentation/analytics_screen.dart';
import 'package:mindtrainer/features/analytics/domain/analytics_service.dart';
import 'package:mindtrainer/core/payments/pro_feature_gates.dart';
import 'package:mindtrainer/core/billing/billing_adapter.dart';

void main() {
  group('Analytics Integration Tests', () {
    late FakeBillingAdapter fakeAdapter;
    late MindTrainerProGates proGates;
    late AdvancedAnalyticsService analyticsService;
    
    setUp(() {
      fakeAdapter = FakeBillingAdapter();
      proGates = MindTrainerProGates(() => fakeAdapter.isProActive);
      analyticsService = AdvancedAnalyticsService(proGates);
    });
    
    tearDown(() {
      fakeAdapter.dispose();
    });
    
    group('Free User Experience', () {
      testWidgets('should show basic analytics and Pro previews', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        // Wait for loading to complete
        await tester.pump(Duration(milliseconds: 600));
        
        // Should show basic analytics
        expect(find.text('Your Focus Journey'), findsOneWidget);
        expect(find.text('Sessions'), findsOneWidget);
        expect(find.text('Avg Focus'), findsOneWidget);
        expect(find.text('Total Time'), findsOneWidget);
        
        // Should show Pro badges on locked features
        expect(find.text('PRO'), findsAtLeastNWidgets(3));
        
        // Should show locked previews
        expect(find.text('Discover how your mood affects focus performance'), findsOneWidget);
        expect(find.text('Analyze which tags boost your performance'), findsOneWidget);
        expect(find.text('Discover power words that enhance focus'), findsOneWidget);
        
        // Should show unlock buttons
        expect(find.text('Unlock'), findsAtLeastNWidgets(3));
        
        // Should show limited history message
        expect(find.textContaining('Currently showing last 30 days'), findsOneWidget);
      });
      
      testWidgets('should show upgrade dialog when Pro feature tapped', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Tap unlock button
        await tester.tap(find.text('Unlock').first);
        await tester.pumpAndSettle();
        
        // Should show upgrade dialog
        expect(find.text('Upgrade to Pro'), findsOneWidget);
        expect(find.text('Unlock advanced analytics features:'), findsOneWidget);
        expect(find.text('• Mood-focus correlations'), findsOneWidget);
        expect(find.text('• Tag performance insights'), findsOneWidget);
        expect(find.text('• Keyword uplift analysis'), findsOneWidget);
        expect(find.text('• Unlimited historical data'), findsOneWidget);
        
        // Should have upgrade and dismiss buttons
        expect(find.text('Not Now'), findsOneWidget);
        expect(find.text('Upgrade'), findsOneWidget);
        
        // Tap dismiss
        await tester.tap(find.text('Not Now'));
        await tester.pumpAndSettle();
        
        // Dialog should close
        expect(find.text('Upgrade to Pro'), findsNothing);
      });
      
      testWidgets('should show upgrade action from app bar', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should have upgrade star in app bar
        expect(find.byIcon(Icons.star), findsOneWidget);
        
        // Tap upgrade star
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();
        
        // Should show upgrade dialog
        expect(find.text('Upgrade to Pro'), findsOneWidget);
      });
    });
    
    group('Pro User Experience', () {
      testWidgets('should show full analytics when Pro active', (WidgetTester tester) async {
        // Simulate Pro activation
        fakeAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should show basic analytics
        expect(find.text('Your Focus Journey'), findsOneWidget);
        
        // Should NOT show Pro badges (user has Pro)
        expect(find.text('PRO'), findsNothing);
        
        // Should NOT show upgrade star in app bar
        expect(find.byIcon(Icons.star), findsNothing);
        
        // Should show actual data instead of previews
        expect(find.text('Mood-Focus Correlations'), findsOneWidget);
        expect(find.text('Tag Performance'), findsOneWidget);
        expect(find.text('Keyword Uplift'), findsOneWidget);
        
        // Should show unlimited history
        expect(find.text('Access to unlimited historical data'), findsOneWidget);
        
        // Should NOT show unlock buttons
        expect(find.text('Unlock'), findsNothing);
      });
      
      testWidgets('should show mood correlation data', (WidgetTester tester) async {
        fakeAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should show mood data
        final moodSection = find.text('Mood-Focus Correlations');
        expect(moodSection, findsOneWidget);
        
        // Should show at least some mood entries
        expect(find.textContaining('/10'), findsAtLeastNWidgets(3));
        
        // Should show View All if more than 3 moods
        expect(find.text('View All'), findsAtLeastNWidgets(1));
      });
      
      testWidgets('should show tag performance data', (WidgetTester tester) async {
        fakeAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should show tag performance section
        expect(find.text('Tag Performance'), findsOneWidget);
        
        // Should show some tags as chips
        expect(find.byType(Chip), findsAtLeastNWidgets(3));
        
        // Should show uplift values (+ or -)
        expect(find.textContaining('+'), findsAtLeastNWidgets(1));
      });
      
      testWidgets('should show detail dialogs when View All tapped', (WidgetTester tester) async {
        fakeAdapter.simulateProActivation('mindtrainer_pro_yearly');
        
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Scroll to ensure View All button is visible
        await tester.scrollUntilVisible(
          find.text('View All').first,
          500.0,
          scrollable: find.byType(Scrollable).first,
        );
        
        // Find and tap View All for mood correlations  
        final viewAllButtons = find.text('View All');
        if (viewAllButtons.evaluate().isNotEmpty) {
          await tester.tap(viewAllButtons.first, warnIfMissed: false);
          await tester.pumpAndSettle();
          
          // Should show detail dialog
          expect(find.textContaining('Correlations'), findsOneWidget);
          expect(find.text('Close'), findsOneWidget);
          
          // Close dialog
          await tester.tap(find.text('Close'));
          await tester.pumpAndSettle();
        }
      });
    });
    
    group('Free to Pro Transition', () {
      testWidgets('should update UI when Pro activated', (WidgetTester tester) async {
        // Start as free user
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should show Pro badges initially
        expect(find.text('PRO'), findsAtLeastNWidgets(1));
        expect(find.text('Unlock'), findsAtLeastNWidgets(1));
        
        // Simulate Pro activation
        fakeAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        // Rebuild widget with new Pro status
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should no longer show Pro badges or unlock buttons
        expect(find.text('PRO'), findsNothing);
        expect(find.text('Unlock'), findsNothing);
        
        // Should show actual Pro data
        expect(find.text('Mood-Focus Correlations'), findsOneWidget);
        expect(find.text('Access to unlimited historical data'), findsOneWidget);
      });
      
      testWidgets('should handle Pro expiration gracefully', (WidgetTester tester) async {
        // Start with Pro active
        fakeAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should show Pro features
        expect(find.text('PRO'), findsNothing);
        
        // Simulate Pro expiration
        fakeAdapter.simulateProExpiration();
        
        // Rebuild widget
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should now show locked features again
        expect(find.text('PRO'), findsAtLeastNWidgets(1));
        expect(find.text('Unlock'), findsAtLeastNWidgets(1));
        expect(find.byIcon(Icons.star), findsOneWidget);
      });
    });
    
    group('Error Handling', () {
      testWidgets('should handle loading state correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        // Should show loading initially
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Wait for loading to complete
        await tester.pump(Duration(milliseconds: 600));
        
        // Should no longer show loading
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Analytics'), findsOneWidget);
      });
      
      testWidgets('should handle null billing adapter gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: null, // No billing adapter
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should still work without billing adapter
        expect(find.text('Your Focus Journey'), findsOneWidget);
        
        // Try to open upgrade dialog
        await tester.tap(find.text('Unlock').first);
        await tester.pumpAndSettle();
        
        expect(find.text('Upgrade to Pro'), findsOneWidget);
        
        // Tap upgrade (should show message since no adapter)
        await tester.tap(find.text('Upgrade'));
        await tester.pumpAndSettle();
        
        // Should show snackbar message
        expect(find.textContaining('Upgrade flow will be implemented'), findsOneWidget);
      });
    });
    
    group('Accessibility', () {
      testWidgets('should provide proper semantics', (WidgetTester tester) async {
        fakeAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should have accessible app bar
        expect(find.text('Analytics'), findsOneWidget);
        
        // Should have proper button semantics
        final elevatedButtons = find.byType(ElevatedButton);
        for (final button in elevatedButtons.evaluate()) {
          expect(button.widget, isA<ElevatedButton>());
        }
        
        // Should have proper card structure
        expect(find.byType(Card), findsAtLeastNWidgets(4));
      });
      
      testWidgets('should support tooltips for icons', (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: AnalyticsScreen(
              analyticsService: analyticsService,
              proGates: proGates,
              billingAdapter: fakeAdapter,
            ),
          ),
        );
        
        await tester.pump(Duration(milliseconds: 600));
        
        // Should have tooltip for upgrade icon
        final upgradeIcon = find.byTooltip('Upgrade to Pro');
        expect(upgradeIcon, findsOneWidget);
      });
    });
  });
}
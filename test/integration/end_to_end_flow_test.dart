/// End-to-end flow tests for MindTrainer Pro
/// Tests complete user journeys: free onboarding, Pro unlock, expiration/renewal

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/main.dart';
import 'package:mindtrainer/features/focus_session/presentation/home_screen.dart';
import 'package:mindtrainer/features/analytics/presentation/analytics_screen.dart';
import 'package:mindtrainer/core/billing/billing_adapter.dart';

void main() {
  group('End-to-End Flow Tests', () {
    
    group('Free User Onboarding Flow', () {
      testWidgets('should complete full free user journey', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        
        // 1. Splash screen appears
        expect(find.byType(Image), findsOneWidget); // DigitalWolf logo
        
        // Wait for splash to complete (5 seconds)
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        
        // 2. Start screen appears
        expect(find.text('MindTrainer'), findsOneWidget);
        expect(find.text('Transform your mind, one session at a time'), findsOneWidget);
        expect(find.text('Begin Your Journey'), findsOneWidget);
        expect(find.text('Continue Training'), findsOneWidget);
        
        // 3. Tap "Begin Your Journey"
        await tester.tap(find.text('Begin Your Journey'));
        await tester.pumpAndSettle();
        
        // 4. Home screen appears
        expect(find.text('MindTrainer'), findsOneWidget);
        expect(find.text('Start Focus Session'), findsOneWidget);
        expect(find.text('Analytics'), findsOneWidget);
        
        // 5. Verify Pro badge is visible on analytics
        expect(find.text('PRO'), findsOneWidget);
        
        // 6. Navigate to analytics
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        
        // Wait for analytics loading
        await tester.pump(const Duration(milliseconds: 600));
        
        // 7. Verify free analytics screen
        expect(find.text('Analytics'), findsOneWidget);
        expect(find.text('Your Focus Journey'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget); // Upgrade star
        
        // 8. Verify Pro features are locked
        expect(find.text('PRO'), findsAtLeastNWidgets(3));
        expect(find.text('Unlock'), findsAtLeastNWidgets(3));
        expect(find.text('Discover how your mood affects focus performance'), findsOneWidget);
        
        // 9. Tap upgrade from locked feature
        await tester.tap(find.text('Unlock').first);
        await tester.pumpAndSettle();
        
        // 10. Verify upgrade dialog appears
        expect(find.text('Upgrade to Pro'), findsOneWidget);
        expect(find.text('Unlock advanced analytics features:'), findsOneWidget);
        expect(find.text('• Mood-focus correlations'), findsOneWidget);
        expect(find.text('• Tag performance insights'), findsOneWidget);
        expect(find.text('Not Now'), findsOneWidget);
        expect(find.text('Upgrade'), findsOneWidget);
        
        // 11. Dismiss upgrade dialog
        await tester.tap(find.text('Not Now'));
        await tester.pumpAndSettle();
        
        // 12. Navigate back to home
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        
        // 13. Verify we're back at home screen
        expect(find.text('Start Focus Session'), findsOneWidget);
      });
      
      testWidgets('should show consistent Pro indicators across screens', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        
        // Skip splash
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        
        // Start journey
        await tester.tap(find.text('Begin Your Journey'));
        await tester.pumpAndSettle();
        
        // Check home screen Pro indicator
        expect(find.text('PRO'), findsOneWidget);
        
        // Go to analytics
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Check analytics screen Pro indicators
        expect(find.text('PRO'), findsAtLeastNWidgets(3));
        expect(find.byIcon(Icons.star), findsOneWidget);
        
        // Go to other screens and verify consistency
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        
        // Check other home screen buttons
        expect(find.text('View Session History'), findsOneWidget);
        expect(find.text('Animal Check-in'), findsOneWidget);
      });
    });
    
    group('Pro Unlock Flow', () {
      testWidgets('should complete Pro purchase simulation flow', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        
        // Navigate to analytics
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Begin Your Journey'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Verify we're in free mode
        expect(find.text('PRO'), findsAtLeastNWidgets(3));
        expect(find.text('Unlock'), findsAtLeastNWidgets(3));
        
        // Trigger upgrade flow
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();
        
        expect(find.text('Upgrade to Pro'), findsOneWidget);
        
        // Tap upgrade button
        await tester.tap(find.text('Upgrade'));
        await tester.pumpAndSettle();
        
        // Should show "coming in Stage 2" message
        expect(find.textContaining('Upgrade flow will be implemented'), findsOneWidget);
        
        // Dismiss snackbar and dialog
        await tester.tap(find.text('Not Now'));
        await tester.pumpAndSettle();
      });
      
      testWidgets('should simulate Pro activation effects', (WidgetTester tester) async {
        // This test simulates what would happen after a successful purchase
        // by manually creating a Pro-enabled version of the app
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) {
              // Create a fake adapter with Pro already active
              final billingAdapter = BillingAdapterFactory.createFake();
              billingAdapter.simulateProActivation('mindtrainer_pro_monthly');
              
              return HomeScreen();
            },
          ),
        ));
        
        await tester.pumpAndSettle();
        
        // Home screen should NOT show Pro badge when Pro is active
        final proTexts = find.text('PRO');
        expect(proTexts.evaluate().isEmpty, true);
        
        // Analytics button should be highlighted for Pro users
        final analyticsButton = find.text('Analytics');
        expect(analyticsButton, findsOneWidget);
        
        // Navigate to analytics
        await tester.tap(analyticsButton);
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Should NOT show upgrade star for Pro users
        expect(find.byIcon(Icons.star), findsNothing);
        
        // Should NOT show Pro badges or unlock buttons
        expect(find.text('PRO'), findsNothing);
        expect(find.text('Unlock'), findsNothing);
        
        // Should show actual Pro data
        expect(find.text('Mood-Focus Correlations'), findsOneWidget);
        expect(find.text('Tag Performance'), findsOneWidget);
        expect(find.text('Keyword Uplift'), findsOneWidget);
        expect(find.text('Access to unlimited historical data'), findsOneWidget);
      });
    });
    
    group('Expiration/Renewal Flow', () {
      testWidgets('should handle Pro expiration gracefully', (WidgetTester tester) async {
        // Start with Pro active, then simulate expiration
        final billingAdapter = BillingAdapterFactory.createFake();
        billingAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) => HomeScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        
        // Initially Pro (no Pro badges)
        expect(find.text('PRO'), findsNothing);
        
        // Go to analytics to verify Pro features
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        expect(find.text('Mood-Focus Correlations'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsNothing);
        
        // Go back and simulate expiration
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        
        // Simulate Pro expiration
        billingAdapter.simulateProExpiration();
        
        // Rebuild the app with expired Pro
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) => HomeScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        
        // Should now show Pro badge again
        expect(find.text('PRO'), findsOneWidget);
        
        // Go to analytics to verify features are locked
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Should show upgrade prompts again
        expect(find.byIcon(Icons.star), findsOneWidget);
        expect(find.text('PRO'), findsAtLeastNWidgets(3));
        expect(find.text('Unlock'), findsAtLeastNWidgets(3));
        
        billingAdapter.dispose();
      });
      
      testWidgets('should handle subscription renewal correctly', (WidgetTester tester) async {
        final billingAdapter = BillingAdapterFactory.createFake();
        
        // Initial Pro activation
        billingAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) => HomeScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        
        // Go to analytics
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Verify Pro features are available
        expect(find.text('Access to unlimited historical data'), findsOneWidget);
        expect(find.text('Mood-Focus Correlations'), findsOneWidget);
        
        // Simulate renewal (same subscription)
        billingAdapter.simulateProExpiration();
        billingAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        // Features should remain available
        await tester.pump();
        expect(find.text('Access to unlimited historical data'), findsOneWidget);
        
        billingAdapter.dispose();
      });
      
      testWidgets('should handle subscription upgrade flow', (WidgetTester tester) async {
        final billingAdapter = BillingAdapterFactory.createFake();
        
        // Start with monthly Pro
        billingAdapter.simulateProActivation('mindtrainer_pro_monthly');
        
        await tester.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) => HomeScreen(),
          ),
        ));
        await tester.pumpAndSettle();
        
        // Go to analytics
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Verify Pro features work
        expect(find.text('Mood-Focus Correlations'), findsOneWidget);
        
        // Simulate upgrade to yearly (cancel monthly, purchase yearly)
        billingAdapter.simulateProExpiration();
        billingAdapter.simulateProActivation('mindtrainer_pro_yearly');
        
        // Features should still be available
        await tester.pump();
        expect(find.text('Mood-Focus Correlations'), findsOneWidget);
        expect(find.text('Access to unlimited historical data'), findsOneWidget);
        
        billingAdapter.dispose();
      });
    });
    
    group('Error Handling Flow', () {
      testWidgets('should handle billing errors gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        
        // Navigate to analytics
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Begin Your Journey'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Try to trigger purchase with null billing adapter
        await tester.tap(find.byIcon(Icons.star));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Upgrade'));
        await tester.pumpAndSettle();
        
        // Should show error message instead of crashing
        expect(find.textContaining('Upgrade flow will be implemented'), findsOneWidget);
      });
      
      testWidgets('should maintain UI consistency during errors', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        
        // Navigate through the app
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Begin Your Journey'));
        await tester.pumpAndSettle();
        
        // Even with potential billing errors, UI should remain stable
        expect(find.text('Start Focus Session'), findsOneWidget);
        expect(find.text('Analytics'), findsOneWidget);
        expect(find.text('PRO'), findsOneWidget); // Should show Pro badge
        
        // Navigate to other screens
        await tester.tap(find.text('View Session History'));
        await tester.pumpAndSettle();
        
        // Should navigate successfully
        expect(find.text('Session History'), findsOneWidget);
      });
    });
    
    group('Cross-Platform Flow', () {
      testWidgets('should work consistently across different device types', (WidgetTester tester) async {
        // Test with different screen sizes
        await tester.binding.setSurfaceSize(const Size(360, 640)); // Small phone
        await tester.pumpWidget(const MyApp());
        
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Begin Your Journey'));
        await tester.pumpAndSettle();
        
        expect(find.text('Analytics'), findsOneWidget);
        
        // Test with tablet size
        await tester.binding.setSurfaceSize(const Size(800, 1200)); // Tablet
        await tester.pump();
        
        expect(find.text('Analytics'), findsOneWidget);
        
        // Reset to default
        await tester.binding.setSurfaceSize(null);
      });
      
      testWidgets('should handle configuration changes gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(const MyApp());
        
        // Navigate to analytics
        await tester.pump(const Duration(seconds: 5));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Begin Your Journey'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Analytics'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 600));
        
        // Simulate configuration change (like rotation)
        await tester.binding.setSurfaceSize(const Size(640, 360)); // Landscape
        await tester.pump();
        
        // Should still show analytics content
        expect(find.text('Your Focus Journey'), findsOneWidget);
        
        // Reset
        await tester.binding.setSurfaceSize(null);
      });
    });
  });
}
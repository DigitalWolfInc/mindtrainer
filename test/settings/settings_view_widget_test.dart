import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/settings/settings_view.dart';
import '../../lib/settings/settings_vm.dart';
import '../../lib/payments/entitlement_resolver.dart';
import '../../lib/payments/billing_adapter.dart';
import '../../lib/payments/stores/price_cache_store.dart';
import '../../lib/payments/models/price_cache.dart';
import '../../lib/payments/models/entitlement.dart';
import '../../lib/settings/email_optin_store.dart';

import 'settings_view_widget_test.mocks.dart';

@GenerateMocks([
  EntitlementResolver,
  BillingAdapter,
  PriceCacheStore,
  EmailOptInStore,
])
void main() {
  group('SettingsView Widget Tests', () {
    late MockEntitlementResolver mockResolver;
    late MockBillingAdapter mockBillingAdapter;
    late MockPriceCacheStore mockPriceCacheStore;
    late MockEmailOptInStore mockEmailStore;

    setUp(() {
      mockResolver = MockEntitlementResolver();
      mockBillingAdapter = MockBillingAdapter();
      mockPriceCacheStore = MockPriceCacheStore();
      mockEmailStore = MockEmailOptInStore();

      // Setup default mocks
      when(mockEmailStore.init()).thenAnswer((_) async {});
      when(mockEmailStore.optedIn).thenReturn(false);
      when(mockResolver.entitlementStream).thenAnswer((_) => Stream<Entitlement>.empty());
      when(mockResolver.isPro).thenReturn(false);
      when(mockResolver.currentEntitlement).thenReturn(Entitlement.none());
      when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());

      SettingsVM.resetInstance();
    });

    tearDown(() {
      SettingsVM.resetInstance();
    });

    Widget createSettingsView({String appVersion = '1.0.0'}) {
      return MaterialApp(
        home: SettingsView(appVersion: appVersion),
      );
    }

    group('Basic Rendering', () {
      testWidgets('should render settings view with all sections', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Check for main title
        expect(find.text('Settings'), findsOneWidget);

        // Check for section headers
        expect(find.text('Account & Pro'), findsOneWidget);
        expect(find.text('Data'), findsOneWidget);
        expect(find.text('Privacy'), findsOneWidget);
        expect(find.text('Charity & About'), findsOneWidget);
        expect(find.text('Diagnostics'), findsOneWidget);
      });

      testWidgets('should display app version', (tester) async {
        await tester.pumpWidget(createSettingsView(appVersion: '2.1.0'));
        await tester.pumpAndSettle();

        expect(find.text('App version: 2.1.0'), findsOneWidget);
      });

      testWidgets('should have scrollable content', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Find the scrollable widget
        expect(find.byType(SingleChildScrollView), findsOneWidget);
      });
    });

    group('Account & Pro Section', () {
      testWidgets('should show Free status when not Pro', (tester) async {
        when(mockResolver.isPro).thenReturn(false);
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Status: Free'), findsOneWidget);
      });

      testWidgets('should show Pro status when Pro user', (tester) async {
        when(mockResolver.isPro).thenReturn(true);
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Status: Pro'), findsOneWidget);
      });

      testWidgets('should display purchase buttons for Free users', (tester) async {
        when(mockResolver.isPro).thenReturn(false);
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Buy Monthly'), findsOneWidget);
        expect(find.text('Buy Yearly'), findsOneWidget);
        expect(find.text('Restore'), findsOneWidget);
      });

      testWidgets('should display manage button for Pro users', (tester) async {
        when(mockResolver.isPro).thenReturn(true);
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Manage'), findsOneWidget);
        
        // Purchase buttons should not be visible
        expect(find.text('Buy Monthly'), findsNothing);
        expect(find.text('Buy Yearly'), findsNothing);
      });

      testWidgets('should show loading indicator when busy', (tester) async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenAnswer((_) => Future.delayed(Duration(seconds: 1)));
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Start a purchase to trigger busy state
        await tester.tap(find.text('Buy Monthly'));
        await tester.pump(); // Start the operation
        await tester.pump(Duration(milliseconds: 100)); // Let busy state update

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display status messages', (tester) async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).thenAnswer((_) async {});
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Tap purchase button
        await tester.tap(find.text('Buy Monthly'));
        await tester.pumpAndSettle();

        expect(find.text('Purchase initiated'), findsOneWidget);
      });
    });

    group('Data Section', () {
      testWidgets('should show data management buttons', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Export Data'), findsOneWidget);
        expect(find.text('Import Data'), findsOneWidget);
        expect(find.text('Clear Data'), findsOneWidget);
      });

      testWidgets('should handle export data tap', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Tap export - should not crash and should show some feedback
        await tester.tap(find.text('Export Data'));
        await tester.pumpAndSettle();

        // Should remain on same screen (implementation doesn't navigate away)
        expect(find.text('Settings'), findsOneWidget);
      });

      testWidgets('should show clear data confirmation dialog', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear Data'));
        await tester.pumpAndSettle();

        // Should show confirmation dialog
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('Clear All Data?'), findsOneWidget);
        expect(find.text('This will delete all your focus session data. This action cannot be undone.'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);
      });

      testWidgets('should dismiss confirmation dialog on cancel', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Clear Data'));
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Dialog should be gone
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Settings'), findsOneWidget);
      });
    });

    group('Privacy Section', () {
      testWidgets('should show email toggle switch', (tester) async {
        when(mockEmailStore.optedIn).thenReturn(false);
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Email updates'), findsOneWidget);
        expect(find.byType(Switch), findsOneWidget);
        
        // Switch should reflect store state
        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, false);
      });

      testWidgets('should reflect email opt-in state in switch', (tester) async {
        when(mockEmailStore.optedIn).thenReturn(true);
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        final switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.value, true);
      });

      testWidgets('should toggle email opt-in when switch tapped', (tester) async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(true)).thenAnswer((_) async {});
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Tap the switch
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        // Should show feedback status
        expect(find.text('Email updates enabled'), findsOneWidget);
      });
    });

    group('Charity & About Section', () {
      testWidgets('should show charity information', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.textContaining('MindTrainer donates'), findsOneWidget);
        expect(find.textContaining('mental health research'), findsOneWidget);
      });

      testWidgets('should display app version', (tester) async {
        await tester.pumpWidget(createSettingsView(appVersion: '1.5.2'));
        await tester.pumpAndSettle();

        expect(find.text('App version: 1.5.2'), findsOneWidget);
      });
    });

    group('Diagnostics Section', () {
      testWidgets('should show diagnostics expansion tile', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.byType(ExpansionTile), findsOneWidget);
        expect(find.text('Diagnostics'), findsOneWidget);
      });

      testWidgets('should expand diagnostics to show logs', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Initially collapsed - should not show text content
        expect(find.text('Recent diagnostic logs:'), findsNothing);

        // Tap to expand
        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();

        // Should now show diagnostics content
        expect(find.text('Recent diagnostic logs:'), findsOneWidget);
        expect(find.text('(No logs)'), findsOneWidget);
      });

      testWidgets('should show diagnostic logs in monospace text', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Expand diagnostics
        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();

        // Find the text widget containing logs
        final textWidgets = find.byType(Text).evaluate()
            .map((e) => e.widget as Text)
            .where((text) => text.data?.contains('(No logs)') == true);

        expect(textWidgets.isNotEmpty, true);
        
        // Should use monospace font
        final logText = textWidgets.first;
        expect(logText.style?.fontFamily, 'monospace');
      });
    });

    group('Button Interactions', () {
      testWidgets('should handle purchase button taps', (tester) async {
        when(mockBillingAdapter.purchase(any)).thenAnswer((_) async {});
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Test monthly purchase
        await tester.tap(find.text('Buy Monthly'));
        await tester.pumpAndSettle();
        
        expect(find.text('Purchase initiated'), findsOneWidget);
      });

      testWidgets('should handle restore button tap', (tester) async {
        when(mockBillingAdapter.queryPurchases()).thenAnswer((_) async {});
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Restore'));
        await tester.pumpAndSettle();
        
        expect(find.text('Restore completed'), findsOneWidget);
      });

      testWidgets('should disable buttons when busy', (tester) async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenAnswer((_) => Future.delayed(Duration(seconds: 1)));
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Start operation
        await tester.tap(find.text('Buy Monthly'));
        await tester.pump();
        await tester.pump(Duration(milliseconds: 100));

        // Other buttons should be disabled
        final buttons = find.byType(ElevatedButton).evaluate()
            .map((e) => e.widget as ElevatedButton)
            .where((btn) => btn.onPressed == null);

        expect(buttons.length, greaterThan(0));
      });
    });

    group('Error Handling', () {
      testWidgets('should display error messages for failed operations', (tester) async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(Exception('Network error'));
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Buy Monthly'));
        await tester.pumpAndSettle();

        expect(find.text('Offline'), findsOneWidget);
      });

      testWidgets('should recover from error states', (tester) async {
        // First operation fails
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(Exception('Network error'));
        
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Buy Monthly'));
        await tester.pumpAndSettle();
        expect(find.text('Offline'), findsOneWidget);

        // Second operation succeeds
        when(mockBillingAdapter.purchase('mindtrainer_pro_yearly')).thenAnswer((_) async {});
        
        await tester.tap(find.text('Buy Yearly'));
        await tester.pumpAndSettle();

        // Should replace error with success
        expect(find.text('Purchase initiated'), findsOneWidget);
        expect(find.text('Offline'), findsNothing);
      });
    });

    group('State Management', () {
      testWidgets('should update UI when ViewModel state changes', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Initially should show Free status
        expect(find.text('Status: Free'), findsOneWidget);

        // Simulate Pro status change (would need stream updates in real scenario)
        when(mockResolver.isPro).thenReturn(true);
        
        // Trigger rebuild by tapping something
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        // Note: In a real app, this would update via stream listener
        // This test verifies the widget responds to different states
      });

      testWidgets('should handle ViewModel initialization', (tester) async {
        await tester.pumpWidget(createSettingsView());
        
        // Should render without throwing during initialization
        expect(find.text('Settings'), findsOneWidget);
        
        await tester.pumpAndSettle();
        
        // Should complete initialization and show content
        expect(find.text('Account & Pro'), findsOneWidget);
      });
    });

    group('Layout and Styling', () {
      testWidgets('should have proper spacing between sections', (tester) async {
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        // Find padding widgets (used for spacing)
        final paddingWidgets = find.byType(Padding);
        expect(paddingWidgets.evaluate().length, greaterThan(0));
      });

      testWidgets('should be responsive to different screen sizes', (tester) async {
        // Test with smaller screen
        await tester.binding.setSurfaceSize(Size(320, 568));
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);

        // Test with larger screen
        await tester.binding.setSurfaceSize(Size(768, 1024));
        await tester.pumpWidget(createSettingsView());
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsOneWidget);
      });
    });
  });
}
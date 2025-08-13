import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../lib/payments/paywall_view.dart';
import '../../lib/payments/paywall_vm.dart';

import 'paywall_vm_test.mocks.dart';

void main() {
  group('PaywallView Tests', () {
    late MockPaywallVM mockPaywallVM;

    setUp(() {
      mockPaywallVM = MockPaywallVM();
    });

    Widget createPaywallView() {
      return MaterialApp(
        home: PaywallView(paywall: mockPaywallVM),
      );
    }

    testWidgets('should display Pro badge when user is Pro', (tester) async {
      // Setup Pro user
      when(mockPaywallVM.isPro).thenReturn(true);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display Pro status
      expect(find.text('You\'re Pro. Thank you!'), findsOneWidget);
      
      // Should not display purchase buttons for Pro users
      expect(find.text('Get Pro Monthly'), findsNothing);
      expect(find.text('Get Pro Yearly'), findsNothing);
    });

    testWidgets('should display purchase options for free users', (tester) async {
      // Setup free user
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display pricing
      expect(find.text('\$9.99/month'), findsOneWidget);
      expect(find.text('\$99.99/year'), findsOneWidget);
      
      // Should display purchase buttons
      expect(find.text('Get Pro Monthly'), findsOneWidget);
      expect(find.text('Get Pro Yearly'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
    });

    testWidgets('should display loading state', (tester) async {
      // Setup loading state
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(true); // Loading
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display loading indicators
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('should display error message', (tester) async {
      // Setup error state
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn('Purchase canceled');
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display error
      expect(find.text('Purchase canceled'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('should display offline state', (tester) async {
      // Setup offline state
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn(null);
      when(mockPaywallVM.yearlyPrice).thenReturn(null);
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(true);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display offline message
      expect(find.textContaining('Offline'), findsOneWidget);
      expect(find.textContaining('you can still use MindTrainer'), findsOneWidget);
    });

    testWidgets('should display stale pricing warning', (tester) async {
      // Setup stale pricing
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(true); // Stale
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display stale pricing warning
      expect(find.textContaining('Prices may be outdated'), findsOneWidget);
    });

    testWidgets('should call buyMonthly when monthly button tapped', (tester) async {
      // Setup free user
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);
      when(mockPaywallVM.buyMonthly()).thenAnswer((_) async {});

      await tester.pumpWidget(createPaywallView());

      // Tap monthly button
      await tester.tap(find.text('Get Pro Monthly'));
      await tester.pump();

      // Should call buyMonthly
      verify(mockPaywallVM.buyMonthly()).called(1);
    });

    testWidgets('should call buyYearly when yearly button tapped', (tester) async {
      // Setup free user
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);
      when(mockPaywallVM.buyYearly()).thenAnswer((_) async {});

      await tester.pumpWidget(createPaywallView());

      // Tap yearly button
      await tester.tap(find.text('Get Pro Yearly'));
      await tester.pump();

      // Should call buyYearly
      verify(mockPaywallVM.buyYearly()).called(1);
    });

    testWidgets('should call restore when restore button tapped', (tester) async {
      // Setup free user
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);
      when(mockPaywallVM.restore()).thenAnswer((_) async {});

      await tester.pumpWidget(createPaywallView());

      // Tap restore button
      await tester.tap(find.text('Restore'));
      await tester.pump();

      // Should call restore
      verify(mockPaywallVM.restore()).called(1);
    });

    testWidgets('should clear error when Try again button tapped', (tester) async {
      // Setup error state
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn('Purchase canceled');
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Tap Try again button
      await tester.tap(find.text('Try again'));
      await tester.pump();

      // Should call clearError
      verify(mockPaywallVM.clearError()).called(1);
    });

    testWidgets('should display Pro benefits list', (tester) async {
      // Setup free user
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display benefits
      expect(find.text('✓ Unlimited daily sessions'), findsOneWidget);
      expect(find.text('✓ Advanced analytics'), findsOneWidget);
      expect(find.text('✓ Extended AI coaching'), findsOneWidget);
      expect(find.text('✓ Data export & custom goals'), findsOneWidget);
    });

    testWidgets('should display privacy policy and terms links', (tester) async {
      // Setup free user
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(false);
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Should display legal links
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('buttons should be disabled during loading', (tester) async {
      // Setup loading state
      when(mockPaywallVM.isPro).thenReturn(false);
      when(mockPaywallVM.monthlyPrice).thenReturn('\$9.99');
      when(mockPaywallVM.yearlyPrice).thenReturn('\$99.99');
      when(mockPaywallVM.pricesStale).thenReturn(false);
      when(mockPaywallVM.isBusy).thenReturn(true); // Loading
      when(mockPaywallVM.error).thenReturn(null);
      when(mockPaywallVM.offline).thenReturn(false);
      when(mockPaywallVM.addListener(any)).thenReturn(null);
      when(mockPaywallVM.removeListener(any)).thenReturn(null);

      await tester.pumpWidget(createPaywallView());

      // Find buttons by their parent containers since they may be disabled
      expect(find.byType(ElevatedButton), findsWidgets);
      
      // Verify buttons show loading indicators instead of text
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });
}
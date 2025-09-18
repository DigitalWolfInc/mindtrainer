import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/payments/pro_gate.dart';
import '../../lib/payments/entitlement_resolver.dart';
import '../../lib/payments/models/entitlement.dart';

import 'pro_gate_test.mocks.dart';

@GenerateMocks([EntitlementResolver])
void main() {
  group('ProGate Tests', () {
    late MockEntitlementResolver mockResolver;

    setUp(() {
      mockResolver = MockEntitlementResolver();
      
      // Replace the singleton with our mock
      EntitlementResolver.setTestInstance(mockResolver);
    });

    tearDown(() {
      EntitlementResolver.resetInstance();
    });

    Widget createTestApp({required Widget child}) {
      return MaterialApp(
        home: child,
        routes: {
          '/paywall': (context) => Scaffold(
            appBar: AppBar(title: Text('Paywall')),
            body: Center(child: Text('Paywall Screen')),
          ),
        },
      );
    }

    testWidgets('maybePromptPaywall should show paywall for free users', (tester) async {
      // Setup free user
      when(mockResolver.isPro).thenReturn(false);

      final testWidget = createTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                final wasGated = await context.maybePromptPaywall();
                // In test, we can verify navigation occurred
              },
              child: Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      
      // Tap the test button
      await tester.tap(find.text('Test Button'));
      await tester.pumpAndSettle();

      // Should navigate to paywall
      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    testWidgets('maybePromptPaywall should not show paywall for Pro users', (tester) async {
      // Setup Pro user
      when(mockResolver.isPro).thenReturn(true);

      bool wasGated = false;
      final testWidget = createTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                wasGated = await context.maybePromptPaywall();
              },
              child: Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      
      // Tap the test button
      await tester.tap(find.text('Test Button'));
      await tester.pumpAndSettle();

      // Should NOT navigate to paywall
      expect(find.text('Paywall Screen'), findsNothing);
      expect(wasGated, false); // No gating occurred
    });

    testWidgets('gatedAction should execute action for Pro users', (tester) async {
      // Setup Pro user
      when(mockResolver.isPro).thenReturn(true);

      bool actionExecuted = false;
      final testWidget = createTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await context.gatedAction(() {
                  actionExecuted = true;
                });
              },
              child: Text('Test Action'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      
      // Tap the test button
      await tester.tap(find.text('Test Action'));
      await tester.pumpAndSettle();

      // Action should have been executed
      expect(actionExecuted, true);
      // Should NOT navigate to paywall
      expect(find.text('Paywall Screen'), findsNothing);
    });

    testWidgets('gatedAction should show paywall and not execute action for free users', (tester) async {
      // Setup free user
      when(mockResolver.isPro).thenReturn(false);

      bool actionExecuted = false;
      final testWidget = createTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                await context.gatedAction(() {
                  actionExecuted = true;
                });
              },
              child: Text('Test Action'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(testWidget);
      
      // Tap the test button
      await tester.tap(find.text('Test Action'));
      await tester.pumpAndSettle();

      // Action should NOT have been executed
      expect(actionExecuted, false);
      // Should navigate to paywall
      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    test('isPro getter should return resolver status', () {
      // Setup Pro user
      when(mockResolver.isPro).thenReturn(true);
      expect(ProGate.isPro, true);

      // Setup free user
      when(mockResolver.isPro).thenReturn(false);
      expect(ProGate.isPro, false);
    });

    test('entitlementDebug should return resolver entitlement string', () {
      final proEntitlement = Entitlement.pro(
        source: 'subscription',
        since: DateTime(2024, 1, 1),
        until: DateTime(2024, 12, 31),
      );
      
      when(mockResolver.currentEntitlement).thenReturn(proEntitlement);
      
      final debugString = ProGate.entitlementDebug;
      expect(debugString.contains('Pro'), true);
      expect(debugString.contains('subscription'), true);
    });

    testWidgets('ProGateContext extension should work correctly', (tester) async {
      // Setup free user
      when(mockResolver.isPro).thenReturn(false);

      final testWidget = createTestApp(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: [
                  Text('Is Pro: ${context.isPro}'),
                  ElevatedButton(
                    onPressed: () async {
                      await context.maybePromptPaywall();
                    },
                    child: Text('Test Extension'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Should show free user status
      expect(find.text('Is Pro: false'), findsOneWidget);
      
      // Tap the extension method button
      await tester.tap(find.text('Test Extension'));
      await tester.pumpAndSettle();

      // Should navigate to paywall via extension
      expect(find.text('Paywall Screen'), findsOneWidget);
    });

    group('Static methods', () {
      test('maybePromptPaywall static method should work for Pro users', () async {
        // Setup Pro user
        when(mockResolver.isPro).thenReturn(true);

        // Create a fake context (this is a unit test, not widget test)
        final context = MockBuildContext();
        when(context.mounted).thenReturn(true);
        
        final wasGated = await ProGate.maybePromptPaywall(context);
        expect(wasGated, false); // No gating for Pro users
      });

      test('gatedAction static method should execute for Pro users', () async {
        // Setup Pro user  
        when(mockResolver.isPro).thenReturn(true);

        bool actionExecuted = false;
        final context = MockBuildContext();
        when(context.mounted).thenReturn(true);
        
        await ProGate.gatedAction(context, () {
          actionExecuted = true;
        });

        expect(actionExecuted, true);
      });
    });
  });
}

// Mock for BuildContext in unit tests
class MockBuildContext extends Mock implements BuildContext {}
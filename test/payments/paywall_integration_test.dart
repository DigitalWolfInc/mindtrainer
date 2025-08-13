import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'dart:async';

import '../../lib/payments/paywall_vm.dart';
import '../../lib/payments/paywall_view.dart';
import '../../lib/payments/pro_gate.dart';
import '../../lib/payments/entitlement_resolver.dart';
import '../../lib/payments/models/entitlement.dart';
import '../../lib/core/payments/pro_feature_gates.dart';

import 'paywall_vm_test.mocks.dart';

void main() {
  group('Paywall Integration Tests', () {
    late MockEntitlementResolver mockResolver;
    late MockBillingAdapter mockBillingAdapter;
    late MockPriceCacheStore mockPriceCacheStore;

    setUp(() {
      mockResolver = MockEntitlementResolver();
      mockBillingAdapter = MockBillingAdapter();
      mockPriceCacheStore = MockPriceCacheStore();
      
      // Setup default mocks
      when(mockResolver.initialize()).thenAnswer((_) async {});
      when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
      when(mockResolver.entitlementStream).thenAnswer((_) => Stream<Entitlement>.empty());
      when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
      
      // Set test instance
      EntitlementResolver.setTestInstance(mockResolver);
      PaywallVM.resetInstance();
    });

    tearDown(() {
      EntitlementResolver.resetInstance();
      PaywallVM.resetInstance();
    });

    Widget createIntegrationApp() {
      return MaterialApp(
        home: TestHomeScreen(),
        routes: {
          '/paywall': (context) => const PaywallView(),
        },
      );
    }

    testWidgets('Complete free user to Pro upgrade flow', (tester) async {
      // Setup free user initially
      when(mockResolver.isPro).thenReturn(false);
      final entitlementController = StreamController<Entitlement>();
      when(mockResolver.entitlementStream).thenAnswer((_) => entitlementController.stream);
      
      // Setup successful purchase
      when(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).thenAnswer((_) async {});
      
      await tester.pumpWidget(createIntegrationApp());
      
      // 1. User starts as free user
      expect(find.text('Analytics (Pro Required)'), findsOneWidget);
      
      // 2. User taps on Pro feature
      await tester.tap(find.text('Analytics (Pro Required)'));
      await tester.pumpAndSettle();
      
      // 3. Should navigate to paywall
      expect(find.text('Get MindTrainer Pro'), findsOneWidget);
      expect(find.text('Get Pro Monthly'), findsOneWidget);
      
      // 4. User taps monthly purchase
      await tester.tap(find.text('Get Pro Monthly'));
      await tester.pump();
      
      // 5. Should show loading state
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      // 6. Simulate successful purchase by emitting Pro entitlement
      when(mockResolver.isPro).thenReturn(true);
      final proEntitlement = Entitlement.pro(
        source: 'subscription',
        since: DateTime.now(),
        until: DateTime.now().add(Duration(days: 30)),
      );
      entitlementController.add(proEntitlement);
      
      await tester.pumpAndSettle();
      
      // 7. Should show Pro status
      expect(find.text('You\'re Pro. Thank you!'), findsOneWidget);
      
      // 8. Navigate back to home
      await tester.pageBack();
      await tester.pumpAndSettle();
      
      // 9. Should now show Pro access granted
      expect(find.text('Analytics (Pro Active)'), findsOneWidget);
      
      await entitlementController.close();
    });

    testWidgets('Pro user should bypass paywall', (tester) async {
      // Setup Pro user
      when(mockResolver.isPro).thenReturn(true);
      
      await tester.pumpWidget(createIntegrationApp());
      
      // User taps on feature
      await tester.tap(find.text('Analytics (Pro Active)'));
      await tester.pumpAndSettle();
      
      // Should NOT navigate to paywall, should go directly to analytics
      expect(find.text('Analytics Screen'), findsOneWidget);
      expect(find.text('Get MindTrainer Pro'), findsNothing);
    });

    testWidgets('Error handling in purchase flow', (tester) async {
      // Setup free user
      when(mockResolver.isPro).thenReturn(false);
      when(mockResolver.entitlementStream).thenAnswer((_) => Stream<Entitlement>.empty());
      
      // Setup purchase failure
      when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
          .thenThrow(BillingException._(code: 'purchase_canceled', message: 'User canceled'));
      
      await tester.pumpWidget(createIntegrationApp());
      
      // Navigate to paywall
      await tester.tap(find.text('Analytics (Pro Required)'));
      await tester.pumpAndSettle();
      
      // Attempt purchase
      await tester.tap(find.text('Get Pro Monthly'));
      await tester.pumpAndSettle();
      
      // Should show error message
      expect(find.text('Purchase canceled'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      
      // User can try again
      await tester.tap(find.text('Try again'));
      await tester.pump();
      
      // Error should clear
      expect(find.text('Purchase canceled'), findsNothing);
    });

    testWidgets('Offline state handling', (tester) async {
      // Setup offline state
      when(mockResolver.isPro).thenReturn(false);
      when(mockResolver.entitlementStream).thenAnswer((_) => Stream<Entitlement>.empty());
      when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
          .thenThrow(BillingException._(code: 'offline', message: 'No network'));
      
      await tester.pumpWidget(createIntegrationApp());
      
      // Navigate to paywall
      await tester.tap(find.text('Analytics (Pro Required)'));
      await tester.pumpAndSettle();
      
      // Attempt purchase while offline
      await tester.tap(find.text('Get Pro Monthly'));
      await tester.pumpAndSettle();
      
      // Should show offline state
      expect(find.textContaining('Offline'), findsOneWidget);
      expect(find.textContaining('you can still use MindTrainer'), findsOneWidget);
    });

    testWidgets('Restore purchases flow', (tester) async {
      // Setup free user initially
      when(mockResolver.isPro).thenReturn(false);
      final entitlementController = StreamController<Entitlement>();
      when(mockResolver.entitlementStream).thenAnswer((_) => entitlementController.stream);
      
      // Setup successful restore
      when(mockBillingAdapter.queryPurchases()).thenAnswer((_) async {});
      
      await tester.pumpWidget(createIntegrationApp());
      
      // Navigate to paywall
      await tester.tap(find.text('Analytics (Pro Required)'));
      await tester.pumpAndSettle();
      
      // Tap restore
      await tester.tap(find.text('Restore'));
      await tester.pump();
      
      // Should show loading
      expect(find.byType(CircularProgressIndicator), findsWidgets);
      
      // Simulate successful restore by emitting Pro entitlement
      when(mockResolver.isPro).thenReturn(true);
      final restoredEntitlement = Entitlement.pro(
        source: 'restored',
        since: DateTime.now().subtract(Duration(days: 10)),
        until: DateTime.now().add(Duration(days: 20)),
      );
      entitlementController.add(restoredEntitlement);
      
      await tester.pumpAndSettle();
      
      // Should show Pro status
      expect(find.text('You\'re Pro. Thank you!'), findsOneWidget);
      
      await entitlementController.close();
    });

    testWidgets('ProGate soft-gating integration', (tester) async {
      // Setup free user
      when(mockResolver.isPro).thenReturn(false);
      
      // Create ProGates using EntitlementResolver
      final proGates = MindTrainerProGates.fromEntitlementResolver(mockResolver);
      
      await tester.pumpWidget(createIntegrationApp());
      
      // Should show feature as locked
      expect(proGates.isProActive, false);
      expect(proGates.advancedAnalytics, false);
      expect(proGates.unlimitedDailySessions, false);
      
      // After "upgrading" (changing mock)
      when(mockResolver.isPro).thenReturn(true);
      
      expect(proGates.isProActive, true);
      expect(proGates.advancedAnalytics, true);
      expect(proGates.unlimitedDailySessions, true);
    });
  });
}

// Test home screen that demonstrates the integration
class TestHomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Home')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () async {
              final wasGated = await context.maybePromptPaywall();
              if (!wasGated) {
                // Navigate to analytics
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text('Analytics')),
                      body: Center(child: Text('Analytics Screen')),
                    ),
                  ),
                );
              }
            },
            child: Text(context.isPro ? 'Analytics (Pro Active)' : 'Analytics (Pro Required)'),
          ),
        ],
      ),
    );
  }
}
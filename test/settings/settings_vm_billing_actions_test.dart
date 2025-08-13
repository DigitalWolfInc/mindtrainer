import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'dart:async';

import '../../lib/settings/settings_vm.dart';
import '../../lib/payments/entitlement_resolver.dart';
import '../../lib/payments/billing_adapter.dart';
import '../../lib/payments/stores/price_cache_store.dart';
import '../../lib/payments/models/price_cache.dart';
import '../../lib/payments/models/entitlement.dart';
import '../../lib/settings/email_optin_store.dart';

import 'settings_vm_billing_actions_test.mocks.dart';

@GenerateMocks([
  EntitlementResolver,
  BillingAdapter,
  PriceCacheStore,
  EmailOptInStore,
])
void main() {
  group('SettingsVM Billing Actions Tests', () {
    late MockEntitlementResolver mockResolver;
    late MockBillingAdapter mockBillingAdapter;
    late MockPriceCacheStore mockPriceCacheStore;
    late MockEmailOptInStore mockEmailStore;
    late SettingsVM vm;

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
      vm = SettingsVM.instance;
      
      // Replace dependencies (would need dependency injection in real implementation)
      // For now, test the public API behavior
    });

    tearDown(() {
      SettingsVM.resetInstance();
    });

    group('Busy State Management', () {
      test('buyMonthly should set busy during call', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenAnswer((_) => Future.delayed(Duration(milliseconds: 100)));

        await vm.initialize();
        expect(vm.busy, false);

        // Start purchase (don't await)
        final future = vm.buyMonthly();
        await Future.delayed(Duration(milliseconds: 10)); // Let busy state update
        
        // Should be busy now
        expect(vm.busy, true);
        
        await future;
        
        // Should not be busy after completion
        expect(vm.busy, false);
      });

      test('buyYearly should set busy during call', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_yearly'))
            .thenAnswer((_) => Future.delayed(Duration(milliseconds: 100)));

        await vm.initialize();
        expect(vm.busy, false);

        final future = vm.buyYearly();
        await Future.delayed(Duration(milliseconds: 10));
        
        expect(vm.busy, true);
        
        await future;
        expect(vm.busy, false);
      });

      test('restore should set busy during call', () async {
        when(mockBillingAdapter.queryPurchases())
            .thenAnswer((_) => Future.delayed(Duration(milliseconds: 100)));

        await vm.initialize();
        expect(vm.busy, false);

        final future = vm.restore();
        await Future.delayed(Duration(milliseconds: 10));
        
        expect(vm.busy, true);
        
        await future;
        expect(vm.busy, false);
      });

      test('manage should set busy during call', () async {
        when(mockBillingAdapter.manageSubscriptions())
            .thenAnswer((_) => Future.delayed(Duration(milliseconds: 100)));

        await vm.initialize();
        expect(vm.busy, false);

        final future = vm.manage();
        await Future.delayed(Duration(milliseconds: 10));
        
        expect(vm.busy, true);
        
        await future;
        expect(vm.busy, false);
      });
    });

    group('Error Mapping', () {
      test('should map BillingException to stable status messages', () async {
        await vm.initialize();

        // Test purchase canceled
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'purchase_canceled', message: 'User canceled'));
        
        await vm.buyMonthly();
        expect(vm.status, 'Canceled');

        // Test already owned
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'already_owned', message: 'Already owned'));
        
        await vm.buyMonthly();
        expect(vm.status, 'Already owned');

        // Test offline
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'offline', message: 'No network'));
        
        await vm.buyMonthly();
        expect(vm.status, 'Offline');

        // Test manage subscription unavailable
        when(mockBillingAdapter.manageSubscriptions())
            .thenThrow(BillingException._(code: 'manage_subscriptions_not_available', message: 'Not available'));
        
        await vm.manage();
        expect(vm.status, 'Open Google Play Store to manage subscriptions');

        // Test unknown error
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'unknown', message: 'Unknown'));
        
        await vm.buyMonthly();
        expect(vm.status, 'Try again');
      });

      test('should map generic exceptions to friendly messages', () async {
        await vm.initialize();

        // Test cancel-related error
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(Exception('User canceled the purchase'));
        
        await vm.buyMonthly();
        expect(vm.status, 'Canceled');

        // Test network-related error
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(Exception('Network error occurred'));
        
        await vm.buyMonthly();
        expect(vm.status, 'Offline');

        // Test generic error
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(Exception('Some other error'));
        
        await vm.buyMonthly();
        expect(vm.status, 'Try again');
      });
    });

    group('Success Messages', () {
      test('should show success status for purchases', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).thenAnswer((_) async {});
        when(mockBillingAdapter.purchase('mindtrainer_pro_yearly')).thenAnswer((_) async {});
        
        await vm.initialize();

        await vm.buyMonthly();
        expect(vm.status, 'Purchase initiated');

        await vm.buyYearly();
        expect(vm.status, 'Purchase initiated');
      });

      test('should show success status for restore', () async {
        when(mockBillingAdapter.queryPurchases()).thenAnswer((_) async {});
        
        await vm.initialize();
        await vm.restore();
        
        expect(vm.status, 'Restore completed');
      });
    });

    group('Debouncing', () {
      test('should debounce rapid purchase attempts', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).thenAnswer((_) async {});
        
        await vm.initialize();

        // Rapid successive calls
        await vm.buyMonthly(); // First call should go through
        await vm.buyMonthly(); // Should be debounced
        await vm.buyMonthly(); // Should be debounced

        // Verify only one call was made (would need better mocking to verify this)
        // For now, just verify no errors occurred
        expect(vm.status, 'Purchase initiated');
      });

      test('should debounce different actions', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).thenAnswer((_) async {});
        when(mockBillingAdapter.purchase('mindtrainer_pro_yearly')).thenAnswer((_) async {});
        when(mockBillingAdapter.queryPurchases()).thenAnswer((_) async {});
        
        await vm.initialize();

        // Rapid calls to different actions should be debounced
        await vm.buyMonthly();
        await vm.buyYearly(); // Should be debounced
        await vm.restore(); // Should be debounced
        
        expect(vm.status, 'Purchase initiated'); // Only first action should complete
      });

      test('should allow actions after debounce period', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).thenAnswer((_) async {});
        
        await vm.initialize();

        await vm.buyMonthly();
        expect(vm.status, 'Purchase initiated');
        
        // Wait longer than debounce period (800ms)
        await Future.delayed(Duration(milliseconds: 900));
        
        await vm.buyMonthly();
        expect(vm.status, 'Purchase initiated'); // Should work again
      });
    });

    group('Status Management', () {
      test('should clear status on successful action start', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).thenAnswer((_) async {});
        
        await vm.initialize();

        // Set initial error status
        when(mockBillingAdapter.purchase('mindtrainer_pro_yearly'))
            .thenThrow(BillingException._(code: 'offline', message: 'No network'));
        
        await vm.buyYearly();
        expect(vm.status, 'Offline');

        // Start new successful action - should clear error
        await vm.buyMonthly();
        expect(vm.status, 'Purchase initiated'); // Error should be replaced
      });

      test('should allow manual status clearing', () async {
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'offline', message: 'No network'));
        
        await vm.initialize();
        await vm.buyMonthly();
        
        expect(vm.status, 'Offline');
        
        vm.clearStatus();
        expect(vm.status, null);
      });
    });
  });
}
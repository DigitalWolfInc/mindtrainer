import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/settings/settings_vm.dart';
import '../../lib/payments/entitlement_resolver.dart';
import '../../lib/payments/billing_adapter.dart';
import '../../lib/payments/stores/price_cache_store.dart';
import '../../lib/payments/models/price_cache.dart';
import '../../lib/payments/models/entitlement.dart';
import '../../lib/settings/email_optin_store.dart';

import 'settings_vm_email_toggle_test.mocks.dart';

@GenerateMocks([
  EntitlementResolver,
  BillingAdapter,
  PriceCacheStore,
  EmailOptInStore,
])
void main() {
  group('SettingsVM Email Toggle Tests', () {
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
      when(mockResolver.entitlementStream).thenAnswer((_) => Stream<Entitlement>.empty());
      when(mockResolver.isPro).thenReturn(false);
      when(mockResolver.currentEntitlement).thenReturn(Entitlement.none());
      when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());

      SettingsVM.resetInstance();
      vm = SettingsVM.instance;
    });

    tearDown(() {
      SettingsVM.resetInstance();
    });

    group('Email Opt-in State', () {
      test('should load initial email opt-in state', () async {
        when(mockEmailStore.optedIn).thenReturn(true);
        
        await vm.initialize();
        expect(vm.emailOptIn, true);
        
        verify(mockEmailStore.init()).called(1);
        verify(mockEmailStore.optedIn).called(1);
      });

      test('should start with false when store returns false', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        
        await vm.initialize();
        expect(vm.emailOptIn, false);
      });
    });

    group('Toggle Email Opt-in', () {
      test('should persist true and update emailOptIn', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(true)).thenAnswer((_) async {});
        
        await vm.initialize();
        expect(vm.emailOptIn, false);

        await vm.toggleEmailOptIn(true);
        
        verify(mockEmailStore.setOptIn(true)).called(1);
        expect(vm.emailOptIn, true);
        expect(vm.status, 'Email updates enabled');
      });

      test('should persist false and update emailOptIn', () async {
        when(mockEmailStore.optedIn).thenReturn(true);
        when(mockEmailStore.setOptIn(false)).thenAnswer((_) async {});
        
        await vm.initialize();
        expect(vm.emailOptIn, true);

        await vm.toggleEmailOptIn(false);
        
        verify(mockEmailStore.setOptIn(false)).called(1);
        expect(vm.emailOptIn, false);
        expect(vm.status, 'Email updates disabled');
      });
    });

    group('Status Messages', () {
      test('should set appropriate status messages', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(any)).thenAnswer((_) async {});
        
        await vm.initialize();

        // Enable email updates
        await vm.toggleEmailOptIn(true);
        expect(vm.status, 'Email updates enabled');

        // Disable email updates
        await vm.toggleEmailOptIn(false);
        expect(vm.status, 'Email updates disabled');
      });

      test('should clear status before setting new one', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(any)).thenAnswer((_) async {});
        
        await vm.initialize();
        
        // Set initial status
        vm.clearStatus();
        vm.notifyListeners(); // Simulate some other status being set
        
        await vm.toggleEmailOptIn(true);
        expect(vm.status, 'Email updates enabled');
      });
    });

    group('Busy State', () {
      test('should set busy during toggle operation', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(true))
            .thenAnswer((_) => Future.delayed(Duration(milliseconds: 100)));
        
        await vm.initialize();
        expect(vm.busy, false);

        final future = vm.toggleEmailOptIn(true);
        await Future.delayed(Duration(milliseconds: 10)); // Let busy state update
        
        expect(vm.busy, true);
        
        await future;
        expect(vm.busy, false);
      });
    });

    group('Error Handling', () {
      test('should handle store errors gracefully', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(true)).thenThrow(Exception('File write error'));
        
        await vm.initialize();
        
        await vm.toggleEmailOptIn(true);
        
        // Should map error to friendly message
        expect(vm.status, 'Try again');
        expect(vm.busy, false);
        
        // State should remain unchanged on error
        expect(vm.emailOptIn, false);
      });

      test('should handle different error types', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        
        await vm.initialize();

        // Test network-like error
        when(mockEmailStore.setOptIn(true)).thenThrow(Exception('Network timeout'));
        await vm.toggleEmailOptIn(true);
        expect(vm.status, 'Offline');

        // Test cancellation-like error
        when(mockEmailStore.setOptIn(true)).thenThrow(Exception('Operation canceled'));
        await vm.toggleEmailOptIn(true);
        expect(vm.status, 'Canceled');
      });
    });

    group('Debouncing', () {
      test('should debounce rapid toggle attempts', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(any)).thenAnswer((_) async {});
        
        await vm.initialize();

        // Rapid successive calls
        await vm.toggleEmailOptIn(true);  // First call should go through
        await vm.toggleEmailOptIn(false); // Should be debounced
        await vm.toggleEmailOptIn(true);  // Should be debounced

        // Only first call should have persisted
        verify(mockEmailStore.setOptIn(true)).called(1);
        verifyNever(mockEmailStore.setOptIn(false));
        
        expect(vm.emailOptIn, true);
        expect(vm.status, 'Email updates enabled');
      });

      test('should allow toggle after debounce period', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(any)).thenAnswer((_) async {});
        
        await vm.initialize();

        await vm.toggleEmailOptIn(true);
        expect(vm.status, 'Email updates enabled');
        
        // Wait longer than debounce period (800ms)
        await Future.delayed(Duration(milliseconds: 900));
        
        await vm.toggleEmailOptIn(false);
        
        verify(mockEmailStore.setOptIn(true)).called(1);
        verify(mockEmailStore.setOptIn(false)).called(1);
        expect(vm.status, 'Email updates disabled');
      });
    });

    group('State Consistency', () {
      test('should maintain consistent state across operations', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(any)).thenAnswer((_) async {});
        
        await vm.initialize();
        
        // Multiple successful toggles
        await vm.toggleEmailOptIn(true);
        expect(vm.emailOptIn, true);
        
        // Wait for debounce
        await Future.delayed(Duration(milliseconds: 900));
        
        await vm.toggleEmailOptIn(false);
        expect(vm.emailOptIn, false);
        
        await Future.delayed(Duration(milliseconds: 900));
        
        await vm.toggleEmailOptIn(true);
        expect(vm.emailOptIn, true);
      });

      test('should not update state on error', () async {
        when(mockEmailStore.optedIn).thenReturn(false);
        when(mockEmailStore.setOptIn(true)).thenThrow(Exception('Storage error'));
        
        await vm.initialize();
        final initialState = vm.emailOptIn;
        
        await vm.toggleEmailOptIn(true);
        
        // State should remain unchanged after error
        expect(vm.emailOptIn, initialState);
        expect(vm.status, 'Try again');
      });
    });
  });
}
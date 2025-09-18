import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/payments/paywall_vm.dart';
import '../../lib/payments/billing_adapter.dart';
import '../../lib/payments/entitlement_resolver.dart';
import '../../lib/payments/stores/price_cache_store.dart';
import '../../lib/payments/models/price_cache.dart';
import '../../lib/payments/models/entitlement.dart';

import 'paywall_vm_test.mocks.dart';

@GenerateMocks([
  BillingAdapter,
  EntitlementResolver, 
  PriceCacheStore,
  PaywallVM,
])
void main() {
  group('PaywallVM Tests', () {
    late MockBillingAdapter mockBillingAdapter;
    late MockEntitlementResolver mockEntitlementResolver;
    late MockPriceCacheStore mockPriceCacheStore;
    late PaywallVM paywall;

    setUp(() {
      mockBillingAdapter = MockBillingAdapter();
      mockEntitlementResolver = MockEntitlementResolver();
      mockPriceCacheStore = MockPriceCacheStore();
      
      // Reset PaywallVM singleton
      PaywallVM.resetInstance();
    });

    tearDown(() {
      PaywallVM.resetInstance();
    });

    PaywallVM createPaywallVM() {
      // Since PaywallVM is a singleton, we need to test it with the actual instance
      // but we can control its dependencies through dependency injection
      return PaywallVM._(
        mockEntitlementResolver,
        mockPriceCacheStore,
        mockBillingAdapter,
      );
    }

    group('Initialization', () {
      test('should initialize correctly with mocked dependencies', () async {
        // Setup mocks
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());

        paywall = createPaywallVM();
        
        // Test initial state
        expect(paywall.isPro, false);
        expect(paywall.monthlyPrice, null);
        expect(paywall.yearlyPrice, null);
        expect(paywall.pricesStale, false);
        expect(paywall.isBusy, false);
        expect(paywall.error, null);
        expect(paywall.offline, false);

        // Initialize
        await paywall.initialize();

        // Verify initialization calls
        verify(mockEntitlementResolver.initialize()).called(1);
        verify(mockBillingAdapter.initialize()).called(1);
        verify(mockEntitlementResolver.entitlementStream).called(1);
        verify(mockPriceCacheStore.getCache()).called(1);
      });

      test('should update isPro when entitlement changes', () async {
        // Setup entitlement stream
        final entitlementController = StreamController<Entitlement>();
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => entitlementController.stream);
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());

        paywall = createPaywallVM();
        await paywall.initialize();

        expect(paywall.isPro, false);

        // Emit Pro entitlement
        final proEntitlement = Entitlement.pro(
          source: 'subscription',
          since: DateTime.now(),
          until: DateTime.now().add(Duration(days: 30)),
        );
        entitlementController.add(proEntitlement);

        // Wait for stream update
        await Future.delayed(Duration(milliseconds: 10));

        expect(paywall.isPro, true);

        await entitlementController.close();
      });
    });

    group('Price Cache Integration', () {
      test('should load prices from cache', () async {
        final priceCache = PriceCache({
          'mindtrainer_pro_monthly': PriceCacheEntry(
            productId: 'mindtrainer_pro_monthly',
            price: '\$9.99',
            cachedAt: DateTime.now(),
          ),
          'mindtrainer_pro_yearly': PriceCacheEntry(
            productId: 'mindtrainer_pro_yearly', 
            price: '\$99.99',
            cachedAt: DateTime.now(),
          ),
        });

        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => priceCache);

        paywall = createPaywallVM();
        await paywall.initialize();

        expect(paywall.monthlyPrice, '\$9.99');
        expect(paywall.yearlyPrice, '\$99.99');
        expect(paywall.pricesStale, false);
      });

      test('should detect stale prices', () async {
        final staleCache = PriceCache({
          'mindtrainer_pro_monthly': PriceCacheEntry(
            productId: 'mindtrainer_pro_monthly',
            price: '\$9.99',
            cachedAt: DateTime.now().subtract(Duration(hours: 72)), // 3 days old
          ),
        });

        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => staleCache);

        paywall = createPaywallVM();
        await paywall.initialize();

        expect(paywall.pricesStale, true);
      });
    });

    group('Billing Operations', () {
      test('buyMonthly should call billing adapter', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenAnswer((_) async {});

        paywall = createPaywallVM();
        await paywall.initialize();

        await paywall.buyMonthly();

        verify(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).called(1);
        expect(paywall.error, null);
      });

      test('buyYearly should call billing adapter', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.purchase('mindtrainer_pro_yearly'))
            .thenAnswer((_) async {});

        paywall = createPaywallVM();
        await paywall.initialize();

        await paywall.buyYearly();

        verify(mockBillingAdapter.purchase('mindtrainer_pro_yearly')).called(1);
        expect(paywall.error, null);
      });

      test('restore should call queryPurchases', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.queryPurchases()).thenAnswer((_) async {});

        paywall = createPaywallVM();
        await paywall.initialize();

        await paywall.restore();

        verify(mockBillingAdapter.queryPurchases()).called(1);
        expect(paywall.error, null);
      });

      test('manage should call manageSubscriptions', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.manageSubscriptions()).thenAnswer((_) async {});

        paywall = createPaywallVM();
        await paywall.initialize();

        await paywall.manage();

        verify(mockBillingAdapter.manageSubscriptions()).called(1);
        expect(paywall.error, null);
      });
    });

    group('Error Handling', () {
      test('should handle billing exceptions properly', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'purchase_canceled', message: 'User canceled'));

        paywall = createPaywallVM();
        await paywall.initialize();

        await paywall.buyMonthly();

        expect(paywall.error, 'Purchase canceled');
        expect(paywall.isBusy, false);
      });

      test('should handle offline errors', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'offline', message: 'No network connection'));

        paywall = createPaywallVM();
        await paywall.initialize();

        await paywall.buyMonthly();

        expect(paywall.error, 'Offline');
        expect(paywall.offline, true);
      });

      test('should clear errors when requested', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenThrow(BillingException._(code: 'offline', message: 'No network connection'));

        paywall = createPaywallVM();
        await paywall.initialize();

        await paywall.buyMonthly();
        expect(paywall.error, 'Offline');
        expect(paywall.offline, true);

        paywall.clearError();
        expect(paywall.error, null);
        expect(paywall.offline, false);
      });
    });

    group('Debouncing', () {
      test('should debounce rapid purchase attempts', () async {
        when(mockEntitlementResolver.initialize()).thenAnswer((_) async {});
        when(mockBillingAdapter.initialize()).thenAnswer((_) async {});
        when(mockEntitlementResolver.entitlementStream)
            .thenAnswer((_) => Stream<Entitlement>.empty());
        when(mockEntitlementResolver.isPro).thenReturn(false);
        when(mockPriceCacheStore.getCache()).thenAnswer((_) async => PriceCache.empty());
        when(mockBillingAdapter.purchase('mindtrainer_pro_monthly'))
            .thenAnswer((_) async {});

        paywall = createPaywallVM();
        await paywall.initialize();

        // Rapid successive calls
        await paywall.buyMonthly(); // First call should go through
        await paywall.buyMonthly(); // Second call should be debounced
        await paywall.buyMonthly(); // Third call should be debounced

        // Only first call should reach billing adapter
        verify(mockBillingAdapter.purchase('mindtrainer_pro_monthly')).called(1);
      });
    });
  });
}
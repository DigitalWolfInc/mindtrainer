import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/payments/models.dart';
import 'package:mindtrainer/payments/receipt_store.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../test_helpers/fake_path_provider_platform.dart';

void main() {
  group('ReceiptStore', () {
    late ReceiptStore store;

    setUpAll(() {
      // Set up fake path provider
      PathProviderPlatform.instance = FakePathProviderPlatform();
      FakePathProviderPlatform.setUp();
    });

    tearDownAll(() {
      FakePathProviderPlatform.tearDown();
    });

    setUp(() async {
      // Reset singleton for each test
      ReceiptStore.resetInstance();
      store = ReceiptStore.instance;
      await store.initialize();
    });

    tearDown(() async {
      // Clean up
      await store.clearAll();
    });

    group('initialization', () {
      test('initializes with empty cache when file does not exist', () async {
        expect(store.receiptCount, equals(0));
        expect(store.getAllReceipts(), isEmpty);
        expect(store.hasValidProReceipt(), isFalse);
      });

      test('initializes properly', () async {
        expect(store.isInitialized, isTrue);
      });
    });

    group('saving receipts', () {
      test('saves valid receipt successfully', () async {
        final receipt = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'test_token_123',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        await store.saveReceipt(receipt);

        expect(store.receiptCount, equals(1));
        final saved = store.getReceipt('mindtrainer_pro_monthly', 'test_token_123');
        expect(saved, isNotNull);
        expect(saved!.productId, equals('mindtrainer_pro_monthly'));
        expect(saved.purchaseToken, equals('test_token_123'));
      });

      test('rejects invalid receipt', () async {
        final invalidReceipt = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: null, // Invalid
          purchaseState: PurchaseInfo.statePurchased,
        );

        expect(
          () async => await store.saveReceipt(invalidReceipt),
          throwsA(isA<ArgumentError>()),
        );
        expect(store.receiptCount, equals(0));
      });

      test('persists receipt across store instances', () async {
        final receipt = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'test_token_123',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        await store.saveReceipt(receipt);

        // Create new store instance and verify persistence
        ReceiptStore.resetInstance();
        final newStore = ReceiptStore.instance;
        await newStore.initialize();
        
        final loaded = newStore.getReceipt('mindtrainer_pro_monthly', 'test_token_123');
        expect(loaded, isNotNull);
        expect(loaded!.productId, equals('mindtrainer_pro_monthly'));
      });

      test('overwrites existing receipt with same key', () async {
        final receipt1 = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'test_token_123',
          acknowledged: false,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        final receipt2 = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'test_token_123',
          acknowledged: true, // Different value
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        await store.saveReceipt(receipt1);
        await store.saveReceipt(receipt2);

        expect(store.receiptCount, equals(1)); // Should still be 1
        final saved = store.getReceipt('mindtrainer_pro_monthly', 'test_token_123');
        expect(saved!.acknowledged, isTrue); // Should have updated value
      });
    });

    group('retrieving receipts', () {
      setUp(() async {
        // Add test receipts
        final receipt1 = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'token_monthly',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
          purchaseTime: 1640995200000, // 2022-01-01
        );

        final receipt2 = PurchaseInfo(
          productId: 'mindtrainer_pro_yearly',
          purchaseToken: 'token_yearly',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
          purchaseTime: 1672531200000, // 2023-01-01
        );

        await store.saveReceipt(receipt1);
        await store.saveReceipt(receipt2);
      });

      test('retrieves specific receipt by product and token', () {
        final receipt = store.getReceipt('mindtrainer_pro_monthly', 'token_monthly');
        expect(receipt, isNotNull);
        expect(receipt!.productId, equals('mindtrainer_pro_monthly'));
        expect(receipt.purchaseToken, equals('token_monthly'));
      });

      test('returns null for non-existent receipt', () {
        final receipt = store.getReceipt('non_existent', 'fake_token');
        expect(receipt, isNull);
      });

      test('retrieves all receipts for specific product', () {
        final monthlyReceipts = store.getReceiptsForProduct('mindtrainer_pro_monthly');
        expect(monthlyReceipts.length, equals(1));
        expect(monthlyReceipts[0].productId, equals('mindtrainer_pro_monthly'));
      });

      test('retrieves all receipts', () {
        final allReceipts = store.getAllReceipts();
        expect(allReceipts.length, equals(2));
      });

      test('detects valid Pro receipt', () {
        expect(store.hasValidProReceipt(), isTrue);
      });

      test('gets most recent Pro purchase', () {
        final recent = store.getMostRecentProPurchase();
        expect(recent, isNotNull);
        expect(recent!.productId, equals('mindtrainer_pro_yearly')); // More recent
        expect(recent.purchaseTime, equals(1672531200000));
      });
    });

    group('removing receipts', () {
      test('removes existing receipt', () async {
        final receipt = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'test_token',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        await store.saveReceipt(receipt);
        expect(store.receiptCount, equals(1));

        await store.removeReceipt('mindtrainer_pro_monthly', 'test_token');
        expect(store.receiptCount, equals(0));
        expect(store.getReceipt('mindtrainer_pro_monthly', 'test_token'), isNull);
      });

      test('ignores removal of non-existent receipt', () async {
        await store.removeReceipt('non_existent', 'fake_token');
        expect(store.receiptCount, equals(0));
      });

      test('persists removal to file', () async {
        final receipt = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'test_token',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        await store.saveReceipt(receipt);
        await store.removeReceipt('mindtrainer_pro_monthly', 'test_token');

        // Verify removal persisted by creating new store instance
        ReceiptStore.resetInstance();
        final newStore = ReceiptStore.instance;
        await newStore.initialize();
        expect(newStore.receiptCount, equals(0));
      });
    });

    group('clearing all receipts', () {
      test('clears all receipts from memory and file', () async {
        final receipt1 = PurchaseInfo(
          productId: 'mindtrainer_pro_monthly',
          purchaseToken: 'token1',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        final receipt2 = PurchaseInfo(
          productId: 'mindtrainer_pro_yearly',
          purchaseToken: 'token2',
          acknowledged: true,
          autoRenewing: true,
          purchaseState: PurchaseInfo.statePurchased,
        );

        await store.saveReceipt(receipt1);
        await store.saveReceipt(receipt2);
        expect(store.receiptCount, equals(2));

        await store.clearAll();
        expect(store.receiptCount, equals(0));
        expect(store.getAllReceipts(), isEmpty);

        // Verify persistence by creating new store instance
        ReceiptStore.resetInstance();
        final newStore = ReceiptStore.instance;
        await newStore.initialize();
        expect(newStore.receiptCount, equals(0));
      });
    });
  });

  group('ReceiptStoreStats', () {
    test('generates correct stats from store with receipts', () async {
      final receipt1 = PurchaseInfo(
        productId: 'mindtrainer_pro_monthly',
        purchaseToken: 'token1',
        acknowledged: true,
        autoRenewing: true,
        purchaseState: PurchaseInfo.statePurchased,
        purchaseTime: DateTime(2022, 1, 1).millisecondsSinceEpoch,
      );

      final receipt2 = PurchaseInfo(
        productId: 'mindtrainer_pro_yearly',
        purchaseToken: 'token2',
        acknowledged: true,
        autoRenewing: true,
        purchaseState: PurchaseInfo.statePurchased,
        purchaseTime: DateTime(2023, 1, 1).millisecondsSinceEpoch,
      );

      ReceiptStore.resetInstance();
      final testStore = ReceiptStore.instance;
      await testStore.initialize();
      
      await testStore.saveReceipt(receipt1);
      await testStore.saveReceipt(receipt2);

      final stats = ReceiptStoreStats.fromStore(testStore);

      expect(stats.totalReceipts, equals(2));
      expect(stats.proReceipts, equals(2));
      expect(stats.productIds.length, equals(2));
      expect(stats.hasValidProSubscription, isTrue);
      expect(stats.oldestPurchase!.year, equals(2022));
      expect(stats.newestPurchase!.year, equals(2023));
    });

    test('handles empty store', () async {
      ReceiptStore.resetInstance();
      final testStore = ReceiptStore.instance;
      await testStore.initialize();
      await testStore.clearAll(); // Ensure store is empty

      final stats = ReceiptStoreStats.fromStore(testStore);

      expect(stats.totalReceipts, equals(0));
      expect(stats.proReceipts, equals(0));
      expect(stats.productIds, isEmpty);
      expect(stats.hasValidProSubscription, isFalse);
      expect(stats.oldestPurchase, isNull);
      expect(stats.newestPurchase, isNull);
    });
  });
}
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:path_provider/path_provider.dart';

import '../../../lib/payments/models/receipt.dart';
import '../../../lib/payments/stores/receipt_store.dart';
import '../test_helpers/fake_path_provider_platform.dart';

void main() {
  group('ReceiptStore', () {
    late ReceiptStore store;
    late FakePathProviderPlatform fakePathProvider;

    setUp(() {
      fakePathProvider = FakePathProviderPlatform();
      PathProviderPlatform.instance = fakePathProvider;
      
      ReceiptStore.resetInstance();
      store = ReceiptStore.instance;
    });

    tearDown(() async {
      await store.clear();
      ReceiptStore.resetInstance();
    });

    group('basic operations', () {
      test('starts empty', () async {
        expect(await store.isEmpty(), true);
        expect(await store.isNotEmpty(), false);
        expect(await store.count(), 0);
      });

      test('addReceipt stores receipt', () async {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'acknowledged': true,
          'source': 'test',
        });

        await store.addReceipt(receipt);

        expect(await store.count(), 1);
        expect(await store.isEmpty(), false);
        expect(await store.isNotEmpty(), true);

        final retrieved = await store.getReceipt('token_123');
        expect(retrieved, isNotNull);
        expect(retrieved!.productId, 'mindtrainer_pro_monthly');
      });

      test('addReceipts stores multiple receipts', () async {
        final receipts = [
          Receipt.fromEvent({
            'purchaseToken': 'token_1',
            'productId': 'product_1',
            'source': 'test',
          }),
          Receipt.fromEvent({
            'purchaseToken': 'token_2',
            'productId': 'product_2',
            'source': 'test',
          }),
        ];

        await store.addReceipts(receipts);

        expect(await store.count(), 2);
        expect(await store.getReceipt('token_1'), isNotNull);
        expect(await store.getReceipt('token_2'), isNotNull);
      });

      test('addReceipts skips duplicates efficiently', () async {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'product_123',
          'source': 'test',
        });

        await store.addReceipt(receipt);
        await store.addReceipts([receipt]); // Add same receipt again

        expect(await store.count(), 1);
      });
    });

    group('queries', () {
      setUp(() async {
        final receipts = [
          Receipt.fromEvent({
            'purchaseToken': 'token_pro_monthly',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'acknowledged': true,
            'source': 'play_billing',
          }),
          Receipt.fromEvent({
            'purchaseToken': 'token_pro_yearly',
            'productId': 'mindtrainer_pro_yearly',
            'purchaseState': 'purchased',
            'acknowledged': true,
            'source': 'play_billing',
          }),
          Receipt.fromEvent({
            'purchaseToken': 'token_pending',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'pending',
            'acknowledged': false,
            'source': 'play_billing',
          }),
          Receipt.fromEvent({
            'purchaseToken': 'token_other',
            'productId': 'other_product',
            'purchaseState': 'purchased',
            'acknowledged': true,
            'source': 'test',
          }),
        ];

        await store.addReceipts(receipts);
      });

      test('getAllReceipts returns all receipts', () async {
        final allReceipts = await store.getAllReceipts();
        expect(allReceipts, hasLength(4));
      });

      test('getReceiptsForProduct filters by product ID', () async {
        final monthlyReceipts = await store.getReceiptsForProduct('mindtrainer_pro_monthly');
        expect(monthlyReceipts, hasLength(2)); // One purchased, one pending
        
        final yearlyReceipts = await store.getReceiptsForProduct('mindtrainer_pro_yearly');
        expect(yearlyReceipts, hasLength(1));
      });

      test('getActiveProReceipts filters correctly', () async {
        final activeProReceipts = await store.getActiveProReceipts();
        expect(activeProReceipts, hasLength(2)); // Only purchased + acknowledged + pro products
        
        for (final receipt in activeProReceipts) {
          expect(receipt.isPro, true);
          expect(receipt.isActive, true);
        }
      });
    });

    group('persistence', () {
      test('persists receipts across instances', () async {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'persistent_token',
          'productId': 'persistent_product',
          'purchaseState': 'purchased',
          'source': 'persistence_test',
        });

        await store.addReceipt(receipt);

        // Create new instance to test persistence
        ReceiptStore.resetInstance();
        final newStore = ReceiptStore.instance;

        final retrieved = await newStore.getReceipt('persistent_token');
        expect(retrieved, isNotNull);
        expect(retrieved!.productId, 'persistent_product');
        expect(retrieved.source, 'persistence_test');
      });

      test('handles corrupted file gracefully', () async {
        // Create a corrupted file
        final file = await store._getFile();
        await file.parent.create(recursive: true);
        await file.writeAsString('invalid json content');

        // Should start with empty store
        ReceiptStore.resetInstance();
        final newStore = ReceiptStore.instance;
        
        expect(await newStore.isEmpty(), true);
      });

      test('handles missing file gracefully', () async {
        // Delete the file if it exists
        final file = await store._getFile();
        if (await file.exists()) {
          await file.delete();
        }

        // Should start with empty store
        ReceiptStore.resetInstance();
        final newStore = ReceiptStore.instance;
        
        expect(await newStore.isEmpty(), true);
      });
    });

    group('removal and clearing', () {
      test('removeReceipt removes specific receipt', () async {
        final receipts = [
          Receipt.fromEvent({'purchaseToken': 'token_1', 'source': 'test'}),
          Receipt.fromEvent({'purchaseToken': 'token_2', 'source': 'test'}),
        ];

        await store.addReceipts(receipts);
        expect(await store.count(), 2);

        final removed = await store.removeReceipt('token_1');
        expect(removed, true);
        expect(await store.count(), 1);
        expect(await store.getReceipt('token_1'), isNull);
        expect(await store.getReceipt('token_2'), isNotNull);
      });

      test('removeReceipt returns false for non-existent receipt', () async {
        final removed = await store.removeReceipt('non_existent_token');
        expect(removed, false);
      });

      test('clear removes all receipts', () async {
        await store.addReceipts([
          Receipt.fromEvent({'purchaseToken': 'token_1', 'source': 'test'}),
          Receipt.fromEvent({'purchaseToken': 'token_2', 'source': 'test'}),
        ]);

        expect(await store.count(), 2);

        await store.clear();

        expect(await store.count(), 0);
        expect(await store.isEmpty(), true);
      });
    });

    group('debug info', () {
      test('getDebugInfo provides useful information', () async {
        await store.addReceipts([
          Receipt.fromEvent({
            'purchaseToken': 'debug_token_12345',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'acknowledged': true,
            'source': 'debug_test',
          }),
        ]);

        final debugInfo = store.getDebugInfo();
        expect(debugInfo['loaded'], true);
        expect(debugInfo['cacheSize'], 1);
        expect(debugInfo['receiptTokens'], contains('debug_to...'));
        expect(debugInfo['activeProCount'], 1);
      });
    });

    group('atomic operations', () {
      test('uses temporary file for atomic writes', () async {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'atomic_token',
          'productId': 'atomic_product',
          'source': 'atomic_test',
        });

        await store.addReceipt(receipt);

        // Verify the temp file is not left behind
        final file = await store._getFile();
        final tempFile = File('${file.path}.tmp');
        expect(await tempFile.exists(), false);
      });
    });
  });
}

// Helper extension to access private methods for testing
extension ReceiptStoreTestHelpers on ReceiptStore {
  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/receipts.json');
  }
}
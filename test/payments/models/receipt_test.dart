import 'package:flutter_test/flutter_test.dart';
import '../../../lib/payments/models/receipt.dart';

void main() {
  group('Receipt', () {
    group('fromEvent', () {
      test('creates receipt from complete event data', () {
        final event = {
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': 1640995200000, // 2022-01-01
          'acknowledged': true,
          'source': 'play_billing',
        };

        final receipt = Receipt.fromEvent(event);

        expect(receipt.purchaseToken, 'token_123');
        expect(receipt.productId, 'mindtrainer_pro_monthly');
        expect(receipt.purchaseState, 'purchased');
        expect(receipt.purchaseTime, DateTime.fromMillisecondsSinceEpoch(1640995200000));
        expect(receipt.acknowledged, true);
        expect(receipt.source, 'play_billing');
        expect(receipt.raw, event);
      });

      test('handles missing fields with defaults', () {
        final event = <String, dynamic>{};

        final receipt = Receipt.fromEvent(event);

        expect(receipt.purchaseToken, '');
        expect(receipt.productId, '');
        expect(receipt.purchaseState, 'unknown');
        expect(receipt.purchaseTime, DateTime.fromMillisecondsSinceEpoch(0));
        expect(receipt.acknowledged, false);
        expect(receipt.source, 'unknown');
      });

      test('normalizes purchase state correctly', () {
        final testCases = [
          {'purchaseState': 'purchased', 'expected': 'purchased'},
          {'purchaseState': 1, 'expected': 'purchased'},
          {'purchaseState': 'pending', 'expected': 'pending'},
          {'purchaseState': 0, 'expected': 'pending'},
          {'purchaseState': 'cancelled', 'expected': 'cancelled'},
          {'purchaseState': 'canceled', 'expected': 'cancelled'},
          {'purchaseState': 2, 'expected': 'cancelled'},
          {'purchaseState': 'invalid', 'expected': 'invalid'},
        ];

        for (final testCase in testCases) {
          final event = {'purchaseState': testCase['purchaseState']};
          final receipt = Receipt.fromEvent(event);
          expect(receipt.purchaseState, testCase['expected']);
        }
      });
    });

    group('JSON serialization', () {
      test('toJson and fromJson work correctly', () {
        final original = Receipt.fromEvent({
          'purchaseToken': 'token_456',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': 1640995200000,
          'acknowledged': true,
          'source': 'restore',
        });

        final json = original.toJson();
        final restored = Receipt.fromJson(json);

        expect(restored.purchaseToken, original.purchaseToken);
        expect(restored.productId, original.productId);
        expect(restored.purchaseState, original.purchaseState);
        expect(restored.purchaseTime, original.purchaseTime);
        expect(restored.acknowledged, original.acknowledged);
        expect(restored.source, original.source);
      });
    });

    group('properties', () {
      test('isPro returns true for pro products', () {
        final proReceipt = Receipt.fromEvent({
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'acknowledged': true,
        });

        final nonProReceipt = Receipt.fromEvent({
          'productId': 'some_other_product',
          'purchaseState': 'purchased',
          'acknowledged': true,
        });

        expect(proReceipt.isPro, true);
        expect(nonProReceipt.isPro, false);
      });

      test('isPro requires purchased and acknowledged', () {
        final cases = [
          {'purchaseState': 'pending', 'acknowledged': true, 'expected': false},
          {'purchaseState': 'purchased', 'acknowledged': false, 'expected': false},
          {'purchaseState': 'cancelled', 'acknowledged': true, 'expected': false},
          {'purchaseState': 'purchased', 'acknowledged': true, 'expected': true},
        ];

        for (final testCase in cases) {
          final receipt = Receipt.fromEvent({
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': testCase['purchaseState'],
            'acknowledged': testCase['acknowledged'],
          });

          expect(receipt.isPro, testCase['expected']);
        }
      });

      test('isActive returns true for purchased and acknowledged', () {
        final activeReceipt = Receipt.fromEvent({
          'purchaseState': 'purchased',
          'acknowledged': true,
        });

        final inactiveReceipt = Receipt.fromEvent({
          'purchaseState': 'pending',
          'acknowledged': false,
        });

        expect(activeReceipt.isActive, true);
        expect(inactiveReceipt.isActive, false);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = Receipt.fromEvent({
          'purchaseToken': 'original_token',
          'productId': 'original_product',
          'purchaseState': 'pending',
          'acknowledged': false,
        });

        final updated = original.copyWith(
          purchaseState: 'purchased',
          acknowledged: true,
        );

        expect(updated.purchaseToken, 'original_token');
        expect(updated.productId, 'original_product');
        expect(updated.purchaseState, 'purchased');
        expect(updated.acknowledged, true);
      });
    });

    group('equality', () {
      test('receipts with same data are equal', () {
        final receipt1 = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'product_123',
          'purchaseState': 'purchased',
          'purchaseTime': 1640995200000,
          'acknowledged': true,
          'source': 'test',
        });

        final receipt2 = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'product_123',
          'purchaseState': 'purchased',
          'purchaseTime': 1640995200000,
          'acknowledged': true,
          'source': 'test',
        });

        expect(receipt1, receipt2);
        expect(receipt1.hashCode, receipt2.hashCode);
      });

      test('receipts with different data are not equal', () {
        final receipt1 = Receipt.fromEvent({
          'purchaseToken': 'token_123',
        });

        final receipt2 = Receipt.fromEvent({
          'purchaseToken': 'token_456',
        });

        expect(receipt1, isNot(receipt2));
      });
    });

    test('toString provides readable format', () {
      final receipt = Receipt.fromEvent({
        'purchaseToken': 'very_long_purchase_token_12345',
        'productId': 'test_product',
        'purchaseState': 'purchased',
      });

      final str = receipt.toString();
      expect(str, contains('very_lon')); // First 8 characters
      expect(str, contains('test_product'));
      expect(str, contains('purchased'));
    });
  });
}
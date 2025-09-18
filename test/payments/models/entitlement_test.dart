import 'package:flutter_test/flutter_test.dart';
import '../../../lib/payments/models/receipt.dart';
import '../../../lib/payments/models/entitlement.dart';

void main() {
  group('Entitlement', () {
    group('none factory', () {
      test('creates non-pro entitlement', () {
        final entitlement = Entitlement.none();
        
        expect(entitlement.isPro, false);
        expect(entitlement.source, 'none');
        expect(entitlement.since, isNull);
        expect(entitlement.until, isNull);
      });
    });

    group('fromReceipts', () {
      test('returns none for empty receipts', () {
        final entitlement = Entitlement.fromReceipts([]);
        
        expect(entitlement.isPro, false);
        expect(entitlement.source, 'none');
      });

      test('returns none for no active pro receipts', () {
        final receipts = [
          Receipt.fromEvent({
            'purchaseToken': 'token_1',
            'productId': 'regular_product',
            'purchaseState': 'purchased',
            'acknowledged': true,
            'source': 'test',
          }),
        ];

        final entitlement = Entitlement.fromReceipts(receipts);
        
        expect(entitlement.isPro, false);
        expect(entitlement.source, 'test');
      });

      test('returns pro entitlement for active pro receipt', () {
        final purchaseTime = DateTime(2024, 1, 1);
        final receipts = [
          Receipt.fromEvent({
            'purchaseToken': 'token_1',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': purchaseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
          }),
        ];

        final entitlement = Entitlement.fromReceipts(receipts);
        
        expect(entitlement.isPro, true);
        expect(entitlement.source, 'play_billing');
        expect(entitlement.since, purchaseTime);
        expect(entitlement.until, purchaseTime.add(const Duration(days: 30)));
      });

      test('calculates yearly subscription expiration', () {
        final purchaseTime = DateTime(2024, 1, 1);
        final receipts = [
          Receipt.fromEvent({
            'purchaseToken': 'token_1',
            'productId': 'mindtrainer_pro_yearly',
            'purchaseState': 'purchased',
            'purchaseTime': purchaseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
          }),
        ];

        final entitlement = Entitlement.fromReceipts(receipts);
        
        expect(entitlement.until, purchaseTime.add(const Duration(days: 365)));
      });

      test('uses latest active pro receipt', () {
        final earlyTime = DateTime(2024, 1, 1);
        final laterTime = DateTime(2024, 2, 1);
        
        final receipts = [
          Receipt.fromEvent({
            'purchaseToken': 'token_early',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': earlyTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'old',
          }),
          Receipt.fromEvent({
            'purchaseToken': 'token_later',
            'productId': 'mindtrainer_pro_yearly',
            'purchaseState': 'purchased',
            'purchaseTime': laterTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'new',
          }),
        ];

        final entitlement = Entitlement.fromReceipts(receipts);
        
        expect(entitlement.source, 'new');
        expect(entitlement.since, laterTime);
        expect(entitlement.until, laterTime.add(const Duration(days: 365)));
      });
    });

    group('properties', () {
      test('isExpired returns false when no until date', () {
        final entitlement = Entitlement.none();
        expect(entitlement.isExpired, false);
      });

      test('isExpired checks against current time', () {
        final past = DateTime.now().subtract(const Duration(days: 1));
        final future = DateTime.now().add(const Duration(days: 1));

        final expiredEntitlement = Entitlement.fromReceipts([
          Receipt.fromEvent({
            'purchaseToken': 'token',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': past.subtract(const Duration(days: 31)).millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'test',
          }),
        ]);

        final activeEntitlement = Entitlement.fromReceipts([
          Receipt.fromEvent({
            'purchaseToken': 'token',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': future.subtract(const Duration(days: 29)).millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'test',
          }),
        ]);

        expect(expiredEntitlement.isExpired, true);
        expect(activeEntitlement.isExpired, false);
      });

      test('isValid combines isPro and not expired', () {
        final activeTime = DateTime.now().subtract(const Duration(days: 1));
        
        final validEntitlement = Entitlement.fromReceipts([
          Receipt.fromEvent({
            'purchaseToken': 'token',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': activeTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'test',
          }),
        ]);

        final nonProEntitlement = Entitlement.none();

        expect(validEntitlement.isValid, true);
        expect(nonProEntitlement.isValid, false);
      });

      test('timeRemaining calculates correctly', () {
        final now = DateTime.now();
        final future = now.add(const Duration(hours: 5));
        
        final receipts = [
          Receipt.fromEvent({
            'purchaseToken': 'token',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': future.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'test',
          }),
        ];

        final entitlement = Entitlement.fromReceipts(receipts);
        final remaining = entitlement.timeRemaining;
        
        expect(remaining, isNotNull);
        expect(remaining!.inHours, closeTo(5, 1));
      });
    });

    group('JSON serialization', () {
      test('toJson and fromJson work correctly', () {
        final original = Entitlement.fromReceipts([
          Receipt.fromEvent({
            'purchaseToken': 'token',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': DateTime(2024, 1, 1).millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
          }),
        ]);

        final json = original.toJson();
        final restored = Entitlement.fromJson(json);

        expect(restored.isPro, original.isPro);
        expect(restored.source, original.source);
        expect(restored.since, original.since);
        expect(restored.until, original.until);
      });
    });

    group('copyWith', () {
      test('creates copy with updated fields', () {
        final original = Entitlement.none();
        final updated = original.copyWith(
          isPro: true,
          source: 'updated',
        );

        expect(updated.isPro, true);
        expect(updated.source, 'updated');
        expect(updated.since, original.since);
        expect(updated.until, original.until);
      });
    });

    group('equality', () {
      test('entitlements with same data are equal', () {
        final time = DateTime(2024, 1, 1);
        final entitlement1 = Entitlement.fromReceipts([
          Receipt.fromEvent({
            'purchaseToken': 'token',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': time.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'test',
          }),
        ]);

        final entitlement2 = Entitlement.fromReceipts([
          Receipt.fromEvent({
            'purchaseToken': 'token',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': time.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'test',
          }),
        ]);

        expect(entitlement1, entitlement2);
        expect(entitlement1.hashCode, entitlement2.hashCode);
      });
    });

    test('toString provides readable format', () {
      final entitlement = Entitlement.fromReceipts([
        Receipt.fromEvent({
          'purchaseToken': 'token',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': DateTime(2024, 1, 1).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'test',
        }),
      ]);

      final str = entitlement.toString();
      expect(str, contains('isPro: true'));
      expect(str, contains('source: test'));
    });
  });
}
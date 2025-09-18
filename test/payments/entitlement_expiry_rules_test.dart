import 'package:flutter_test/flutter_test.dart';

import '../../lib/payments/models/receipt.dart';
import '../../lib/payments/models/entitlement.dart';

void main() {
  group('Entitlement Expiry Rules Tests', () {
    late DateTime baseTime;
    late DateTime futureTime;
    late DateTime pastTime;

    setUp(() {
      baseTime = DateTime(2025, 1, 15, 12, 0, 0);
      futureTime = baseTime.add(const Duration(days: 30));
      pastTime = baseTime.subtract(const Duration(days: 1));
    });

    group('Active Subscriptions', () {
      test('should grant access when expiryTime > now and autoRenewing=true', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, futureTime);
      });

      test('should grant access when expiryTime > now and autoRenewing=false', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureTime.millisecondsSinceEpoch,
          'autoRenewing': false,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, futureTime);
      });

      test('should grant access when no expiryTime (perpetual)', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          // No expiryTimeMillis field
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, null);
      });
    });

    group('Expired Subscriptions with Auto-Renew', () {
      test('should deny access after expiry when autoRenewing=true (await renewal)', () {
        final expiredTime = baseTime.subtract(const Duration(hours: 1));
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'awaiting_renewal');
      });

      test('should advance clock to expiry + 1s with autoRenewing=true', () {
        final expiredTime = baseTime.subtract(const Duration(seconds: 1));
        final checkTime = baseTime.add(const Duration(seconds: 1));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], checkTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'awaiting_renewal');
      });
    });

    group('Expired Subscriptions without Auto-Renew', () {
      test('should deny access when autoRenewing=false at/after expiry', () {
        final expiredTime = baseTime.subtract(const Duration(hours: 1));
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': false,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired');
      });

      test('should deny access when autoRenewing=null (unknown) after expiry', () {
        final expiredTime = baseTime.subtract(const Duration(hours: 1));
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          // No autoRenewing field
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired');
      });
    });

    group('Edge Cases', () {
      test('should handle exact expiry time moment', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': baseTime.millisecondsSinceEpoch,
          'autoRenewing': false,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired');
      });

      test('should handle multiple receipts with different expiry times', () {
        final oldExpiry = baseTime.subtract(const Duration(days: 5));
        final futureExpiry = baseTime.add(const Duration(days: 10));

        final expiredReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_old',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 35)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': oldExpiry.millisecondsSinceEpoch,
          'autoRenewing': false,
        });

        final activeReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_new',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 15)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([expiredReceipt, activeReceipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, futureExpiry);
        expect(entitlement.since, activeReceipt.purchaseTime);
      });

      test('should choose receipt with furthest future access', () {
        final nearExpiry = baseTime.add(const Duration(days: 5));
        final farExpiry = baseTime.add(const Duration(days: 30));

        final shortTermReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_short',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': nearExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final longTermReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_long',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': farExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([shortTermReceipt, longTermReceipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.until, farExpiry);
        expect(entitlement.since, longTermReceipt.purchaseTime);
      });

      test('should ignore non-purchased receipts', () {
        final pendingReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_pending',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'pending',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': false,
          'source': 'play_billing',
          'expiryTimeMillis': futureTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final cancelledReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_cancelled',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'cancelled',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([pendingReceipt, cancelledReceipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'no_valid_receipts');
      });

      test('should handle empty receipts list', () {
        final entitlement = Entitlement.fromReceipts([], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'no_receipts');
        expect(entitlement.source, 'none');
      });
    });

    group('Time Boundary Testing', () {
      test('should grant access 1 millisecond before expiry', () {
        final expiryTime = baseTime.add(const Duration(milliseconds: 1));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
      });

      test('should deny access 1 millisecond after expiry with autoRenewing=false', () {
        final expiryTime = baseTime.subtract(const Duration(milliseconds: 1));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_123',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': false,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired');
      });
    });

    group('Legacy Behavior Compatibility', () {
      test('should handle receipts without time fields gracefully', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_legacy',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          // No time-bounded fields
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, null); // Perpetual
      });

      test('should handle malformed expiry time fields', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_malformed',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': 'invalid_timestamp',
          'autoRenewing': 'not_boolean',
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        // Should default to perpetual when expiry parsing fails
        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, null);
      });
    });
  });
}
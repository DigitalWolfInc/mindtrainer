import 'package:flutter_test/flutter_test.dart';

import '../../lib/payments/models/receipt.dart';
import '../../lib/payments/models/entitlement.dart';

void main() {
  group('Entitlement Grace and Hold Tests', () {
    late DateTime baseTime;
    late DateTime expiredTime;

    setUp(() {
      baseTime = DateTime(2025, 1, 15, 12, 0, 0);
      expiredTime = baseTime.subtract(const Duration(hours: 6));
    });

    group('Grace Period Access', () {
      test('should grant access in IN_GRACE state after expiry with default 3-day window', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, expiredTime.add(const Duration(days: 3)));
      });

      test('should use explicit accountStateUntil when provided', () {
        final explicitGraceEnd = expiredTime.add(const Duration(days: 1));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace_explicit',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': explicitGraceEnd.millisecondsSinceEpoch,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, explicitGraceEnd);
      });

      test('should deny access when grace period has ended', () {
        final graceEndTime = baseTime.subtract(const Duration(hours: 1));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace_ended',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': graceEndTime.millisecondsSinceEpoch,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'awaiting_renewal');
      });

      test('should deny access when default grace period (3 days) has ended', () {
        final longExpiredTime = baseTime.subtract(const Duration(days: 4));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace_default_ended',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': longExpiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'awaiting_renewal');
      });
    });

    group('Hold State Access', () {
      test('should grant access in ON_HOLD state after expiry', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_hold',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'accountHold': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, expiredTime.add(const Duration(days: 3)));
      });

      test('should grant access in ON_HOLD with explicit end time', () {
        final holdEndTime = expiredTime.add(const Duration(days: 2));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_hold_explicit',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isOnHold': true,
          'accountStateUntilMillis': holdEndTime.millisecondsSinceEpoch,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, holdEndTime);
      });

      test('should deny access when hold period has ended', () {
        final holdEndTime = baseTime.subtract(const Duration(hours: 2));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_hold_ended',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'accountHold': true,
          'accountStateUntilMillis': holdEndTime.millisecondsSinceEpoch,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'awaiting_renewal');
      });
    });

    group('Paused State Behavior', () {
      test('should deny access when PAUSED regardless of expiry time', () {
        final futureTime = baseTime.add(const Duration(days: 10));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_paused_future',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isPaused': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired'); // Since no receipt grants access
      });

      test('should deny access when PAUSED even in grace period', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_paused_grace',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isPaused': true,
          'isInGracePeriod': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired');
      });
    });

    group('State Priority Testing', () {
      test('should prioritize PAUSED over ON_HOLD', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_paused_hold',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isPaused': true,
          'accountHold': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired');
      });

      test('should prioritize ON_HOLD over IN_GRACE', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_hold_grace',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'accountHold': true,
          'isInGracePeriod': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(receipt.accountState, 'ON_HOLD'); // Should be parsed as ON_HOLD
      });

      test('should use ACTIVE state when no special states present', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_active',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, false); // Expired
        expect(entitlement.reason, 'awaiting_renewal');
        expect(receipt.accountState, 'ACTIVE');
      });
    });

    group('Multiple Receipt Grace/Hold Logic', () {
      test('should choose receipt with furthest grace/hold access', () {
        final shortGraceEnd = expiredTime.add(const Duration(days: 1));
        final longGraceEnd = expiredTime.add(const Duration(days: 5));

        final shortGraceReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_short_grace',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': shortGraceEnd.millisecondsSinceEpoch,
        });

        final longGraceReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_long_grace',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 35)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': longGraceEnd.millisecondsSinceEpoch,
        });

        final entitlement = Entitlement.fromReceipts([shortGraceReceipt, longGraceReceipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, longGraceEnd);
        expect(entitlement.since, longGraceReceipt.purchaseTime);
      });

      test('should prefer active receipt over grace/hold receipt', () {
        final futureExpiry = baseTime.add(const Duration(days: 15));
        
        final graceReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 35)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
        });

        final activeReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_active',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([graceReceipt, activeReceipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned'); // Normal ownership, not grace
        expect(entitlement.until, futureExpiry);
        expect(entitlement.since, activeReceipt.purchaseTime);
      });
    });

    group('Edge Cases', () {
      test('should handle grace period boundary precisely', () {
        final graceBoundary = expiredTime.add(const Duration(days: 3));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace_boundary',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
        });

        // Test exactly at grace boundary
        final entitlementAtBoundary = Entitlement.fromReceipts([receipt], graceBoundary);
        expect(entitlementAtBoundary.isPro, false);
        expect(entitlementAtBoundary.reason, 'awaiting_renewal');

        // Test 1ms before boundary
        final entitlementBeforeBoundary = Entitlement.fromReceipts([receipt], graceBoundary.subtract(const Duration(milliseconds: 1)));
        expect(entitlementBeforeBoundary.isPro, true);
        expect(entitlementBeforeBoundary.reason, 'grace');
      });

      test('should handle earlier accountStateUntil than default grace period', () {
        final earlyGraceEnd = expiredTime.add(const Duration(hours: 12));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_early_grace_end',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': earlyGraceEnd.millisecondsSinceEpoch,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, earlyGraceEnd); // Should use explicit end, not default 3 days
      });

      test('should handle malformed accountStateUntil gracefully', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_malformed_state',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': 'invalid_timestamp',
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, expiredTime.add(const Duration(days: 3))); // Should fall back to default
      });
    });

    group('Integration with Non-Grace States', () {
      test('should not grant grace access when autoRenewing=false', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_no_renew_grace',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiredTime.millisecondsSinceEpoch,
          'autoRenewing': false,
          'isInGracePeriod': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true); // Grace period should still apply
        expect(entitlement.reason, 'grace');
      });

      test('should handle receipt with no expiry time in grace state', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace_no_expiry',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          // No expiryTimeMillis
          'autoRenewing': true,
          'isInGracePeriod': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], baseTime);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned'); // Should be treated as perpetual, not grace
        expect(entitlement.until, null);
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';

import '../../lib/payments/models/receipt.dart';
import '../../lib/payments/models/entitlement.dart';

void main() {
  group('Renewal Flow Tests', () {
    late DateTime baseTime;
    late DateTime dayN;
    late DateTime dayNPlus1;

    setUp(() {
      baseTime = DateTime(2025, 1, 15, 12, 0, 0);
      dayN = baseTime;
      dayNPlus1 = baseTime.add(const Duration(days: 1));
    });

    group('Basic Renewal Scenarios', () {
      test('should maintain access when expiry is tomorrow at day N', () {
        final expiryTomorrow = dayN.add(const Duration(days: 1));
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_expiry_tomorrow',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 29)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTomorrow.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, expiryTomorrow);
      });

      test('should simulate renewal event with larger expiryTime and return to owned', () {
        final originalExpiry = dayN.add(const Duration(hours: 12));
        final renewedExpiry = dayNPlus1.add(const Duration(days: 30));

        // Start with subscription expiring today
        final originalReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_original',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': originalExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        // Check entitlement at day N
        final entitlementDayN = Entitlement.fromReceipts([originalReceipt], dayN);
        expect(entitlementDayN.isPro, true);
        expect(entitlementDayN.reason, 'owned');

        // Simulate renewal event next day with new expiry
        final renewedReceipt = originalReceipt.copyWith(
          expiryTime: renewedExpiry,
          purchaseTime: dayNPlus1, // New purchase event
        );

        final entitlementAfterRenewal = Entitlement.fromReceipts([renewedReceipt], dayNPlus1);

        expect(entitlementAfterRenewal.isPro, true);
        expect(entitlementAfterRenewal.reason, 'owned');
        expect(entitlementAfterRenewal.until, renewedExpiry);
        expect(entitlementAfterRenewal.since, dayNPlus1);
      });

      test('should handle seamless renewal without access interruption', () {
        final originalExpiry = dayN.add(const Duration(hours: 1));
        final renewedExpiry = dayNPlus1.add(const Duration(days: 30));

        // Multiple time points to test seamless transition
        final timePoints = [
          dayN.subtract(const Duration(minutes: 30)), // Before renewal
          dayN,                                        // At renewal time
          dayN.add(const Duration(minutes: 30)),       // After renewal
        ];

        final originalReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_seamless',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': originalExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final renewedReceipt = originalReceipt.copyWith(
          purchaseToken: 'token_renewed',
          expiryTime: renewedExpiry,
        );

        // Before renewal - should have access with original receipt
        final entitlementBefore = Entitlement.fromReceipts([originalReceipt], timePoints[0]);
        expect(entitlementBefore.isPro, true);
        expect(entitlementBefore.reason, 'owned');

        // At renewal time - should have access with both receipts (chooses best)
        final entitlementDuring = Entitlement.fromReceipts([originalReceipt, renewedReceipt], timePoints[1]);
        expect(entitlementDuring.isPro, true);
        expect(entitlementDuring.reason, 'owned');
        expect(entitlementDuring.until, renewedExpiry);

        // After renewal - should have access with renewed receipt
        final entitlementAfter = Entitlement.fromReceipts([originalReceipt, renewedReceipt], timePoints[2]);
        expect(entitlementAfter.isPro, true);
        expect(entitlementAfter.reason, 'owned');
        expect(entitlementAfter.until, renewedExpiry);
      });
    });

    group('SKU Switch Scenarios', () {
      test('should choose receipt with furthest access when SKU changes', () {
        final monthlyExpiry = dayN.add(const Duration(days: 15));
        final yearlyExpiry = dayN.add(const Duration(days: 350));

        // Older monthly subscription
        final olderMonthly = Receipt.fromEvent({
          'purchaseToken': 'token_monthly_old',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 45)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': monthlyExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        // Newer yearly subscription (upgrade)
        final newerYearly = Receipt.fromEvent({
          'purchaseToken': 'token_yearly_new',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': yearlyExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([olderMonthly, newerYearly], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.until, yearlyExpiry); // Should choose furthest expiry
        expect(entitlement.since, newerYearly.purchaseTime);
      });

      test('should handle edge case where older receipt has longer validity', () {
        final shortTermExpiry = dayN.add(const Duration(days: 5));
        final longTermExpiry = dayN.add(const Duration(days: 300));

        // Newer short-term subscription
        final newerShortTerm = Receipt.fromEvent({
          'purchaseToken': 'token_short_new',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': shortTermExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        // Older long-term subscription (still valid)
        final olderLongTerm = Receipt.fromEvent({
          'purchaseToken': 'token_long_old',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 60)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': longTermExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([newerShortTerm, olderLongTerm], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.until, longTermExpiry);
        expect(entitlement.since, olderLongTerm.purchaseTime); // Older receipt provides longer access
      });

      test('should tie-break by newest purchaseTime when expiry times are equal', () {
        final sameExpiry = dayN.add(const Duration(days: 30));

        final olderReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_older',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 35)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': sameExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final newerReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_newer',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 5)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': sameExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([olderReceipt, newerReceipt], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.until, sameExpiry);
        expect(entitlement.since, newerReceipt.purchaseTime); // Should choose newer purchase
      });
    });

    group('Pause and Resume Flows', () {
      test('should handle pause event that removes access', () {
        final futureExpiry = dayN.add(const Duration(days: 20));

        // Active subscription gets paused
        final pausedReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_paused',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isPaused': true,
        });

        final entitlement = Entitlement.fromReceipts([pausedReceipt], dayN);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'expired'); // No valid receipts provide access
      });

      test('should handle resume event that restores access', () {
        final futureExpiry = dayN.add(const Duration(days: 20));

        // Subscription gets resumed (no longer paused)
        final resumedReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_resumed',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
          // isPaused: false (or omitted - default to active)
        });

        final entitlement = Entitlement.fromReceipts([resumedReceipt], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, futureExpiry);
      });

      test('should handle pause-resume cycle seamlessly', () {
        final futureExpiry = dayN.add(const Duration(days: 20));

        // Timeline: Active -> Paused -> Resumed
        final activeReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_cycle',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final pausedReceipt = activeReceipt.copyWith(
          accountState: 'PAUSED',
        );

        final resumedReceipt = activeReceipt.copyWith(
          accountState: 'ACTIVE',
        );

        // Check each state
        final activeEntitlement = Entitlement.fromReceipts([activeReceipt], dayN);
        expect(activeEntitlement.isPro, true);
        expect(activeEntitlement.reason, 'owned');

        final pausedEntitlement = Entitlement.fromReceipts([pausedReceipt], dayN);
        expect(pausedEntitlement.isPro, false);

        final resumedEntitlement = Entitlement.fromReceipts([resumedReceipt], dayN);
        expect(resumedEntitlement.isPro, true);
        expect(resumedEntitlement.reason, 'owned');
      });
    });

    group('Refund Scenarios', () {
      test('should handle refund event that revokes access', () {
        final futureExpiry = dayN.add(const Duration(days: 15));

        final refundedReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_refunded',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'refunded',
          'purchaseTime': dayN.subtract(const Duration(days: 10)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': futureExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([refundedReceipt], dayN);

        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'no_valid_receipts');
      });

      test('should fall back to other valid receipts after refund', () {
        final refundedExpiry = dayN.add(const Duration(days: 5));
        final activeExpiry = dayN.add(const Duration(days: 25));

        final refundedReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_refunded',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'refunded',
          'purchaseTime': dayN.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': refundedExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final activeReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_active',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': activeExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([refundedReceipt, activeReceipt], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, activeExpiry);
        expect(entitlement.since, activeReceipt.purchaseTime);
      });
    });

    group('Grace Period Renewal Flows', () {
      test('should transition from grace to owned after renewal', () {
        final originalExpiry = dayN.subtract(const Duration(hours: 12));
        final renewedExpiry = dayN.add(const Duration(days: 30));

        // Expired subscription in grace period
        final expiredReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_expired_grace',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': originalExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
        });

        // Check grace state
        final graceEntitlement = Entitlement.fromReceipts([expiredReceipt], dayN);
        expect(graceEntitlement.isPro, true);
        expect(graceEntitlement.reason, 'grace');

        // Renewal event updates expiry
        final renewedReceipt = expiredReceipt.copyWith(
          expiryTime: renewedExpiry,
          accountState: 'ACTIVE', // No longer in grace
        );

        final renewedEntitlement = Entitlement.fromReceipts([renewedReceipt], dayN);
        expect(renewedEntitlement.isPro, true);
        expect(renewedEntitlement.reason, 'owned');
        expect(renewedEntitlement.until, renewedExpiry);
      });

      test('should handle renewal that extends grace period', () {
        final originalExpiry = dayN.subtract(const Duration(days: 1));
        final extendedGraceEnd = dayN.add(const Duration(days: 5));

        final graceReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_grace_extended',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 30)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': originalExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': extendedGraceEnd.millisecondsSinceEpoch,
        });

        final entitlement = Entitlement.fromReceipts([graceReceipt], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'grace');
        expect(entitlement.until, extendedGraceEnd);
      });
    });

    group('Complex Multi-Receipt Scenarios', () {
      test('should handle overlapping subscriptions with different renewal states', () {
        final earlierExpiry = dayN.add(const Duration(days: 10));
        final laterExpiry = dayN.add(const Duration(days: 40));

        // Non-renewing subscription expiring sooner
        final nonRenewingReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_no_renew',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 20)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': earlierExpiry.millisecondsSinceEpoch,
          'autoRenewing': false,
        });

        // Auto-renewing subscription expiring later
        final autoRenewingReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_auto_renew',
          'productId': 'mindtrainer_pro_yearly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.subtract(const Duration(days: 350)).millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': laterExpiry.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([nonRenewingReceipt, autoRenewingReceipt], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.until, laterExpiry); // Should choose furthest expiry
        expect(entitlement.since, autoRenewingReceipt.purchaseTime);
      });

      test('should handle timeline with multiple renewal events', () {
        final timeSlots = [
          dayN,
          dayN.add(const Duration(days: 30)),
          dayN.add(const Duration(days: 60)),
        ];

        final expiryTimes = [
          dayN.add(const Duration(days: 30)),
          dayN.add(const Duration(days: 60)),
          dayN.add(const Duration(days: 90)),
        ];

        // Simulate progression through multiple renewal cycles
        final initialReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_multi_renew_1',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': timeSlots[0].millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTimes[0].millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final firstRenewal = initialReceipt.copyWith(
          purchaseToken: 'token_multi_renew_2',
          expiryTime: expiryTimes[1],
          purchaseTime: timeSlots[1],
        );

        final secondRenewal = initialReceipt.copyWith(
          purchaseToken: 'token_multi_renew_3',
          expiryTime: expiryTimes[2],
          purchaseTime: timeSlots[2],
        );

        // Test entitlement at each time slot
        final initialEntitlement = Entitlement.fromReceipts([initialReceipt], timeSlots[0]);
        expect(initialEntitlement.isPro, true);
        expect(initialEntitlement.until, expiryTimes[0]);

        final firstRenewalEntitlement = Entitlement.fromReceipts([initialReceipt, firstRenewal], timeSlots[1]);
        expect(firstRenewalEntitlement.isPro, true);
        expect(firstRenewalEntitlement.until, expiryTimes[1]);

        final secondRenewalEntitlement = Entitlement.fromReceipts([initialReceipt, firstRenewal, secondRenewal], timeSlots[2]);
        expect(secondRenewalEntitlement.isPro, true);
        expect(secondRenewalEntitlement.until, expiryTimes[2]);
      });
    });

    group('Edge Case Temporal Logic', () {
      test('should handle receipt with zero expiry time', () {
        final zeroExpiry = DateTime.fromMillisecondsSinceEpoch(0);

        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_zero_expiry',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': 0,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], dayN);

        // Should treat as expired since zero time is in far past
        expect(entitlement.isPro, false);
        expect(entitlement.reason, 'awaiting_renewal');
      });

      test('should handle far future expiry times', () {
        final farFuture = DateTime(2099, 12, 31);

        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_far_future',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': farFuture.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final entitlement = Entitlement.fromReceipts([receipt], dayN);

        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, farFuture);
      });

      test('should handle negative expiry times gracefully', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_negative_expiry',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': dayN.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': -1000,
          'autoRenewing': true,
        });

        // Negative timestamp should be ignored (parsed as null)
        expect(receipt.expiryTime, null);

        final entitlement = Entitlement.fromReceipts([receipt], dayN);

        // Should fall back to perpetual access
        expect(entitlement.isPro, true);
        expect(entitlement.reason, 'owned');
        expect(entitlement.until, null);
      });
    });
  });
}
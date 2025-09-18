import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/payments/models/receipt.dart';

void main() {
  group('Receipt Optional Fields Persistence Tests', () {
    late DateTime baseTime;
    late DateTime expiryTime;
    late DateTime stateUntilTime;

    setUp(() {
      baseTime = DateTime(2025, 1, 15, 12, 0, 0);
      expiryTime = baseTime.add(const Duration(days: 30));
      stateUntilTime = baseTime.add(const Duration(days: 3));
    });

    group('JSON Serialization Round-Trip', () {
      test('should serialize and deserialize receipt with all optional fields', () {
        final originalReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_complete',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isInGracePeriod': true,
          'accountStateUntilMillis': stateUntilTime.millisecondsSinceEpoch,
        });

        final json = originalReceipt.toJson();
        final deserializedReceipt = Receipt.fromJson(json);

        expect(deserializedReceipt.purchaseToken, originalReceipt.purchaseToken);
        expect(deserializedReceipt.productId, originalReceipt.productId);
        expect(deserializedReceipt.purchaseState, originalReceipt.purchaseState);
        expect(deserializedReceipt.purchaseTime, originalReceipt.purchaseTime);
        expect(deserializedReceipt.acknowledged, originalReceipt.acknowledged);
        expect(deserializedReceipt.source, originalReceipt.source);
        expect(deserializedReceipt.expiryTime, originalReceipt.expiryTime);
        expect(deserializedReceipt.autoRenewing, originalReceipt.autoRenewing);
        expect(deserializedReceipt.accountState, originalReceipt.accountState);
        expect(deserializedReceipt.accountStateUntil, originalReceipt.accountStateUntil);
      });

      test('should serialize and deserialize receipt with null optional fields', () {
        final originalReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_minimal',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          // No optional fields
        });

        final json = originalReceipt.toJson();
        final deserializedReceipt = Receipt.fromJson(json);

        expect(deserializedReceipt.purchaseToken, originalReceipt.purchaseToken);
        expect(deserializedReceipt.expiryTime, null);
        expect(deserializedReceipt.autoRenewing, null);
        expect(deserializedReceipt.accountState, null);
        expect(deserializedReceipt.accountStateUntil, null);
      });

      test('should handle partial optional fields in JSON', () {
        final partialReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_partial',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': false,
          // accountState and accountStateUntil omitted
        });

        final json = partialReceipt.toJson();
        final deserializedReceipt = Receipt.fromJson(json);

        expect(deserializedReceipt.expiryTime, expiryTime);
        expect(deserializedReceipt.autoRenewing, false);
        expect(deserializedReceipt.accountState, null);
        expect(deserializedReceipt.accountStateUntil, null);
      });

      test('should include optional fields in JSON output', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_json_check',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isPaused': true,
          'accountStateUntilMillis': stateUntilTime.millisecondsSinceEpoch,
        });

        final json = receipt.toJson();

        expect(json, containsPair('expiryTime', expiryTime.toIso8601String()));
        expect(json, containsPair('autoRenewing', true));
        expect(json, containsPair('accountState', 'PAUSED'));
        expect(json, containsPair('accountStateUntil', stateUntilTime.toIso8601String()));
      });

      test('should handle null fields gracefully in JSON', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_nulls',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
        });

        final json = receipt.toJson();

        expect(json, containsPair('expiryTime', null));
        expect(json, containsPair('autoRenewing', null));
        expect(json, containsPair('accountState', null));
        expect(json, containsPair('accountStateUntil', null));
      });
    });

    group('Malformed Input Tolerance', () {
      test('should handle malformed expiryTimeMillis gracefully', () {
        final malformedInputs = [
          'invalid_number',
          -1,
          'null',
          true,
          {},
          [],
        ];

        for (final malformedInput in malformedInputs) {
          final receipt = Receipt.fromEvent({
            'purchaseToken': 'token_malformed_expiry',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': baseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
            'expiryTimeMillis': malformedInput,
          });

          expect(receipt.expiryTime, null, reason: 'Should handle malformed expiryTimeMillis: $malformedInput');
        }
      });

      test('should handle malformed autoRenewing gracefully', () {
        final malformedInputs = [
          'true',
          1,
          0,
          'yes',
          {},
          [],
        ];

        for (final malformedInput in malformedInputs) {
          final receipt = Receipt.fromEvent({
            'purchaseToken': 'token_malformed_autorenew',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': baseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
            'autoRenewing': malformedInput,
          });

          expect(receipt.autoRenewing, null, reason: 'Should handle malformed autoRenewing: $malformedInput');
        }
      });

      test('should handle malformed account state fields gracefully', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_malformed_states',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'isPaused': 'not_boolean',
          'accountHold': 123,
          'isInGracePeriod': {},
        });

        // Should default to null or ACTIVE when parsing fails
        expect(receipt.accountState, 'ACTIVE'); // Default for purchased state
      });

      test('should handle malformed accountStateUntilMillis gracefully', () {
        final malformedInputs = [
          'invalid_timestamp',
          -1000,
          true,
          {},
        ];

        for (final malformedInput in malformedInputs) {
          final receipt = Receipt.fromEvent({
            'purchaseToken': 'token_malformed_state_until',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': baseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
            'accountStateUntilMillis': malformedInput,
          });

          expect(receipt.accountStateUntil, null, reason: 'Should handle malformed accountStateUntilMillis: $malformedInput');
        }
      });
    });

    group('Edge Case Values', () {
      test('should handle zero timestamps correctly', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_zero_timestamps',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': 0,
          'accountStateUntilMillis': 0,
        });

        expect(receipt.expiryTime, null); // Zero should be treated as null/invalid
        expect(receipt.accountStateUntil, null);
      });

      test('should handle very large timestamps', () {
        final maxSafeTimestamp = 8640000000000000; // Max safe JS timestamp
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_large_timestamps',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': maxSafeTimestamp,
          'accountStateUntilMillis': maxSafeTimestamp,
        });

        expect(receipt.expiryTime, isNotNull);
        expect(receipt.accountStateUntil, isNotNull);
        expect(receipt.expiryTime!.millisecondsSinceEpoch, maxSafeTimestamp);
      });

      test('should handle string timestamps', () {
        final stringTimestamp = expiryTime.millisecondsSinceEpoch.toString();
        
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_string_timestamps',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': stringTimestamp,
          'accountStateUntilMillis': stringTimestamp,
        });

        expect(receipt.expiryTime, expiryTime);
        expect(receipt.accountStateUntil, expiryTime);
      });

      test('should handle Boolean values correctly', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_booleans',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'autoRenewing': false,
        });

        expect(receipt.autoRenewing, false);

        final trueReceipt = Receipt.fromEvent({
          'purchaseToken': 'token_booleans_true',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'autoRenewing': true,
        });

        expect(trueReceipt.autoRenewing, true);
      });
    });

    group('Account State Parsing', () {
      test('should parse various grace period indicators', () {
        final graceVariants = [
          {'isInGracePeriod': true},
          {'inGracePeriod': true},
          {'accountState': 'IN_GRACE'},
          {'accountState': 'in_grace'},
        ];

        for (final variant in graceVariants) {
          final receipt = Receipt.fromEvent({
            'purchaseToken': 'token_grace_variant',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': baseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
            ...variant,
          });

          expect(receipt.accountState, 'IN_GRACE', reason: 'Should parse grace variant: $variant');
        }
      });

      test('should parse various hold state indicators', () {
        final holdVariants = [
          {'accountHold': true},
          {'isOnHold': true},
          {'accountState': 'ON_HOLD'},
          {'accountState': 'on_hold'},
        ];

        for (final variant in holdVariants) {
          final receipt = Receipt.fromEvent({
            'purchaseToken': 'token_hold_variant',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': baseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
            ...variant,
          });

          expect(receipt.accountState, 'ON_HOLD', reason: 'Should parse hold variant: $variant');
        }
      });

      test('should parse paused state indicators', () {
        final pausedVariants = [
          {'isPaused': true},
          {'accountState': 'PAUSED'},
          {'accountState': 'paused'},
        ];

        for (final variant in pausedVariants) {
          final receipt = Receipt.fromEvent({
            'purchaseToken': 'token_paused_variant',
            'productId': 'mindtrainer_pro_monthly',
            'purchaseState': 'purchased',
            'purchaseTime': baseTime.millisecondsSinceEpoch,
            'acknowledged': true,
            'source': 'play_billing',
            ...variant,
          });

          expect(receipt.accountState, 'PAUSED', reason: 'Should parse paused variant: $variant');
        }
      });

      test('should respect state priority PAUSED > ON_HOLD > IN_GRACE', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_priority_test',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'isPaused': true,
          'accountHold': true,
          'isInGracePeriod': true,
        });

        expect(receipt.accountState, 'PAUSED'); // Highest priority
      });

      test('should respect ON_HOLD > IN_GRACE priority', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_hold_grace_priority',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'accountHold': true,
          'isInGracePeriod': true,
        });

        expect(receipt.accountState, 'ON_HOLD');
      });

      test('should default to ACTIVE for valid purchase state', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_default_active',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
        });

        expect(receipt.accountState, 'ACTIVE');
      });
    });

    group('Equality and Hashing', () {
      test('should consider optional fields in equality comparison', () {
        final baseData = {
          'purchaseToken': 'token_equality',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
        };

        final receipt1 = Receipt.fromEvent({
          ...baseData,
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
        });

        final receipt2 = Receipt.fromEvent({
          ...baseData,
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
        });

        final receipt3 = Receipt.fromEvent({
          ...baseData,
          'expiryTimeMillis': expiryTime.add(const Duration(days: 1)).millisecondsSinceEpoch,
        });

        final receipt4 = Receipt.fromEvent(baseData); // No expiry time

        expect(receipt1, equals(receipt2));
        expect(receipt1, isNot(equals(receipt3)));
        expect(receipt1, isNot(equals(receipt4)));
        expect(receipt1.hashCode, equals(receipt2.hashCode));
        expect(receipt1.hashCode, isNot(equals(receipt3.hashCode)));
      });

      test('should include all optional fields in hash calculation', () {
        final receipt1 = Receipt.fromEvent({
          'purchaseToken': 'token_hash',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
        });

        final receipt2 = Receipt.fromEvent({
          'purchaseToken': 'token_hash',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'autoRenewing': true,
        });

        expect(receipt1.hashCode, isNot(equals(receipt2.hashCode)));
      });
    });

    group('copyWith Functionality', () {
      test('should copy with updated optional fields', () {
        final original = Receipt.fromEvent({
          'purchaseToken': 'token_copy',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': true,
        });

        final newExpiry = expiryTime.add(const Duration(days: 30));
        final copied = original.copyWith(
          expiryTime: newExpiry,
          autoRenewing: false,
          accountState: 'PAUSED',
        );

        expect(copied.purchaseToken, original.purchaseToken);
        expect(copied.expiryTime, newExpiry);
        expect(copied.autoRenewing, false);
        expect(copied.accountState, 'PAUSED');
      });

      test('should preserve original optional fields when not overridden', () {
        final original = Receipt.fromEvent({
          'purchaseToken': 'token_preserve',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isPaused': true,
          'accountStateUntilMillis': stateUntilTime.millisecondsSinceEpoch,
        });

        final copied = original.copyWith(purchaseState: 'cancelled');

        expect(copied.purchaseState, 'cancelled');
        expect(copied.expiryTime, original.expiryTime);
        expect(copied.autoRenewing, original.autoRenewing);
        expect(copied.accountState, original.accountState);
        expect(copied.accountStateUntil, original.accountStateUntil);
      });
    });

    group('toString Representation', () {
      test('should include optional fields in string representation', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_tostring_long_token_for_display_testing',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
          'expiryTimeMillis': expiryTime.millisecondsSinceEpoch,
          'autoRenewing': true,
          'isPaused': true,
        });

        final str = receipt.toString();

        expect(str, contains('token_tos...'));
        expect(str, contains('expiry: ${expiryTime.toIso8601String()}'));
        expect(str, contains('autoRenew: true'));
        expect(str, contains('state: PAUSED'));
      });

      test('should not include null optional fields in string representation', () {
        final receipt = Receipt.fromEvent({
          'purchaseToken': 'token_minimal_string',
          'productId': 'mindtrainer_pro_monthly',
          'purchaseState': 'purchased',
          'purchaseTime': baseTime.millisecondsSinceEpoch,
          'acknowledged': true,
          'source': 'play_billing',
        });

        final str = receipt.toString();

        expect(str, isNot(contains('expiry:')));
        expect(str, isNot(contains('autoRenew:')));
        expect(str, isNot(contains('state:')));
      });
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/foundation/timeouts.dart';
import 'package:mindtrainer/foundation/retry.dart';

void main() {
  group('Timeouts', () {
    test('provides reasonable billing timeout constants', () {
      expect(Timeouts.billingConnect, equals(const Duration(seconds: 6)));
      expect(Timeouts.purchaseFlowGuard, equals(const Duration(seconds: 15)));
      expect(Timeouts.restoreGuard, equals(const Duration(seconds: 8)));
    });

    test('provides UI responsiveness constants', () {
      expect(Timeouts.spinnerDebounce, equals(const Duration(milliseconds: 250)));
      expect(Timeouts.uiTransition, equals(const Duration(milliseconds: 300)));
    });

    test('provides backoff constants', () {
      expect(Timeouts.backoffMin, equals(const Duration(milliseconds: 200)));
      expect(Timeouts.backoffMax, equals(const Duration(seconds: 5)));
    });

    test('provides pending state management constants', () {
      expect(Timeouts.pendingGracePeriod, equals(const Duration(minutes: 10)));
      expect(Timeouts.statusCheckInterval, equals(const Duration(seconds: 30)));
    });
  });

  group('RetryPolicy', () {
    test('has sensible defaults', () {
      const policy = RetryPolicy();
      
      expect(policy.minBackoff, equals(Timeouts.backoffMin));
      expect(policy.maxBackoff, equals(Timeouts.backoffMax));
      expect(policy.maxAttempts, equals(5));
    });

    test('calculates exponential backoff correctly', () {
      const policy = RetryPolicy(
        minBackoff: Duration(milliseconds: 100),
        maxBackoff: Duration(seconds: 2),
        maxAttempts: 4,
      );

      // 0-based attempt numbers
      expect(policy.backoffForAttempt(0), equals(const Duration(milliseconds: 100))); // 100 * 2^0 = 100
      expect(policy.backoffForAttempt(1), equals(const Duration(milliseconds: 200))); // 100 * 2^1 = 200
      expect(policy.backoffForAttempt(2), equals(const Duration(milliseconds: 400))); // 100 * 2^2 = 400
      expect(policy.backoffForAttempt(3), equals(const Duration(milliseconds: 800))); // 100 * 2^3 = 800
    });

    test('caps backoff at maximum value', () {
      const policy = RetryPolicy(
        minBackoff: Duration(milliseconds: 500),
        maxBackoff: Duration(seconds: 1), // 1000ms
        maxAttempts: 5,
      );

      expect(policy.backoffForAttempt(0), equals(const Duration(milliseconds: 500))); // 500 * 2^0 = 500
      expect(policy.backoffForAttempt(1), equals(const Duration(seconds: 1))); // 500 * 2^1 = 1000 (capped)
      expect(policy.backoffForAttempt(2), equals(const Duration(seconds: 1))); // Would be 2000, but capped at 1000
      expect(policy.backoffForAttempt(3), equals(const Duration(seconds: 1))); // Would be 4000, but capped at 1000
    });

    test('handles edge cases gracefully', () {
      const policy = RetryPolicy();
      
      expect(policy.backoffForAttempt(-1), equals(Duration.zero));
      expect(policy.backoffForAttempt(-10), equals(Duration.zero));
    });

    test('provides all backoff delays as a list', () {
      const policy = RetryPolicy(
        minBackoff: Duration(milliseconds: 100),
        maxBackoff: Duration(seconds: 2),
        maxAttempts: 4,
      );

      final delays = policy.allBackoffDelays;
      expect(delays.length, equals(3)); // maxAttempts - 1 (initial attempt doesn't have delay)
      expect(delays[0], equals(const Duration(milliseconds: 100)));
      expect(delays[1], equals(const Duration(milliseconds: 200)));
      expect(delays[2], equals(const Duration(milliseconds: 400)));
    });

    test('calculates total max time correctly', () {
      const policy = RetryPolicy(
        minBackoff: Duration(milliseconds: 100),
        maxBackoff: Duration(seconds: 2),
        maxAttempts: 4,
      );

      // Total of: 100ms + 200ms + 400ms = 700ms
      expect(policy.totalMaxTime, equals(const Duration(milliseconds: 700)));
    });

    test('has predefined billing policy', () {
      const policy = RetryPolicy.billing;
      
      expect(policy.minBackoff, equals(Timeouts.backoffMin));
      expect(policy.maxBackoff, equals(Timeouts.backoffMax));
      expect(policy.maxAttempts, equals(3));
    });

    test('has predefined critical policy', () {
      const policy = RetryPolicy.critical;
      
      expect(policy.minBackoff, equals(const Duration(milliseconds: 100)));
      expect(policy.maxBackoff, equals(const Duration(seconds: 2)));
      expect(policy.maxAttempts, equals(6));
    });

    test('implements equality correctly', () {
      const policy1 = RetryPolicy(maxAttempts: 3);
      const policy2 = RetryPolicy(maxAttempts: 3);
      const policy3 = RetryPolicy(maxAttempts: 4);

      expect(policy1, equals(policy2));
      expect(policy1.hashCode, equals(policy2.hashCode));
      expect(policy1, isNot(equals(policy3)));
    });

    test('has readable string representation', () {
      const policy = RetryPolicy(
        minBackoff: Duration(milliseconds: 100),
        maxBackoff: Duration(seconds: 2),
        maxAttempts: 3,
      );

      expect(policy.toString(), contains('RetryPolicy'));
      expect(policy.toString(), contains('100'));
      expect(policy.toString(), contains('2'));
      expect(policy.toString(), contains('3'));
    });
  });
}
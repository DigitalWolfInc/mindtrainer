# Timing and Timeout Configuration

This document describes the centralized timeout system implemented in MindTrainer to replace hardcoded 10-second timers with configurable, testable timeout behavior.

## Overview

The timeout system is designed to:
- Eliminate hardcoded magic numbers (like `Duration(seconds: 10)`)
- Provide centralized timeout configuration
- Enable deterministic testing with fake clocks
- Implement exponential backoff for retry operations
- Provide user-friendly timeout messaging

## Architecture

### Dart Side

#### Core Components

1. **`lib/foundation/timeouts.dart`** - Centralized timeout constants
2. **`lib/foundation/retry.dart`** - Retry policy with exponential backoff
3. **`lib/foundation/clock.dart`** - Clock abstraction for testable time
4. **`lib/payments/api.dart`** - Enhanced API with timeout guards

#### Key Constants

```dart
class Timeouts {
  // Billing Operations
  static const Duration billingConnect = Duration(seconds: 6);
  static const Duration purchaseFlowGuard = Duration(seconds: 15);
  static const Duration restoreGuard = Duration(seconds: 8);
  
  // UI Responsiveness
  static const Duration spinnerDebounce = Duration(milliseconds: 250);
  static const Duration uiTransition = Duration(milliseconds: 300);
  
  // Backoff and Retry
  static const Duration backoffMin = Duration(milliseconds: 200);
  static const Duration backoffMax = Duration(seconds: 5);
  
  // Pending State Management
  static const Duration pendingGracePeriod = Duration(minutes: 10);
  static const Duration statusCheckInterval = Duration(seconds: 30);
}
```

### Android Side

#### Constants in BillingHandler.kt

```kotlin
private const val BACKOFF_MIN_MS = 200L
private const val BACKOFF_MAX_MS = 5000L
private const val CONNECT_TIMEOUT_MS = 6000L
private const val RESTORE_TIMEOUT_MS = 8000L
private const val PURCHASE_FLOW_GUARD_MS = 15000L
```

## Backoff Behavior

### Exponential Backoff Formula

Both Dart and Android use capped exponential backoff:

```
delay = min(minBackoff * 2^attemptNumber, maxBackoff)
```

### Examples

For `RetryPolicy(minBackoff: 200ms, maxBackoff: 5000ms)`:

| Attempt | Delay     |
|---------|-----------|
| 0       | 200ms     |
| 1       | 400ms     |
| 2       | 800ms     |
| 3       | 1600ms    |
| 4       | 3200ms    |
| 5       | 5000ms (capped) |

## Testing with Deterministic Clock

### Using FakeClock in Tests

```dart
void main() {
  group('Timeout behavior', () {
    late FakeClock fakeClock;

    setUp(() {
      fakeClock = FakeClock(DateTime(2024, 1, 1));
      PurchaseAPI.setClock(fakeClock);
    });

    test('triggers timeout after configured duration', () async {
      var timeoutTriggered = false;
      
      final result = await PurchaseAPI.startPurchaseWithGuard(
        'product_id',
        timeout: const Duration(seconds: 5),
        onTimeout: () => timeoutTriggered = true,
      );
      
      // Advance fake clock past timeout
      fakeClock.advance(const Duration(seconds: 6));
      
      expect(timeoutTriggered, isTrue);
    });
  });
}
```

### Benefits of Fake Clock

1. **Deterministic**: Tests run in predictable, repeatable time
2. **Fast**: No actual waiting for timeouts
3. **Precise**: Can test exact timing scenarios
4. **Reliable**: No flakiness from system timing variations

## Timeout Handling Patterns

### Purchase Flow Guard

```dart
final result = await PurchaseAPI.startPurchaseWithGuard(
  productId,
  timeout: Timeouts.purchaseFlowGuard,
  onTimeout: () {
    // Show user-friendly timeout message
    // Don't fail the actual purchase
  },
);
```

### Connection Retry with Backoff

```dart
Future<BillingResult> connectWithRetry() async {
  const policy = RetryPolicy.billing;
  
  for (int attempt = 0; attempt < policy.maxAttempts; attempt++) {
    final result = await _attemptConnection();
    
    if (result.isSuccess) {
      return result;
    }
    
    if (attempt < policy.maxAttempts - 1) {
      final delay = policy.backoffForAttempt(attempt);
      await _clock.delay(delay);
    }
  }
  
  return BillingResult.error('CONNECTION_FAILED', 'Max attempts exceeded');
}
```

## User Experience

### Timeout Messages

The system provides user-friendly timeout messages via i18n:

- `purchaseWaiting`: "Waiting for Google Play..."
- `purchasePending`: "Purchase pending confirmation"
- `purchaseTimeoutMessage`: "Still waiting on Google Play... You can close this message."
- `purchaseCheckStatus`: "Check status"
- `restoreTimeout`: "Restore timed out. Try again."

### UI Flow

1. **Immediate Response**: Purchase starts immediately
2. **Timeout Guard**: After timeout, show friendly message
3. **No Failure**: Timeout doesn't fail the actual purchase
4. **Status Check**: User can manually trigger restore/status check
5. **Graceful Degradation**: User can dismiss timeout message

## Migration Guide

### Replacing Hardcoded Timers

**Before:**
```dart
await Future.delayed(Duration(seconds: 10));
```

**After:**
```dart
await _clock.delay(Timeouts.billingConnect);
```

**Before:**
```dart
Timer(Duration(seconds: 10), callback);
```

**After:**
```dart
_clock.timer(Timeouts.purchaseFlowGuard, callback);
```

### Testing Migration

**Before:**
```dart
test('waits 10 seconds', () async {
  await Future.delayed(Duration(seconds: 10));
  // Test took 10 actual seconds
});
```

**After:**
```dart
test('waits configured timeout', () async {
  final clock = FakeClock(DateTime.now());
  MyService.setClock(clock);
  
  final future = myService.operationWithTimeout();
  clock.advance(Timeouts.operationTimeout);
  
  await future;
  // Test completed instantly
});
```

## Configuration

### Development vs Production

- **Development**: May use shorter timeouts for faster iteration
- **Production**: Use full timeouts for real-world network conditions
- **Testing**: Use FakeClock for deterministic behavior

### Platform Parity

Android and Dart timeout constants are kept in sync:

| Purpose | Dart | Android |
|---------|------|---------|
| Connection | `Timeouts.billingConnect` | `CONNECT_TIMEOUT_MS` |
| Restore | `Timeouts.restoreGuard` | `RESTORE_TIMEOUT_MS` |
| Purchase Guard | `Timeouts.purchaseFlowGuard` | `PURCHASE_FLOW_GUARD_MS` |
| Backoff Min | `Timeouts.backoffMin` | `BACKOFF_MIN_MS` |
| Backoff Max | `Timeouts.backoffMax` | `BACKOFF_MAX_MS` |

## Troubleshooting

### Common Issues

1. **Timers not triggering**: Ensure FakeClock.advance() is called in tests
2. **Tests timing out**: Check that clock is properly injected
3. **Inconsistent behavior**: Verify platform timeout constants match
4. **Memory leaks**: Always dispose PurchaseFlowResult to clean up timers

### Debug Information

```dart
// Get pending timer count in tests
print('Pending timers: ${fakeClock.pendingTimersCount}');

// Check timeout configuration
print('Purchase timeout: ${Timeouts.purchaseFlowGuard}');
print('Backoff range: ${Timeouts.backoffMin} - ${Timeouts.backoffMax}');
```
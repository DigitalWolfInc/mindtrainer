/// Retry policy system for billing operations and network-like operations
/// 
/// Provides deterministic, testable retry behavior with exponential backoff
/// and configurable limits.

import 'timeouts.dart';

/// Function signature for operations that can be retried
typedef RetryFn<T> = Future<T> Function();

/// Configurable retry policy with exponential backoff
class RetryPolicy {
  /// Minimum delay between retry attempts
  final Duration minBackoff;
  
  /// Maximum delay between retry attempts
  final Duration maxBackoff;
  
  /// Maximum number of attempts (including initial attempt)
  final int maxAttempts;
  
  /// Create a retry policy with the specified parameters
  const RetryPolicy({
    this.minBackoff = Timeouts.backoffMin,
    this.maxBackoff = Timeouts.backoffMax,
    this.maxAttempts = 5,
  });
  
  /// Default billing retry policy
  static const billing = RetryPolicy(
    minBackoff: Timeouts.backoffMin,
    maxBackoff: Timeouts.backoffMax,
    maxAttempts: 3,
  );
  
  /// Aggressive retry policy for critical operations
  static const critical = RetryPolicy(
    minBackoff: Duration(milliseconds: 100),
    maxBackoff: Duration(seconds: 2),
    maxAttempts: 6,
  );
  
  /// Calculate backoff delay for a given attempt number
  /// 
  /// Uses capped exponential backoff: delay = min(minBackoff * 2^attempt, maxBackoff)
  /// Attempt numbers are 0-based (0 = first retry, 1 = second retry, etc.)
  Duration backoffForAttempt(int attemptNumber) {
    if (attemptNumber < 0) return Duration.zero;
    
    // Calculate exponential backoff: minBackoff * 2^attemptNumber  
    final exponentialMs = minBackoff.inMilliseconds * (1 << attemptNumber);
    
    // Cap at maxBackoff
    final cappedMs = exponentialMs > maxBackoff.inMilliseconds 
        ? maxBackoff.inMilliseconds 
        : exponentialMs;
    
    return Duration(milliseconds: cappedMs);
  }
  
  /// Get all backoff delays for this policy as a list
  List<Duration> get allBackoffDelays {
    return List.generate(maxAttempts - 1, (i) => backoffForAttempt(i));
  }
  
  /// Total time if all attempts are exhausted
  Duration get totalMaxTime {
    return allBackoffDelays.fold(Duration.zero, (sum, delay) => sum + delay);
  }
  
  @override
  String toString() => 'RetryPolicy(min: $minBackoff, max: $maxBackoff, attempts: $maxAttempts)';
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetryPolicy &&
          minBackoff == other.minBackoff &&
          maxBackoff == other.maxBackoff &&
          maxAttempts == other.maxAttempts;
  
  @override
  int get hashCode => Object.hash(minBackoff, maxBackoff, maxAttempts);
}
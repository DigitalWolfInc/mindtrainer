import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/foundation/clock.dart';

void main() {
  group('SystemClock', () {
    test('provides current time', () {
      const clock = SystemClock();
      final now = DateTime.now();
      final clockTime = clock.now();
      
      // Should be within a reasonable time window
      expect(clockTime.difference(now).abs(), lessThan(const Duration(seconds: 1)));
    });
    
    test('creates working delays', () async {
      const clock = SystemClock();
      final start = DateTime.now();
      
      await clock.delay(const Duration(milliseconds: 100));
      
      final elapsed = DateTime.now().difference(start);
      expect(elapsed, greaterThanOrEqualTo(const Duration(milliseconds: 90)));
      expect(elapsed, lessThan(const Duration(milliseconds: 200)));
    });
    
    test('creates working timers', () async {
      const clock = SystemClock();
      var timerFired = false;
      
      final timer = clock.timer(const Duration(milliseconds: 100), () {
        timerFired = true;
      });
      
      expect(timer.isActive, isTrue);
      
      await Future.delayed(const Duration(milliseconds: 150));
      
      expect(timerFired, isTrue);
      expect(timer.isActive, isFalse);
    });
  });
  
  group('FakeClock', () {
    late FakeClock clock;
    
    setUp(() {
      clock = FakeClock(DateTime(2024, 1, 1, 12, 0, 0));
    });
    
    test('provides controllable time', () {
      expect(clock.now(), equals(DateTime(2024, 1, 1, 12, 0, 0)));
      
      clock.advance(const Duration(hours: 2));
      expect(clock.now(), equals(DateTime(2024, 1, 1, 14, 0, 0)));
    });
    
    test('handles delays deterministically', () async {
      final delayFuture = clock.delay(const Duration(minutes: 5));
      
      // Should not complete immediately
      var completed = false;
      delayFuture.then((_) => completed = true);
      
      await Future.delayed(Duration.zero); // Let microtasks run
      expect(completed, isFalse);
      
      // Advance to just before delay expires
      clock.advance(const Duration(minutes: 4, seconds: 59));
      await Future.delayed(Duration.zero);
      expect(completed, isFalse);
      
      // Advance past delay expiration
      clock.advance(const Duration(seconds: 2));
      await Future.delayed(Duration.zero);
      expect(completed, isTrue);
    });
    
    test('handles timers deterministically', () async {
      var timerCount = 0;
      
      final timer = clock.timer(const Duration(seconds: 30), () {
        timerCount++;
      });
      
      expect(timer.isActive, isTrue);
      expect(timerCount, equals(0));
      
      // Advance past timer expiration
      clock.advance(const Duration(seconds: 35));
      
      expect(timerCount, equals(1));
      expect(timer.isActive, isFalse);
    });
    
    test('handles multiple overlapping timers', () async {
      var timer1Fired = false;
      var timer2Fired = false;
      
      clock.timer(const Duration(seconds: 10), () {
        timer1Fired = true;
      });
      
      clock.timer(const Duration(seconds: 5), () {
        timer2Fired = true;
      });
      
      expect(clock.pendingTimersCount, equals(2));
      
      // Advance to trigger second timer only
      clock.advance(const Duration(seconds: 7));
      
      expect(timer2Fired, isTrue);
      expect(timer1Fired, isFalse);
      expect(clock.pendingTimersCount, equals(1));
      
      // Advance to trigger first timer
      clock.advance(const Duration(seconds: 5));
      
      expect(timer1Fired, isTrue);
      expect(clock.pendingTimersCount, equals(0));
    });
    
    test('cancels timers correctly', () async {
      var timerFired = false;
      
      final timer = clock.timer(const Duration(seconds: 10), () {
        timerFired = true;
      });
      
      expect(timer.isActive, isTrue);
      expect(clock.pendingTimersCount, equals(1));
      
      timer.cancel();
      
      expect(timer.isActive, isFalse);
      
      // Timer should not fire even after advancing past expiration
      clock.advance(const Duration(seconds: 15));
      
      expect(timerFired, isFalse);
    });
    
    test('maintains proper timer ordering', () async {
      final firingOrder = <int>[];
      
      clock.timer(const Duration(seconds: 3), () => firingOrder.add(3));
      clock.timer(const Duration(seconds: 1), () => firingOrder.add(1));
      clock.timer(const Duration(seconds: 2), () => firingOrder.add(2));
      
      clock.advance(const Duration(seconds: 5));
      
      expect(firingOrder, equals([1, 2, 3]));
    });
  });
}
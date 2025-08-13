import 'package:flutter_test/flutter_test.dart';

import '../../lib/settings/diagnostics.dart';

void main() {
  group('Diagnostics Ring Buffer Tests', () {
    setUp(() {
      Diag.clear();
    });

    group('Basic Logging', () {
      test('should add entries with timestamp and tag', () {
        Diag.d('Test', 'First message');
        Diag.d('Other', 'Second message');

        final snapshot = Diag.snapshot();
        expect(snapshot.length, 2);
        
        expect(snapshot[0], contains('[Test] First message'));
        expect(snapshot[1], contains('[Other] Second message'));
        
        // Should include timestamp format HH:MM:SS
        expect(RegExp(r'\d{2}:\d{2}:\d{2} \[Test\] First message').hasMatch(snapshot[0]), true);
        expect(RegExp(r'\d{2}:\d{2}:\d{2} \[Other\] Second message').hasMatch(snapshot[1]), true);
      });

      test('should handle empty tag and message', () {
        Diag.d('', '');
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 1);
        expect(snapshot[0], contains('[] '));
      });

      test('should handle special characters in tag and message', () {
        Diag.d('Tag[{}]', 'Message with "quotes" and symbols: !@#$%');
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 1);
        expect(snapshot[0], contains('[Tag[{}]] Message with "quotes" and symbols: !@#$%'));
      });
    });

    group('Ring Buffer Capacity', () {
      test('should maintain fixed capacity of 200 lines', () {
        // Add exactly 200 entries
        for (int i = 0; i < 200; i++) {
          Diag.d('Test', 'Message $i');
        }
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 200);
        expect(snapshot[0], contains('Message 0'));
        expect(snapshot[199], contains('Message 199'));
      });

      test('should evict oldest entries when capacity exceeded', () {
        // Add 250 entries (50 over capacity)
        for (int i = 0; i < 250; i++) {
          Diag.d('Test', 'Message $i');
        }
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 200);
        
        // Should start from message 50 (first 50 evicted)
        expect(snapshot[0], contains('Message 50'));
        expect(snapshot[199], contains('Message 249'));
        
        // Verify first 50 messages were evicted
        final allContent = snapshot.join('\n');
        expect(allContent.contains('Message 0'), false);
        expect(allContent.contains('Message 49'), false);
        expect(allContent.contains('Message 50'), true);
      });

      test('should handle continuous additions beyond capacity', () {
        // Add 300 entries
        for (int i = 0; i < 300; i++) {
          Diag.d('Test', 'Entry $i');
        }
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 200);
        
        // Should contain entries 100-299
        expect(snapshot[0], contains('Entry 100'));
        expect(snapshot[199], contains('Entry 299'));
        
        // Add 50 more entries
        for (int i = 300; i < 350; i++) {
          Diag.d('Test', 'Entry $i');
        }
        
        final newSnapshot = Diag.snapshot();
        expect(newSnapshot.length, 200);
        
        // Should now contain entries 150-349
        expect(newSnapshot[0], contains('Entry 150'));
        expect(newSnapshot[199], contains('Entry 349'));
      });
    });

    group('Order Preservation', () {
      test('should maintain chronological order in snapshot', () {
        final timestamps = <String>[];
        
        // Add entries with slight delays to ensure different timestamps
        for (int i = 0; i < 5; i++) {
          Diag.d('Test', 'Message $i');
          // Small delay to potentially get different timestamps
          // (though within same second, order should still be preserved)
        }
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 5);
        
        // Verify messages appear in order they were added
        for (int i = 0; i < 5; i++) {
          expect(snapshot[i], contains('Message $i'));
        }
      });

      test('should maintain order when wrapping around buffer', () {
        // Fill buffer to capacity
        for (int i = 0; i < 200; i++) {
          Diag.d('Fill', 'Entry $i');
        }
        
        // Add a few more to cause wrap-around
        Diag.d('Wrap', 'First wrap entry');
        Diag.d('Wrap', 'Second wrap entry');
        Diag.d('Wrap', 'Third wrap entry');
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 200);
        
        // Last three entries should be the wrap entries
        expect(snapshot[197], contains('First wrap entry'));
        expect(snapshot[198], contains('Second wrap entry'));
        expect(snapshot[199], contains('Third wrap entry'));
        
        // First entry should be 'Entry 3' (entries 0,1,2 evicted by wrap entries)
        expect(snapshot[0], contains('Entry 3'));
      });
    });

    group('Snapshot Behavior', () {
      test('should return independent snapshot copies', () {
        Diag.d('Test', 'Initial entry');
        
        final snapshot1 = Diag.snapshot();
        expect(snapshot1.length, 1);
        
        // Add more entries
        Diag.d('Test', 'Second entry');
        Diag.d('Test', 'Third entry');
        
        final snapshot2 = Diag.snapshot();
        expect(snapshot2.length, 3);
        
        // First snapshot should be unchanged
        expect(snapshot1.length, 1);
        expect(snapshot1[0], contains('Initial entry'));
        
        // Second snapshot should have all entries
        expect(snapshot2[0], contains('Initial entry'));
        expect(snapshot2[1], contains('Second entry'));
        expect(snapshot2[2], contains('Third entry'));
      });

      test('should return empty list when no entries', () {
        final snapshot = Diag.snapshot();
        expect(snapshot, isEmpty);
      });
    });

    group('Clear Functionality', () {
      test('should clear all entries', () {
        // Add some entries
        for (int i = 0; i < 10; i++) {
          Diag.d('Test', 'Entry $i');
        }
        
        expect(Diag.snapshot().length, 10);
        
        Diag.clear();
        
        final snapshot = Diag.snapshot();
        expect(snapshot, isEmpty);
      });

      test('should allow new entries after clear', () {
        // Add entries, clear, add more
        Diag.d('Before', 'Entry 1');
        Diag.d('Before', 'Entry 2');
        
        Diag.clear();
        
        Diag.d('After', 'New entry 1');
        Diag.d('After', 'New entry 2');
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 2);
        expect(snapshot[0], contains('New entry 1'));
        expect(snapshot[1], contains('New entry 2'));
        
        // Should not contain old entries
        final allContent = snapshot.join('\n');
        expect(allContent.contains('Entry 1'), false);
        expect(allContent.contains('Entry 2'), false);
      });
    });

    group('Concurrent Access', () {
      test('should handle concurrent logging safely', () {
        final futures = <Future>[];
        
        // Simulate concurrent logging
        for (int i = 0; i < 50; i++) {
          futures.add(Future.microtask(() => Diag.d('Concurrent', 'Entry $i')));
        }
        
        return Future.wait(futures).then((_) {
          final snapshot = Diag.snapshot();
          expect(snapshot.length, 50);
          
          // All entries should be present (order may vary due to concurrency)
          final allContent = snapshot.join('\n');
          for (int i = 0; i < 50; i++) {
            expect(allContent.contains('Entry $i'), true);
          }
        });
      });

      test('should handle concurrent snapshot calls', () {
        // Add some entries
        for (int i = 0; i < 10; i++) {
          Diag.d('Test', 'Entry $i');
        }
        
        // Call snapshot multiple times concurrently
        final futures = List.generate(10, (_) => Future.microtask(() => Diag.snapshot()));
        
        return Future.wait(futures).then((snapshots) {
          // All snapshots should be identical
          final first = snapshots[0];
          expect(first.length, 10);
          
          for (final snapshot in snapshots) {
            expect(snapshot.length, first.length);
            for (int i = 0; i < snapshot.length; i++) {
              expect(snapshot[i], first[i]);
            }
          }
        });
      });
    });

    group('Memory Efficiency', () {
      test('should not grow beyond capacity with heavy usage', () {
        // Simulate heavy logging (way beyond capacity)
        for (int i = 0; i < 1000; i++) {
          Diag.d('Heavy', 'Entry $i');
        }
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 200); // Should still be at capacity
        
        // Should contain most recent 200 entries
        expect(snapshot[0], contains('Entry 800'));
        expect(snapshot[199], contains('Entry 999'));
      });
    });

    group('Timestamp Format', () {
      test('should use consistent HH:MM:SS format', () {
        Diag.d('Time', 'Test message');
        
        final snapshot = Diag.snapshot();
        expect(snapshot.length, 1);
        
        // Should match pattern: HH:MM:SS [Tag] Message
        final timestampPattern = RegExp(r'^\d{2}:\d{2}:\d{2} \[Time\] Test message$');
        expect(timestampPattern.hasMatch(snapshot[0]), true);
      });

      test('should pad single digit time components', () {
        // This test depends on system time, but checks format consistency
        Diag.d('Pad', 'Padding test');
        
        final snapshot = Diag.snapshot();
        final entry = snapshot[0];
        
        // Extract timestamp part (first 8 characters: HH:MM:SS)
        final timestamp = entry.substring(0, 8);
        expect(timestamp.length, 8);
        expect(timestamp[2], ':');
        expect(timestamp[5], ':');
        
        // Each component should be 2 digits
        final parts = timestamp.split(':');
        expect(parts.length, 3);
        expect(parts[0].length, 2); // hours
        expect(parts[1].length, 2); // minutes  
        expect(parts[2].length, 2); // seconds
      });
    });
  });
}
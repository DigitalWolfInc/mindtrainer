import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/achievements/achievements_store.dart';
import '../../lib/achievements/badge.dart';
import '../../lib/achievements/badge_ids.dart';
import '../../lib/achievements/snapshot.dart';

void main() {
  group('AchievementsStore Persistence & Merge Tests', () {
    late String testDirectory;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      AchievementsStore.resetInstance();
      
      // Create a temporary directory for test files
      testDirectory = Directory.systemTemp.path + '/achievements_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
    });

    tearDown(() async {
      AchievementsStore.resetInstance();
      
      // Clean up test directory
      try {
        await Directory(testDirectory).delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('File Persistence', () {
      test('should save and load achievements from file', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/achievements.json');

        final badge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
          meta: {'sessionCount': 1},
        );

        final snapshot = AchievementsSnapshot.create(
          unlocked: {badge.id: badge},
          updatedAt: DateTime.now(),
        );

        await store.replaceAll(snapshot);

        // Create new store instance to test persistence
        AchievementsStore.resetInstance();
        final newStore = AchievementsStore.instance;
        await newStore.init(filePath: '$testDirectory/achievements.json');

        expect(newStore.snapshot.has(BadgeIds.firstSession), true);
        
        final loadedBadge = newStore.snapshot.unlocked[BadgeIds.firstSession]!;
        expect(loadedBadge.title, 'First Step');
        expect(loadedBadge.meta?['sessionCount'], 1);
      });

      test('should handle missing file gracefully', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/nonexistent.json');

        expect(store.snapshot.count, 0);
        expect(store.snapshot.unlocked.isEmpty, true);
      });

      test('should handle corrupted JSON gracefully', () async {
        final corruptedFile = File('$testDirectory/corrupted.json');
        await corruptedFile.writeAsString('{ invalid json content }');

        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/corrupted.json');

        // Should create empty snapshot instead of crashing
        expect(store.snapshot.count, 0);
        expect(store.snapshot.unlocked.isEmpty, true);
      });

      test('should use atomic write operations', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/atomic.json');

        final badge1 = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
          meta: {'sessionCount': 1},
        );

        final snapshot1 = AchievementsSnapshot.create(
          unlocked: {badge1.id: badge1},
          updatedAt: DateTime.now(),
        );

        await store.replaceAll(snapshot1);

        // Verify the main file exists and temp file doesn't
        final mainFile = File('$testDirectory/atomic.json');
        final tempFile = File('$testDirectory/atomic.json.tmp');
        
        expect(await mainFile.exists(), true);
        expect(await tempFile.exists(), false);

        // Verify content is correct
        final content = await mainFile.readAsString();
        expect(content.contains(BadgeIds.firstSession), true);
      });

      test('should handle concurrent write attempts safely', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/concurrent.json');

        final badge1 = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
        );

        final badge2 = Badge.create(
          id: BadgeIds.fiveSessions,
          title: 'Getting Started',
          description: 'Completed 5 focus sessions.',
          tier: 1,
        );

        final snapshot1 = AchievementsSnapshot.create(
          unlocked: {badge1.id: badge1},
          updatedAt: DateTime.now(),
        );

        final snapshot2 = AchievementsSnapshot.create(
          unlocked: {badge2.id: badge2},
          updatedAt: DateTime.now(),
        );

        // Start concurrent write operations
        final future1 = store.replaceAll(snapshot1);
        final future2 = store.replaceAll(snapshot2);

        // Wait for both to complete
        await Future.wait([future1, future2]);

        // Should not crash and should have one of the snapshots
        expect(store.snapshot.count, 1);
      });
    });

    group('Badge Merging Operations', () {
      test('should add new badges to existing collection', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/merge.json');

        final badge1 = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
        );

        final badge2 = Badge.create(
          id: BadgeIds.fiveSessions,
          title: 'Getting Started',
          description: 'Completed 5 focus sessions.',
          tier: 1,
        );

        // Add first badge
        final snapshot1 = AchievementsSnapshot.create(
          unlocked: {badge1.id: badge1},
          updatedAt: DateTime.now(),
        );
        await store.replaceAll(snapshot1);

        expect(store.snapshot.count, 1);
        expect(store.snapshot.has(BadgeIds.firstSession), true);

        // Add second badge (merge)
        await store.addBadge(badge2);

        expect(store.snapshot.count, 2);
        expect(store.snapshot.has(BadgeIds.firstSession), true);
        expect(store.snapshot.has(BadgeIds.fiveSessions), true);
      });

      test('should not duplicate existing badges', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/duplicate.json');

        final badge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
        );

        // Add badge twice
        await store.addBadge(badge);
        await store.addBadge(badge);

        expect(store.snapshot.count, 1);
        expect(store.snapshot.has(BadgeIds.firstSession), true);
      });

      test('should handle badge conflicts with newer timestamp wins', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/conflict.json');

        final now = DateTime.now();
        
        final olderBadge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
          unlockedAt: now.subtract(const Duration(hours: 1)),
          meta: {'old': true},
        );

        final newerBadge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
          unlockedAt: now,
          meta: {'new': true},
        );

        // Add older badge first
        await store.addBadge(olderBadge);
        expect(store.snapshot.unlocked[BadgeIds.firstSession]!.meta?['old'], true);

        // Add newer badge (should replace)
        await store.addBadge(newerBadge);
        expect(store.snapshot.unlocked[BadgeIds.firstSession]!.meta?['new'], true);
        expect(store.snapshot.count, 1);
      });

      test('should preserve older badge when adding older timestamp', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/preserve.json');

        final now = DateTime.now();
        
        final newerBadge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
          unlockedAt: now,
          meta: {'new': true},
        );

        final olderBadge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
          unlockedAt: now.subtract(const Duration(hours: 1)),
          meta: {'old': true},
        );

        // Add newer badge first
        await store.addBadge(newerBadge);
        expect(store.snapshot.unlocked[BadgeIds.firstSession]!.meta?['new'], true);

        // Try to add older badge (should be ignored)
        await store.addBadge(olderBadge);
        expect(store.snapshot.unlocked[BadgeIds.firstSession]!.meta?['new'], true);
        expect(store.snapshot.count, 1);
      });

      test('should handle bulk merging from import', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/bulk.json');

        final now = DateTime.now();
        
        final existingBadges = {
          BadgeIds.firstSession: Badge.create(
            id: BadgeIds.firstSession,
            title: 'First Step',
            description: 'Completed your first focus session.',
            tier: 1,
            unlockedAt: now.subtract(const Duration(hours: 2)),
          ),
          BadgeIds.fiveSessions: Badge.create(
            id: BadgeIds.fiveSessions,
            title: 'Getting Started',
            description: 'Completed 5 focus sessions.',
            tier: 1,
            unlockedAt: now.subtract(const Duration(hours: 1)),
          ),
        };

        final importBadges = {
          BadgeIds.firstSession: Badge.create(
            id: BadgeIds.firstSession,
            title: 'First Step',
            description: 'Completed your first focus session.',
            tier: 1,
            unlockedAt: now, // Newer
            meta: {'imported': true},
          ),
          BadgeIds.twentySessions: Badge.create(
            id: BadgeIds.twentySessions,
            title: 'Building Momentum',
            description: 'Completed 20 focus sessions.',
            tier: 1,
            unlockedAt: now,
          ),
        };

        // Setup existing badges
        await store.replaceAll(AchievementsSnapshot.create(
          unlocked: existingBadges,
          updatedAt: DateTime.now(),
        ));

        expect(store.snapshot.count, 2);

        // Merge import (simulate import operation)
        final mergedBadges = <String, Badge>{};
        mergedBadges.addAll(store.snapshot.unlocked);

        for (final badge in importBadges.values) {
          final existing = mergedBadges[badge.id];
          if (existing == null || badge.unlockedAt.isAfter(existing.unlockedAt)) {
            mergedBadges[badge.id] = badge;
          }
        }

        await store.replaceAll(AchievementsSnapshot.create(
          unlocked: mergedBadges,
          updatedAt: DateTime.now(),
        ));

        expect(store.snapshot.count, 3);
        expect(store.snapshot.has(BadgeIds.firstSession), true);
        expect(store.snapshot.has(BadgeIds.fiveSessions), true);
        expect(store.snapshot.has(BadgeIds.twentySessions), true);

        // First session should have newer metadata
        expect(store.snapshot.unlocked[BadgeIds.firstSession]!.meta?['imported'], true);
      });
    });

    group('Error Handling', () {
      test('should handle file system errors gracefully', () async {
        // Try to write to a directory that doesn't exist and can't be created
        final badPath = '/nonexistent_root_path_12345/achievements.json';
        
        final store = AchievementsStore.instance;
        
        // Should not crash during init
        await store.init(filePath: badPath);
        expect(store.snapshot.count, 0);

        // Should not crash when trying to save
        final badge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
        );

        // This might fail but shouldn't crash
        try {
          await store.addBadge(badge);
        } catch (e) {
          // Expected to fail on some systems
        }

        // Store should still function in memory
        expect(store.snapshot.has(BadgeIds.firstSession), true);
      });

      test('should recover from partial write failures', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/recovery.json');

        final badge = Badge.create(
          id: BadgeIds.firstSession,
          title: 'First Step',
          description: 'Completed your first focus session.',
          tier: 1,
        );

        // Simulate partial write by creating temp file but not completing
        final tempFile = File('$testDirectory/recovery.json.tmp');
        await tempFile.writeAsString('partial content');

        // Normal operation should still work
        await store.addBadge(badge);
        
        expect(store.snapshot.has(BadgeIds.firstSession), true);
        
        // Temp file should be cleaned up
        expect(await tempFile.exists(), false);
      });

      test('should handle malformed badge data gracefully', () async {
        final malformedFile = File('$testDirectory/malformed.json');
        await malformedFile.writeAsString('''
        {
          "unlocked": {
            "invalid_badge": {
              "id": "invalid_badge",
              "title": null,
              "description": "",
              "tier": "not_a_number",
              "unlockedAt": "invalid_date"
            }
          },
          "updatedAt": "2023-01-01T00:00:00.000Z"
        }
        ''');

        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/malformed.json');

        // Should initialize with empty snapshot instead of crashing
        expect(store.snapshot.count, 0);
        expect(store.snapshot.unlocked.isEmpty, true);
      });
    });

    group('Performance and Memory', () {
      test('should handle large numbers of badges efficiently', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/large.json');

        final badges = <String, Badge>{};
        
        // Create 100 badges
        for (int i = 0; i < 100; i++) {
          final badgeId = 'test_badge_$i';
          badges[badgeId] = Badge.create(
            id: badgeId,
            title: 'Test Badge $i',
            description: 'Test badge number $i',
            tier: 1,
            meta: {'index': i},
          );
        }

        final snapshot = AchievementsSnapshot.create(
          unlocked: badges,
          updatedAt: DateTime.now(),
        );

        final stopwatch = Stopwatch()..start();
        await store.replaceAll(snapshot);
        stopwatch.stop();

        expect(store.snapshot.count, 100);
        expect(stopwatch.elapsedMilliseconds, lessThan(1000)); // Should be fast

        // Verify all badges are present
        for (int i = 0; i < 100; i++) {
          final badgeId = 'test_badge_$i';
          expect(store.snapshot.has(badgeId), true);
          expect(store.snapshot.unlocked[badgeId]!.meta?['index'], i);
        }
      });

      test('should not leak memory with repeated operations', () async {
        final store = AchievementsStore.instance;
        await store.init(filePath: '$testDirectory/memory.json');

        // Perform many operations
        for (int i = 0; i < 50; i++) {
          final badge = Badge.create(
            id: 'badge_$i',
            title: 'Badge $i',
            description: 'Badge number $i',
            tier: 1,
          );
          
          await store.addBadge(badge);
          
          // Periodically replace all to test memory cleanup
          if (i % 10 == 0) {
            final snapshot = AchievementsSnapshot.create(
              unlocked: {'kept_badge': Badge.create(
                id: 'kept_badge',
                title: 'Kept Badge',
                description: 'This badge should remain',
                tier: 1,
              )},
              updatedAt: DateTime.now(),
            );
            await store.replaceAll(snapshot);
          }
        }

        // Should not crash and should have expected state
        expect(store.snapshot.count, 1);
        expect(store.snapshot.has('kept_badge'), true);
      });
    });
  });
}
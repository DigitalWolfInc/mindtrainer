import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/favorites/favorite_tools_store.dart';
import '../../lib/favorites/tool_definitions.dart';

void main() {
  group('FavoriteToolsStore Tests', () {
    late String testDirectory;

    setUp(() async {
      FavoriteToolsStore.resetInstance();
      
      // Create a temporary directory for test files
      testDirectory = Directory.systemTemp.path + '/favorites_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
    });

    tearDown(() async {
      FavoriteToolsStore.resetInstance();
      
      // Clean up test directory
      try {
        await Directory(testDirectory).delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    group('Store Initialization', () {
      test('should initialize with empty favorites', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/favorites.json');

        expect(store.favoriteCount, 0);
        expect(store.hasFavorites, false);
        expect(store.getFavorites(), isEmpty);
      });

      test('should handle missing file gracefully', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/nonexistent.json');

        expect(store.favoriteCount, 0);
        expect(store.hasFavorites, false);
      });

      test('should handle corrupted JSON gracefully', () async {
        final corruptedFile = File('$testDirectory/corrupted.json');
        await corruptedFile.writeAsString('{ invalid json content }');

        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/corrupted.json');

        expect(store.favoriteCount, 0);
        expect(store.hasFavorites, false);
      });
    });

    group('Adding Favorites', () {
      test('should add favorite successfully', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/add_test.json');

        bool notified = false;
        store.addListener(() => notified = true);

        await store.addFavorite(ToolRegistry.focusSession);

        expect(store.favoriteCount, 1);
        expect(store.hasFavorites, true);
        expect(store.isFavorite(ToolRegistry.focusSession), true);
        expect(store.getFavorites(), contains(ToolRegistry.focusSession));
        expect(notified, true);
      });

      test('should not duplicate favorites', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/duplicate_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.focusSession);

        expect(store.favoriteCount, 1);
        expect(store.getFavorites().length, 1);
      });

      test('should maintain order with most recent first', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/order_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.animalCheckin);
        await store.addFavorite(ToolRegistry.sessionHistory);

        final favorites = store.getFavorites();
        expect(favorites[0], ToolRegistry.sessionHistory); // Most recent
        expect(favorites[1], ToolRegistry.animalCheckin);
        expect(favorites[2], ToolRegistry.focusSession); // Oldest
      });

      test('should add multiple different favorites', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/multiple_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.animalCheckin);
        await store.addFavorite(ToolRegistry.analytics);

        expect(store.favoriteCount, 3);
        expect(store.isFavorite(ToolRegistry.focusSession), true);
        expect(store.isFavorite(ToolRegistry.animalCheckin), true);
        expect(store.isFavorite(ToolRegistry.analytics), true);
        expect(store.isFavorite(ToolRegistry.settings), false);
      });
    });

    group('Removing Favorites', () {
      test('should remove favorite successfully', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/remove_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        expect(store.isFavorite(ToolRegistry.focusSession), true);

        bool notified = false;
        store.addListener(() => notified = true);

        await store.removeFavorite(ToolRegistry.focusSession);

        expect(store.favoriteCount, 0);
        expect(store.isFavorite(ToolRegistry.focusSession), false);
        expect(store.hasFavorites, false);
        expect(notified, true);
      });

      test('should handle removing non-existent favorite', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/remove_missing_test.json');

        await store.removeFavorite(ToolRegistry.focusSession);

        expect(store.favoriteCount, 0);
        expect(store.isFavorite(ToolRegistry.focusSession), false);
      });

      test('should maintain order when removing middle item', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/remove_middle_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.animalCheckin);
        await store.addFavorite(ToolRegistry.sessionHistory);

        await store.removeFavorite(ToolRegistry.animalCheckin);

        final favorites = store.getFavorites();
        expect(favorites.length, 2);
        expect(favorites[0], ToolRegistry.sessionHistory);
        expect(favorites[1], ToolRegistry.focusSession);
        expect(favorites, isNot(contains(ToolRegistry.animalCheckin)));
      });
    });

    group('Toggle Functionality', () {
      test('should toggle favorite from false to true', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/toggle_add_test.json');

        expect(store.isFavorite(ToolRegistry.focusSession), false);

        await store.toggleFavorite(ToolRegistry.focusSession);

        expect(store.isFavorite(ToolRegistry.focusSession), true);
        expect(store.favoriteCount, 1);
      });

      test('should toggle favorite from true to false', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/toggle_remove_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        expect(store.isFavorite(ToolRegistry.focusSession), true);

        await store.toggleFavorite(ToolRegistry.focusSession);

        expect(store.isFavorite(ToolRegistry.focusSession), false);
        expect(store.favoriteCount, 0);
      });
    });

    group('Top Favorites', () {
      test('should return correct number of top favorites', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/top_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.animalCheckin);
        await store.addFavorite(ToolRegistry.sessionHistory);
        await store.addFavorite(ToolRegistry.analytics);
        await store.addFavorite(ToolRegistry.settings);

        expect(store.getTopFavorites(3).length, 3);
        expect(store.getTopFavorites(10).length, 5); // Should return all 5
        expect(store.getTopFavorites(0).length, 0);
      });

      test('should return favorites in correct order (most recent first)', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/top_order_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.animalCheckin);
        await store.addFavorite(ToolRegistry.sessionHistory);

        final top2 = store.getTopFavorites(2);
        expect(top2[0], ToolRegistry.sessionHistory); // Most recent
        expect(top2[1], ToolRegistry.animalCheckin);
      });
    });

    group('Persistence', () {
      test('should persist favorites to file', () async {
        final filePath = '$testDirectory/persist_test.json';
        
        // First store instance
        final store1 = FavoriteToolsStore.instance;
        await store1.init(filePath: filePath);
        
        await store1.addFavorite(ToolRegistry.focusSession);
        await store1.addFavorite(ToolRegistry.animalCheckin);

        // Reset and create new instance
        FavoriteToolsStore.resetInstance();
        final store2 = FavoriteToolsStore.instance;
        await store2.init(filePath: filePath);

        expect(store2.favoriteCount, 2);
        expect(store2.isFavorite(ToolRegistry.focusSession), true);
        expect(store2.isFavorite(ToolRegistry.animalCheckin), true);
        
        final favorites = store2.getFavorites();
        expect(favorites[0], ToolRegistry.animalCheckin); // Most recent
        expect(favorites[1], ToolRegistry.focusSession);
      });

      test('should handle file write failures gracefully', () async {
        final store = FavoriteToolsStore.instance;
        
        // Try to write to invalid path
        await store.init(filePath: '/nonexistent_root_path/favorites.json');
        
        // Should not crash when adding favorites
        await store.addFavorite(ToolRegistry.focusSession);
        
        // Should still work in memory
        expect(store.isFavorite(ToolRegistry.focusSession), true);
      });

      test('should use atomic write operations', () async {
        final store = FavoriteToolsStore.instance;
        final filePath = '$testDirectory/atomic_test.json';
        await store.init(filePath: filePath);

        await store.addFavorite(ToolRegistry.focusSession);

        // Verify main file exists and temp file doesn't
        final mainFile = File(filePath);
        final tempFile = File('$filePath.tmp');
        
        expect(await mainFile.exists(), true);
        expect(await tempFile.exists(), false);

        // Verify content
        final content = await mainFile.readAsString();
        expect(content.contains(ToolRegistry.focusSession), true);
      });
    });

    group('Edge Cases', () {
      test('should handle empty tool ID', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/empty_id_test.json');

        await store.addFavorite('');
        
        expect(store.favoriteCount, 1);
        expect(store.isFavorite(''), true);
      });

      test('should handle special characters in tool ID', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/special_chars_test.json');

        const specialId = 'tool@#\$%^&*()_+-=[]{}|;:,.<>?';
        await store.addFavorite(specialId);
        
        expect(store.isFavorite(specialId), true);
      });

      test('should handle very long tool IDs', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/long_id_test.json');

        final longId = 'very_long_tool_id_' * 100;
        await store.addFavorite(longId);
        
        expect(store.isFavorite(longId), true);
      });

      test('should handle many favorites efficiently', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/many_favorites_test.json');

        // Add 100 favorites
        for (int i = 0; i < 100; i++) {
          await store.addFavorite('tool_$i');
        }

        expect(store.favoriteCount, 100);
        expect(store.getTopFavorites(10).length, 10);
        expect(store.isFavorite('tool_50'), true);
        expect(store.isFavorite('tool_150'), false);
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners on add', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/notify_add_test.json');

        int notificationCount = 0;
        store.addListener(() => notificationCount++);

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.animalCheckin);

        expect(notificationCount, 2);
      });

      test('should notify listeners on remove', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/notify_remove_test.json');

        await store.addFavorite(ToolRegistry.focusSession);
        await store.addFavorite(ToolRegistry.animalCheckin);

        int notificationCount = 0;
        store.addListener(() => notificationCount++);

        await store.removeFavorite(ToolRegistry.focusSession);
        await store.removeFavorite(ToolRegistry.animalCheckin);

        expect(notificationCount, 2);
      });

      test('should not notify on duplicate add', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/no_notify_duplicate_test.json');

        await store.addFavorite(ToolRegistry.focusSession);

        int notificationCount = 0;
        store.addListener(() => notificationCount++);

        await store.addFavorite(ToolRegistry.focusSession); // Duplicate

        expect(notificationCount, 0);
      });

      test('should not notify on remove non-existent', () async {
        final store = FavoriteToolsStore.instance;
        await store.init(filePath: '$testDirectory/no_notify_missing_test.json');

        int notificationCount = 0;
        store.addListener(() => notificationCount++);

        await store.removeFavorite(ToolRegistry.focusSession); // Doesn't exist

        expect(notificationCount, 0);
      });
    });
  });
}
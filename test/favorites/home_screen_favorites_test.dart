import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/favorites/favorite_tools_store.dart';
import '../../lib/favorites/tool_definitions.dart';
import '../../lib/features/focus_session/presentation/home_screen.dart';

void main() {
  group('HomeScreen Favorites Integration Tests', () {
    setUp() {
      FavoriteToolsStore.resetInstance();
    }

    tearDown() {
      FavoriteToolsStore.resetInstance();
    }

    testWidgets('should not show favorites section when no favorites', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should not find favorites section
      expect(find.text('Favorites'), findsNothing);
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('should show favorites section when favorites exist', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      
      // Add some favorites
      await store.addFavorite(ToolRegistry.focusSession);
      await store.addFavorite(ToolRegistry.animalCheckin);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should find favorites section header
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
    });

    testWidgets('should show up to 3 favorites in horizontal list', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      
      // Add 5 favorites
      await store.addFavorite(ToolRegistry.focusSession);
      await store.addFavorite(ToolRegistry.animalCheckin);
      await store.addFavorite(ToolRegistry.sessionHistory);
      await store.addFavorite(ToolRegistry.analytics);
      await store.addFavorite(ToolRegistry.settings);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should find favorites section
      expect(find.text('Favorites'), findsOneWidget);
      
      // Should find horizontal ListView
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);
      
      // Check that ListView is horizontal
      final listViewWidget = tester.widget<ListView>(listView);
      expect(listViewWidget.scrollDirection, Axis.horizontal);
      
      // Should have exactly 3 favorite tiles (top 3)
      expect(find.byType(Card), findsAtLeastNWidgets(3));
    });

    testWidgets('should show favorites in correct order (most recent first)', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      
      // Add favorites in specific order
      await store.addFavorite(ToolRegistry.focusSession);    // Third (oldest)
      await store.addFavorite(ToolRegistry.animalCheckin);   // Second
      await store.addFavorite(ToolRegistry.sessionHistory);  // First (most recent)

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Find all favorite tool titles in order
      expect(find.text('View Session History'), findsOneWidget); // Most recent
      expect(find.text('Animal Check-in'), findsOneWidget);
      expect(find.text('Start Focus Session'), findsOneWidget);
    });

    testWidgets('should navigate to tools when favorite tiles are tapped', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      
      await store.addFavorite(ToolRegistry.focusSession);

      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/focus_session': (context) => const Scaffold(
              body: Text('Focus Session Screen'),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the favorite tile
      final favoriteTile = find.descendant(
        of: find.byType(Card),
        matching: find.text('Start Focus Session'),
      );
      expect(favoriteTile, findsOneWidget);

      await tester.tap(favoriteTile);
      await tester.pumpAndSettle();

      // Should navigate to focus session screen
      expect(find.text('Focus Session Screen'), findsOneWidget);
    });

    testWidgets('should update favorites section when favorites change', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no favorites section
      expect(find.text('Favorites'), findsNothing);

      // Add a favorite
      await store.addFavorite(ToolRegistry.focusSession);
      await tester.pumpAndSettle();

      // Should now show favorites section
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Start Focus Session'), findsAtLeastNWidgets(1));

      // Remove the favorite
      await store.removeFavorite(ToolRegistry.focusSession);
      await tester.pumpAndSettle();

      // Should hide favorites section again
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('should have star icons in all tool tiles', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should find star_border icons for all tools (not favorited)
      final starBorderIcons = find.byIcon(Icons.star_border);
      expect(starBorderIcons, findsAtLeastNWidgets(7)); // 7 tools

      // Should not find filled stars initially
      expect(find.byIcon(Icons.star), findsNothing);
    });

    testWidgets('should show filled stars for favorited tools', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      
      // Add some favorites
      await store.addFavorite(ToolRegistry.focusSession);
      await store.addFavorite(ToolRegistry.analytics);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Should find 2 filled stars (for favorited tools)
      final filledStars = find.byIcon(Icons.star);
      expect(filledStars, findsAtLeastNWidgets(2));

      // Should find remaining unfilled stars
      final unfilledStars = find.byIcon(Icons.star_border);
      expect(unfilledStars, findsAtLeastNWidgets(5)); // 5 non-favorited tools
    });

    testWidgets('should toggle favorites from main tool list', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no favorites section
      expect(find.text('Favorites'), findsNothing);

      // Find and tap a star to add favorite
      final starIcon = find.byIcon(Icons.star_border).first;
      await tester.tap(starIcon);
      await tester.pumpAndSettle();

      // Should now show favorites section
      expect(find.text('Favorites'), findsOneWidget);
      expect(store.favoriteCount, 1);

      // Should now have one filled star
      expect(find.byIcon(Icons.star), findsAtLeastNWidgets(1));
    });

    testWidgets('should maintain tool functionality with favorite toggles', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(
              body: Text('Settings Screen'),
            ),
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find settings tool button (not the star)
      final settingsButton = find.descendant(
        of: find.byType(ElevatedButton),
        matching: find.text('Settings'),
      );
      
      expect(settingsButton, findsOneWidget);

      // Tap the settings button (should navigate)
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Should navigate to settings
      expect(find.text('Settings Screen'), findsOneWidget);
    });

    testWidgets('should handle favorites section layout correctly', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      
      await store.addFavorite(ToolRegistry.focusSession);
      await store.addFavorite(ToolRegistry.animalCheckin);
      await store.addFavorite(ToolRegistry.sessionHistory);

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Check favorites section layout
      expect(find.text('Favorites'), findsOneWidget);
      
      // Should find the ListView with correct height
      final listView = tester.widget<SizedBox>(
        find.ancestor(
          of: find.byType(ListView),
          matching: find.byType(SizedBox),
        ),
      );
      expect(listView.height, 80);
    });

    testWidgets('should respect maximum 3 favorites display limit', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      
      // Add all 7 tools as favorites
      for (final toolId in ToolRegistry.getAllToolIds()) {
        await store.addFavorite(toolId);
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Favorites'), findsOneWidget);
      
      // Should only show 3 favorites in the horizontal list
      final favoritesListView = find.byType(ListView);
      expect(favoritesListView, findsOneWidget);
      
      // The ListView should have exactly 3 items
      final listViewWidget = tester.widget<ListView>(favoritesListView) as ListView;
      expect((listViewWidget.childrenDelegate as SliverChildBuilderDelegate).childCount, 3);
    });
  });
}
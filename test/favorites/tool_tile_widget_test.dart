import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/favorites/favorite_tools_store.dart';
import '../../lib/favorites/tool_definitions.dart';
import '../../lib/favorites/tool_tile.dart';

void main() {
  group('ToolTile Widget Tests', () {
    setUp(() {
      FavoriteToolsStore.resetInstance();
    });

    tearDown(() {
      FavoriteToolsStore.resetInstance();
    });

    testWidgets('should display tool with star toggle', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      bool toolTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () => toolTapped = true,
            ),
          ),
        ),
      );

      // Should show the tool button
      expect(find.text('Start Focus Session'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      
      // Should show unfilled star (not favorite)
      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(find.byIcon(Icons.star), findsNothing);

      // Test tool button tap
      await tester.tap(find.text('Start Focus Session'));
      await tester.pump();
      expect(toolTapped, true);
    });

    testWidgets('should show filled star when tool is favorite', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();
      await store.addFavorite(ToolRegistry.focusSession);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show filled star (is favorite)
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('should toggle favorite when star is tapped', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      // Initially not favorite
      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(store.isFavorite(ToolRegistry.focusSession), false);

      // Tap the star to add to favorites
      await tester.tap(find.byIcon(Icons.star_border));
      await tester.pumpAndSettle();

      // Should now be favorite
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(store.isFavorite(ToolRegistry.focusSession), true);

      // Tap again to remove from favorites
      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      // Should no longer be favorite
      expect(find.byIcon(Icons.star_border), findsOneWidget);
      expect(store.isFavorite(ToolRegistry.focusSession), false);
    });

    testWidgets('should show trailing widget when provided', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.analytics,
              onTap: () {},
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('should apply custom style when provided', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.analytics,
              onTap: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[100],
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ),
      );

      // Find the ElevatedButton and check its style
      final buttonWidget = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(buttonWidget.style?.backgroundColor?.resolve({}), Colors.amber[100]);
      expect(buttonWidget.style?.foregroundColor?.resolve({}), Colors.black);
    });

    testWidgets('should handle unknown tool ID gracefully', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: 'unknown_tool_id',
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show empty widget for unknown tool
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('should update when favorites change externally', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      // Initially not favorite
      expect(find.byIcon(Icons.star_border), findsOneWidget);

      // Add to favorites externally
      await store.addFavorite(ToolRegistry.focusSession);
      await tester.pumpAndSettle();

      // Should update to show filled star
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('should show correct tooltip text', (WidgetTester tester) async {
      final store = FavoriteToolsStore.instance;
      await store.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check tooltip for non-favorite
      final starButton = find.byIcon(Icons.star_border);
      await tester.longPress(starButton);
      await tester.pumpAndSettle();
      expect(find.text('Add to favorites'), findsOneWidget);

      // Dismiss tooltip
      await tester.tap(find.byType(Scaffold));
      await tester.pumpAndSettle();

      // Add to favorites
      await tester.tap(starButton);
      await tester.pumpAndSettle();

      // Check tooltip for favorite
      final filledStarButton = find.byIcon(Icons.star);
      await tester.longPress(filledStarButton);
      await tester.pumpAndSettle();
      expect(find.text('Remove from favorites'), findsOneWidget);
    });
  });

  group('FavoriteToolTile Widget Tests', () {
    setUp(() {
      FavoriteToolsStore.resetInstance();
    });

    tearDown(() {
      FavoriteToolsStore.resetInstance();
    });

    testWidgets('should display compact tool tile', (WidgetTester tester) async {
      bool toolTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () => toolTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Start Focus Session'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(toolTapped, true);
    });

    testWidgets('should handle text overflow correctly', (WidgetTester tester) async {
      // Use a tool with a longer name
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80, // Very narrow to force overflow
              child: FavoriteToolTile(
                toolId: ToolRegistry.sessionHistory,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('View Session History'));
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should handle unknown tool ID gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteToolTile(
              toolId: 'unknown_tool',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should have correct fixed width', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      final containerWidget = tester.widget<Container>(
        find.descendant(
          of: find.byType(Card),
          matching: find.byType(Container),
        ),
      );

      expect(containerWidget.constraints?.minWidth, 120);
    });

    testWidgets('should use theme colors correctly', (WidgetTester tester) async {
      const primaryColor = Colors.red;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: primaryColor),
          ),
          home: Scaffold(
            body: FavoriteToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.psychology));
      expect(iconWidget.color, primaryColor);
    });
  });
}
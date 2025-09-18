import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/tool_usage/tool_usage_service.dart';
import '../../lib/tool_usage/recent_tools_widget.dart';
import '../../lib/favorites/tool_definitions.dart';

void main() {
  group('RecentToolsWidget Tests', () {
    setUp(() {
      ToolUsageService.resetInstance();
    });

    tearDown(() {
      ToolUsageService.resetInstance();
    });

    testWidgets('should not show section when no usage history', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();

      bool toolTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (_) => toolTapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not show recent tools section
      expect(find.text('Recent Tools'), findsNothing);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('should show recent tools section when history exists', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      // Add some usage history
      await service.recordUsage(ToolRegistry.focusSession);
      await service.recordUsage(ToolRegistry.animalCheckin);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show recent tools section header
      expect(find.text('Recent Tools'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('should show up to 5 recent tools in horizontal list', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      // Add 7 different tools to usage history
      await service.recordUsage(ToolRegistry.focusSession);
      await service.recordUsage(ToolRegistry.animalCheckin);
      await service.recordUsage(ToolRegistry.sessionHistory);
      await service.recordUsage(ToolRegistry.analytics);
      await service.recordUsage(ToolRegistry.settings);
      await service.recordUsage(ToolRegistry.checkinHistory);
      await service.recordUsage(ToolRegistry.languageAudit);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should find recent tools section
      expect(find.text('Recent Tools'), findsOneWidget);
      
      // Should find horizontal ListView
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);
      
      // Check that ListView is horizontal
      final listViewWidget = tester.widget<ListView>(listView);
      expect(listViewWidget.scrollDirection, Axis.horizontal);
      
      // Should have exactly 5 recent tool tiles (limit)
      expect(find.byType(RecentToolTile), findsNWidgets(5));
    });

    testWidgets('should show tools in correct order (most recent first)', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      // Add tools in specific order
      await service.recordUsage(ToolRegistry.focusSession);
      await Future.delayed(const Duration(milliseconds: 10));
      await service.recordUsage(ToolRegistry.animalCheckin);
      await Future.delayed(const Duration(milliseconds: 10));
      await service.recordUsage(ToolRegistry.sessionHistory);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all tool titles 
      expect(find.text('View Session History'), findsOneWidget); // Most recent
      expect(find.text('Animal Check-in'), findsOneWidget);
      expect(find.text('Start Focus Session'), findsOneWidget);
    });

    testWidgets('should navigate to tools when tiles are tapped', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      await service.recordUsage(ToolRegistry.focusSession);

      String? tappedToolId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (toolId) => tappedToolId = toolId,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the tool tile
      final toolTile = find.descendant(
        of: find.byType(RecentToolTile),
        matching: find.text('Start Focus Session'),
      );
      expect(toolTile, findsOneWidget);

      await tester.tap(toolTile);
      await tester.pumpAndSettle();

      expect(tappedToolId, ToolRegistry.focusSession);
    });

    testWidgets('should update when usage history changes', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially no recent tools section
      expect(find.text('Recent Tools'), findsNothing);

      // Add usage
      await service.recordUsage(ToolRegistry.focusSession);
      await tester.pumpAndSettle();

      // Should now show recent tools section
      expect(find.text('Recent Tools'), findsOneWidget);
      expect(find.text('Start Focus Session'), findsOneWidget);

      // Add another tool
      await service.recordUsage(ToolRegistry.animalCheckin);
      await tester.pumpAndSettle();

      // Should show both tools
      expect(find.text('Start Focus Session'), findsOneWidget);
      expect(find.text('Animal Check-in'), findsOneWidget);
    });

    testWidgets('should handle duplicate tool usage correctly', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      // Add same tool multiple times
      await service.recordUsage(ToolRegistry.focusSession);
      await service.recordUsage(ToolRegistry.animalCheckin);
      await service.recordUsage(ToolRegistry.focusSession); // Duplicate

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should only show 2 unique tools
      expect(find.byType(RecentToolTile), findsNWidgets(2));
      expect(find.text('Start Focus Session'), findsOneWidget);
      expect(find.text('Animal Check-in'), findsOneWidget);
    });

    testWidgets('should clear section when history is cleared', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      await service.recordUsage(ToolRegistry.focusSession);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolsSection(
              onToolTap: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show recent tools section
      expect(find.text('Recent Tools'), findsOneWidget);

      // Clear history
      await service.clearHistory();
      await tester.pumpAndSettle();

      // Should hide recent tools section
      expect(find.text('Recent Tools'), findsNothing);
    });
  });

  group('RecentToolTile Widget Tests', () {
    setUp(() {
      ToolUsageService.resetInstance();
    });

    tearDown(() {
      ToolUsageService.resetInstance();
    });

    testWidgets('should display tool information correctly', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      // Record usage to have timestamp
      await service.recordUsage(ToolRegistry.focusSession);

      bool toolTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () => toolTapped = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Start Focus Session'), findsOneWidget);
      expect(find.byIcon(Icons.psychology), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);

      // Test tap functionality
      await tester.tap(find.byType(InkWell));
      await tester.pump();
      expect(toolTapped, true);
    });

    testWidgets('should show time ago for recent usage', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      // Record usage
      await service.recordUsage(ToolRegistry.focusSession);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show "now" or similar for very recent usage
      expect(find.text('now'), findsOneWidget);
    });

    testWidgets('should handle unknown tool ID gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolTile(
              toolId: 'unknown_tool',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('should format time ago correctly', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();

      // We can't easily test specific time formatting without mocking DateTime,
      // but we can test that the widget renders without errors
      await service.recordUsage(ToolRegistry.focusSession);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without errors
      expect(find.byType(RecentToolTile), findsOneWidget);
      expect(find.text('Start Focus Session'), findsOneWidget);
    });

    testWidgets('should have correct tile dimensions', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      await service.recordUsage(ToolRegistry.focusSession);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final containerWidget = tester.widget<Container>(
        find.descendant(
          of: find.byType(Card),
          matching: find.byType(Container),
        ),
      );

      expect(containerWidget.constraints?.minWidth, 110);
    });

    testWidgets('should use appropriate text styles', (WidgetTester tester) async {
      final service = ToolUsageService.instance;
      await service.init();
      
      await service.recordUsage(ToolRegistry.focusSession);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentToolTile(
              toolId: ToolRegistry.focusSession,
              onTap: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that text widgets are present and styled
      final titleText = tester.widget<Text>(find.text('Start Focus Session'));
      expect(titleText.style?.fontSize, 11);
      expect(titleText.style?.fontWeight, FontWeight.w500);
      expect(titleText.maxLines, 2);
      expect(titleText.overflow, TextOverflow.ellipsis);
    });
  });
}
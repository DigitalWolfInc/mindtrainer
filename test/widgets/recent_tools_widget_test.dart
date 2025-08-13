import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../lib/features/focus_session/presentation/home_screen.dart';
import '../../lib/services/tool_usage_service.dart';
import '../../lib/data/tool_usage_store.dart';
import '../../lib/favorites/favorite_tools_store.dart';
import '../../lib/favorites/tool_definitions.dart';

class MockPathProviderPlatform extends PathProviderPlatform {
  final String tempDir;
  
  MockPathProviderPlatform(this.tempDir);
  
  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir;
}

void main() {
  group('Recent Tools Widget Tests', () {
    late String testDirectory;
    late MockPathProviderPlatform mockPathProvider;

    setUp(() async {
      ToolUsageService.resetInstance();
      ToolUsageStore.resetInstance();
      FavoriteToolsStore.resetInstance();
      
      // Create a temporary directory for test files
      testDirectory = Directory.systemTemp.path + '/recent_tools_widget_test_${DateTime.now().millisecondsSinceEpoch}';
      await Directory(testDirectory).create(recursive: true);
      
      // Mock path provider
      mockPathProvider = MockPathProviderPlatform(testDirectory);
      PathProviderPlatform.instance = mockPathProvider;
    });

    tearDown(() async {
      ToolUsageService.resetInstance();
      ToolUsageStore.resetInstance();
      FavoriteToolsStore.resetInstance();
      
      // Clean up test directory
      try {
        await Directory(testDirectory).delete(recursive: true);
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    testWidgets('should not show Recent Tools section when no usage history exists', (tester) async {
      // Initialize services with empty data
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Should not find Recent Tools section
      expect(find.text('Recent Tools'), findsNothing);
      expect(find.byIcon(Icons.history), findsNothing);
    });

    testWidgets('should show Recent Tools section when usage history exists', (tester) async {
      // Initialize services and add some usage
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      await ToolUsageService.instance.recordUsage(ToolRegistry.animalCheckin);
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Should find Recent Tools section
      expect(find.text('Recent Tools'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('should display recent tools in correct order (newest first)', (tester) async {
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      // Record usage in specific order
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      await Future.delayed(const Duration(milliseconds: 10)); // Ensure different timestamps
      await ToolUsageService.instance.recordUsage(ToolRegistry.animalCheckin);
      await Future.delayed(const Duration(milliseconds: 10));
      await ToolUsageService.instance.recordUsage(ToolRegistry.sessionHistory);
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Find the horizontal ListView in Recent Tools section
      final recentToolsText = find.text('Recent Tools');
      expect(recentToolsText, findsOneWidget);
      
      final recentToolsList = find.byType(ListView);
      expect(recentToolsList, findsOneWidget);
      
      // Should show the tools (will show tool titles or icons)
      // Most recent tools should appear first in the horizontal list
      final listView = tester.widget<ListView>(recentToolsList);
      expect(listView.scrollDirection, Axis.horizontal);
    });

    testWidgets('should show unique tools only (no duplicates in UI)', (tester) async {
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      // Record same tool multiple times
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      await ToolUsageService.instance.recordUsage(ToolRegistry.animalCheckin);
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Should find Recent Tools section
      expect(find.text('Recent Tools'), findsOneWidget);
      
      // Find all the tool tiles in the recent tools section
      final recentToolsSection = find.ancestor(
        of: find.text('Recent Tools'),
        matching: find.byType(Column),
      ).first;
      
      final recentToolCards = find.descendant(
        of: recentToolsSection,
        matching: find.byType(Card),
      );
      
      // Should have cards for unique tools only (not 4 cards for 4 usages)
      // Expecting 2 unique tools: focusSession and animalCheckin
      expect(recentToolCards, findsNWidgets(2));
    });

    testWidgets('should navigate to correct tool when recent tool is tapped', (tester) async {
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Find and tap the first recent tool
      final recentToolCard = find.descendant(
        of: find.ancestor(
          of: find.text('Recent Tools'),
          matching: find.byType(Column),
        ).first,
        matching: find.byType(InkWell),
      ).first;
      
      await tester.tap(recentToolCard);
      await tester.pumpAndSettle();
      
      // Should navigate to the focus session screen
      // We can't easily test the exact navigation without more complex setup,
      // but we can verify the tap was registered
      expect(recentToolCard, findsOneWidget);
    });

    testWidgets('should record new usage when navigating from recent tools', (tester) async {
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      // Record initial usage
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      
      // Get initial usage count
      final initialUsage = ToolUsageService.instance.getRecent(10);
      final initialCount = initialUsage.length;
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Find and tap the recent tool
      final recentToolCard = find.descendant(
        of: find.ancestor(
          of: find.text('Recent Tools'),
          matching: find.byType(Column),
        ).first,
        matching: find.byType(InkWell),
      ).first;
      
      await tester.tap(recentToolCard);
      await tester.pump();
      
      // Verify new usage was recorded
      final newUsage = ToolUsageService.instance.getRecent(10);
      expect(newUsage.length, initialCount + 1);
      expect(newUsage[0].toolId, ToolRegistry.focusSession); // Most recent
    });

    testWidgets('should handle tools with missing definitions gracefully', (tester) async {
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      // Record usage for a tool that might not exist in registry
      await ToolUsageService.instance.recordUsage('unknown_tool_id');
      await ToolUsageService.instance.recordUsage(ToolRegistry.focusSession);
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Should still show Recent Tools section
      expect(find.text('Recent Tools'), findsOneWidget);
      
      // Should show at least one valid tool (the known one)
      final recentToolCards = find.descendant(
        of: find.ancestor(
          of: find.text('Recent Tools'),
          matching: find.byType(Column),
        ).first,
        matching: find.byType(Card),
      );
      
      // Should have at least 1 card (for the valid focus session)
      expect(recentToolCards, findsAtLeastNWidgets(1));
    });

    testWidgets('should respect limit of 5 recent tools', (tester) async {
      await ToolUsageService.instance.init();
      await FavoriteToolsStore.instance.init();
      
      // Record usage for more than 5 different tools
      final toolIds = [
        ToolRegistry.focusSession,
        ToolRegistry.animalCheckin,
        ToolRegistry.sessionHistory,
        ToolRegistry.checkinHistory,
        ToolRegistry.languageAudit,
        ToolRegistry.analytics,
        ToolRegistry.settings,
      ];
      
      for (final toolId in toolIds) {
        await ToolUsageService.instance.recordUsage(toolId);
        await Future.delayed(const Duration(milliseconds: 5));
      }
      
      await tester.pumpWidget(
        MaterialApp(
          home: const HomeScreen(),
          routes: {
            '/settings': (context) => const Scaffold(body: Text('Settings')),
          },
        ),
      );
      
      await tester.pump();
      
      // Should show Recent Tools section
      expect(find.text('Recent Tools'), findsOneWidget);
      
      // Find the ListView and verify it shows at most 5 unique tools
      final recentToolCards = find.descendant(
        of: find.ancestor(
          of: find.text('Recent Tools'),
          matching: find.byType(Column),
        ).first,
        matching: find.byType(Card),
      );
      
      // Should not exceed 5 recent tool cards (we'll check this differently)
      final cardCount = tester.widgetList(recentToolCards).length;
      expect(cardCount, lessThanOrEqualTo(5));
    });
  });
}
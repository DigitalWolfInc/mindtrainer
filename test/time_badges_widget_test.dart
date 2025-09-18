import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/favorites/tool_tile.dart';
import '../lib/favorites/tool_definitions.dart';

void main() {
  group('Time Badges Widget Tests', () {
    testWidgets('ToolTile should show time badge when estimated duration is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.calmBreath, // Has 1m estimated duration
              onTap: () {},
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Should find the time badge
      expect(find.text('• 1m'), findsOneWidget);
      
      // Should also find the tool title
      expect(find.text('Calm Breath'), findsOneWidget);
    });
    
    testWidgets('ToolTile should not show time badge when estimated duration is absent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.sessionHistory, // No estimated duration
              onTap: () {},
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Should not find any time badge
      expect(find.textContaining('•'), findsNothing);
      expect(find.textContaining('m'), findsNothing);
      
      // Should still find the tool title
      expect(find.text('View Session History'), findsOneWidget);
    });
    
    testWidgets('ToolTile should show correct duration for different tools', (tester) async {
      // Test multiple tools with different durations
      final testCases = [
        (ToolRegistry.calmBreath, '• 1m'),
        (ToolRegistry.brainDump, '• 5m'),
        (ToolRegistry.perspectiveFlip, '• 3m'),
        (ToolRegistry.windDown, '• 10m'),
      ];
      
      for (final (toolId, expectedBadge) in testCases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ToolTile(
                toolId: toolId,
                onTap: () {},
              ),
            ),
          ),
        );
        
        await tester.pump();
        
        expect(find.text(expectedBadge), findsOneWidget, 
               reason: 'Expected badge $expectedBadge for tool $toolId');
        
        // Clear the widget tree for next test
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
    
    testWidgets('FavoriteToolTile should show time badge when estimated duration is present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteToolTile(
              toolId: ToolRegistry.tinyNextStep, // Has 1m estimated duration
              onTap: () {},
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Should find the time badge
      expect(find.text('• 1m'), findsOneWidget);
      
      // Should also find the tool title
      expect(find.text('Tiny Next Step'), findsOneWidget);
    });
    
    testWidgets('FavoriteToolTile should not show time badge when estimated duration is absent', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteToolTile(
              toolId: ToolRegistry.analytics, // No estimated duration
              onTap: () {},
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Should not find any time badge
      expect(find.textContaining('•'), findsNothing);
      expect(find.textContaining('m'), findsNothing);
      
      // Should still find the tool title
      expect(find.text('Analytics'), findsOneWidget);
    });
    
    testWidgets('Time badge should have correct styling in ToolTile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.brainDump,
              onTap: () {},
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Find the time badge text widget
      final timeBadgeFinder = find.text('• 5m');
      expect(timeBadgeFinder, findsOneWidget);
      
      // Check the text style
      final textWidget = tester.widget<Text>(timeBadgeFinder);
      expect(textWidget.style?.fontSize, 11);
      expect(textWidget.style?.fontWeight, FontWeight.w500);
    });
    
    testWidgets('Time badge should have correct styling in FavoriteToolTile', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FavoriteToolTile(
              toolId: ToolRegistry.perspectiveFlip,
              onTap: () {},
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Find the time badge text widget
      final timeBadgeFinder = find.text('• 3m');
      expect(timeBadgeFinder, findsOneWidget);
      
      // Check the text style
      final textWidget = tester.widget<Text>(timeBadgeFinder);
      expect(textWidget.style?.fontSize, 10); // Smaller font in favorite tiles
      expect(textWidget.style?.fontWeight, FontWeight.w500);
    });
    
    testWidgets('Time badge should not break tool tile layout', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ToolTile(
                  toolId: ToolRegistry.windDown, // With badge
                  onTap: () {},
                ),
                ToolTile(
                  toolId: ToolRegistry.settings, // Without badge
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      
      await tester.pump();
      
      // Both tiles should be present
      expect(find.text('Wind Down'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      
      // Only one should have a time badge
      expect(find.text('• 10m'), findsOneWidget);
      expect(find.textContaining('• '), findsOneWidget); // Only one badge total
    });
    
    testWidgets('Tool tile with trailing widget and time badge should layout correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ToolTile(
              toolId: ToolRegistry.languageAudit, // Has estimated duration
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
      
      await tester.pump();
      
      // Should find all elements
      expect(find.text('Language Safety Check'), findsOneWidget);
      expect(find.text('• 3m'), findsOneWidget);
      expect(find.text('PRO'), findsOneWidget);
    });
    
    testWidgets('Unknown tool should not show time badge', (tester) async {
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
      
      await tester.pump();
      
      // Should render as empty (SizedBox.shrink)
      expect(find.byType(ToolTile), findsOneWidget);
      expect(find.textContaining('•'), findsNothing);
    });
  });
}
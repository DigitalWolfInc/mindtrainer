import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/shell/tab_shell.dart';
import 'package:mindtrainer/core/feature_flags.dart';

void main() {
  group('TabShell', () {
    testWidgets('renders 6 tabs with correct labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TabShell(),
        ),
      );

      // Wait for any animations to complete
      await tester.pumpAndSettle();

      // Verify all 6 tabs are present
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('Coach'), findsOneWidget);
      expect(find.text('Regulate'), findsOneWidget);
      expect(find.text('Think'), findsOneWidget);
      expect(find.text('Do'), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);
    });

    testWidgets('switching tabs changes content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TabShell(),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on Coach tab
      await tester.tap(find.text('Coach'));
      await tester.pumpAndSettle();

      // Verify coach-specific content is visible
      expect(find.text('Talk to Coach'), findsOneWidget);
      
      // Tap on Do tab
      await tester.tap(find.text('Do'));
      await tester.pumpAndSettle();

      // Verify do-specific content is visible
      expect(find.text('Focus Timer'), findsOneWidget);
    });

    testWidgets('accessibility - large text support', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
            child: const TabShell(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not have any overflow errors with 140% text scaling
      expect(tester.takeException(), isNull);
    });
  });
}
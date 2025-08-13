import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/a11y/a11y.dart';

void main() {
  group('A11y Basic Tests', () {
    test('should have correct minimum touch target size constant', () {
      expect(kMinTouchTargetSize, equals(44.0));
    });
    
    test('should have correct high contrast factor', () {
      expect(kHighContrastFactor, equals(0.3));
    });
    
    testWidgets('should ensure minimum touch target size', (tester) async {
      const smallWidget = SizedBox(width: 20, height: 20);
      final wrappedWidget = A11y.ensureMinTouchTarget(smallWidget);
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: wrappedWidget,
          ),
        ),
      );
      
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      
      expect(constrainedBox.constraints.minWidth, equals(kMinTouchTargetSize));
      expect(constrainedBox.constraints.minHeight, equals(kMinTouchTargetSize));
    });
    
    test('should adjust colors for high contrast', () {
      const lightColor = Color(0xFF888888);
      const darkColor = Color(0xFF222222);
      
      // Test high contrast adjustments
      final adjustedLight = A11y.contrastOn(lightColor, true);
      final adjustedDark = A11y.contrastOn(darkColor, true);
      
      // Light colors should become darker
      expect(adjustedLight.computeLuminance(), lessThan(lightColor.computeLuminance()));
      
      // Dark colors should become lighter
      expect(adjustedDark.computeLuminance(), greaterThan(darkColor.computeLuminance()));
      
      // Non-high contrast should return original
      expect(A11y.contrastOn(lightColor, false), equals(lightColor));
      expect(A11y.contrastOn(darkColor, false), equals(darkColor));
    });
    
    test('should provide appropriate text colors for backgrounds', () {
      const lightBackground = Color(0xFFFFFFFF);
      const darkBackground = Color(0xFF000000);
      
      // Light background should have dark text
      final lightBgTextColor = A11y.textColorForBackground(lightBackground, false);
      expect(lightBgTextColor.computeLuminance(), lessThan(0.5));
      
      // Dark background should have light text
      final darkBgTextColor = A11y.textColorForBackground(darkBackground, false);
      expect(darkBgTextColor.computeLuminance(), greaterThan(0.5));
      
      // High contrast should be pure black/white
      final highContrastLight = A11y.textColorForBackground(lightBackground, true);
      final highContrastDark = A11y.textColorForBackground(darkBackground, true);
      
      expect(highContrastLight, equals(Colors.black));
      expect(highContrastDark, equals(Colors.white));
    });
    
    testWidgets('should clamp text scale factor appropriately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final scale = A11y.getClampedTextScale(context);
              
              // Should be within reasonable bounds
              expect(scale, greaterThanOrEqualTo(0.8));
              expect(scale, lessThanOrEqualTo(2.0));
              
              return Container();
            },
          ),
        ),
      );
    });
    
    testWidgets('should apply focus traversal order', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                A11y.focusTraversalOrder(
                  order: 1.0,
                  child: const TextField(decoration: InputDecoration(labelText: 'First')),
                ),
                A11y.focusTraversalOrder(
                  order: 2.0, 
                  child: const TextField(decoration: InputDecoration(labelText: 'Second')),
                ),
              ],
            ),
          ),
        ),
      );
      
      // Check that focus traversal orders exist
      expect(find.byType(FocusTraversalOrder), findsNWidgets(2));
      
      final firstOrder = tester.widget<FocusTraversalOrder>(
        find.byType(FocusTraversalOrder).first,
      );
      final secondOrder = tester.widget<FocusTraversalOrder>(
        find.byType(FocusTraversalOrder).last,
      );
      
      expect((firstOrder.order as NumericFocusOrder).order, equals(1.0));
      expect((secondOrder.order as NumericFocusOrder).order, equals(2.0));
    });
    
    testWidgets('should detect accessibility features', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // These should not throw in tests
              expect(() => A11y.isScreenReaderEnabled(context), returnsNormally);
              expect(() => A11y.prefersReducedMotion(context), returnsNormally);
              
              return Container();
            },
          ),
        ),
      );
    });
  });
  
  group('Widget Extensions', () {
    testWidgets('should add semantic label via extension', (tester) async {
      const label = 'Test Label';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Hello').semanticLabel(label),
          ),
        ),
      );
      
      // Check that Semantics widget exists
      expect(find.byType(Semantics), findsOneWidget);
    });
    
    testWidgets('should add semantic hint via extension', (tester) async {
      const hint = 'Test Hint';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Hello').semanticHint(hint),
          ),
        ),
      );
      
      // Check that Semantics widget exists
      expect(find.byType(Semantics), findsOneWidget);
    });
    
    testWidgets('should apply min touch target via extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const SizedBox(width: 10, height: 10).minTouchTarget(),
          ),
        ),
      );
      
      final constrainedBox = tester.widget<ConstrainedBox>(
        find.byType(ConstrainedBox),
      );
      
      expect(constrainedBox.constraints.minWidth, equals(kMinTouchTargetSize));
      expect(constrainedBox.constraints.minHeight, equals(kMinTouchTargetSize));
    });
    
    testWidgets('should apply focus order via extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Hello').focusOrder(5.0),
          ),
        ),
      );
      
      final focusOrder = tester.widget<FocusTraversalOrder>(
        find.byType(FocusTraversalOrder),
      );
      
      expect((focusOrder.order as NumericFocusOrder).order, equals(5.0));
    });
  });
  
  group('High Contrast Theme', () {
    test('should adjust theme for high contrast', () {
      final baseTheme = ThemeData.light();
      final highContrastTheme = A11yTheme.adjustForHighContrast(baseTheme, true);
      
      // Should return original theme if high contrast is false
      final normalTheme = A11yTheme.adjustForHighContrast(baseTheme, false);
      expect(normalTheme, equals(baseTheme));
      
      // High contrast theme should have adjusted colors
      expect(highContrastTheme, isNot(equals(baseTheme)));
      expect(highContrastTheme.elevatedButtonTheme.style?.foregroundColor?.resolve({}), equals(Colors.white));
      expect(highContrastTheme.elevatedButtonTheme.style?.backgroundColor?.resolve({}), equals(Colors.black));
    });
  });
  
  group('Test Helpers', () {
    test('should validate minimum size requirements', () {
      const largeSize = Size(50, 50);
      const smallSize = Size(30, 30);
      
      expect(A11yTestHelpers.hasMinimumSize(largeSize), isTrue);
      expect(A11yTestHelpers.hasMinimumSize(smallSize), isFalse);
    });
    
    test('should check basic widget requirements', () {
      expect(A11yTestHelpers.meetsMinimumRequirements(const Text('Test')), isTrue);
      expect(A11yTestHelpers.meetsMinimumRequirements(Container()), isFalse);
    });
  });
}
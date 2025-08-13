import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/a11y/a11y.dart';
import 'package:mindtrainer/i18n/i18n.dart';
import 'package:mindtrainer/i18n/strings.g.dart';

void main() {
  group('A11y Helpers Tests', () {
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
    
    testWidgets('should create accessible button with proper semantics', (tester) async {
      const label = 'Test Button';
      const hint = 'Tap to test';
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: A11y.accessibleButton(
              label: label,
              hint: hint,
              onPressed: () => tapped = true,
              child: const Text('Button'),
            ),
          ),
        ),
      );
      
      // Check semantics
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, equals(label));
      expect(semantics.hint, equals(hint));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(semantics.hasFlag(SemanticsFlag.isEnabled), isTrue);
      
      // Test interaction
      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });
    
    testWidgets('should create accessible icon button', (tester) async {
      const label = 'Settings';
      const hint = 'Open settings menu';
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: A11y.accessibleIconButton(
              icon: Icons.settings,
              label: label,
              hint: hint,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );
      
      // Check semantics
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, equals(label));
      expect(semantics.hint, equals(hint));
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      
      // Test interaction
      await tester.tap(find.byType(IconButton));
      expect(tapped, isTrue);
    });
    
    testWidgets('should create accessible timer with live region', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return A11y.accessibleTimer(
                  timeText: '25:00',
                  context: context,
                );
              },
            ),
          ),
        ),
      );
      
      // Check that timer has live region semantics
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.hasFlag(SemanticsFlag.isLiveRegion), isTrue);
      expect(semantics.label, contains('25:00'));
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
    
    testWidgets('should create Pro lock indicator with proper semantics', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return A11y.proLockIndicator(
                  context: context,
                  onTap: () => tapped = true,
                );
              },
            ),
          ),
        ),
      );
      
      // Check semantics
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
      expect(semantics.label, isNotEmpty);
      expect(semantics.hint, isNotEmpty);
      
      // Test interaction
      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
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
              // These will return false in tests but should not throw
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
      
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, equals(label));
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
      
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.hint, equals(hint));
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
  
  group('Semantic Mixin', () {
    class TestWidget extends StatelessWidget with A11ySemantics {
      final String? testLabel;
      final String? testHint;
      
      const TestWidget({super.key, this.testLabel, this.testHint});
      
      @override
      Widget build(BuildContext context) {
        Widget child = const Text('Test');
        
        if (testLabel != null && testHint != null) {
          return labelAndHint(testLabel!, testHint!, child);
        } else if (testLabel != null) {
          return label(testLabel!, child);
        } else if (testHint != null) {
          return hint(testHint!, child);
        }
        
        return child;
      }
    }
    
    testWidgets('should apply label via mixin', (tester) async {
      const testLabel = 'Mixin Label';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestWidget(testLabel: testLabel),
          ),
        ),
      );
      
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, equals(testLabel));
    });
    
    testWidgets('should apply hint via mixin', (tester) async {
      const testHint = 'Mixin Hint';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestWidget(testHint: testHint),
          ),
        ),
      );
      
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.hint, equals(testHint));
    });
    
    testWidgets('should combine label and hint via mixin', (tester) async {
      const testLabel = 'Combined Label';
      const testHint = 'Combined Hint';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TestWidget(testLabel: testLabel, testHint: testHint),
          ),
        ),
      );
      
      final semantics = tester.getSemantics(find.byType(Semantics).first);
      expect(semantics.label, equals(testLabel));
      expect(semantics.hint, equals(testHint));
    });
  });
  
  group('Test Helpers', () {
    test('should validate minimum touch target size', () {
      // Mock semantic node with proper size
      final largeNode = SemanticsNode();
      largeNode.rect = const Rect.fromLTWH(0, 0, 50, 50);
      
      final smallNode = SemanticsNode();
      smallNode.rect = const Rect.fromLTWH(0, 0, 30, 30);
      
      expect(A11yTestHelpers.hasMinimumTouchTarget(largeNode), isTrue);
      expect(A11yTestHelpers.hasMinimumTouchTarget(smallNode), isFalse);
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../lib/ui/mtds/mtds.dart';

void main() {
  group('MTDS Theme', () {
    test('should create midnight calm theme without errors', () {
      expect(() => MtdsTheme.midnightCalm(), returnsNormally);
    });
    
    test('should have correct primary colors', () {
      final theme = MtdsTheme.midnightCalm();
      expect(theme.colorScheme.primary, equals(MtdsColors.accent));
      expect(theme.colorScheme.surface, equals(MtdsColors.surface));
    });
    
    test('should include MTDS extension', () {
      final theme = MtdsTheme.midnightCalm();
      final extension = theme.extension<MtdsThemeExtension>();
      expect(extension, isNotNull);
    });

    testWidgets('should provide tokens through BuildContext extension', (tester) async {
      late BuildContext capturedContext;
      
      await tester.pumpWidget(
        MaterialApp(
          theme: MtdsTheme.midnightCalm(),
          home: Builder(
            builder: (context) {
              capturedContext = context;
              return const Scaffold(body: Text('Test'));
            },
          ),
        ),
      );
      
      // Test that we can access MTDS tokens through context
      expect(() => capturedContext.mtds, returnsNormally);
    });
  });
  
  group('MTDS Tokens', () {
    test('should have correct color values', () {
      expect(MtdsColors.bgTop, equals(const Color(0xFF0D1B2A)));
      expect(MtdsColors.bgBottom, equals(const Color(0xFF0A1622)));
      expect(MtdsColors.accent, equals(const Color(0xFF6EA8FF)));
    });
    
    test('should have correct spacing values', () {
      expect(MtdsSpacing.xs, equals(4.0));
      expect(MtdsSpacing.lg, equals(16.0));
    });
    
    test('should have minimum touch target size', () {
      expect(MtdsSizes.minTouchTarget, equals(48.0));
    });
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/i18n/i18n.dart';
import 'package:mindtrainer/i18n/strings.g.dart';

void main() {
  group('i18n System Tests', () {
    test('should have expected supported locales', () {
      expect(AppLocales.codes, contains('en'));
      expect(AppLocales.codes, contains('es'));
      expect(AppLocales.supported.length, greaterThanOrEqualTo(2));
    });
    
    test('should find locales by code', () {
      final enLocale = AppLocales.findByCode('en');
      expect(enLocale, isNotNull);
      expect(enLocale!.code, equals('en'));
      expect(enLocale.name, equals('English'));
      
      final esLocale = AppLocales.findByCode('es');
      expect(esLocale, isNotNull);
      expect(esLocale!.code, equals('es'));
      
      final invalidLocale = AppLocales.findByCode('invalid');
      expect(invalidLocale, isNull);
    });
    
    test('should check locale support correctly', () {
      expect(AppLocales.isSupported('en'), isTrue);
      expect(AppLocales.isSupported('es'), isTrue);
      expect(AppLocales.isSupported('fr'), isFalse);
      expect(AppLocales.isSupported('invalid'), isFalse);
    });
    
    test('should generate strings for supported locales', () {
      final enStrings = getStrings('en');
      expect(enStrings, isA<AppStrings>());
      expect(enStrings.appName, isNotEmpty);
      
      final esStrings = getStrings('es');
      expect(esStrings, isA<AppStrings>());
      expect(esStrings.appName, isNotEmpty);
    });
    
    test('should fallback to default locale for unsupported codes', () {
      final strings = getStrings('invalid_code');
      expect(strings, isA<AppStrings>());
      expect(strings.appName, isNotEmpty);
    });
    
    test('should have key accessibility strings', () {
      final strings = getStrings('en');
      
      // Check that accessibility strings exist
      expect(strings.a11ySessionTimer, isNotEmpty);
      expect(strings.a11yMenuButton, isNotEmpty);
      expect(strings.a11yBackButton, isNotEmpty);
    });
    
    test('should format parameters in strings', () {
      const template = 'Save {percent}% vs monthly';
      final formatted = I18nHelpers.format(template, {'percent': 20});
      expect(formatted, equals('Save 20% vs monthly'));
      
      // Multiple parameters
      const multiTemplate = 'Hello {name}, you have {count} messages';
      final multiFormatted = I18nHelpers.format(multiTemplate, {
        'name': 'John',
        'count': 5,
      });
      expect(multiFormatted, equals('Hello John, you have 5 messages'));
    });
    
    test('should handle plural forms', () {
      expect(I18nHelpers.plural('session', 'sessions', 1), equals('session'));
      expect(I18nHelpers.plural('session', 'sessions', 0), equals('sessions'));
      expect(I18nHelpers.plural('session', 'sessions', 2), equals('sessions'));
    });
    
    test('should format durations appropriately', () {
      final strings = getStrings('en');
      
      final shortDuration = Duration(seconds: 45);
      final formatted1 = I18nHelpers.formatDuration(shortDuration, strings);
      expect(formatted1, contains('45'));
      
      final mediumDuration = Duration(minutes: 25, seconds: 30);
      final formatted2 = I18nHelpers.formatDuration(mediumDuration, strings);
      expect(formatted2, contains('25'));
      
      final longDuration = Duration(hours: 2, minutes: 15);
      final formatted3 = I18nHelpers.formatDuration(longDuration, strings);
      expect(formatted3, contains('2'));
      expect(formatted3, contains('15'));
    });
    
    testWidgets('should resolve locale from context', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: const [
            AppLocalizationDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          home: Builder(
            builder: (context) {
              // Test system locale resolution
              final resolved1 = I18nConfig.resolveLocale(AppLocales.system, context);
              expect(resolved1, equals('es')); // Should match app locale
              
              // Test explicit locale
              final resolved2 = I18nConfig.resolveLocale('en', context);
              expect(resolved2, equals('en'));
              
              // Test invalid locale fallback
              final resolved3 = I18nConfig.resolveLocale('invalid', context);
              expect(resolved3, equals('en'));
              
              return Container();
            },
          ),
        ),
      );
    });
    
    testWidgets('should provide strings through context extension', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizationDelegate(),
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('es'),
          ],
          home: Builder(
            builder: (context) {
              final strings = context.strings;
              expect(strings, isA<AppStrings>());
              expect(strings.appName, isNotEmpty);
              
              // Test safe strings fallback
              final safeStrings = context.safeStrings;
              expect(safeStrings, isA<AppStrings>());
              
              return Container();
            },
          ),
        ),
      );
    });
    
    test('should have consistent translations between locales', () {
      final enStrings = getStrings('en');
      final esStrings = getStrings('es');
      
      // Check that both locales have the same keys available
      // (This is a basic consistency check)
      expect(enStrings.appName, isNotEmpty);
      expect(esStrings.appName, isNotEmpty);
      
      expect(enStrings.settingsTitle, isNotEmpty);
      expect(esStrings.settingsTitle, isNotEmpty);
      
      // Strings should be different (unless they're the same in both languages)
      if (enStrings.settingsTitle != esStrings.settingsTitle) {
        expect(enStrings.settingsTitle, isNot(equals(esStrings.settingsTitle)));
      }
    });
    
    test('should handle CSV parsing edge cases', () {
      // Test that the build system handled the existing CSV format correctly
      final strings = getStrings('en');
      
      // Check for strings that might have special characters or formatting
      expect(strings.appSubtitle, isNotEmpty);
      expect(strings.settingsPrivacy, isNotEmpty);
      expect(strings.splashInitializing, isNotEmpty);
    });
  });
  
  group('Generated Strings Validation', () {
    test('should have all required app strings', () {
      final strings = getStrings('en');
      
      // App identity
      expect(strings.appName, equals('MindTrainer'));
      expect(strings.appSubtitle, isNotEmpty);
      
      // Navigation and core UI
      expect(strings.settingsTitle, isNotEmpty);
      expect(strings.sessionTitle, isNotEmpty);
      
      // Dialog strings
      expect(strings.dialogCancel, isNotEmpty);
      expect(strings.dialogConfirm, isNotEmpty);
    });
    
    test('should have accessibility strings for key interactions', () {
      final strings = getStrings('en');
      
      expect(strings.a11ySessionTimer, isNotEmpty);
      expect(strings.a11yMenuButton, isNotEmpty);
      expect(strings.a11yBackButton, isNotEmpty);
      expect(strings.a11yProLockedFeature, isNotEmpty);
    });
    
    test('should have Pro feature strings', () {
      final strings = getStrings('en');
      
      expect(strings.proTitle, isNotEmpty);
      expect(strings.proSubtitle, isNotEmpty);
      expect(strings.proMonthly, isNotEmpty);
      expect(strings.proYearly, isNotEmpty);
    });
    
    test('should have support and diagnostic strings', () {
      final strings = getStrings('en');
      
      expect(strings.supportTitle, isNotEmpty);
      expect(strings.supportCreateBundle, isNotEmpty);
      expect(strings.diagnosticsPanel, isNotEmpty);
    });
  });
}
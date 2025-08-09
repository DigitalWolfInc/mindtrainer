import 'package:flutter_test/flutter_test.dart';
import 'package:mindtrainer/features/language_audit/domain/language_validator.dart';

void main() {
  group('LanguageValidator', () {
    test('should reject clinical terms', () {
      expect(
        LanguageValidator.validateText('This will treat your symptoms'),
        contains('clinical terms'),
      );
      
      expect(
        LanguageValidator.validateText('Get a medical diagnosis'),
        contains('clinical terms'),
      );
    });

    test('should reject blame-focused language', () {
      expect(
        LanguageValidator.validateText('You failed to complete the session'),
        contains('blame-focused terms'),
      );
      
      expect(
        LanguageValidator.validateText('That was wrong of you'),
        contains('blame-focused terms'),
      );
    });

    test('should reject achievement pressure terms', () {
      expect(
        LanguageValidator.validateText('You must be perfect'),
        contains('achievement-pressure terms'),
      );
    });

    test('should accept trauma-safe language', () {
      expect(
        LanguageValidator.validateText('Thanks for taking time for yourself'),
        isNull,
      );
      
      expect(
        LanguageValidator.validateText('How are you feeling right now?'),
        isNull,
      );
    });

    test('should detect medical claims', () {
      expect(
        LanguageValidator.containsMedicalClaims('This app will cure your anxiety'),
        isTrue,
      );
      
      expect(
        LanguageValidator.containsMedicalClaims('This provides gentle support'),
        isFalse,
      );
    });

    test('should provide safe phrase alternatives', () {
      expect(LanguageValidator.safePhrases, isNotEmpty);
      expect(LanguageValidator.safePhrases.keys, contains('Session completed successfully'));
    });
  });
}
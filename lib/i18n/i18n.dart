/// i18n Support for MindTrainer
/// 
/// Provides localization utilities and string access methods.

import 'package:flutter/material.dart';
import 'strings.g.dart';

/// Supported locale configurations
class SupportedLocale {
  final String code;
  final String name;
  final String nativeName;
  
  const SupportedLocale({
    required this.code,
    required this.name,
    required this.nativeName,
  });
}

/// Available locales for the app
class AppLocales {
  static const List<SupportedLocale> supported = [
    SupportedLocale(
      code: 'en',
      name: 'English',
      nativeName: 'English',
    ),
    SupportedLocale(
      code: 'es', 
      name: 'Spanish',
      nativeName: 'Español',
    ),
  ];
  
  /// System locale (follows device settings)
  static const String system = 'system';
  
  /// Get locale by code
  static SupportedLocale? findByCode(String code) {
    try {
      return supported.firstWhere((locale) => locale.code == code);
    } catch (e) {
      return null;
    }
  }
  
  /// Get all locale codes
  static List<String> get codes => supported.map((l) => l.code).toList();
  
  /// Check if locale code is supported
  static bool isSupported(String code) {
    return codes.contains(code);
  }
}

/// i18n Configuration Manager
class I18nConfig {
  /// Resolve effective locale from preference and context
  static String resolveLocale(String preference, BuildContext context) {
    if (preference == AppLocales.system) {
      // Use system locale if supported, otherwise fall back to English
      final systemLocale = Localizations.localeOf(context).languageCode;
      return AppLocales.isSupported(systemLocale) ? systemLocale : 'en';
    }
    
    // Use explicit preference if valid
    return AppLocales.isSupported(preference) ? preference : 'en';
  }
  
  /// Get locale display name for settings
  static String getDisplayName(String localeCode, BuildContext context) {
    if (localeCode == AppLocales.system) {
      return context.strings.settingsSystemLanguage;
    }
    
    final locale = AppLocales.findByCode(localeCode);
    return locale?.nativeName ?? localeCode;
  }
}

/// Helper methods for common i18n patterns
class I18nHelpers {
  /// Format strings with parameters (e.g., "Save {percent}%" with {percent: 20})
  static String format(String template, Map<String, dynamic> params) {
    var result = template;
    for (final entry in params.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return result;
  }
  
  /// Get appropriate plural form (simple English/Spanish rules)
  static String plural(String singular, String plural, int count) {
    return count == 1 ? singular : plural;
  }
  
  /// Format duration strings with locale-appropriate units
  static String formatDuration(Duration duration, AppStrings strings) {
    if (duration.inHours > 0) {
      return '${duration.inHours}${strings.timeHoursShort} ${duration.inMinutes % 60}${strings.timeMinutesShort}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}${strings.timeMinutesShort}';
    } else {
      return '${duration.inSeconds}${strings.timeSecondsShort}';
    }
  }
}

/// Locale delegation for MaterialApp
class AppLocalizationDelegate extends LocalizationsDelegate<AppStrings> {
  const AppLocalizationDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return AppLocales.isSupported(locale.languageCode);
  }
  
  @override
  Future<AppStrings> load(Locale locale) async {
    return getStrings(locale.languageCode);
  }
  
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;
}

/// Convenience getters for common strings
extension AppStringsConvenience on AppStrings {
  /// Common dialog buttons
  String get cancel => dialogCancel;
  String get ok => dialogConfirm;
  String get yes => dialogConfirm;
  String get no => dialogCancel;
}

/// Error-safe string access
extension SafeStringAccess on BuildContext {
  /// Get strings with fallback error handling
  AppStrings get safeStrings {
    try {
      return strings;
    } catch (e) {
      // Fallback to English if there's any issue
      return getStrings('en');
    }
  }
}
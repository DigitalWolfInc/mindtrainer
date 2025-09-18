/// i18n Build Script for MindTrainer
/// 
/// Generates type-safe Dart code from CSV translation files.
/// Run with: dart run tool/i18n/build_i18n.dart

import 'dart:io';
import 'dart:convert';

const String csvPath = 'assets/i18n';
const String outputPath = 'lib/i18n';
const String generatedFile = 'strings.g.dart';

void main() async {
  print('Building i18n strings...');
  
  try {
    // Read CSV files
    final csvFiles = await _findCsvFiles();
    if (csvFiles.isEmpty) {
      print('No CSV files found in $csvPath');
      return;
    }
    
    print('Found ${csvFiles.length} CSV files: ${csvFiles.map((f) => f.path.split('/').last).join(', ')}');
    
    // Parse translations - use first CSV file as it contains all locales
    final translations = <String, Map<String, String>>{};
    final allKeys = <String>{};
    
    final primaryCsvFile = csvFiles.first;
    final csvContent = await primaryCsvFile.readAsString();
    
    // Parse all locales from the multi-column CSV
    final allLocaleTranslations = await _parseMultiLocaleCsv(csvContent);
    
    for (final entry in allLocaleTranslations.entries) {
      final locale = entry.key;
      final localeTranslations = entry.value;
      
      translations[locale] = localeTranslations;
      allKeys.addAll(localeTranslations.keys);
      
      print('Parsed $locale: ${localeTranslations.length} strings');
    }
    
    // Ensure we found some translations
    if (translations.isEmpty) {
      print('No translations found');
      return;
    }
    
    // Generate Dart code
    final dartCode = _generateDartCode(translations, allKeys.toList()..sort());
    
    // Ensure output directory exists
    final outputDir = Directory(outputPath);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }
    
    // Write generated file
    final outputFile = File('$outputPath/$generatedFile');
    await outputFile.writeAsString(dartCode);
    
    print('Generated $outputPath/$generatedFile');
    print('Build complete! Found ${allKeys.length} translation keys.');
    
  } catch (e, stackTrace) {
    print('Error building i18n: $e');
    print('Stack trace: $stackTrace');
    exit(1);
  }
}

Future<List<File>> _findCsvFiles() async {
  final csvDir = Directory(csvPath);
  if (!await csvDir.exists()) {
    return [];
  }
  
  return await csvDir
      .list()
      .where((entity) => entity is File && entity.path.endsWith('.csv'))
      .cast<File>()
      .toList();
}

String? _getLocaleFromFilename(String path) {
  final filename = path.split('/').last;
  final nameWithoutExt = filename.replaceAll('.csv', '');
  
  // Support simple locale codes like 'en', 'es', etc.
  if (RegExp(r'^[a-z]{2}$').hasMatch(nameWithoutExt)) {
    return nameWithoutExt;
  }
  
  return null;
}

Future<Map<String, Map<String, String>>> _parseMultiLocaleCsv(String csvContent) async {
  final lines = const LineSplitter().convert(csvContent);
  final allTranslations = <String, Map<String, String>>{};
  
  if (lines.isEmpty) return allTranslations;
  
  // Parse header to find column indices
  final header = _parseCsvLine(lines[0]);
  final keyIndex = header.indexOf('key');
  
  if (keyIndex == -1) {
    throw Exception('No \"key\" column found in CSV');
  }
  
  // Find all locale columns (skip 'key' column)
  final localeIndices = <String, int>{};
  for (int i = 0; i < header.length; i++) {
    final columnName = header[i].trim();
    if (columnName != 'key' && columnName.isNotEmpty && !columnName.startsWith('#')) {
      localeIndices[columnName] = i;
      allTranslations[columnName] = <String, String>{};
    }
  }
  
  // Parse data rows
  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    
    final cells = _parseCsvLine(line);
    if (cells.length <= keyIndex) continue;
    
    final key = cells[keyIndex].trim();
    if (key.isEmpty) continue;
    
    // Extract translations for each locale
    for (final entry in localeIndices.entries) {
      final locale = entry.key;
      final index = entry.value;
      
      if (cells.length > index) {
        final value = cells[index].trim();
        if (value.isNotEmpty) {
          allTranslations[locale]![key] = value;
        }
      }
    }
  }
  
  return allTranslations;
}

Future<Map<String, String>> _parseCsv(String csvContent, String targetLocale) async {
  final lines = const LineSplitter().convert(csvContent);
  final translations = <String, String>{};
  
  if (lines.isEmpty) return translations;
  
  // Parse header to find column indices
  final header = _parseCsvLine(lines[0]);
  final keyIndex = header.indexOf('key');
  final localeIndex = header.indexOf(targetLocale);
  
  if (keyIndex == -1) {
    throw Exception('No "key" column found in CSV');
  }
  if (localeIndex == -1) {
    throw Exception('No "$targetLocale" column found in CSV');
  }
  
  // Parse data rows
  for (int i = 1; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    
    final cells = _parseCsvLine(line);
    if (cells.length <= keyIndex || cells.length <= localeIndex) {
      continue; // Skip incomplete rows
    }
    
    final key = cells[keyIndex].trim();
    final value = cells[localeIndex].trim();
    
    if (key.isNotEmpty && value.isNotEmpty) {
      translations[key] = value;
    }
  }
  
  return translations;
}

List<String> _parseCsvLine(String line) {
  // Simple CSV parser - handles quoted values and basic escaping
  final cells = <String>[];
  var current = StringBuffer();
  var inQuotes = false;
  var i = 0;
  
  while (i < line.length) {
    final char = line[i];
    
    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote
        current.write('"');
        i += 2;
      } else {
        // Toggle quote mode
        inQuotes = !inQuotes;
        i++;
      }
    } else if (char == ',' && !inQuotes) {
      // Field separator
      cells.add(current.toString());
      current.clear();
      i++;
    } else {
      current.write(char);
      i++;
    }
  }
  
  cells.add(current.toString());
  return cells;
}

String _generateDartCode(Map<String, Map<String, String>> translations, List<String> allKeys) {
  final buffer = StringBuffer();
  
  // File header
  buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
  buffer.writeln('// Generated by tool/i18n/build_i18n.dart');
  buffer.writeln();
  buffer.writeln('// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars');
  buffer.writeln();
  
  // Import statements
  buffer.writeln('import \'package:flutter/widgets.dart\';');
  buffer.writeln();
  
  // Supported locales constant
  final locales = translations.keys.toList()..sort();
  buffer.writeln('/// Supported locale codes');
  buffer.writeln('const List<String> kSupportedLocales = [');
  for (final locale in locales) {
    buffer.writeln('  \'$locale\',');
  }
  buffer.writeln('];');
  buffer.writeln();
  
  // Base strings class
  buffer.writeln('/// Base class for all translations');
  buffer.writeln('abstract class AppStrings {');
  
  // Generate method signatures
  for (final key in allKeys) {
    final methodName = _keyToMethodName(key);
    buffer.writeln('  String get $methodName;');
  }
  
  // Parameter replacement method
  buffer.writeln();
  buffer.writeln('  /// Replace parameters in a string (e.g., {name} -> John)');
  buffer.writeln('  String replace(String template, Map<String, dynamic> params) {');
  buffer.writeln('    var result = template;');
  buffer.writeln('    for (final entry in params.entries) {');
  buffer.writeln('      result = result.replaceAll(\'{\${entry.key}}\', entry.value.toString());');
  buffer.writeln('    }');
  buffer.writeln('    return result;');
  buffer.writeln('  }');
  
  buffer.writeln('}');
  buffer.writeln();
  
  // Generate locale-specific classes
  for (final locale in locales) {
    final className = 'AppStrings${locale.toUpperCase()}';
    final localeTranslations = translations[locale]!;
    
    buffer.writeln('/// Strings for $locale locale');
    buffer.writeln('class $className extends AppStrings {');
    
    for (final key in allKeys) {
      final methodName = _keyToMethodName(key);
      final value = localeTranslations[key] ?? key; // Fallback to key if translation missing
      final escapedValue = _escapeString(value);
      buffer.writeln('  @override');
      buffer.writeln('  String get $methodName => \'$escapedValue\';');
    }
    
    buffer.writeln('}');
    buffer.writeln();
  }
  
  // Strings factory function
  buffer.writeln('/// Get strings for a specific locale');
  buffer.writeln('AppStrings getStrings(String localeCode) {');
  buffer.writeln('  switch (localeCode) {');
  for (final locale in locales) {
    final className = 'AppStrings${locale.toUpperCase()}';
    buffer.writeln('    case \'$locale\':');
    buffer.writeln('      return $className();');
  }
  buffer.writeln('    default:');
  final defaultClass = 'AppStrings${locales.first.toUpperCase()}';
  buffer.writeln('      return $defaultClass(); // Default to first locale');
  buffer.writeln('  }');
  buffer.writeln('}');
  buffer.writeln();
  
  // Locale-aware widget extension
  buffer.writeln('/// Extension to get strings from BuildContext');
  buffer.writeln('extension StringsExtension on BuildContext {');
  buffer.writeln('  AppStrings get strings {');
  buffer.writeln('    final locale = Localizations.localeOf(this);');
  buffer.writeln('    final localeCode = locale.languageCode;');
  buffer.writeln('    return getStrings(localeCode);');
  buffer.writeln('  }');
  buffer.writeln('}');
  
  return buffer.toString();
}

String _keyToMethodName(String key) {
  // Convert snake_case to camelCase
  final parts = key.split('_');
  if (parts.isEmpty) return key;
  
  final result = parts.first + 
      parts.skip(1).map((part) => part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1)).join('');
  
  // Ensure valid Dart identifier
  if (result.isEmpty || !RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(result)) {
    return 'key_$key'.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }
  
  return result;
}

String _escapeString(String value) {
  return value
      .replaceAll('\\', '\\\\')
      .replaceAll('\'', '\\')
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
}
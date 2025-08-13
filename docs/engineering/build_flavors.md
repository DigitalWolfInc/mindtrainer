# MindTrainer Build Flavors & Configuration

This document defines build-time configuration options using Dart defines (no additional packages required).

## Build Configuration System

### Dart Defines Strategy
Use `--dart-define` flags during compilation to control app behavior without additional dependencies.

### Available Configuration Flags

#### 1. FAKE_BILLING
**Purpose**: Control billing system behavior for development and testing  
**Values**: 
- `true` - Use fake/mock billing adapter (default for debug)
- `false` - Use real Google Play billing (required for production)

**Usage**:
```bash
# Development build with fake billing
flutter build apk --dart-define=FAKE_BILLING=true

# Production build with real billing  
flutter build apk --release --dart-define=FAKE_BILLING=false
```

#### 2. LOG_LEVEL
**Purpose**: Control debugging output and performance logging  
**Values**:
- `DEBUG` - Verbose logging, performance traces, debug UI elements
- `INFO` - Basic app flow logging, user action tracking
- `WARNING` - Only warnings and errors
- `ERROR` - Error logging only
- `NONE` - No logging output

**Usage**:
```bash
# Debug build with full logging
flutter run --dart-define=LOG_LEVEL=DEBUG

# Production build with minimal logging
flutter build apk --release --dart-define=LOG_LEVEL=ERROR
```

#### 3. SHOW_DEBUG_BADGES
**Purpose**: Display debug information badges in UI during development  
**Values**:
- `true` - Show billing mode, build version, performance metrics in UI
- `false` - Hide all debug UI elements (default for release)

**Usage**:
```bash
# Show debug info during development
flutter run --dart-define=SHOW_DEBUG_BADGES=true

# Clean UI for production
flutter build apk --release --dart-define=SHOW_DEBUG_BADGES=false
```

## Entry Point Implementation

### main_fake.dart
```dart
import 'package:flutter/material.dart';
import 'core/app.dart';
import 'core/config/app_config.dart';
import 'core/logging/logger.dart';

void main() {
  // Force fake billing for development
  const config = AppConfig(
    useFakeBilling: true,
    logLevel: LogLevel.debug,
    showDebugBadges: true,
  );
  
  Logger.initialize(config.logLevel);
  Logger.info('Starting MindTrainer in FAKE BILLING mode');
  
  runApp(MindTrainerApp(config: config));
}
```

### main_prod.dart  
```dart
import 'package:flutter/material.dart';
import 'core/app.dart';
import 'core/config/app_config.dart';
import 'core/logging/logger.dart';

void main() {
  // Force production settings
  const config = AppConfig(
    useFakeBilling: false,
    logLevel: LogLevel.error,
    showDebugBadges: false,
  );
  
  Logger.initialize(config.logLevel);
  Logger.info('Starting MindTrainer in PRODUCTION mode');
  
  runApp(MindTrainerApp(config: config));
}
```

### main.dart (Auto-detecting)
```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'core/app.dart';
import 'core/config/app_config.dart';
import 'core/logging/logger.dart';

void main() {
  // Auto-detect configuration based on build mode and dart defines
  final config = AppConfig.fromEnvironment();
  
  Logger.initialize(config.logLevel);
  Logger.info('Starting MindTrainer with config: ${config.toJson()}');
  
  runApp(MindTrainerApp(config: config));
}
```

## Configuration Classes

### lib/core/config/app_config.dart
```dart
import 'package:flutter/foundation.dart';

/// Application configuration determined at build time
class AppConfig {
  final bool useFakeBilling;
  final LogLevel logLevel;
  final bool showDebugBadges;
  
  const AppConfig({
    required this.useFakeBilling,
    required this.logLevel,
    required this.showDebugBadges,
  });
  
  /// Create configuration from environment variables and dart defines
  factory AppConfig.fromEnvironment() {
    // Parse FAKE_BILLING flag
    const fakeBillingStr = String.fromEnvironment('FAKE_BILLING', defaultValue: '');
    final useFakeBilling = kDebugMode 
        ? (fakeBillingStr.toLowerCase() != 'false') // Default true for debug
        : (fakeBillingStr.toLowerCase() == 'true');  // Default false for release
    
    // Parse LOG_LEVEL flag
    const logLevelStr = String.fromEnvironment('LOG_LEVEL', defaultValue: '');
    final logLevel = _parseLogLevel(logLevelStr, kDebugMode);
    
    // Parse SHOW_DEBUG_BADGES flag
    const debugBadgesStr = String.fromEnvironment('SHOW_DEBUG_BADGES', defaultValue: '');
    final showDebugBadges = kDebugMode
        ? (debugBadgesStr.toLowerCase() != 'false') // Default true for debug
        : (debugBadgesStr.toLowerCase() == 'true');  // Default false for release
    
    return AppConfig(
      useFakeBilling: useFakeBilling,
      logLevel: logLevel,
      showDebugBadges: showDebugBadges,
    );
  }
  
  static LogLevel _parseLogLevel(String levelStr, bool isDebugMode) {
    switch (levelStr.toUpperCase()) {
      case 'DEBUG': return LogLevel.debug;
      case 'INFO': return LogLevel.info;
      case 'WARNING': return LogLevel.warning;
      case 'ERROR': return LogLevel.error;
      case 'NONE': return LogLevel.none;
      default:
        // Auto-select based on build mode
        return isDebugMode ? LogLevel.debug : LogLevel.error;
    }
  }
  
  Map<String, dynamic> toJson() => {
    'useFakeBilling': useFakeBilling,
    'logLevel': logLevel.toString(),
    'showDebugBadges': showDebugBadges,
  };
}

enum LogLevel { debug, info, warning, error, none }
```

## Logger Implementation

### lib/core/logging/logger.dart
```dart
import '../config/app_config.dart';

/// Simple logging utility respecting build-time log level configuration
class Logger {
  static LogLevel? _currentLevel;
  static bool _initialized = false;
  
  static void initialize(LogLevel level) {
    _currentLevel = level;
    _initialized = true;
  }
  
  static void debug(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.debug, 'DEBUG', message, context);
  }
  
  static void info(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.info, 'INFO', message, context);
  }
  
  static void warning(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.warning, 'WARNING', message, context);
  }
  
  static void error(String message, [Map<String, dynamic>? context]) {
    _log(LogLevel.error, 'ERROR', message, context);
  }
  
  static void _log(LogLevel messageLevel, String prefix, String message, Map<String, dynamic>? context) {
    if (!_initialized || _currentLevel == null) return;
    if (_currentLevel == LogLevel.none) return;
    if (messageLevel.index < _currentLevel!.index) return;
    
    final timestamp = DateTime.now().toIso8601String();
    final contextStr = context != null ? ' | Context: $context' : '';
    
    print('[$timestamp] $prefix: $message$contextStr');
  }
  
  /// Check if debug logging is enabled
  static bool get isDebugEnabled => 
      _initialized && _currentLevel != null && _currentLevel!.index <= LogLevel.debug.index;
      
  /// Check if any logging is enabled
  static bool get isLoggingEnabled =>
      _initialized && _currentLevel != null && _currentLevel != LogLevel.none;
}
```

## Build Script Examples

### build_debug.sh (Development)
```bash
#!/bin/bash
echo "Building MindTrainer for development..."

flutter clean
flutter pub get

# Build with fake billing and debug logging
flutter build apk \
  --debug \
  --dart-define=FAKE_BILLING=true \
  --dart-define=LOG_LEVEL=DEBUG \
  --dart-define=SHOW_DEBUG_BADGES=true

echo "Development build complete: build/app/outputs/flutter-apk/app-debug.apk"
```

### build_testing.sh (Internal Testing)
```bash
#!/bin/bash
echo "Building MindTrainer for internal testing..."

flutter clean
flutter pub get

# Build with fake billing but release optimizations
flutter build apk \
  --release \
  --dart-define=FAKE_BILLING=true \
  --dart-define=LOG_LEVEL=INFO \
  --dart-define=SHOW_DEBUG_BADGES=false

echo "Testing build complete: build/app/outputs/flutter-apk/app-release.apk"
```

### build_production.sh (App Store Release)
```bash
#!/bin/bash
echo "Building MindTrainer for production release..."

flutter clean
flutter pub get

# Verify no fake billing in production
flutter build appbundle \
  --release \
  --dart-define=FAKE_BILLING=false \
  --dart-define=LOG_LEVEL=ERROR \
  --dart-define=SHOW_DEBUG_BADGES=false

echo "Production build complete: build/app/outputs/bundle/release/app-release.aab"
echo "⚠️  VERIFY: This build uses REAL BILLING - test carefully!"
```

## Configuration Validation

### Runtime Validation
```dart
// In main.dart or app initialization
void validateConfiguration(AppConfig config) {
  // Prevent fake billing in production builds
  if (kReleaseMode && config.useFakeBilling) {
    throw Exception('CRITICAL: Fake billing detected in release build!');
  }
  
  // Warn about debug badges in release
  if (kReleaseMode && config.showDebugBadges) {
    Logger.warning('Debug badges enabled in release build - consider disabling');
  }
  
  // Log configuration for verification
  Logger.info('App configuration validated', config.toJson());
}
```

## Integration with Existing Systems

### Billing Adapter Integration
```dart
// In BillingAdapterFactory.create()
static BillingAdapter create() {
  final config = AppConfig.fromEnvironment();
  
  if (config.useFakeBilling) {
    Logger.info('Using FakeBillingAdapter');
    return FakeBillingAdapter();
  } else {
    Logger.info('Using PlatformChannelBilling');
    return PlatformChannelBilling();
  }
}
```

### Debug UI Integration
```dart
// In app UI where debug info should appear
class DebugInfoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final config = AppConfig.fromEnvironment();
    
    if (!config.showDebugBadges) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.red.withOpacity(0.8),
      child: Text(
        'DEBUG: ${config.useFakeBilling ? "FAKE" : "REAL"} BILLING | ${config.logLevel}',
        style: TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
```

## Compilation Commands Reference

### Development Workflow
```bash
# Quick debug run with fake billing
flutter run --dart-define=FAKE_BILLING=true

# Test real billing in debug mode  
flutter run --dart-define=FAKE_BILLING=false --dart-define=LOG_LEVEL=INFO

# Silent debug mode (minimal logging)
flutter run --dart-define=LOG_LEVEL=WARNING
```

### Testing Workflow  
```bash
# Internal testing build
flutter build apk --dart-define=FAKE_BILLING=true --dart-define=LOG_LEVEL=INFO

# Staging with real billing
flutter build apk --dart-define=FAKE_BILLING=false --dart-define=LOG_LEVEL=WARNING

# Production simulation
flutter build apk --release --dart-define=FAKE_BILLING=false --dart-define=LOG_LEVEL=ERROR
```

### Production Release
```bash
# Android App Bundle for Play Store
flutter build appbundle --release --dart-define=FAKE_BILLING=false --dart-define=LOG_LEVEL=ERROR --dart-define=SHOW_DEBUG_BADGES=false

# iOS build for App Store
flutter build ios --release --dart-define=FAKE_BILLING=false --dart-define=LOG_LEVEL=ERROR --dart-define=SHOW_DEBUG_BADGES=false
```

## Troubleshooting

### Common Issues

#### "Fake billing in production"
**Cause**: FAKE_BILLING=true set for release build  
**Solution**: Explicitly set `--dart-define=FAKE_BILLING=false` for production builds

#### "No logging output"
**Cause**: LOG_LEVEL set too high or Logger not initialized  
**Solution**: Check LOG_LEVEL setting and ensure `Logger.initialize()` is called

#### "Debug badges visible in release"  
**Cause**: SHOW_DEBUG_BADGES not explicitly set to false
**Solution**: Add `--dart-define=SHOW_DEBUG_BADGES=false` to release builds

### Verification Steps
1. **Before each release**: Check `flutter logs` for configuration validation messages
2. **After building**: Verify no "FAKE BILLING" warnings in release builds  
3. **In testing**: Confirm debug badges appear only when expected
4. **Before upload**: Double-check all dart-define flags in build commands

---

**Security Note**: Never commit files with hardcoded production secrets. All configuration should come from build-time flags or secure environment variables.
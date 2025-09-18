/// Billing Configuration for MindTrainer
/// 
/// Handles build-time configuration for billing modes and feature flags.
/// Supports fake/sandbox/production modes via environment variables.

/// Billing configuration class
class BillingConfig {
  /// Get current billing mode from environment
  static String get mode {
    return const String.fromEnvironment('BILLING_MODE', defaultValue: 'production');
  }
  
  /// Whether we're running in fake billing mode (for testing)
  static bool get isFakeMode {
    return mode.toLowerCase() == 'fake' || mode.toLowerCase() == 'test';
  }
  
  /// Whether we're running in sandbox mode (for development)
  static bool get isSandboxMode {
    return mode.toLowerCase() == 'sandbox' || mode.toLowerCase() == 'debug';
  }
  
  /// Whether we're running in production mode
  static bool get isProductionMode {
    return mode.toLowerCase() == 'production' || mode.toLowerCase() == 'release';
  }
  
  /// Get debug flag state
  static bool get debugMode {
    return const bool.fromEnvironment('DEBUG', defaultValue: false);
  }
  
  /// Print billing configuration info (for debugging)
  static void printConfig() {
    if (debugMode) {
      print('=== MindTrainer Billing Configuration ===');
      print('Mode: $mode');
      print('Fake Mode: $isFakeMode');
      print('Sandbox Mode: $isSandboxMode'); 
      print('Production Mode: $isProductionMode');
      print('Debug: $debugMode');
      print('==========================================');
    }
  }
  
  /// Get appropriate log level based on mode
  static String get logLevel {
    if (isFakeMode || isSandboxMode) {
      return 'debug';
    }
    return 'info';
  }
  
  /// Whether to show billing debug UI elements
  static bool get showDebugUI {
    return isFakeMode || (isSandboxMode && debugMode);
  }
}

/// Build configuration helper
class BuildConfig {
  /// Check if running in Flutter test environment
  static bool get isTest {
    return const bool.fromEnvironment('flutter.inspector.structuredErrors', defaultValue: false);
  }
  
  /// Check if this is a debug build
  static bool get isDebug {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }
  
  /// Check if this is a release build
  static bool get isRelease => !isDebug && !isTest;
  
  /// Get app version from environment
  static String get appVersion {
    return const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  }
  
  /// Get build number from environment
  static String get buildNumber {
    return const String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');
  }
}
import 'dart:io' show Platform;

/// Configuration for billing system
/// Determines whether to use fake or real billing based on environment
class BillingConfig {
  /// Whether to use fake billing adapter
  static bool get useFakeBilling => _shouldUseFake();
  
  /// Check if we should use fake billing
  static bool _shouldUseFake() {
    // Always use fake billing in debug mode unless explicitly overridden
    const kDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    
    // Check for explicit override via environment variables
    const forceFake = bool.fromEnvironment('MINDTRAINER_FORCE_FAKE_BILLING', defaultValue: false);
    const forceReal = bool.fromEnvironment('MINDTRAINER_FORCE_REAL_BILLING', defaultValue: false);
    
    if (forceFake) return true;
    if (forceReal) return false;
    
    // Use fake billing in the following scenarios:
    
    // 1. Always in debug builds
    if (kDebugMode) return true;
    
    // 2. In CI/test environments
    if (_isTestEnvironment()) return true;
    
    // 3. On unsupported platforms
    if (!_isPlatformSupported()) return true;
    
    // Default to real billing in production
    return false;
  }
  
  /// Check if running in test environment
  static bool _isTestEnvironment() {
    // Flutter test environment
    const isFlutterTest = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);
    if (isFlutterTest) return true;
    
    // GitHub Actions or other CI
    try {
      final ciEnv = Platform.environment['CI'];
      if (ciEnv == 'true' || ciEnv == '1') return true;
      
      final githubActions = Platform.environment['GITHUB_ACTIONS'];
      if (githubActions == 'true') return true;
    } catch (e) {
      // Platform.environment might not be available in all contexts
    }
    
    return false;
  }
  
  /// Check if platform supports Google Play Billing
  static bool _isPlatformSupported() {
    try {
      return Platform.isAndroid;
    } catch (e) {
      // Platform might not be available in all contexts (like tests)
      return false;
    }
  }
  
  /// Get configuration description for debugging
  static String getConfigDescription() {
    final useFake = useFakeBilling;
    final reason = _getReasonForFakeBilling();
    
    return 'Using ${useFake ? 'FAKE' : 'REAL'} billing${reason.isNotEmpty ? ' ($reason)' : ''}';
  }
  
  /// Get reason why fake billing is being used
  static String _getReasonForFakeBilling() {
    if (!useFakeBilling) return '';
    
    const forceFake = bool.fromEnvironment('MINDTRAINER_FORCE_FAKE_BILLING', defaultValue: false);
    if (forceFake) return 'force fake env var';
    
    const kDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    if (kDebugMode) return 'debug mode';
    
    if (_isTestEnvironment()) return 'test environment';
    
    if (!_isPlatformSupported()) return 'unsupported platform';
    
    return 'default';
  }
  
  /// Check if real billing is available and should be used
  static bool get isRealBillingAvailable => !useFakeBilling && _isPlatformSupported();
  
  /// Check if running in production with real billing
  static bool get isProductionBilling {
    const kDebugMode = bool.fromEnvironment('dart.vm.product') == false;
    return !kDebugMode && !useFakeBilling && _isPlatformSupported();
  }
}
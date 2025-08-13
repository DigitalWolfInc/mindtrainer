/// Accessibility Helpers for MindTrainer
/// 
/// Provides utilities for screen reader support, high contrast mode,
/// touch targets, and other accessibility features.

import 'package:flutter/material.dart';
import '../i18n/i18n.dart';

/// Minimum touch target size per accessibility guidelines (44x44 dp)
const double kMinTouchTargetSize = 44.0;

/// High contrast color adjustments
const double kHighContrastFactor = 0.3;

/// Mixin for semantic labels and hints
mixin A11ySemantics {
  /// Add semantic label to a widget
  Widget label(String labelText, Widget child) {
    return Semantics(
      label: labelText,
      child: child,
    );
  }
  
  /// Add semantic hint to a widget
  Widget hint(String hintText, Widget child) {
    return Semantics(
      hint: hintText,
      child: child,
    );
  }
  
  /// Combine label and hint
  Widget labelAndHint(String labelText, String hintText, Widget child) {
    return Semantics(
      label: labelText,
      hint: hintText,
      child: child,
    );
  }
  
  /// Mark widget as button for screen readers
  Widget button(String labelText, Widget child, {String? hint}) {
    return Semantics(
      label: labelText,
      hint: hint,
      button: true,
      child: child,
    );
  }
  
  /// Mark widget as header for screen readers
  Widget header(String labelText, Widget child) {
    return Semantics(
      label: labelText,
      header: true,
      child: child,
    );
  }
  
  /// Mark widget as live region for dynamic content
  Widget liveRegion(Widget child, {bool assertive = false}) {
    return Semantics(
      liveRegion: true,
      child: child,
    );
  }
}

/// Main accessibility utilities class
class A11y with A11ySemantics {
  /// Singleton instance
  static final A11y _instance = A11y._internal();
  factory A11y() => _instance;
  A11y._internal();
  
  /// Ensure minimum touch target size
  static Widget ensureMinTouchTarget(Widget child) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: kMinTouchTargetSize,
        minHeight: kMinTouchTargetSize,
      ),
      child: child,
    );
  }
  
  /// Wrap button with proper touch target and semantics
  static Widget accessibleButton({
    required Widget child,
    required VoidCallback? onPressed,
    required String label,
    String? hint,
    String? tooltip,
  }) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      child: child,
    );
    
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }
    
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: ensureMinTouchTarget(button),
    );
  }
  
  /// Wrap icon button with proper accessibility
  static Widget accessibleIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String label,
    String? hint,
    String? tooltip,
    double? iconSize,
  }) {
    Widget iconButton = IconButton(
      icon: Icon(icon, size: iconSize),
      onPressed: onPressed,
      tooltip: tooltip ?? label, // Fallback to label if no tooltip
    );
    
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: onPressed != null,
      child: ensureMinTouchTarget(iconButton),
    );
  }
  
  /// Create accessible timer display
  static Widget accessibleTimer({
    required String timeText,
    required BuildContext context,
    TextStyle? style,
  }) {
    // Simple fallback for timer accessibility
    return Semantics(
      label: 'Session timer showing $timeText remaining',
      liveRegion: true,
      child: Text(
        timeText,
        style: style,
      ),
    );
  }
  
  /// High contrast color adjustment
  static Color contrastOn(Color color, bool highContrast) {
    if (!highContrast) return color;
    
    // Increase contrast by adjusting towards black or white
    final luminance = color.computeLuminance();
    if (luminance > 0.5) {
      // Light colors -> make darker
      return Color.lerp(color, Colors.black, kHighContrastFactor) ?? color;
    } else {
      // Dark colors -> make lighter
      return Color.lerp(color, Colors.white, kHighContrastFactor) ?? color;
    }
  }
  
  /// High contrast text color
  static Color textColorForBackground(Color backgroundColor, bool highContrast) {
    final luminance = backgroundColor.computeLuminance();
    final baseColor = luminance > 0.5 ? Colors.black : Colors.white;
    
    if (highContrast) {
      return baseColor;
    }
    
    // Standard contrast
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
  
  /// Get text scale factor with sensible limits
  static double getClampedTextScale(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return textScaler.scale(1.0).clamp(0.8, 2.0);
  }
  
  /// Create accessible Pro lock indicator
  static Widget proLockIndicator({
    required BuildContext context,
    required VoidCallback? onTap,
    Widget? child,
  }) {
    Widget indicator = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.amber),
      ),
      child: child ?? Icon(
        Icons.lock,
        color: Colors.amber[700],
        size: 16,
      ),
    );
    
    if (onTap != null) {
      indicator = GestureDetector(
        onTap: onTap,
        child: indicator,
      );
    }
    
    return Semantics(
      label: 'Pro feature locked',
      hint: 'Tap to unlock with Pro',
      button: onTap != null,
      child: Tooltip(
        message: 'Tap to unlock with Pro',
        child: ensureMinTouchTarget(indicator),
      ),
    );
  }
  
  /// Focus order helper for screen reader traversal
  static Widget focusTraversalOrder({
    required double order,
    required Widget child,
  }) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: child,
    );
  }
  
  /// Screen reader announcement
  static void announce(BuildContext context, String message) {
    // Simple debug print for development/testing
    debugPrint('A11y Announcement: $message');
  }
  
  /// Check if device is using a screen reader
  static bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.accessibleNavigationOf(context);
  }
  
  /// Check if device prefers reduced motion
  static bool prefersReducedMotion(BuildContext context) {
    return MediaQuery.disableAnimationsOf(context);
  }
}

/// Extension methods for easier accessibility integration
extension A11yWidget on Widget {
  /// Add semantic label
  Widget semanticLabel(String label) {
    return Semantics(
      label: label,
      child: this,
    );
  }
  
  /// Add semantic hint
  Widget semanticHint(String hint) {
    return Semantics(
      hint: hint,
      child: this,
    );
  }
  
  /// Ensure minimum touch target
  Widget minTouchTarget() {
    return A11y.ensureMinTouchTarget(this);
  }
  
  /// Apply focus traversal order
  Widget focusOrder(double order) {
    return A11y.focusTraversalOrder(order: order, child: this);
  }
}

/// High contrast theme data provider
class A11yTheme {
  /// Create high contrast theme adjustments
  static ThemeData adjustForHighContrast(ThemeData baseTheme, bool highContrast) {
    if (!highContrast) return baseTheme;
    
    return baseTheme.copyWith(
      // Increase button text contrast
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.black,
        ),
      ),
      
      // High contrast text themes
      textTheme: baseTheme.textTheme.copyWith(
        bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
          color: A11y.textColorForBackground(baseTheme.scaffoldBackgroundColor, true),
        ),
        bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
          color: A11y.textColorForBackground(baseTheme.scaffoldBackgroundColor, true),
        ),
      ),
      
      // High contrast dividers
      dividerColor: highContrast ? Colors.black : baseTheme.dividerColor,
      
      // High contrast borders
      inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: highContrast ? Colors.black : Colors.grey,
            width: highContrast ? 2.0 : 1.0,
          ),
        ),
      ),
    );
  }
}

/// Accessibility settings provider
class A11ySettings {
  static const String keyHighContrast = 'high_contrast_mode';
  static const String keyScreenReader = 'screen_reader_optimizations';
  
  /// Check if high contrast is enabled
  static bool isHighContrastEnabled(BuildContext context) {
    // Check both system preference and app-specific setting
    // For now, return false - will be connected to settings in Stage 5
    return false;
  }
}

/// Accessibility testing helpers
class A11yTestHelpers {
  /// Verify minimum touch target size from widget size
  static bool hasMinimumSize(Size size) {
    return size.width >= kMinTouchTargetSize && 
           size.height >= kMinTouchTargetSize;
  }
  
  /// Check if a widget meets minimum accessibility requirements
  static bool meetsMinimumRequirements(Widget widget) {
    // Basic check - can be extended later
    return widget is Semantics || widget is Text || widget is ElevatedButton;
  }
}
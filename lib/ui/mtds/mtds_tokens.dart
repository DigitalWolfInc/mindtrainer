/// MindTrainer Design System Tokens v1
/// Defines colors, typography, spacing, and other design primitives
library mtds_tokens;

import 'package:flutter/material.dart';

/// MTDS Color Tokens - Midnight Calm Palette
class MtdsColors {
  // Background gradient
  static const Color bgTop = Color(0xFF0D1B2A);
  static const Color bgBottom = Color(0xFF0A1622);
  
  // Surfaces
  static const Color surface = Color(0xFF0F2436);
  static const Color outline = Color(0x66274862); // 40% opacity
  
  // Text
  static const Color textPrimary = Color(0xFFF2F5F7);
  static const Color textSecondary = Color(0xFFC7D1DD);
  
  // Accent states
  static const Color accent = Color(0xFF6EA8FF);
  static const Color accentPressed = Color(0xFF5A95EB);
  static const Color accentDisabled = Color(0xFF2A3A51);
  
  // Chips
  static const Color chipIdle = Color(0xFF16354B);
  static const Color chipSelected = Color(0xFF1E4970);
  
  // Status colors
  static const Color success = Color(0xFF7ED3B2);
  static const Color warning = Color(0xFFFFD084);
  
  // SOS/Emergency (high contrast neutral)
  static const Color sosSurface = Color(0xFFF6F6F6);
  static const Color sosText = Color(0xFF111111);
  
  // Semantic colors for Flutter theme
  static const Color error = Color(0xFFFF6B6B);
  static const Color onError = Color(0xFFFFFFFF);
  
  MtdsColors._();
}

/// MTDS Typography Scale
class MtdsTypography {
  // Display (32/38 SemiBold)
  static const TextStyle display = TextStyle(
    fontSize: 32,
    height: 38 / 32, // line-height / font-size
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );
  
  // Title (24/30 SemiBold)  
  static const TextStyle title = TextStyle(
    fontSize: 24,
    height: 30 / 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
  );
  
  // Body (16/24 Regular)
  static const TextStyle body = TextStyle(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
  
  // Button/Chip (17/22 SemiBold)
  static const TextStyle button = TextStyle(
    fontSize: 17,
    height: 22 / 17,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );
  
  // Small overline for section headers
  static const TextStyle overline = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  MtdsTypography._();
}

/// MTDS Spacing Scale
class MtdsSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;  
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  
  MtdsSpacing._();
}

/// MTDS Border Radius Scale
class MtdsRadius {
  static const double card = 20.0;
  static const double chip = 12.0;
  static const double pill = 28.0;
  
  MtdsRadius._();
}

/// MTDS Elevation/Shadow
class MtdsElevation {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000), // 20% black
      blurRadius: 8.0,
      offset: Offset(0, 2),
    ),
  ];
  
  MtdsElevation._();
}

/// MTDS Motion/Animation
class MtdsMotion {
  // Standard transition duration  
  static const Duration standard = Duration(milliseconds: 225);
  static const Duration quick = Duration(milliseconds: 150);
  
  // Easing curves
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  
  MtdsMotion._();
}

/// MTDS Size Constants
class MtdsSizes {
  // Minimum touch targets (accessibility)
  static const double minTouchTarget = 48.0;
  
  // Common component heights
  static const double pillButtonHeight = 56.0;
  static const double chipHeight = 36.0;
  static const double listTileHeight = 64.0;
  
  // Icon sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  
  MtdsSizes._();
}

/// MTDS Haptic Feedback Types
enum MtdsHaptic {
  /// Soft feedback for primary actions
  soft,
  /// No haptic for error states
  none,
}
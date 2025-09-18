/// MindTrainer Design System Theme v1
/// Provides ThemeData and extensions using MTDS tokens
library mtds_theme;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mtds_tokens.dart';

/// MTDS Theme Extension for accessing design tokens in widgets
@immutable
class MtdsThemeExtension extends ThemeExtension<MtdsThemeExtension> {
  const MtdsThemeExtension._internal();

  @override
  ThemeExtension<MtdsThemeExtension> copyWith() {
    return this; // Tokens are static, no need to copy
  }

  @override
  ThemeExtension<MtdsThemeExtension> lerp(
    covariant ThemeExtension<MtdsThemeExtension>? other,
    double t,
  ) {
    if (other is! MtdsThemeExtension) return this;
    // For simplicity, return this since our tokens are static
    return this;
  }
}

/// MTDS Theme Factory
class MtdsTheme {
  /// Creates the primary Midnight Calm theme
  static ThemeData midnightCalm({bool useMaterial3 = true}) {
    final colorScheme = ColorScheme.dark(
      // Primary colors
      primary: MtdsColors.accent,
      onPrimary: MtdsColors.textPrimary,
      
      // Surface colors  
      surface: MtdsColors.surface,
      onSurface: MtdsColors.textPrimary,
      
      // Background
      background: MtdsColors.bgBottom,
      onBackground: MtdsColors.textPrimary,
      
      // Secondary
      secondary: MtdsColors.textSecondary,
      onSecondary: MtdsColors.bgBottom,
      
      // Error
      error: MtdsColors.error,
      onError: MtdsColors.onError,
      
      // Outline
      outline: MtdsColors.outline,
      
      // Container variants
      primaryContainer: MtdsColors.chipSelected,
      onPrimaryContainer: MtdsColors.textPrimary,
      
      surfaceVariant: MtdsColors.chipIdle,
      onSurfaceVariant: MtdsColors.textSecondary,
    );

    final textTheme = TextTheme(
      displayLarge: MtdsTypography.display.copyWith(color: MtdsColors.textPrimary),
      titleLarge: MtdsTypography.title.copyWith(color: MtdsColors.textPrimary),
      bodyLarge: MtdsTypography.body.copyWith(color: MtdsColors.textPrimary),
      bodyMedium: MtdsTypography.body.copyWith(color: MtdsColors.textSecondary),
      labelLarge: MtdsTypography.button.copyWith(color: MtdsColors.textPrimary),
      labelSmall: MtdsTypography.overline.copyWith(color: MtdsColors.textSecondary),
    );

    return ThemeData(
      useMaterial3: useMaterial3,
      colorScheme: colorScheme,
      textTheme: textTheme,
      
      // Component themes
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: MtdsColors.textPrimary,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MtdsColors.accent,
          foregroundColor: MtdsColors.textPrimary,
          textStyle: MtdsTypography.button,
          minimumSize: const Size(0, MtdsSizes.pillButtonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MtdsRadius.pill),
          ),
        ),
      ),
      
      chipTheme: ChipThemeData(
        backgroundColor: MtdsColors.chipIdle,
        selectedColor: MtdsColors.chipSelected,
        labelStyle: MtdsTypography.button.copyWith(color: MtdsColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MtdsRadius.chip),
        ),
        showCheckmark: false,
      ),
      
      cardTheme: CardThemeData(
        color: MtdsColors.surface,
        shadowColor: Colors.black,
        elevation: 0, // We'll use custom shadows
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MtdsRadius.card),
        ),
      ),
      
      listTileTheme: ListTileThemeData(
        textColor: MtdsColors.textPrimary,
        iconColor: MtdsColors.textSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MtdsSpacing.lg,
          vertical: MtdsSpacing.sm,
        ),
      ),
      
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: MtdsColors.surface,
        selectedItemColor: MtdsColors.accent,
        unselectedItemColor: MtdsColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Add the MTDS extension
      extensions: const [
        MtdsThemeExtension._internal(),
      ],
    );
  }
  
  MtdsTheme._();
}

/// Extension to easily access MTDS tokens from BuildContext
extension MtdsThemeContext on BuildContext {
  MtdsThemeExtension get mtds {
    final extension = Theme.of(this).extension<MtdsThemeExtension>();
    if (extension == null) {
      throw FlutterError(
        'MtdsThemeExtension not found. '
        'Make sure to use MtdsTheme.midnightCalm() as your app theme.',
      );
    }
    return extension;
  }
}

/// Background gradient for MTDS screens
class MtdsGradient {
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      MtdsColors.bgTop,
      MtdsColors.bgBottom,
    ],
  );
  
  MtdsGradient._();
}
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Single, unified Material theme shared across iOS and Android.
/// No Cupertino, no platform-adaptive styling (CLAUDE.md Section C.1).
///
/// Radii and paddings match the `Dental-Lab-Admin` design system exactly
/// (see [AppRadius] / [AppSpacing]). `dark` drives the OS-following dark mode
/// for every Material-chrome widget (scaffold background, app bar, buttons,
/// inputs, dialogs, dividers, default text color). Screens that paint custom
/// `Container`s using [AppColorsManger] constants directly (not
/// `Theme.of(context)`) keep their light styling — those constants are
/// compile-time `const` and used inside `const` widget trees throughout the
/// app, so they cannot be swapped at runtime without removing `const` at
/// every call site. Converting those screens to read from `Theme.of(context)`
/// is a larger, separate follow-up.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Tajawal';

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsManger.background,
      primaryColor: AppColorsManger.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColorsManger.primary,
        onPrimary: Colors.white,
        secondary: AppColorsManger.primaryDark,
        surface: AppColorsManger.surface,
        onSurface: AppColorsManger.textPrimary,
        error: AppColorsManger.error,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColorsManger.textPrimary,
        displayColor: AppColorsManger.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsManger.surface,
        foregroundColor: AppColorsManger.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.font18MediumText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsManger.surface,
        hintStyle: AppTextStyles.font14RegularSecondary,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: _border(AppColorsManger.border, radius: AppRadius.md),
        focusedBorder: _border(
          AppColorsManger.primary,
          radius: AppRadius.md,
          width: 1.4,
        ),
        errorBorder: _border(AppColorsManger.error, radius: AppRadius.md),
        focusedErrorBorder: _border(
          AppColorsManger.error,
          radius: AppRadius.md,
          width: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsManger.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(44),
          textStyle: AppTextStyles.font16MediumText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsManger.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColorsManger.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsManger.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: AppTextStyles.font18MediumText,
        contentTextStyle: AppTextStyles.font14RegularSecondary,
      ),
      dividerColor: AppColorsManger.divider,
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColorsDark.background,
      primaryColor: AppColorsDark.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.primaryForeground,
        secondary: AppColorsDark.secondary,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.textPrimary,
        error: AppColorsDark.error,
      ),
      textTheme: base.textTheme.apply(
        fontFamily: fontFamily,
        bodyColor: AppColorsDark.textPrimary,
        displayColor: AppColorsDark.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColorsDark.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surface,
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColorsDark.textSecondary,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: _border(AppColorsDark.input, radius: AppRadius.md),
        focusedBorder: _border(
          AppColorsDark.primary,
          radius: AppRadius.md,
          width: 1.4,
        ),
        errorBorder: _border(AppColorsDark.error, radius: AppRadius.md),
        focusedErrorBorder: _border(
          AppColorsDark.error,
          radius: AppRadius.md,
          width: 1.4,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.primaryForeground,
          elevation: 0,
          minimumSize: const Size.fromHeight(44),
          textStyle: TextStyle(
            fontFamily: fontFamily,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColorsDark.surface,
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: const BorderSide(color: AppColorsDark.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: AppColorsDark.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 14,
          color: AppColorsDark.textSecondary,
        ),
      ),
      dividerColor: AppColorsDark.border,
    );
  }

  static OutlineInputBorder _border(
    Color color, {
    double radius = AppRadius.md,
    double width = 1.2,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

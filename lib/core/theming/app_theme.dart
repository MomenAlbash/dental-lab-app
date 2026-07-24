import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Single, unified Material theme shared across iOS and Android.
/// No Cupertino, no platform-adaptive styling (CLAUDE.md Section C.1).
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
        enabledBorder: _border(AppColorsManger.border),
        focusedBorder: _border(AppColorsManger.primary, width: 1.4),
        errorBorder: _border(AppColorsManger.error),
        focusedErrorBorder: _border(AppColorsManger.error, width: 1.4),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsManger.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          textStyle: AppTextStyles.font16MediumText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerColor: AppColorsManger.divider,
    );
  }

  static OutlineInputBorder _border(Color color, {double width = 1.2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Single, unified Material theme shared across iOS and Android.
/// No Cupertino, no platform-adaptive styling (CLAUDE.md Section C.1).
///
/// Radii and paddings match the `Dental-Lab-Admin` design system exactly
/// (see [AppRadius] / [AppSpacing]). `dark` drives the OS-following dark mode
/// for every Material-chrome widget (scaffold background, app bar, buttons,
/// inputs, dialogs, dividers, default text color).
///
/// The page and app-bar colours here are the ones the doctor/patient/clinic
/// screens already use via [GlassTokens], so a plain Material screen and a
/// glass screen sit on the same tone. Screens must not re-specify
/// `Scaffold.backgroundColor` — doing so is what previously pinned them to a
/// flat white and made the app look like two different products.
///
/// Feature screens no longer read [AppColorsManger] directly. They paint from
/// [GlassTokens] via `context.glass` (surfaces, strokes, status colours) and
/// `Theme.of(context).colorScheme.primary` for the brand accent, so a
/// `Container` on a plain screen shifts with the theme exactly like the glass
/// screens do. Keep it that way: a compile-time `const` colour cannot follow
/// dark mode, which is the bug this indirection exists to prevent.
///
/// [AppColorsManger] remains the light palette's source of truth, consumed
/// here and by [GlassTokens.light] — not by screens.
class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Tajawal';

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      // The warm off-white the glass backdrop starts from, not pure white.
      // The doctor/patient/clinic screens sit on that gradient; every other
      // screen used a flat `#FFFFFF`, which is what made the two sets look
      // like different apps. Sharing the tone here unifies them without each
      // screen having to opt in.
      scaffoldBackgroundColor: AppColorsManger.backdropTop,
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
      appBarTheme: AppBarTheme(
        // Matches the page beneath it, the way the translucent GlassAppBar
        // does on the doctor screens. A solid white bar over the warm page
        // would draw a hard seam the glass screens don't have.
        backgroundColor: AppColorsManger.backdropTop,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColorsManger.textPrimary,
        elevation: 0,
        centerTitle: true,
        // The colour must be spelled out: when `titleTextStyle` is set,
        // AppBar uses it as-is and never folds `foregroundColor` in, so a
        // colourless style leaves the title unpainted.
        titleTextStyle: AppTextStyles.font18MediumText.copyWith(
          color: AppColorsManger.textPrimary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsManger.surface,
        hintStyle: AppTextStyles.font14RegularSecondary.copyWith(
          color: AppColorsManger.textSecondary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
        style: _primaryButtonStyle(AppColorsManger.primary, Colors.white),
      ),
      // Every button variant is themed here, so a screen never has to name a
      // colour to get the app's button. Previously only ElevatedButton was
      // covered, which is why call sites kept passing `AppColorsManger.primary`
      // by hand — and why an old screen could quietly drift off-palette.
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(AppColorsManger.primary, Colors.white),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _flatButtonStyle(AppColorsManger.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _flatButtonStyle(AppColorsManger.primary).copyWith(
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColorsManger.primary),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColorsManger.primary,
        foregroundColor: Colors.white,
        elevation: 0,
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
        titleTextStyle: AppTextStyles.font18MediumText.copyWith(
          color: AppColorsManger.textPrimary,
        ),
        contentTextStyle: AppTextStyles.font14RegularSecondary.copyWith(
          color: AppColorsManger.textSecondary,
        ),
      ),
      dividerColor: AppColorsManger.divider,
      extensions: const <ThemeExtension<dynamic>>[GlassTokens.light],
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
        // Same rule as light: the bar shares the page colour instead of
        // sitting on it as a distinct slab.
        backgroundColor: AppColorsDark.background,
        surfaceTintColor: Colors.transparent,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
        style: _primaryButtonStyle(
          AppColorsDark.primary,
          AppColorsDark.primaryForeground,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(
          AppColorsDark.primary,
          AppColorsDark.primaryForeground,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _flatButtonStyle(AppColorsDark.primary),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _flatButtonStyle(AppColorsDark.primary).copyWith(
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColorsDark.primary),
          ),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.primaryForeground,
        elevation: 0,
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
      extensions: const <ThemeExtension<dynamic>>[GlassTokens.dark],
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

  /// Solid, accent-filled buttons (elevated + filled). One shape and height
  /// for both so a screen's primary action looks the same whichever widget
  /// it happens to use.
  static ButtonStyle _primaryButtonStyle(Color background, Color foreground) {
    return ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(background),
      foregroundColor: WidgetStatePropertyAll(foreground),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: const WidgetStatePropertyAll(Size.fromHeight(48)),
      textStyle: WidgetStatePropertyAll(AppTextStyles.font16MediumText),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.glass),
        ),
      ),
    );
  }

  /// Transparent buttons that carry the accent in their label (text +
  /// outlined).
  static ButtonStyle _flatButtonStyle(Color accent) {
    return ButtonStyle(
      foregroundColor: WidgetStatePropertyAll(accent),
      minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
      textStyle: WidgetStatePropertyAll(AppTextStyles.font14MediumText),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.glass),
        ),
      ),
    );
  }
}

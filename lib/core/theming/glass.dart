import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:flutter/material.dart';

/// Glassmorphism design tokens, delivered as a [ThemeExtension].
///
/// Why an extension and not more `const` colors: the app's screens historically
/// read `AppColorsManger` constants directly, which are compile-time values and
/// therefore cannot react to a theme change (see the note in `AppTheme`). Every
/// glass widget reads these tokens through `context.glass` instead, so the new
/// UI follows light/dark correctly — and `lerp` gives us a smooth cross-fade
/// when the user flips the theme switch in the drawer.
@immutable
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.blurSigma,
    required this.subtleBlurSigma,
    required this.surfaceGradient,
    required this.strokeGradient,
    required this.strokeColor,
    required this.shadows,
    required this.backdropGradient,
    required this.backdropGlow,
    required this.glowColor,
    required this.fillColor,
    required this.onGlass,
    required this.onGlassMuted,
    required this.brandGradient,
    required this.primaryDark,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accentSurface,
    required this.surfaceColor,
    required this.mutedSurface,
    required this.toothGum,
    required this.toothEnamel,
  });

  /// Blur radius for floating chrome (app bar, drawer, sheets, dialogs, FAB).
  final double blurSigma;

  /// Lighter blur for inline elements that sit close to the background.
  final double subtleBlurSigma;

  /// Translucent fill painted over the backdrop to form a pane.
  final Gradient surfaceGradient;

  /// Gradient used for the hairline highlight around a pane's edge.
  final Gradient strokeGradient;

  /// Flat fallback for the pane edge (used where a gradient stroke would cost
  /// an extra shader pass, e.g. inside list items).
  final Color strokeColor;

  /// Soft double shadow that lifts a pane off the backdrop.
  final List<BoxShadow> shadows;

  /// Full-screen page background. Without this, translucent panes have nothing
  /// to refract and the whole style collapses into flat grey.
  final Gradient backdropGradient;

  /// Corner glows layered over [backdropGradient] for depth.
  final Color backdropGlow;

  /// Accent glow used for focus rings and the FAB halo.
  final Color glowColor;

  /// Fill for inputs and other interactive glass surfaces.
  final Color fillColor;

  /// Primary text/icon color legible on a glass pane.
  final Color onGlass;

  /// Secondary text/icon color on a glass pane.
  final Color onGlassMuted;

  /// The three-stop brand identity gradient used on hero headers, avatars,
  /// and primary action pills. Reading it from here — instead of the old
  /// `AppColorsManger.primaryLight/primary/primaryDark` constants used
  /// directly — is what makes these elements follow the active theme: the
  /// constants never changed with dark mode, so headers stayed lit in the
  /// light-mode orange even when the rest of the screen went dark.
  final Gradient brandGradient;

  /// The deeper stop of [brandGradient] as a flat colour, for spots that need
  /// a single accent tint rather than a gradient (e.g. an info tile's icon
  /// chip) but should still shift with the brand color between themes.
  final Color primaryDark;

  /// Status colours. These exist here — rather than being read from
  /// [AppColorsManger] directly — for the same reason as everything above:
  /// the constants are compile-time values, so a screen painting a "success"
  /// badge with them kept the light-theme green on the dark theme, where it
  /// sits too dark against the surface to read.
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  /// Tinted fill behind an accent icon or chip (the old `primarySurface`).
  final Color accentSurface;

  /// Flat card/sheet fill, for the screens that paint a solid `color:` rather
  /// than [surfaceGradient]. Same role as the old `AppColorsManger.surface`,
  /// but it follows the theme.
  final Color surfaceColor;

  /// Neutral fill for inert blocks — dividers' backgrounds, disabled chips,
  /// empty-state plates (the old `moreLightGray`).
  final Color mutedSurface;

  /// Gum tissue on the tooth chart. Anatomical rather than brand colour: a
  /// jaw has to read as a jaw, so it stays pink in both themes and only its
  /// depth changes.
  final Color toothGum;

  /// Enamel — the unselected crown fill on the tooth chart.
  final Color toothEnamel;

  static const GlassTokens light = GlassTokens(
    blurSigma: 18,
    subtleBlurSigma: 10,
    surfaceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x99FFFFFF), Color(0x59FFFFFF)],
    ),
    strokeGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xCCFFFFFF), Color(0x33FFFFFF)],
    ),
    strokeColor: Color(0x8CFFFFFF),
    shadows: [
      BoxShadow(color: Color(0x14241F1C), blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x0AF2760F), blurRadius: 6, offset: Offset(0, 2)),
    ],
    backdropGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColorsManger.backdropTop,
        AppColorsManger.backdropMid,
        AppColorsManger.backdropBottom,
      ],
      stops: [0.0, 0.45, 1.0],
    ),
    backdropGlow: Color(0x33F2760F),
    glowColor: Color(0x4DF2760F),
    fillColor: Color(0x80FFFFFF),
    onGlass: AppColorsManger.textPrimary,
    onGlassMuted: AppColorsManger.textSecondary,
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColorsManger.primaryLight,
        AppColorsManger.primary,
        AppColorsManger.primaryDark,
      ],
    ),
    primaryDark: AppColorsManger.primaryDark,
    success: AppColorsManger.success,
    warning: AppColorsManger.warning,
    error: AppColorsManger.error,
    info: AppColorsManger.info,
    accentSurface: AppColorsManger.primarySurface,
    surfaceColor: AppColorsManger.surface,
    mutedSurface: AppColorsManger.moreLightGray,
    toothGum: Color(0xFFEE8593),
    toothEnamel: Color(0xFFFDFBF7),
  );

  static const GlassTokens dark = GlassTokens(
    blurSigma: 18,
    subtleBlurSigma: 10,
    surfaceGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x24FFFFFF), Color(0x0FFFFFFF)],
    ),
    strokeGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0x40FFFFFF), Color(0x0DFFFFFF)],
    ),
    strokeColor: Color(0x26FFFFFF),
    shadows: [
      BoxShadow(color: Color(0x66000000), blurRadius: 24, offset: Offset(0, 8)),
      BoxShadow(color: Color(0x1AFF9142), blurRadius: 6, offset: Offset(0, 2)),
    ],
    backdropGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColorsDark.backdropTop,
        AppColorsDark.backdropMid,
        AppColorsDark.backdropBottom,
      ],
      stops: [0.0, 0.45, 1.0],
    ),
    backdropGlow: Color(0x40FF9142),
    glowColor: Color(0x66FF9142),
    fillColor: Color(0x1FFFFFFF),
    onGlass: AppColorsDark.textPrimary,
    onGlassMuted: AppColorsDark.textSecondary,
    brandGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColorsDark.primaryLight,
        AppColorsDark.primary,
        AppColorsDark.primaryDark,
      ],
    ),
    primaryDark: AppColorsDark.primaryDark,
    success: AppColorsDark.success,
    warning: AppColorsDark.warning,
    error: AppColorsDark.error,
    // No dark `info` constant exists; the light blue is too dark against the
    // dark surface, so this is its lifted counterpart.
    info: Color(0xFF5B9DF9),
    // Translucent rather than solid: it has to tint whatever glass pane it is
    // painted on, which is itself translucent.
    accentSurface: Color(0x33FF9142),
    surfaceColor: AppColorsDark.surface,
    mutedSurface: Color(0x14FFFFFF),
    // Deeper and less saturated than the light gum so it does not glow
    // against a dark backdrop, while still reading as tissue.
    toothGum: Color(0xFFA8515E),
    toothEnamel: Color(0xFFE8E3DA),
  );

  @override
  GlassTokens copyWith({
    double? blurSigma,
    double? subtleBlurSigma,
    Gradient? surfaceGradient,
    Gradient? strokeGradient,
    Color? strokeColor,
    List<BoxShadow>? shadows,
    Gradient? backdropGradient,
    Color? backdropGlow,
    Color? glowColor,
    Color? fillColor,
    Color? onGlass,
    Color? onGlassMuted,
    Gradient? brandGradient,
    Color? primaryDark,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? accentSurface,
    Color? surfaceColor,
    Color? mutedSurface,
    Color? toothGum,
    Color? toothEnamel,
  }) {
    return GlassTokens(
      blurSigma: blurSigma ?? this.blurSigma,
      subtleBlurSigma: subtleBlurSigma ?? this.subtleBlurSigma,
      surfaceGradient: surfaceGradient ?? this.surfaceGradient,
      strokeGradient: strokeGradient ?? this.strokeGradient,
      strokeColor: strokeColor ?? this.strokeColor,
      shadows: shadows ?? this.shadows,
      backdropGradient: backdropGradient ?? this.backdropGradient,
      backdropGlow: backdropGlow ?? this.backdropGlow,
      glowColor: glowColor ?? this.glowColor,
      fillColor: fillColor ?? this.fillColor,
      onGlass: onGlass ?? this.onGlass,
      onGlassMuted: onGlassMuted ?? this.onGlassMuted,
      brandGradient: brandGradient ?? this.brandGradient,
      primaryDark: primaryDark ?? this.primaryDark,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      accentSurface: accentSurface ?? this.accentSurface,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      mutedSurface: mutedSurface ?? this.mutedSurface,
      toothGum: toothGum ?? this.toothGum,
      toothEnamel: toothEnamel ?? this.toothEnamel,
    );
  }

  @override
  GlassTokens lerp(covariant GlassTokens? other, double t) {
    if (other == null) return this;
    return GlassTokens(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t),
      subtleBlurSigma: lerpDouble(subtleBlurSigma, other.subtleBlurSigma, t),
      surfaceGradient:
          Gradient.lerp(surfaceGradient, other.surfaceGradient, t) ??
          surfaceGradient,
      strokeGradient:
          Gradient.lerp(strokeGradient, other.strokeGradient, t) ??
          strokeGradient,
      strokeColor: Color.lerp(strokeColor, other.strokeColor, t)!,
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? shadows,
      backdropGradient:
          Gradient.lerp(backdropGradient, other.backdropGradient, t) ??
          backdropGradient,
      backdropGlow: Color.lerp(backdropGlow, other.backdropGlow, t)!,
      glowColor: Color.lerp(glowColor, other.glowColor, t)!,
      fillColor: Color.lerp(fillColor, other.fillColor, t)!,
      onGlass: Color.lerp(onGlass, other.onGlass, t)!,
      onGlassMuted: Color.lerp(onGlassMuted, other.onGlassMuted, t)!,
      brandGradient:
          Gradient.lerp(brandGradient, other.brandGradient, t) ?? brandGradient,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      error: Color.lerp(error, other.error, t)!,
      info: Color.lerp(info, other.info, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t)!,
      mutedSurface: Color.lerp(mutedSurface, other.mutedSurface, t)!,
      toothGum: Color.lerp(toothGum, other.toothGum, t)!,
      toothEnamel: Color.lerp(toothEnamel, other.toothEnamel, t)!,
    );
  }

  /// Linear interpolation for the non-nullable doubles above.
  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

/// Reads the glass tokens for the current theme.
///
/// Falls back to [GlassTokens.light] so widgets stay renderable inside bare
/// `MaterialApp`s and tests that do not install the app theme.
extension GlassThemeContext on BuildContext {
  GlassTokens get glass =>
      Theme.of(this).extension<GlassTokens>() ?? GlassTokens.light;
}

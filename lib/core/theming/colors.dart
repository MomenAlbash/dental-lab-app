import 'package:flutter/material.dart';

/// Color system aligned with the app's logo: a charcoal badge, a white tooth
/// mark, and a warm orange accent. Token names are kept stable so every
/// screen picks up the palette without changes.
///
/// Brand identity is the orange `#F2760F`; the charcoal `#241F1C` is the
/// dark surface used for the navigation drawer, matching the logo's badge.
class AppColorsManger {
  AppColorsManger._();

  // ---- Brand / primary (logo orange) ----
  static const Color primary = Color(0xFFF2760F);
  static const Color primaryDark = Color(0xFFC85E0A);
  static const Color primaryLight = Color(0xFFFF9A47);
  static const Color primarySurface = Color(0xFFFCE7D4); // tinted background

  // ---- Brand / dark (logo charcoal, used by the drawer) ----
  static const Color brandCharcoal = Color(0xFF241F1C);
  static const Color brandCharcoalLight = Color(0xFF342C27);

  // ---- Neutrals ----
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE7E1DC);
  static const Color divider = Color(0xFFE7E1DC);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF241F1C); // matches brandCharcoal
  static const Color textSecondary = Color(0xFF6F6660);
  static const Color textHint = Color(0xFF6F6660);

  // ---- Semantic ----
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFEAB308);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF2F80ED);

  // ---- Glass backdrop (page background gradient stops) ----
  /// Warm off-white the light backdrop starts from, just tinted enough that
  /// translucent surfaces painted on top actually read as glass.
  static const Color backdropTop = Color(0xFFFFF8F1);
  static const Color backdropMid = Color(0xFFFDEFE2);
  static const Color backdropBottom = Color(0xFFFFFFFF);

  // ---- Backward-compatible aliases (used by existing core widgets) ----
  @Deprecated('Use primary')
  static const Color mainColor = primary;
  @Deprecated('Use primary')
  static const Color mainBlue = primary;
  static const Color gray = textSecondary;
  static const Color lightGray = Color(0xFFE7E1DC); // border
  static const Color moreLightGray = Color(0xFFF5F1ED); // muted
  static const Color morelighterGray = Color(0xFFF5F1ED); // muted
  static const Color lighterGray = Color(0xFFFFFFFF); // background
  static const Color darkBlue = textPrimary;
  static const Color moredarkBlue = Color(0xFF6F6660);
}

/// Dark-theme tokens (drives `AppTheme.dark`). Only wired into [ThemeData] —
/// screens that reference [AppColorsManger] directly as compile-time `const`
/// values will not repaint automatically; see `AppTheme` for details.
class AppColorsDark {
  AppColorsDark._();

  static const Color background = Color(0xFF171412);
  static const Color surface = Color(0xFF241F1C); // matches the logo badge
  static const Color border = Color(0x1AFFFFFF); // white 10%
  static const Color input = Color(0x24FFFFFF); // white 14%

  static const Color primary = Color(0xFFFF9142);
  static const Color primaryLight = Color(0xFFFFB273);
  static const Color primaryDark = Color(0xFFE6791F);
  static const Color primaryForeground = Color(0xFF241100);
  static const Color secondary = Color(0xFF342C27);

  static const Color textPrimary = Color(0xFFF3EFEC);
  static const Color textSecondary = Color(0xFFAA9F98);

  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFACC15);
  static const Color error = Color(0xFFF87171);

  // ---- Glass backdrop (page background gradient stops) ----
  static const Color backdropTop = Color(0xFF171412);
  static const Color backdropMid = Color(0xFF241F1C);
  static const Color backdropBottom = Color(0xFF1C1714);
}

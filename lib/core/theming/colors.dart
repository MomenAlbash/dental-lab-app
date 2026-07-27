import 'package:flutter/material.dart';

/// Color system aligned with the `Dental-Lab-Admin` design system (light
/// theme). Token names are kept stable so every screen picks up the new
/// palette without changes.
///
/// Brand identity is the teal-green `#0E7764`; gold `#F1B620` is the single
/// accent.
class AppColorsManger {
  AppColorsManger._();

  // ---- Brand / primary (teal-green) ----
  static const Color primary = Color(0xFF0E7764);
  static const Color primaryDark = Color(0xFF103B32); // secondary-foreground
  static const Color primaryLight = Color(0xFF43BD99); // dark-theme primary
  static const Color primarySurface = Color(0xFFD1F0E7); // accent

  // ---- Neutrals ----
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFD4E1DD);
  static const Color divider = Color(0xFFD4E1DD);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF14283C); // foreground (navy)
  static const Color textSecondary = Color(0xFF5C6F76); // muted-foreground
  static const Color textHint = Color(0xFF5C6F76); // muted-foreground

  // ---- Semantic ----
  static const Color success = Color(0xFF009962);
  static const Color warning = Color(0xFFF1B620);
  static const Color error = Color(0xFFDF2225); // destructive
  static const Color info = Color(0xFF155DFC); // stat "blue"

  // ---- Backward-compatible aliases (used by existing core widgets) ----
  @Deprecated('Use primary')
  static const Color mainColor = primary;
  @Deprecated('Use primary')
  static const Color mainBlue = primary;
  static const Color gray = textSecondary;
  static const Color lightGray = Color(0xFFD4E1DD); // border
  static const Color moreLightGray = Color(0xFFEAF5F1); // muted
  static const Color morelighterGray = Color(0xFFEAF5F1); // muted
  static const Color lighterGray = Color(0xFFFFFFFF); // background
  static const Color darkBlue = textPrimary;
  static const Color moredarkBlue = Color(0xFF5C6F76);
}

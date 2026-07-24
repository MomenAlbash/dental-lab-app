import 'package:flutter/material.dart';

/// Medical-blue color system for the Dental Lab app.
///
/// Kept the historical class name [AppColorsManger] so existing core widgets
/// keep compiling; the palette itself is now a clean, clinical blue set.
class AppColorsManger {
  AppColorsManger._();

  // ---- Brand / primary (medical blue) ----
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primarySurface = Color(0xFFE9F2FD); // tinted background

  // ---- Neutrals ----
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF1F7);

  // ---- Text ----
  static const Color textPrimary = Color(0xFF1A2233);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // ---- Semantic ----
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // ---- Backward-compatible aliases (used by existing core widgets) ----
  @Deprecated('Use primary')
  static const Color mainColor = primary;
  @Deprecated('Use primary')
  static const Color mainBlue = primary;
  static const Color gray = textSecondary;
  static const Color lightGray = Color(0xFFC2C2C2);
  static const Color moreLightGray = Color(0xFFEDF1F7);
  static const Color morelighterGray = Color(0xFFF5F5F5);
  static const Color lighterGray = Color(0xFFFDFDFF);
  static const Color darkBlue = textPrimary;
  static const Color moredarkBlue = Color(0xFF616161);
}

import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the user's manual light/dark/system choice and persists it, so the
/// pick survives app restarts. Defaults to [ThemeMode.system].
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(_readInitial());

  static ThemeMode _readInitial() {
    final saved = CacheHelper.getData(key: CacheKeys.themeMode) as String?;
    return switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await CacheHelper.saveData(key: CacheKeys.themeMode, value: mode.name);
  }

  /// Cycles system → light → dark → system, for a single tap toggle.
  Future<void> cycle() async {
    final next = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(next);
  }
}

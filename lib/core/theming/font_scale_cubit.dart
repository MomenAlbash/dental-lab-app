import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The three text sizes offered in settings.
///
/// Deliberately a small, named set rather than a slider: the point is a
/// comfortable default, not fine-grained control, and three options stay
/// testable and predictable at every breakpoint.
enum FontScale {
  small(0.9, 'صغير'),
  medium(1.0, 'وسط'),
  large(1.18, 'كبير');

  const FontScale(this.factor, this.arabicLabel);

  /// Multiplier applied on top of the device's own text scaling.
  final double factor;
  final String arabicLabel;

  static FontScale fromName(String? name) => FontScale.values.firstWhere(
    (scale) => scale.name == name,
    orElse: () => FontScale.medium,
  );
}

/// Holds the user's text size choice and persists it, so it survives restarts.
/// Mirrors [ThemeCubit] — same shape, same storage, same lifetime.
class FontScaleCubit extends Cubit<FontScale> {
  FontScaleCubit() : super(_readInitial());

  static FontScale _readInitial() => FontScale.fromName(
    CacheHelper.getData(key: CacheKeys.fontScale) as String?,
  );

  Future<void> setScale(FontScale scale) async {
    emit(scale);
    await CacheHelper.saveData(key: CacheKeys.fontScale, value: scale.name);
  }
}

/// Applies [scale] on top of whatever the device already asks for.
///
/// The app's own choice multiplies the system setting rather than replacing
/// it: a user who has enlarged text OS-wide must keep that benefit here too
/// (CLAUDE.md §C.1). The system scaler is sampled at a reference size to get
/// its effective factor, which is exact for linear scaling and a close
/// approximation of Android 14+'s non-linear curve.
TextScaler applyFontScale(TextScaler systemScaler, FontScale scale) {
  const reference = 14.0;
  final systemFactor = systemScaler.scale(reference) / reference;
  return TextScaler.linear(systemFactor * scale.factor);
}

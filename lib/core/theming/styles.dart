import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/font_weight_helper.dart';
import 'package:flutter/material.dart';

/// Central text styles, all based on the Tajawal family.
///
/// Sizes are logical (device-independent) — no `.sp`. The framework applies
/// the user's `MediaQuery.textScaler` on top automatically, so we never disable
/// system font scaling (per CLAUDE.md Section C.1).
class AppTextStyles {
  AppTextStyles._();

  static const String _family = 'Tajawal';

  static const TextStyle font28BoldPrimary = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    fontWeight: FontWeightHepler.bold,
    color: AppColorsManger.primary,
  );

  static const TextStyle font24BoldText = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    fontWeight: FontWeightHepler.bold,
    color: AppColorsManger.textPrimary,
  );

  static const TextStyle font20BoldText = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeightHepler.bold,
    color: AppColorsManger.textPrimary,
  );

  static const TextStyle font18MediumText = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    fontWeight: FontWeightHepler.medium,
    color: AppColorsManger.textPrimary,
  );

  static const TextStyle font16MediumText = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeightHepler.medium,
    color: AppColorsManger.textPrimary,
  );

  static const TextStyle font16RegularSecondary = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeightHepler.regular,
    color: AppColorsManger.textSecondary,
  );

  static const TextStyle font14MediumText = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeightHepler.medium,
    color: AppColorsManger.textPrimary,
  );

  static const TextStyle font14RegularSecondary = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeightHepler.regular,
    color: AppColorsManger.textSecondary,
  );

  static const TextStyle font14BoldWhite = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeightHepler.bold,
    color: Colors.white,
  );

  static const TextStyle font13MediumPrimary = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeightHepler.medium,
    color: AppColorsManger.primary,
  );

  static const TextStyle font12RegularHint = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeightHepler.regular,
    color: AppColorsManger.textHint,
  );
}

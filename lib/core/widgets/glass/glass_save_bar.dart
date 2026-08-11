import 'dart:ui';

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:flutter/material.dart';

/// Blurred bar pinned to the bottom of a form, holding its primary save
/// action.
///
/// Every form screen (doctor, patient, clinic, ...) used to carry its own
/// copy of this widget with only the label swapped — consolidated here so a
/// styling change lands everywhere at once.
class GlassSaveBar extends StatelessWidget {
  const GlassSaveBar({
    super.key,
    required this.isSubmitting,
    required this.label,
    required this.onSave,
  });

  final bool isSubmitting;
  final String label;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border(top: BorderSide(color: glass.strokeColor)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              // The bar owns the blurred surface; the button itself is the
              // app's shared one, so it picks up the themed colours and
              // loading state rather than restating them here.
              child: CustomButtonWidget(
                buttonText: label,
                icon: Icons.check_rounded,
                onPressed: onSave,
                isLoading: isSubmitting,
                buttonWidth: double.infinity,
                buttonHeight: 52,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:ui';

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';

/// The base glass pane every other glass widget builds on.
///
/// [blur] controls whether a real [BackdropFilter] is used. It is `false` by
/// default on purpose: a BackdropFilter forces its own saved layer, and one per
/// row inside a `ListView.builder` tanks scroll performance on low-end devices.
/// Reserve `blur: true` for the small, fixed set of floating surfaces (app bar,
/// drawer, sheets, dialogs, FAB). Repeating list content should stay `false` —
/// over the gradient backdrop the translucent fill still reads as glass.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = false,
    this.blurSigma,
    this.borderRadius,
    this.padding,
    this.margin,
    this.showShadow = true,
    this.showBorder = true,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final bool blur;
  final double? blurSigma;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool showShadow;
  final bool showBorder;

  /// Overrides the themed surface fill (used by the drawer's darker pane).
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.glass);

    Widget pane = DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? glass.surfaceGradient,
        borderRadius: radius,
        border: showBorder
            ? Border.all(color: glass.strokeColor, width: 1)
            : null,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (blur) {
      pane = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurSigma ?? glass.blurSigma,
          sigmaY: blurSigma ?? glass.blurSigma,
        ),
        child: pane,
      );
    }

    return Container(
      width: width,
      height: height,
      margin: margin,
      // The shadow must be painted outside the clip, so it lives on this
      // wrapper rather than on the clipped pane itself.
      decoration: showShadow
          ? BoxDecoration(borderRadius: radius, boxShadow: glass.shadows)
          : null,
      child: ClipRRect(borderRadius: radius, child: pane),
    );
  }
}

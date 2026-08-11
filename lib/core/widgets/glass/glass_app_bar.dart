import 'dart:ui';

import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';

/// A translucent, blurred app bar that content scrolls underneath.
///
/// This is one of the fixed-count floating surfaces where a real
/// [BackdropFilter] is worth its cost.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.bottom,
    this.centerTitle = true,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: AppBar(
          title: title,
          actions: actions,
          leading: leading,
          bottom: bottom,
          centerTitle: centerTitle,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          foregroundColor: glass.onGlass,
          elevation: 0,
          scrolledUnderElevation: 0,
          flexibleSpace: DecoratedBox(
            decoration: BoxDecoration(gradient: glass.surfaceGradient),
          ),
          // Hairline separating the bar from the content beneath it.
          shape: Border(
            bottom: BorderSide(color: glass.strokeColor, width: 0.6),
          ),
        ),
      ),
    );
  }
}

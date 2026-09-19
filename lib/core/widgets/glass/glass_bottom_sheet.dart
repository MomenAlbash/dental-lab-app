import 'dart:ui';

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';

/// Shows [builder] inside a blurred glass sheet with a drag handle.
///
/// Mirrors `showModalBottomSheet`'s contract (returns the popped value) so
/// existing call sites only need the function name swapped.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (sheetContext) => GlassSheetSurface(child: builder(sheetContext)),
  );
}

/// The blurred pane used by [showGlassBottomSheet]. Exposed separately so a
/// sheet that needs custom presentation can still reuse the surface.
class GlassSheetSurface extends StatelessWidget {
  const GlassSheetSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    const radius = Radius.circular(AppRadius.glassLg);

    return ClipRRect(
      borderRadius: const BorderRadius.only(topLeft: radius, topRight: radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: glass.blurSigma,
          sigmaY: glass.blurSigma,
        ),
        child: Stack(
          children: [
            // The app's own backdrop, carried by the sheet rather than
            // borrowed from whatever it happens to cover.
            //
            // A glass pane takes its colour from what is behind it, which
            // works while a sheet covers part of a page. A tall form covers
            // the whole screen, and the only thing left behind it is the
            // neutral end of the background — so the sheet rendered flat grey
            // and read as a different app. Kept translucent, so a short sheet
            // still shows the real page through it.
            Positioned.fill(
              child: Opacity(
                opacity: 0.55,
                child: DecoratedBox(
                  decoration: BoxDecoration(gradient: glass.backdropGradient),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: glass.surfaceGradient,
                border: Border(top: BorderSide(color: glass.strokeColor)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: glass.onGlassMuted.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                    ),
                    Flexible(child: child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

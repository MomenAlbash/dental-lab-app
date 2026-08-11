import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A single shimmering placeholder bar.
class GlassSkeletonBox extends StatelessWidget {
  const GlassSkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.shape = BoxShape.rectangle,
  });

  final double? width;
  final double height;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: glass.onGlassMuted.withValues(alpha: 0.18),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

/// Placeholder the size and shape of an input, shown while the options behind
/// a picker load.
///
/// Replaces the "جارٍ تحميل..." hint inside a disabled dropdown: the layout no
/// longer shifts when the real control arrives, and the shimmer reads as
/// "working" without spelling it out.
class GlassFieldSkeleton extends StatelessWidget {
  const GlassFieldSkeleton({super.key, this.height = 52});

  final double height;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: glass.fillColor,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            border: Border.all(color: glass.strokeColor),
          ),
          child: Row(
            children: [
              const GlassSkeletonBox(width: 20, height: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GlassSkeletonBox(width: height * 2.2, height: 12),
                ),
              ),
              const GlassSkeletonBox(width: 16, height: 16),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: glass.glowColor,
        );
  }
}

/// Placeholder list shown while records load — replaces the bare spinner so the
/// screen keeps its shape and the wait feels shorter.
class GlassListSkeleton extends StatelessWidget {
  const GlassListSkeleton({
    super.key,
    this.itemCount = 6,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ListView.builder(
          padding: padding,
          itemCount: itemCount,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: glass.surfaceGradient,
              borderRadius: BorderRadius.circular(AppRadius.glass),
              border: Border.all(color: glass.strokeColor),
            ),
            child: const Row(
              children: [
                GlassSkeletonBox(width: 44, height: 44, shape: BoxShape.circle),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassSkeletonBox(width: 140),
                      SizedBox(height: AppSpacing.sm),
                      GlassSkeletonBox(width: 90, height: 11),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1400),
          color: glass.glowColor,
        );
  }
}

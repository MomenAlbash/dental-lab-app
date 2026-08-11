import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// One attribute in a [GlassInfoTiles] mosaic.
class GlassInfoTile {
  const GlassInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String? value;

  /// Tint for the icon chip — it is what lets the eye group related fields.
  final Color color;

  /// Free-text fields (an address, a note) take a full-width row instead of a
  /// grid cell they would overflow.
  final bool wide;

  bool get hasValue => value != null && value!.trim().isNotEmpty;
}

/// Entity attributes as a tile mosaic.
///
/// A divided label/value list gives every field the same weight and reads like
/// a printed record. Tiles let the eye jump straight to a field, and the
/// accent-tinted icon chips carry the brand into the body of the screen.
class GlassInfoTiles extends StatelessWidget {
  const GlassInfoTiles({super.key, required this.tiles});

  final List<GlassInfoTile> tiles;

  @override
  Widget build(BuildContext context) {
    final narrow = tiles.where((t) => !t.wide).toList();
    final wide = tiles.where((t) => t.wide).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Three across once there is room; two on a phone. Laid out with a
        // Wrap rather than a GridView so tiles size to their content and never
        // clip at large text scales.
        final columns = constraints.maxWidth >= 520 ? 3 : 2;
        const spacing = AppSpacing.md;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (narrow.isNotEmpty)
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final tile in narrow)
                    SizedBox(
                      width: tileWidth,
                      child: _Tile(data: tile),
                    ),
                ],
              ),
            for (final tile in wide) ...[
              const SizedBox(height: spacing),
              _Tile(data: tile),
            ],
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.data});

  final GlassInfoTile data;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final icon = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.md + 2),
        color: data.color.withValues(alpha: 0.14),
      ),
      child: Icon(data.icon, size: 18, color: data.color),
    );

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.label,
          style: AppTextStyles.font12RegularHint.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          data.hasValue ? data.value!.trim() : '—',
          maxLines: data.wide ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.font14MediumText.copyWith(
            color: data.hasValue ? glass.onGlass : glass.onGlassMuted,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: data.wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                icon,
                const SizedBox(width: AppSpacing.md),
                Expanded(child: text),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                icon,
                const SizedBox(height: AppSpacing.sm),
                text,
              ],
            ),
    );
  }
}

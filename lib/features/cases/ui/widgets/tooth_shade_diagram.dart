import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/shade_guide.dart';
import 'package:flutter/material.dart';

/// The tooth split into its three clinical zones (cervical/middle/incisal),
/// each tappable to pick a shade from the active [ShadeGuide]. Matches the
/// "Vita" shade-picker design: a single tooth silhouette with three bands.
class ToothShadeDiagram extends StatelessWidget {
  const ToothShadeDiagram({
    super.key,
    required this.guide,
    required this.cervical,
    required this.middle,
    required this.incisal,
    required this.onCervicalChanged,
    required this.onMiddleChanged,
    required this.onIncisalChanged,
  });

  final ShadeGuide guide;
  final String? cervical;
  final String? middle;
  final String? incisal;
  final ValueChanged<String?> onCervicalChanged;
  final ValueChanged<String?> onMiddleChanged;
  final ValueChanged<String?> onIncisalChanged;

  Future<void> _pickShade(
    BuildContext context,
    String zoneLabel,
    String? current,
    ValueChanged<String?> onChanged,
  ) async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      builder: (context) =>
          _ShadePickerSheet(title: zoneLabel, guide: guide, current: current),
    );
    if (picked != null) onChanged(picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ClipPath(
        clipper: _ToothClipper(),
        child: Column(
          children: [
            Expanded(
              child: _ShadeZone(
                label: 'العنقي',
                value: cervical,
                color: context.glass.mutedSurface,
                onTap: () =>
                    _pickShade(context, 'العنقي', cervical, onCervicalChanged),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: _ShadeZone(
                label: 'الوسط',
                value: middle,
                color: context.glass.mutedSurface,
                onTap: () =>
                    _pickShade(context, 'الوسط', middle, onMiddleChanged),
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: _ShadeZone(
                label: 'القاطع',
                value: incisal,
                color: context.glass.mutedSurface,
                onTap: () =>
                    _pickShade(context, 'القاطع', incisal, onIncisalChanged),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShadeZone extends StatelessWidget {
  const _ShadeZone({
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String? value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        color: color,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: context.glass.onGlassMuted,
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                value!,
                style: AppTextStyles.font16MediumText.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShadePickerSheet extends StatelessWidget {
  const _ShadePickerSheet({
    required this.title,
    required this.guide,
    required this.current,
  });

  final String title;
  final ShadeGuide guide;
  final String? current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'لون $title (${guide.label})',
              style: AppTextStyles.font16MediumText,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final shade in guide.shades)
                  ChoiceChip(
                    label: Text(shade),
                    selected: shade == current,
                    onSelected: (_) => Navigator.of(context).pop(shade),
                  ),
              ],
            ),
            if (current != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(''),
                child: const Text('مسح الاختيار'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A rounded tooth silhouette — wide at the cervical (gum) edge, tapering
/// toward the incisal edge.
class _ToothClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.95, 0, w, h * 0.25, w * 0.85, h * 0.45)
      ..cubicTo(w * 0.78, h * 0.65, w * 0.72, h * 0.85, w * 0.6, h)
      ..quadraticBezierTo(w * 0.5, h * 1.05, w * 0.4, h)
      ..cubicTo(w * 0.28, h * 0.85, w * 0.22, h * 0.65, w * 0.15, h * 0.45)
      ..cubicTo(0, h * 0.25, w * 0.05, 0, w * 0.5, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

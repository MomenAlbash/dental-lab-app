import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Label/value row used across detail screens (employee, doctor, etc).
class DetailInfoRowWidget extends StatelessWidget {
  const DetailInfoRowWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    // Reads the glass tokens so the row stays legible on a translucent card in
    // both themes, instead of the fixed light-mode greys it used before.
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: glass.onGlassMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

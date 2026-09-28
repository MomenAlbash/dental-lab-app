import 'package:dental_lab_app/core/helper/laboratory_identity.dart';
import 'package:dental_lab_app/core/helper/laboratory_scope.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Which laboratory a record belongs to — a coloured initials dot and the
/// name, the same colour everywhere for the same laboratory.
///
/// Draws nothing unless several laboratories are in view: with one, every
/// card would carry the same badge, which is noise rather than information.
class LaboratoryBadge extends StatelessWidget {
  const LaboratoryBadge({
    super.key,
    required this.laboratoryId,
    this.fallbackName,
  });

  final String? laboratoryId;

  /// The name the record itself carried, used when the laboratory is not
  /// among the selected ones (it should always be — this is a safety net).
  final String? fallbackName;

  /// Mid-tones that stay legible as text and as a fill in light and dark.
  /// Fixed order: [LaboratoryIdentity.colorIndexFor] indexes into it.
  static const _palette = <Color>[
    Color(0xFF0E7C86),
    Color(0xFF5B5BD6),
    Color(0xFFD9622B),
    Color(0xFFC2417A),
    Color(0xFF2E8B57),
    Color(0xFF8E44AD),
    Color(0xFF9A6B3F),
    Color(0xFF1F77B4),
  ];

  static Color colorFor(String laboratoryId) =>
      _palette[LaboratoryIdentity.colorIndexFor(laboratoryId) %
          _palette.length];

  @override
  Widget build(BuildContext context) {
    final id = laboratoryId;
    if (id == null || id.isEmpty || !LaboratoryScope.isMulti) {
      return const SizedBox.shrink();
    }

    final name = LaboratoryScope.nameOf(id) ?? fallbackName ?? '';
    final color = colorFor(id);

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 2, 8, 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 9,
            backgroundColor: color,
            child: Text(
              LaboratoryIdentity.initialsOf(name),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              name.isEmpty ? 'مخبر' : name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

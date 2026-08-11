import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// A currency row — matches the doctor/employee/role card: an accent rail,
/// a symbol avatar, then name/code.
class CurrencyListItemWidget extends StatelessWidget {
  const CurrencyListItemWidget({
    super.key,
    required this.name,
    required this.code,
    required this.symbol,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  final String name;
  final String code;
  final String symbol;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: accent),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: glass.brandGradient,
                              ),
                              child: Text(
                                symbol.isEmpty ? code : symbol,
                                style: AppTextStyles.font14MediumText.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font14MediumText
                                        .copyWith(color: glass.onGlass),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    code,
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.onGlassMuted),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'تعديل',
                              onPressed: onEdit,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: glass.onGlassMuted,
                              ),
                            ),
                            IconButton(
                              tooltip: 'حذف',
                              onPressed: onDelete,
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.delete_outline,
                                size: 20,
                                color: glass.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

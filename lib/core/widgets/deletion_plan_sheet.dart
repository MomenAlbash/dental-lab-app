import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/deletion/data/models/deletion_plan_model.dart';
import 'package:dental_lab_app/features/deletion/data/repos/deletion_repo.dart';
import 'package:flutter/material.dart';

/// Deletes a row, saying first what stands in the way.
///
/// Lives in `core/` because it is the same flow for every entity: the screen
/// hands over an entity type and an id, and this asks the server what would
/// have to happen, shows it, and offers only what is safe to offer.
///
/// **The two kinds of blocker are drawn differently on purpose.** A hard stop
/// is transactional history — a doctor with patients, a restoration type on
/// real cases — and gets a plain sentence with no button, because a wizard
/// that offered to clear those is how somebody erases a year of records. A
/// resolvable step is one a service explicitly judged safe, and its rows are
/// offered one at a time — each through this same sheet, so clearing one can
/// surface the next.
///
/// Returns true when the row was actually deleted.
Future<bool> showDeletionPlanSheet(
  BuildContext context, {
  required String entityType,
  required String id,
  required String title,
}) async {
  final deleted = await showGlassBottomSheet<bool>(
    context: context,
    builder: (_) =>
        _DeletionPlanSheet(entityType: entityType, id: id, title: title),
  );
  return deleted ?? false;
}

class _DeletionPlanSheet extends StatefulWidget {
  const _DeletionPlanSheet({
    required this.entityType,
    required this.id,
    required this.title,
  });

  final String entityType;
  final String id;
  final String title;

  @override
  State<_DeletionPlanSheet> createState() => _DeletionPlanSheetState();
}

class _DeletionPlanSheetState extends State<_DeletionPlanSheet> {
  DeletionPlanModel? _plan;
  String? _error;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    setState(() {
      _plan = null;
      _error = null;
    });

    final result = await getIt<DeletionRepo>().getPlan(
      entityType: widget.entityType,
      id: widget.id,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _error = failure.errorMessage),
      (plan) => setState(() => _plan = plan),
    );
  }

  Future<void> _delete() async {
    setState(() => _isBusy = true);

    final result = await getIt<DeletionRepo>().delete(
      entityType: widget.entityType,
      id: widget.id,
    );
    if (!mounted) return;

    setState(() => _isBusy = false);

    result.fold(
      (failure) {
        // The plan is guidance; the server is the authority. When the two
        // disagree it is because something changed under us — say what the
        // server said and reload the plan rather than insisting.
        showToast(message: failure.errorMessage, state: ToastState.error);
        _loadPlan();
      },
      (_) => Navigator.of(context).pop(true),
    );
  }

  /// Clears one blocking row — through this same sheet, because removing it
  /// can itself turn up a further blocker of its own.
  Future<void> _resolve(
    DeletionBlockerStepModel step,
    DeletionBlockerItemModel item,
  ) async {
    final entityType = step.entityType;
    if (entityType == null) return;

    final removed = await showDeletionPlanSheet(
      context,
      entityType: entityType,
      id: item.id,
      title: item.displayLabel,
    );
    if (removed && mounted) await _loadPlan();
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final plan = _plan;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'حذف ${widget.title}',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_error != null)
            Text(
              _error!,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.error,
              ),
            )
          else if (plan == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (plan.canDelete)
              Text(
                'لا يوجد ما يمنع الحذف. لا يمكن التراجع بعد التأكيد.',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlass,
                ),
              ),

            if (plan.hardStops.isNotEmpty) ...[
              const _GroupLabel('لا يمكن الحذف بسبب'),
              for (final stop in plan.hardStops)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.block, size: 16, color: glass.error),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          stop,
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: glass.onGlass,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (plan.resolvableSteps.isNotEmpty) ...[
              const _GroupLabel('يجب حذف هذه أولاً'),
              for (final step in plan.resolvableSteps) ...[
                if (step.message?.trim().isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      step.message!,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ),
                for (final item in step.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_left,
                          size: 16,
                          color: glass.onGlassMuted,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            item.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.font14RegularSecondary
                                .copyWith(color: glass.onGlass),
                          ),
                        ),
                        TextButton(
                          onPressed: _isBusy
                              ? null
                              : () => _resolve(step, item),
                          child: const Text('حذف'),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],

            if (plan.isBlockedOutright && plan.hardStops.isEmpty)
              Text(
                // Refused with nothing named — rare, but the sheet must not
                // sit blank and let the user assume it is still loading.
                'لا يمكن حذف هذا العنصر حالياً',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),

            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: glass.error,
                    ),
                    // Offered only when the server says nothing stands in the
                    // way: a delete button that exists to be refused teaches
                    // users to ignore what this sheet says.
                    onPressed: _isBusy || !plan.canDelete ? null : _delete,
                    child: const Text('حذف نهائي'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.font14MediumText.copyWith(
          color: context.glass.onGlass,
        ),
      ),
    );
  }
}

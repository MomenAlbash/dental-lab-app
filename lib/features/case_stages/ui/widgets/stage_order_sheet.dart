import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:flutter/material.dart';

/// Puts the lab's case stages in running order by dragging them.
///
/// This is where a workflow is shaped now. The API keeps no transition table —
/// a case runs the stages of its intake in `order`, so the first stage is
/// simply the one at the top of this list, and there is no "starting stage"
/// flag to set anywhere.
///
/// Returns true when an order was saved, so the caller can reload.
Future<bool?> showStageOrderSheet(
  BuildContext context, {
  required List<CaseStageModel> stages,
}) {
  return showGlassBottomSheet<bool>(
    context: context,
    builder: (_) => _StageOrderSheet(stages: stages),
  );
}

class _StageOrderSheet extends StatefulWidget {
  const _StageOrderSheet({required this.stages});

  final List<CaseStageModel> stages;

  @override
  State<_StageOrderSheet> createState() => _StageOrderSheetState();
}

class _StageOrderSheetState extends State<_StageOrderSheet> {
  late final List<CaseStageModel> _ordered = [...widget.stages]
    ..sort((a, b) => a.order.compareTo(b.order));

  bool _isSaving = false;

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final result = await getIt<CaseStagesRepo>().saveOrder(_ordered);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _isSaving = false);
        showToast(message: failure.errorMessage, state: ToastState.error);
      },
      (_) {
        showToast(message: 'تم حفظ الترتيب', state: ToastState.success);
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            AppSpacing.cardPadding,
            AppSpacing.cardPadding,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ترتيب المراحل',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'الحالة تمشي بهذا الترتيب — الأولى في الأعلى. اسحب المرحلة '
                'لتغيير موقعها.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
        Flexible(
          child: ReorderableListView.builder(
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.cardPadding,
            ),
            itemCount: _ordered.length,
            onReorderItem: (oldIndex, newIndex) => setState(() {
              final moved = _ordered.removeAt(oldIndex);
              _ordered.insert(newIndex, moved);
            }),
            itemBuilder: (context, index) {
              final stage = _ordered[index];

              return Container(
                key: ValueKey(stage.id),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: glass.surfaceGradient,
                  borderRadius: BorderRadius.circular(AppRadius.glass),
                  border: Border.all(color: glass.strokeColor),
                ),
                child: Row(
                  children: [
                    Text(
                      '${index + 1}',
                      style: AppTextStyles.font14MediumText.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage.displayName.isEmpty ? '—' : stage.displayName,
                            style: AppTextStyles.font14MediumText.copyWith(
                              color: glass.onGlass,
                            ),
                          ),
                          // The intake fork matters here: two stages can share
                          // a position because each runs on a different head
                          // of the route.
                          Text(
                            [
                              stage.appliesTo.label,
                              stage.timing.arabicLabel,
                              if (stage.isOptional) 'اختيارية',
                              if (!stage.isActive) 'معطّلة',
                            ].join(' • '),
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle, color: glass.onGlassMuted),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: CustomButtonWidget(
            buttonText: _isSaving ? 'جارٍ الحفظ...' : 'حفظ الترتيب',
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ],
    );
  }
}

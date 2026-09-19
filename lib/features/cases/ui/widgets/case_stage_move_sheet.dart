import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_move_model.dart';
import 'package:flutter/material.dart';

/// What the user chose to do with the case.
typedef CaseStageMoveResult = ({
  String toStageId,
  String? note,
  String? rejectionReason,
});

/// Moves the case to another stage, offering only what the server allows.
///
/// The list comes from `availableTransitions` on the case, never from a
/// client-side reading of the workflow: the production barrier, the parallel
/// step and the declared rework target are all server rules, and a locally
/// computed list would offer moves that get refused.
Future<CaseStageMoveResult?> showCaseStageMoveSheet(
  BuildContext context, {
  required List<CaseStageMoveModel> transitions,
  Set<String> barredStageIds = const {},
  String? barredReason,
}) {
  return showGlassBottomSheet<CaseStageMoveResult>(
    context: context,
    builder: (_) => _CaseStageMoveSheet(
      transitions: transitions,
      barredStageIds: barredStageIds,
      barredReason: barredReason,
    ),
  );
}

class _CaseStageMoveSheet extends StatefulWidget {
  const _CaseStageMoveSheet({
    required this.transitions,
    required this.barredStageIds,
    required this.barredReason,
  });

  final List<CaseStageMoveModel> transitions;

  /// Targets the client knows are unreachable right now even if the server
  /// offered them — an after-production stage while pieces are still running.
  final Set<String> barredStageIds;
  final String? barredReason;

  @override
  State<_CaseStageMoveSheet> createState() => _CaseStageMoveSheetState();
}

class _CaseStageMoveSheetState extends State<_CaseStageMoveSheet> {
  final _noteController = TextEditingController();
  final _reasonController = TextEditingController();

  CaseStageMoveModel? _selected;

  /// Set once the user tries to submit without the reason a move demands — the
  /// field is not scolded before they have had a chance to fill it.
  bool _reasonTouched = false;

  late final List<CaseStageMoveModel> _sorted = [
    for (final move in widget.transitions)
      // A locally barred target is rendered exactly like a server-barred
      // one: shown, disabled, with the reason — hiding it would leave the
      // user hunting for a move that is simply not available yet.
      if (widget.barredStageIds.contains(move.toStageId))
        CaseStageMoveModel(
          toStageId: move.toStageId,
          toStageName: move.toStageName,
          toStageNameAr: move.toStageNameAr,
          kind: move.kind,
          requiresReason: move.requiresReason,
          blockedReason: move.blockedReason ?? widget.barredReason,
          displayOrder: move.displayOrder,
        )
      else
        move,
  ]..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

  @override
  void dispose() {
    _noteController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _reasonMissing =>
      (_selected?.requiresReason ?? false) &&
      _reasonController.text.trim().isEmpty;

  void _submit() {
    final selected = _selected;
    if (selected == null || selected.isBlocked) return;

    if (_reasonMissing) {
      setState(() => _reasonTouched = true);
      return;
    }

    final note = _noteController.text.trim();
    final reason = _reasonController.text.trim();

    Navigator.of(context).pop((
      toStageId: selected.toStageId,
      note: note.isEmpty ? null : note,
      rejectionReason: reason.isEmpty ? null : reason,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final forward = [
      for (final move in _sorted)
        if (!move.kind.isRework) move,
    ];
    final rework = [
      for (final move in _sorted)
        if (move.kind.isRework) move,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'نقل الحالة',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'الخيارات المعروضة هي ما يسمح به المسار الآن',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Not an error: a case mid-production is waiting on its
            // restorations, and saying so beats an empty sheet.
            if (_sorted.isEmpty)
              Text(
                'لا يوجد نقل متاح الآن — الحالة تنتظر انتهاء تعويضاتها أو '
                'إجراءً آخر.',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),

            if (forward.isNotEmpty) ...[
              const _GroupLabel('إلى الأمام'),
              for (final move in forward)
                _MoveTile(
                  move: move,
                  isSelected: _selected?.toStageId == move.toStageId,
                  onTap: () => setState(() => _selected = move),
                ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (rework.isNotEmpty) ...[
              const _GroupLabel('إرجاع لإعادة العمل'),
              for (final move in rework)
                _MoveTile(
                  move: move,
                  isSelected: _selected?.toStageId == move.toStageId,
                  onTap: () => setState(() => _selected = move),
                ),
              const SizedBox(height: AppSpacing.md),
            ],

            if (_selected != null) ...[
              const SizedBox(height: AppSpacing.sm),
              if (_selected!.requiresReason) ...[
                const _GroupLabel('السبب'),
                AppTextFormField(
                  controller: _reasonController,
                  hintText: 'هذه المرحلة لا تُقبل بدون سبب مكتوب',
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                  validator: (_) => null,
                ),
                if (_reasonTouched && _reasonMissing)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'السبب مطلوب لهذه المرحلة',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.warning,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
              const _GroupLabel('ملاحظة (اختيارية)'),
              AppTextFormField(
                controller: _noteController,
                hintText: 'تُحفظ في سجل الحالة',
                maxLines: 2,
                validator: (_) => null,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            CustomButtonWidget(
              buttonText: 'نقل الحالة',
              // A blocked move stays visible but unusable — see [_MoveTile].
              onPressed: _selected == null || _selected!.isBlocked
                  ? null
                  : _submit,
            ),
          ],
        ),
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

/// One offered move.
///
/// A barred move is shown disabled with the server's own explanation rather
/// than hidden: a case with no visible options and no reason reads as stuck.
class _MoveTile extends StatelessWidget {
  const _MoveTile({
    required this.move,
    required this.isSelected,
    required this.onTap,
  });

  final CaseStageMoveModel move;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = move.kind.isRework
        ? glass.warning
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: move.isBlocked ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.glass),
          child: Opacity(
            opacity: move.isBlocked ? 0.55 : 1,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? accent : glass.strokeColor,
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(AppRadius.glass),
              ),
              child: Row(
                children: [
                  Icon(
                    move.kind.isRework
                        ? Icons.undo_outlined
                        : Icons.arrow_forward,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          move.displayName.isEmpty ? '—' : move.displayName,
                          style: AppTextStyles.font14MediumText.copyWith(
                            color: glass.onGlass,
                          ),
                        ),
                        if (move.isBlocked)
                          Text(
                            move.blockedReason!,
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.warning,
                            ),
                          )
                        else if (move.requiresReason)
                          Text(
                            'تتطلب سبباً مكتوباً',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

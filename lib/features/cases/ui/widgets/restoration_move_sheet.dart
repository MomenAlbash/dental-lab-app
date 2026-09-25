import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/send_back_models.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/send_back_reason_fields.dart';
import 'package:flutter/material.dart';

/// What the user chose to do with the piece. [reason] is empty on a forward
/// move — only a send-back has a why.
typedef RestorationMoveResult = ({
  String stageId,
  String? note,
  SendBackReason reason,
});

/// Moves one restoration along its route — the same shape as the case's move
/// sheet, because it is the same question asked about a smaller thing.
///
/// **Both directions are fetched, never computed.** Forward comes from
/// `forward-targets`: the next step is the stage's declared `nextStageId` or
/// the following position in the case's *frozen* plan, and parallel steps mean
/// there can be more than one — a client walking the restoration type's live
/// route gets all three of those wrong the moment a lab edits a route
/// mid-case. Backward comes from `rework-targets` for the same reason.
Future<RestorationMoveResult?> showRestorationMoveSheet(
  BuildContext context, {
  required String caseId,
  required String restorationId,
}) {
  return showGlassBottomSheet<RestorationMoveResult>(
    context: context,
    builder: (_) =>
        _RestorationMoveSheet(caseId: caseId, restorationId: restorationId),
  );
}

class _RestorationMoveSheet extends StatefulWidget {
  const _RestorationMoveSheet({
    required this.caseId,
    required this.restorationId,
  });

  final String caseId;
  final String restorationId;

  @override
  State<_RestorationMoveSheet> createState() => _RestorationMoveSheetState();
}

class _RestorationMoveSheetState extends State<_RestorationMoveSheet> {
  final _noteController = TextEditingController();

  List<CaseWorkflowStageModel>? _forwardTargets;
  List<CaseWorkflowStageModel>? _reworkTargets;
  String? _selectedStageId;

  /// Why the piece goes back — asked only when a rework target is chosen.
  SendBackReason _reason = const SendBackReason();

  bool get _isSendBack =>
      _reworkTargets?.any((s) => s.id == _selectedStageId) ?? false;

  /// A breakage whose loss is incomplete cannot be sent: the server refuses
  /// it, so the button waits instead.
  bool get _canSubmit =>
      _selectedStageId != null && (!_isSendBack || _reason.problem == null);

  @override
  void initState() {
    super.initState();
    _loadTargets();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadTargets() async {
    final repo = getIt<CasesRepo>();

    // Both at once: they are independent reads, and asking in sequence makes
    // the sheet feel twice as slow on a lab's connection.
    final results = await Future.wait([
      repo.getForwardTargets(
        caseId: widget.caseId,
        restorationId: widget.restorationId,
      ),
      repo.getReworkTargets(
        caseId: widget.caseId,
        restorationId: widget.restorationId,
      ),
    ]);
    if (!mounted) return;

    // One side failing leaves the other usable rather than blocking the whole
    // sheet — an empty list reads as "nothing on offer this way", which is
    // also what the server answers when there genuinely is nothing.
    setState(() {
      _forwardTargets = results[0].fold((_) => const [], (targets) => targets);
      _reworkTargets = results[1].fold((_) => const [], (targets) => targets);
    });
  }

  void _submit() {
    final stageId = _selectedStageId;
    if (stageId == null) return;

    final note = _noteController.text.trim();
    Navigator.of(context).pop((
      stageId: stageId,
      note: note.isEmpty ? null : note,
      reason: _isSendBack ? _reason : const SendBackReason(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final forward = _forwardTargets;
    final rework = _reworkTargets;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'نقل التعويض',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const _GroupLabel('إلى الأمام'),
            if (forward == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (forward.isEmpty)
              Text(
                'التعويض على آخر مرحلة في مساره',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              )
            else
              // More than one when the plan forks: stages sharing an `order`
              // run in parallel, and the piece may be sent to any of them.
              for (final stage in forward)
                _MoveTile(
                  label: stage.displayName,
                  icon: Icons.arrow_forward,
                  isSelected: _selectedStageId == stage.id,
                  onTap: () => setState(() => _selectedStageId = stage.id),
                ),

            const SizedBox(height: AppSpacing.lg),
            const _GroupLabel('إرجاع لإعادة العمل'),
            if (rework == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rework.isEmpty)
              Text(
                'لا توجد مرحلة يمكن الإرجاع إليها',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              )
            else
              for (final stage in rework)
                _MoveTile(
                  label: stage.displayName,
                  icon: Icons.undo_outlined,
                  isRework: true,
                  isSelected: _selectedStageId == stage.id,
                  onTap: () => setState(() => _selectedStageId = stage.id),
                ),

            if (_isSendBack) ...[
              const SizedBox(height: AppSpacing.lg),
              SendBackReasonFields(
                caseId: widget.caseId,
                restorationId: widget.restorationId,
                targetStageId: _selectedStageId!,
                value: _reason,
                onChanged: (reason) => setState(() => _reason = reason),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            const _GroupLabel('ملاحظة (اختيارية)'),
            AppTextFormField(
              controller: _noteController,
              hintText: 'تُحفظ في سجل التعويض',
              maxLines: 2,
              validator: (_) => null,
            ),
            const SizedBox(height: AppSpacing.lg),

            CustomButtonWidget(
              buttonText: 'نقل التعويض',
              onPressed: _canSubmit ? _submit : null,
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

class _MoveTile extends StatelessWidget {
  const _MoveTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.isRework = false,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isRework;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = isRework
        ? glass.warning
        : Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.glass),
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
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label.isEmpty ? '—' : label,
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

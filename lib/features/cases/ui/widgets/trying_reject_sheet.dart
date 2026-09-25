import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/send_back_models.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/send_back_reason_fields.dart';
import 'package:flutter/material.dart';

/// What the user decided: which pieces the doctor refused, and the overall
/// reason recorded on the case.
typedef TryingRejectResult = ({List<TryingRejectLine> lines, String? note});

/// Records a refused trying: the doctor did not accept the fit.
///
/// Not a per-piece action repeated N times — the server takes the whole
/// decision in one request, moving the case back into production and writing
/// one history row per flagged piece. A piece the doctor was happy with is
/// simply left unticked and stays where it is.
///
/// Where each piece goes back to is fetched per restoration (`rework-targets`),
/// never guessed: the declared send-back target, and the "any earlier stage"
/// fallback when none is declared, are the server's to decide.
Future<TryingRejectResult?> showTryingRejectSheet(
  BuildContext context, {
  required String caseId,
  required List<CaseRestorationModel> restorations,
}) {
  return showGlassBottomSheet<TryingRejectResult>(
    context: context,
    builder: (_) =>
        _TryingRejectSheet(caseId: caseId, restorations: restorations),
  );
}

class _TryingRejectSheet extends StatefulWidget {
  const _TryingRejectSheet({required this.caseId, required this.restorations});

  final String caseId;
  final List<CaseRestorationModel> restorations;

  @override
  State<_TryingRejectSheet> createState() => _TryingRejectSheetState();
}

class _TryingRejectSheetState extends State<_TryingRejectSheet> {
  final _noteController = TextEditingController();

  /// Rework targets per restoration id. A missing key is still loading; an
  /// empty list is the server saying there is nowhere to send this one back.
  final Map<String, List<CaseWorkflowStageModel>> _targets = {};

  final Set<String> _selected = {};
  final Map<String, String> _stageOf = {};

  /// Why each flagged piece goes back — a breakage carries its own loss.
  final Map<String, SendBackReason> _reasonOf = {};

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

    // In parallel: a case with eight units would otherwise open its sheet
    // eight round-trips late.
    await Future.wait([
      for (final restoration in widget.restorations)
        repo
            .getReworkTargets(
              caseId: widget.caseId,
              restorationId: restoration.id,
            )
            .then((result) {
              if (!mounted) return;
              setState(() {
                _targets[restoration.id] = result.fold(
                  (_) => const [],
                  (targets) => targets,
                );
              });
            }),
    ]);
  }

  /// Every ticked piece must name where it goes — the server rejects a line
  /// without one, so the button stays disabled rather than failing later.
  bool get _canSubmit =>
      _selected.isNotEmpty &&
      _selected.every((id) => _stageOf[id]?.isNotEmpty ?? false) &&
      // A breakage with an incomplete loss is refused by the server.
      _selected.every((id) => _reasonOf[id]?.problem == null);

  void _submit() {
    final note = _noteController.text.trim();

    Navigator.of(context).pop((
      lines: [
        for (final id in _selected)
          TryingRejectLine(
            restorationId: id,
            stageId: _stageOf[id]!,
            reason: _reasonOf[id] ?? const SendBackReason(),
          ),
      ],
      note: note.isEmpty ? null : note,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'رفض التجربة',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر التعويضات التي رفضها الطبيب، وحدّد المرحلة التي يعود إليها كل منها',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            if (widget.restorations.isEmpty)
              Text(
                'لا توجد تعويضات على هذه الحالة',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              )
            else
              for (final restoration in widget.restorations)
                _RestorationLine(
                  caseId: widget.caseId,
                  restoration: restoration,
                  reason: _reasonOf[restoration.id] ?? const SendBackReason(),
                  onReasonChanged: (reason) =>
                      setState(() => _reasonOf[restoration.id] = reason),
                  targets: _targets[restoration.id],
                  isSelected: _selected.contains(restoration.id),
                  selectedStageId: _stageOf[restoration.id],
                  onToggle: (selected) => setState(() {
                    if (selected) {
                      _selected.add(restoration.id);
                    } else {
                      _selected.remove(restoration.id);
                      _stageOf.remove(restoration.id);
                      _reasonOf.remove(restoration.id);
                    }
                  }),
                  onStageChanged: (stageId) =>
                      setState(() => _stageOf[restoration.id] = stageId),
                ),

            const SizedBox(height: AppSpacing.lg),
            AppTextFormField(
              controller: _noteController,
              hintText: 'سبب الرفض (يُسجَّل على الحالة)',
              maxLines: 2,
              validator: (_) => null,
            ),
            const SizedBox(height: AppSpacing.lg),

            CustomButtonWidget(
              buttonText: 'تسجيل الرفض',
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _RestorationLine extends StatelessWidget {
  const _RestorationLine({
    required this.caseId,
    required this.restoration,
    required this.reason,
    required this.onReasonChanged,
    required this.targets,
    required this.isSelected,
    required this.selectedStageId,
    required this.onToggle,
    required this.onStageChanged,
  });

  final String caseId;
  final CaseRestorationModel restoration;
  final SendBackReason reason;
  final ValueChanged<SendBackReason> onReasonChanged;

  /// Null while the targets are still being fetched.
  final List<CaseWorkflowStageModel>? targets;

  final bool isSelected;
  final String? selectedStageId;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onStageChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final stages = targets;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Checkbox(
                value: isSelected,
                // A piece with nowhere to go back to cannot be flagged: the
                // control says so by being disabled rather than vanishing.
                onChanged: (stages?.isEmpty ?? true)
                    ? null
                    : (value) => onToggle(value ?? false),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restoration.restorationName,
                      style: AppTextStyles.font14MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                    if (restoration.restorationNumber?.isNotEmpty ?? false)
                      Text(
                        'رقم: ${restoration.restorationNumber}',
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (stages == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: LinearProgressIndicator(),
            )
          else if (stages.isEmpty)
            Text(
              'لا توجد مرحلة يمكن إرجاع هذا التعويض إليها',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            )
          else if (isSelected)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: DropdownButtonFormField<String>(
                initialValue: selectedStageId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'يعود إلى مرحلة',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final stage in stages)
                    DropdownMenuItem(
                      value: stage.id,
                      child: Text(
                        stage.displayName.isEmpty ? '—' : stage.displayName,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onStageChanged(value);
                },
              ),
            ),
          if (isSelected && selectedStageId != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: SendBackReasonFields(
                caseId: caseId,
                restorationId: restoration.id,
                targetStageId: selectedStageId!,
                value: reason,
                onChanged: onReasonChanged,
              ),
            ),
        ],
      ),
    );
  }
}

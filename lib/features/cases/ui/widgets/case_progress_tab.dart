import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status.dart';
import 'package:dental_lab_app/features/cases/data/models/case_status_history_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/restoration_stages_stepper.dart';
import 'package:flutter/material.dart';

enum _StepKind {
  /// A single button advances straight to [nextStatus].
  manualAdvance,

  /// Two buttons — accept (→ approved) or reject (→ rejected).
  reviewBranch,

  /// No button — the backend moves the case on once restoration work
  /// finishes. Shown for context only.
  auto,

  /// End of the line — no button, no caption.
  terminal,
}

class _StepConfig {
  const _StepConfig(
    this.status,
    this.kind, {
    this.actionLabel,
    this.nextStatus,
  });

  final CaseStatus status;
  final _StepKind kind;
  final String? actionLabel;
  final CaseStatus? nextStatus;
}

/// The case's main-line status flow, in display order. `inProgress` carries
/// the per-restoration workflow-stage steppers nested inside it — that's
/// where restoration work actually happens, and the case auto-advances to
/// `ready` once every restoration reaches a final stage.
const List<_StepConfig> _mainFlow = [
  _StepConfig(
    CaseStatus.created,
    _StepKind.manualAdvance,
    actionLabel: 'تسجيل الاستلام',
    nextStatus: CaseStatus.received,
  ),
  _StepConfig(
    CaseStatus.received,
    _StepKind.manualAdvance,
    actionLabel: 'بدء المراجعة',
    nextStatus: CaseStatus.underReview,
  ),
  _StepConfig(CaseStatus.underReview, _StepKind.reviewBranch),
  _StepConfig(CaseStatus.approved, _StepKind.auto),
  _StepConfig(CaseStatus.inProgress, _StepKind.auto),
  _StepConfig(
    CaseStatus.ready,
    _StepKind.manualAdvance,
    actionLabel: 'إرسال للتجربة',
    nextStatus: CaseStatus.inTrying,
  ),
  _StepConfig(CaseStatus.inTrying, _StepKind.auto),
  _StepConfig(
    CaseStatus.delivered,
    _StepKind.manualAdvance,
    actionLabel: 'إنهاء الحالة',
    nextStatus: CaseStatus.finished,
  ),
  _StepConfig(CaseStatus.finished, _StepKind.terminal),
];

/// Tab 3 of the case detail screen — a vertical diagram of the case's
/// overall status lifecycle (`CaseStatus`), with actions to advance it via
/// `PUT /Cases/{id}/status`.
class CaseProgressTab extends StatelessWidget {
  const CaseProgressTab({
    super.key,
    required this.caseDetail,
    required this.isBusy,
    required this.onChangeStatus,
    required this.onAdvanceStage,
  });

  final CaseDetailModel caseDetail;
  final bool isBusy;
  final void Function(CaseStatus status, {String? note}) onChangeStatus;

  /// Advances one restoration to the given stage (its immediate next stage,
  /// per the "next stage" button shown while the case is `inProgress`).
  final void Function(CaseRestorationModel restoration, String stageId)
  onAdvanceStage;

  CaseStatusHistoryModel? _historyFor(CaseStatus status) {
    for (final entry in caseDetail.history) {
      if (entry.caseStatus == status) return entry;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final current = caseDetail.caseStatus;
    final currentIndex = _mainFlow.indexWhere((s) => s.status == current);
    final isRejected = current == CaseStatus.rejected;

    // Once rejected, the rest of the main flow no longer applies — only
    // show the steps up through the review decision, then the rejection.
    final reviewIndex = _mainFlow.indexWhere(
      (s) => s.status == CaseStatus.underReview,
    );
    final visibleSteps = isRejected
        ? _mainFlow.sublist(0, reviewIndex + 1)
        : _mainFlow;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (int i = 0; i < visibleSteps.length; i++) ...[
          _StepTile(
            config: visibleSteps[i],
            state: isRejected
                ? _StepState.completed
                : (i < currentIndex
                      ? _StepState.completed
                      : (i == currentIndex
                            ? _StepState.current
                            : _StepState.future)),
            history: _historyFor(visibleSteps[i].status),
            isLast: !isRejected && i == visibleSteps.length - 1,
            isBusy: isBusy,
            onAdvance: (status, note) => onChangeStatus(status, note: note),
          ),
          if (visibleSteps[i].status == CaseStatus.inProgress &&
              caseDetail.restorations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 40, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final restoration in caseDetail.restorations)
                    _RestorationStagesSection(
                      restoration: restoration,
                      // Only the case's own `inProgress` step lets a
                      // restoration's stage move via this tree — otherwise
                      // the stepper is shown read-only, for context.
                      canAdvance:
                          current == CaseStatus.inProgress && !isRejected,
                      isBusy: isBusy,
                      onAdvance: (stageId) =>
                          onAdvanceStage(restoration, stageId),
                    ),
                ],
              ),
            ),
        ],
        if (isRejected)
          _StepTile(
            config: const _StepConfig(CaseStatus.rejected, _StepKind.terminal),
            state: _StepState.current,
            history: _historyFor(CaseStatus.rejected),
            isLast: true,
            isBusy: isBusy,
            onAdvance: (status, note) => onChangeStatus(status, note: note),
            isError: true,
          ),
      ],
    );
  }
}

/// One restoration's header (name + current stage) above its stage path —
/// mirrors the case → restorations → stages shape. Nested inside the case's
/// `inProgress` tile, since that's the step it drives.
class _RestorationStagesSection extends StatelessWidget {
  const _RestorationStagesSection({
    required this.restoration,
    required this.canAdvance,
    required this.isBusy,
    required this.onAdvance,
  });

  final CaseRestorationModel restoration;
  final bool canAdvance;
  final bool isBusy;
  final void Function(String stageId) onAdvance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.strokeColor),
        boxShadow: context.glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.category_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  restoration.restorationName,
                  style: AppTextStyles.font16MediumText,
                ),
              ),
              if (restoration.quantity > 1)
                Text(
                  '×${restoration.quantity}',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: context.glass.onGlassMuted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          RestorationStagesStepper(
            restoration: restoration,
            canAdvance: canAdvance,
            isBusy: isBusy,
            onAdvance: onAdvance,
          ),
        ],
      ),
    );
  }
}

enum _StepState { completed, current, future }

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.config,
    required this.state,
    required this.history,
    required this.isLast,
    required this.isBusy,
    required this.onAdvance,
    this.isError = false,
  });

  final _StepConfig config;
  final _StepState state;
  final CaseStatusHistoryModel? history;
  final bool isLast;
  final bool isBusy;
  final void Function(CaseStatus status, String? note) onAdvance;
  final bool isError;

  Color _nodeColor(BuildContext context) {
    if (isError) return context.glass.error;
    return switch (state) {
      _StepState.completed => context.glass.success,
      _StepState.current => Theme.of(context).colorScheme.primary,
      _StepState.future => context.glass.strokeColor,
    };
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _nodeColor(context),
                  shape: BoxShape.circle,
                ),
                child: state == _StepState.completed
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == _StepState.future
                        ? context.glass.strokeColor
                        : context.glass.success,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.status.arabicLabel,
                    style: state == _StepState.future
                        ? AppTextStyles.font14RegularSecondary
                        : AppTextStyles.font16MediumText,
                  ),
                  if (history != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (history!.changedAt != null)
                          _formatDate(history!.changedAt!),
                        if (history!.changedByName != null)
                          history!.changedByName!,
                      ].join(' • '),
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: context.glass.onGlassMuted,
                      ),
                    ),
                    if (history!.note?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        history!.note!,
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: context.glass.onGlassMuted,
                        ),
                      ),
                    ],
                  ],
                  if (state == _StepState.current) ...[
                    const SizedBox(height: 8),
                    _StepAction(
                      config: config,
                      isBusy: isBusy,
                      onAdvance: onAdvance,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The action row for the current step — an optional single-line note field
/// (no dialog) plus the button(s) that immediately apply the change.
class _StepAction extends StatefulWidget {
  const _StepAction({
    required this.config,
    required this.isBusy,
    required this.onAdvance,
  });

  final _StepConfig config;
  final bool isBusy;
  final void Function(CaseStatus status, String? note) onAdvance;

  @override
  State<_StepAction> createState() => _StepActionState();
}

class _StepActionState extends State<_StepAction> {
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _advance(CaseStatus status) {
    final note = _noteController.text.trim();
    widget.onAdvance(status, note.isEmpty ? null : note);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.config.kind) {
      case _StepKind.manualAdvance:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NoteField(controller: _noteController),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: widget.isBusy
                  ? null
                  : () => _advance(widget.config.nextStatus!),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: Text(widget.config.actionLabel!),
            ),
          ],
        );
      case _StepKind.reviewBranch:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NoteField(controller: _noteController),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: widget.isBusy
                        ? null
                        : () => _advance(CaseStatus.approved),
                    style: FilledButton.styleFrom(
                      backgroundColor: context.glass.success,
                    ),
                    child: const Text('قبول'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.isBusy
                        ? null
                        : () => _advance(CaseStatus.rejected),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.glass.error,
                    ),
                    child: const Text('رفض'),
                  ),
                ),
              ],
            ),
          ],
        );
      case _StepKind.auto:
        return Text(
          'تتحول تلقائياً حسب تقدم مراحل التعويضات',
          style: AppTextStyles.font12RegularHint.copyWith(
            color: context.glass.onGlassMuted,
          ),
        );
      case _StepKind.terminal:
        return const SizedBox.shrink();
    }
  }
}

/// Compact single-line note input — no label, no dialog, easy to skip.
class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: AppTextStyles.font14MediumText.copyWith(
        color: context.glass.onGlass,
      ),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'ملاحظة (اختياري)',
        hintStyle: AppTextStyles.font14RegularSecondary.copyWith(
          color: context.glass.onGlassMuted,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        filled: true,
        fillColor: context.glass.fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.glass),
          borderSide: BorderSide(color: context.glass.strokeColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.glass),
          borderSide: BorderSide(color: context.glass.strokeColor),
        ),
      ),
    );
  }
}

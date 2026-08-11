import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_status_history_model.dart';
import 'package:flutter/material.dart';

enum _StageState { completed, current, future }

/// The full ordered workflow-stage path of one restoration, marking which
/// stages are done, which is current, and which are still ahead. Stages come
/// from the restoration's type; who moved it and when comes from the
/// restoration's own [CaseRestorationModel.statusHistory].
class RestorationStagesStepper extends StatelessWidget {
  const RestorationStagesStepper({
    super.key,
    required this.restoration,
    this.canAdvance = false,
    this.isBusy = false,
    this.onAdvance,
  });

  final CaseRestorationModel restoration;

  /// Whether the "next stage" button should be shown/enabled — true only
  /// while the case is `inProgress`, since that's the only status a
  /// restoration's stage can move forward from.
  final bool canAdvance;
  final bool isBusy;
  final void Function(String stageId)? onAdvance;

  /// Active stages of this restoration's type, in workflow order.
  List<CaseWorkflowStageModel> get _stages {
    final stages = [
      ...?restoration.restorationType?.stages.where((s) => s.isActive),
    ];
    stages.sort((a, b) => a.order.compareTo(b.order));
    return stages;
  }

  CaseRestorationStatusHistoryModel? _historyFor(String stageId) {
    for (final entry in restoration.statusHistory) {
      if (entry.stageId == stageId) return entry;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stages = _stages;

    if (stages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'لا يوجد مراحل لهذا التعويض',
          style: AppTextStyles.font12RegularHint.copyWith(
            color: context.glass.onGlassMuted,
          ),
        ),
      );
    }

    // Anything before the current stage counts as done, even if the backend
    // didn't record a history entry for it.
    final currentIndex = stages.indexWhere(
      (s) => s.id == restoration.currentStageId,
    );
    final nextIndex = currentIndex < 0 ? 0 : currentIndex + 1;
    final nextStage = nextIndex < stages.length ? stages[nextIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < stages.length; i++)
          _StageTile(
            stage: stages[i],
            state: _stateFor(i, currentIndex, stages[i].id),
            history: _historyFor(stages[i].id),
            isLast: i == stages.length - 1,
          ),
        if (canAdvance && nextStage != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FilledButton.tonalIcon(
              onPressed: isBusy ? null : () => onAdvance?.call(nextStage.id),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text('التالية: ${nextStage.name ?? '—'}'),
            ),
          ),
        ],
      ],
    );
  }

  _StageState _stateFor(int index, int currentIndex, String stageId) {
    if (currentIndex >= 0) {
      if (index < currentIndex) return _StageState.completed;
      if (index == currentIndex) return _StageState.current;
      return _StageState.future;
    }
    // No current stage set yet — fall back to whatever the timeline recorded.
    return _historyFor(stageId) != null
        ? _StageState.completed
        : _StageState.future;
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.stage,
    required this.state,
    required this.history,
    required this.isLast,
  });

  final CaseWorkflowStageModel stage;
  final _StageState state;
  final CaseRestorationStatusHistoryModel? history;
  final bool isLast;

  Color _nodeColor(BuildContext context) => switch (state) {
    _StageState.completed => context.glass.success,
    _StageState.current => Theme.of(context).colorScheme.primary,
    _StageState.future => context.glass.strokeColor,
  };

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (history?.changedAt != null) _formatDate(history!.changedAt!),
      if (history?.changedByName?.isNotEmpty == true) history!.changedByName!,
    ].join(' • ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _nodeColor(context),
                  shape: BoxShape.circle,
                ),
                child: state == _StageState.completed
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: state == _StageState.future
                        ? context.glass.strokeColor
                        : context.glass.success,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          stage.name ?? '—',
                          style: state == _StageState.future
                              ? AppTextStyles.font14RegularSecondary
                              : AppTextStyles.font14MediumText,
                        ),
                      ),
                      if (state == _StageState.current) ...[
                        const SizedBox(width: 6),
                        _Badge(
                          label: 'المرحلة الحالية',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ] else if (stage.isFinal) ...[
                        const SizedBox(width: 6),
                        _Badge(
                          label: 'الأخيرة',
                          color: context.glass.onGlassMuted,
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: context.glass.onGlassMuted,
                      ),
                    ),
                  ],
                  if (history?.note?.isNotEmpty == true) ...[
                    const SizedBox(height: 2),
                    Text(
                      history!.note!,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: context.glass.onGlassMuted,
                      ),
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

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

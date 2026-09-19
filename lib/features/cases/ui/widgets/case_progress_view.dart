import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/logic/case_progress/case_progress_state.dart';
import 'package:flutter/material.dart';

/// Where the case has got to, in the order the work actually happens:
///
/// ```
/// نقاط دورة الحياة الست
///   └─ قيد الإنتاج: مراحل الحالة ‖ التعويضات (كلٌّ على مساره) → مراحل بعد الإنتاج
/// ```
///
/// Every node — its state, its order, whether the lab's configuration skipped
/// it — arrives from `GET /Cases/{id}/flow` already decided. This widget draws
/// what it is given and computes nothing about the lifecycle itself.
class CaseProgressView extends StatelessWidget {
  const CaseProgressView({
    super.key,
    required this.state,
    required this.onMoveCase,
    required this.onMoveRestoration,
    required this.phaseCard,
  });

  final CaseProgressLoaded state;

  /// Moves the case along its own workflow. Offered here rather than only in
  /// the app bar: this is the screen where the user is reading the stages, so
  /// it is where they reach for the one that follows.
  final VoidCallback onMoveCase;

  final ValueChanged<RestorationProgress> onMoveRestoration;

  /// The current lifecycle checkpoint's own action, built by the caller since
  /// it talks to the details cubit rather than to the board.
  final Widget phaseCard;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        phaseCard,
        // The case's own move, with its note and — where the target demands
        // one — its reason. What it may move to is the server's answer, so a
        // case with nothing open says so inside the sheet.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.icon(
            onPressed: onMoveCase,
            icon: const Icon(Icons.alt_route, size: 18),
            label: const Text('نقل الحالة'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // The six fixed checkpoints, drawn first because they are the frame
        // every stage below hangs inside: production only means anything once
        // the material has arrived.
        _BandTitle(
          title: 'دورة حياة الحالة',
          count: state.phases.length,
          isActive: true,
        ),
        for (var i = 0; i < state.phases.length; i++)
          _PhaseRow(
            phase: state.phases[i],
            position: i + 1,
            isLast: i == state.phases.length - 1,
          ),

        const SizedBox(height: AppSpacing.lg),
        _BandTitle(
          // Not "before production" — these stages run alongside it, on their
          // own `order`, and neither track waits for the other unless a stage
          // is an after-production one (see the barrier band below).
          title: 'بالتوازي مع الإنتاج',
          count: state.beforeStages.length,
          isActive: state.isOnFirstHalf,
        ),
        if (state.beforeStages.isEmpty)
          const _EmptyBand(text: 'لا توجد مراحل بالتوازي مع الإنتاج')
        else
          for (var i = 0; i < state.beforeStages.length; i++)
            _StageRow(
              position: i + 1,
              stage: state.beforeStages[i],
              isLast: i == state.beforeStages.length - 1,
            ),

        const SizedBox(height: AppSpacing.lg),
        _BandTitle(
          title: 'التعويضات',
          count: state.restorations.length,
          isActive: !state.isOnFirstHalf && !state.isOnSecondHalf,
        ),
        if (state.restorations.isEmpty)
          const _EmptyBand(text: 'لا توجد تعويضات على هذه الحالة')
        else
          for (final restoration in state.restorations)
            _RestorationTrack(
              progress: restoration,
              // Barred until the case has finished its own parallel stages:
              // the pieces do not start while the case is still being received
              // or reviewed, and the server refuses the move anyway.
              onMove: state.blocksRestorations
                  ? null
                  : () => onMoveRestoration(restoration),
            ),

        const SizedBox(height: AppSpacing.lg),
        _BandTitle(
          title: 'بعد الإنتاج',
          count: state.afterStages.length,
          isActive: state.isOnSecondHalf,
        ),
        // The barrier, said before the user wonders why nothing is moving.
        if (state.afterStages.isNotEmpty && !state.restorationsFinished)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'لا تبدأ حتى تنتهي كل التعويضات',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            ),
          ),
        if (state.afterStages.isEmpty)
          const _EmptyBand(text: 'لا توجد مراحل بعد الإنتاج')
        else
          for (var i = 0; i < state.afterStages.length; i++)
            _StageRow(
              position: i + 1,
              stage: state.afterStages[i],
              isLast: i == state.afterStages.length - 1,
            ),
      ],
    );
  }
}

/// One of the six lifecycle checkpoints, with whatever that particular
/// checkpoint knows: how the material was to arrive, how it did, who moved it.
class _PhaseRow extends StatelessWidget {
  const _PhaseRow({
    required this.phase,
    required this.position,
    required this.isLast,
  });

  final CaseFlowPhaseModel phase;
  final int position;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    // Only what this checkpoint actually answers — the rest stay null on the
    // DTO rather than one shape pretending to answer all six.
    final details = <String>[
      if (phase.enteredAt != null) ApiTime.displayDateTime(phase.enteredAt),
      if (phase.changedByName?.trim().isNotEmpty ?? false) phase.changedByName!,
      if (phase.collectionMethod != null &&
          phase.collectionMethod!.label.isNotEmpty)
        phase.collectionMethod!.label,
      if (phase.receivedViaLabel != null) phase.receivedViaLabel!,
      if (phase.note?.trim().isNotEmpty ?? false) phase.note!,
    ];

    return _TimelineRow(
      position: position,
      label: phase.phase?.label ?? '—',
      status: phase.status,
      isLast: isLast,
      subtitle: details.isEmpty ? null : details.join(' · '),
      trailing: phase.status.isCurrent
          ? const _NowChip()
          : phase.status.isSkipped
          ? Text(
              'متجاوَزة',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          : null,
    );
  }
}

/// One restoration and the stages of its own frozen route.
class _RestorationTrack extends StatelessWidget {
  const _RestorationTrack({required this.progress, required this.onMove});

  final RestorationProgress progress;

  /// Null while the case has not cleared its parallel stages — the row says
  /// why instead of offering a move that would be refused.
  final VoidCallback? onMove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final stages = progress.flow.stages;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.title,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              if (progress.isFinished)
                Icon(Icons.check_circle, size: 18, color: glass.success)
              else if (onMove != null)
                TextButton.icon(
                  onPressed: onMove,
                  icon: const Icon(Icons.swap_horiz, size: 16),
                  label: const Text('تغيير المرحلة'),
                )
              else
                Text(
                  'بانتظار مراحل الحالة',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.warning,
                  ),
                ),
            ],
          ),
          if (progress.number?.isNotEmpty ?? false)
            Text(
              'رقم: ${progress.number}',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          const SizedBox(height: AppSpacing.sm),

          if (stages.isEmpty)
            Text(
              // A piece whose type had no route drawn when the case was
              // created. Saying so beats an empty box.
              'لا يوجد مسار لهذا التعويض',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          else
            for (var i = 0; i < stages.length; i++)
              _StageRow(
                position: i + 1,
                stage: stages[i],
                isLast: i == stages.length - 1,
                isCompact: true,
              ),
        ],
      ),
    );
  }
}

/// One stage of a route, with the marks that explain an unusual path: a
/// checkpoint that can refuse work, a stage performed at the doctor's, and a
/// second visit to a stage the piece came back to.
class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.position,
    required this.stage,
    required this.isLast,
    this.isCompact = false,
  });

  final int position;
  final CaseFlowStageModel stage;
  final bool isLast;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final marks = <String>[
      if (stage.isExternal) 'عند الطبيب',
      if (stage.isCheckpoint) 'نقطة فحص',
      // Attempt 1 is the ordinary path and says nothing worth the ink; a
      // second visit is the whole story of a repaired piece.
      if (stage.isReturn || stage.attempt > 1) 'محاولة ${stage.attempt}',
      if (stage.changedAt != null) ApiTime.displayDateTime(stage.changedAt),
      if (stage.changedByName?.trim().isNotEmpty ?? false) stage.changedByName!,
    ];

    return _TimelineRow(
      position: position,
      label: stage.displayName,
      status: stage.status,
      isLast: isLast,
      isCompact: isCompact,
      subtitle: marks.isEmpty ? null : marks.join(' · '),
      trailing: stage.status.isCurrent
          ? const _NowChip()
          : stage.status.isSkipped
          ? Text(
              'متجاوَزة',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            )
          : null,
    );
  }
}

/// One step on a track: a dot, a connector down to the next, and the name.
class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.position,
    required this.label,
    required this.status,
    required this.isLast,
    this.subtitle,
    this.trailing,
    this.isCompact = false,
  });

  final int position;
  final String label;
  final CaseFlowNodeStatus status;
  final bool isLast;
  final String? subtitle;
  final Widget? trailing;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    final Color dotColor = switch (status) {
      CaseFlowNodeStatus.current => accent,
      CaseFlowNodeStatus.done => glass.success,
      // Skipped and pending share the hairline: neither happened, and only
      // the label says which is which.
      CaseFlowNodeStatus.skipped || CaseFlowNodeStatus.pending =>
        glass.strokeColor,
    };
    final isFilled = status.isDone || status.isCurrent;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: isCompact ? 10 : 14,
                height: isCompact ? 10 : 14,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isFilled ? dotColor : Colors.transparent,
                  border: Border.all(color: dotColor, width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              // The connector stops at the last row so the track does not
              // trail off into nothing.
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: status.isDone ? glass.success : glass.strokeColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$position. ${label.isEmpty ? '—' : label}',
                          style: status.isCurrent
                              ? AppTextStyles.font14MediumText.copyWith(
                                  color: glass.onGlass,
                                )
                              : AppTextStyles.font14RegularSecondary.copyWith(
                                  color: status.isDone
                                      ? glass.onGlass
                                      : glass.onGlassMuted,
                                  decoration: status.isSkipped
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowChip extends StatelessWidget {
  const _NowChip();

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        'الآن',
        style: AppTextStyles.font12RegularHint.copyWith(color: accent),
      ),
    );
  }
}

class _BandTitle extends StatelessWidget {
  const _BandTitle({
    required this.title,
    required this.count,
    required this.isActive,
  });

  final String title;
  final int count;

  /// Whether the case is standing in this band right now.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: isActive ? accent : glass.strokeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$count',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBand extends StatelessWidget {
  const _EmptyBand({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.font12RegularHint.copyWith(
          color: context.glass.onGlassMuted,
        ),
      ),
    );
  }
}

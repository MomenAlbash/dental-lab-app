import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The stages the restoration being entered will run.
///
/// Shown while the restoration is being added rather than after the case is
/// filed: discovering that a case is running the wrong stages is expensive to
/// undo.
///
/// It used to also ask the lab's "gating options" here, and gate the save on
/// answering them. That whole idea is gone from the API — options became
/// `isOptional` on the stage itself — and the endpoint behind it had been
/// 404ing, so the questions never appeared and the rule never fired. The
/// optional stages are now asked once, for the whole case, in the wizard's
/// own step; this section only says which of them are still coming.
class RestorationRouteSection extends StatelessWidget {
  const RestorationRouteSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoutePreviewCubit, RoutePreviewState>(
      builder: (context, state) {
        // Nothing to say before a restoration type is picked.
        if (!state.hasLoaded && !state.isLoading) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.sectionGap),
            const GlassSectionTitle('المسار المتوقع'),
            const SizedBox(height: AppSpacing.md),
            if (state.isLoading)
              const _RouteSkeleton()
            else
              _Route(state: state),
          ],
        );
      },
    );
  }
}

class _Route extends StatelessWidget {
  const _Route({required this.state});

  final RoutePreviewState state;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    if (state.errorMessage != null) {
      return _Notice(
        icon: Icons.error_outline,
        color: glass.error,
        text: state.errorMessage!,
      );
    }

    if (state.isEmpty) {
      return _Notice(
        icon: Icons.route_outlined,
        color: glass.onGlassMuted,
        // Different from "no route drawn for the lab": this type has none for
        // the intake this case is being taken in on.
        text: 'لا توجد مراحل مرسومة لهذا التعويض بطريقة الاستلام المختارة',
      );
    }

    final steps = state.steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final problem in state.problems) ...[
          _Notice(
            icon: Icons.warning_amber_outlined,
            color: glass.warning,
            text: problem,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        for (var i = 0; i < steps.length; i++)
          _StepRow(step: steps[i], index: i, isLast: i == steps.length - 1),

        // Named, not counted: "and 3 optional stages" tells the user nothing
        // they can act on, while the names are what they are about to be
        // asked about on the next step of the wizard.
        if (state.optional.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _Notice(
            icon: Icons.help_outline,
            color: glass.info,
            text:
                'مراحل اختيارية سيُسأل عنها لاحقاً: '
                '${state.optional.map((s) => s.displayName).join('، ')}',
          ),
        ],
      ],
    );
  }
}

/// One step of the route. Several stages in a step run in parallel — that is
/// what sharing an `order` means — so they are drawn inside one row rather
/// than as separate steps the user would read as sequential.
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.index,
    required this.isLast,
  });

  final List<CaseWorkflowStageModel> step;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A rail rather than arrows between cards: this is a preview, and a
          // full graph here would compete with the real board on the case.
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: accent,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: glass.strokeColor)),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final stage in step)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              stage.displayName,
                              style: AppTextStyles.font14MediumText.copyWith(
                                color: glass.onGlass,
                              ),
                            ),
                          ),
                          if (stage.isExternal)
                            _Tag(label: 'خارجي', color: glass.warning),
                          if (stage.isCheckpoint) ...[
                            const SizedBox(width: 4),
                            _Tag(label: 'فحص', color: glass.info),
                          ],
                        ],
                      ),
                    ),
                  if (step.length > 1)
                    Text(
                      'تعمل بالتوازي',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

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

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: context.glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteSkeleton extends StatelessWidget {
  const _RouteSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const GlassSkeletonBox(height: 20),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

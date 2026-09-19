import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Asks, one stage at a time, whether this case wants it.
///
/// A stage the lab marked `isOptional` is not on the route until somebody says
/// so, so every one of them is a question with two answers and no default —
/// leaving them all off silently would be an answer the user never gave.
class CaseOptionalStagesStep extends StatelessWidget {
  const CaseOptionalStagesStep({
    super.key,
    required this.answers,
    required this.onChanged,
  });

  /// Each stage's answer by id. A stage absent from the map has not been
  /// answered — which is not the same as answered "no", and is what the form
  /// refuses to submit on.
  final Map<String, bool> answers;

  /// Reports the whole map, so the caller keeps one source of truth.
  final ValueChanged<Map<String, bool>> onChanged;

  void _answer(String stageId, bool wanted) =>
      onChanged({...answers, stageId: wanted});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocBuilder<OptionalStagesCubit, OptionalStagesState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              state.hasFailure
                  ? 'تعذّر جلب المراحل الاختيارية — تابع، ويمكن إضافتها لاحقاً'
                  : 'لا توجد مراحل اختيارية لهذه التعويضات',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'مراحل يمكن إضافتها لهذه الحالة — أجب عن كل سؤال',
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            if (state.hasFailure) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'تعذّر جلب جزء من المراحل — قد تكون القائمة ناقصة',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.warning,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            for (final stage in state.stages) ...[
              _StageQuestion(
                stage: stage,
                answer: answers[stage.id],
                onAnswer: (wanted) => _answer(stage.id, wanted),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

/// "هل تريد مرحلة كذا؟ نعم / لا" — the question the lab asks on paper.
class _StageQuestion extends StatelessWidget {
  const _StageQuestion({
    required this.stage,
    required this.answer,
    required this.onAnswer,
  });

  final OptionalStage stage;

  /// Null until answered — which is why both chips can be unselected at once.
  final bool? answer;

  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'هل تريد "${stage.name}"؟',
            style: AppTextStyles.font14MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stage.source,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _AnswerChip(
                  label: 'نعم',
                  isSelected: answer == true,
                  onTap: () => onAnswer(true),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _AnswerChip(
                  label: 'لا',
                  isSelected: answer == false,
                  onTap: () => onAnswer(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnswerChip extends StatelessWidget {
  const _AnswerChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
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
          child: Text(
            label,
            style: AppTextStyles.font14MediumText.copyWith(
              color: isSelected ? accent : glass.onGlass,
            ),
          ),
        ),
      ),
    );
  }
}

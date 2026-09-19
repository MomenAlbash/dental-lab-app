import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:dental_lab_app/features/details_questions/logic/details_questions/details_questions_cubit.dart';
import 'package:dental_lab_app/features/details_questions/ui/widgets/question_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's own questions, asked of each kind of person it keeps a
/// record of.
///
/// Shown one audience at a time rather than as one flat list: a question
/// written for employees has no business in a doctor's form, and a flat list
/// invites exactly that mistake when somebody edits one.
class DetailsQuestionsPage extends StatelessWidget {
  const DetailsQuestionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DetailsQuestionsCubit>()..load(),
      child: const _QuestionsView(),
    );
  }
}

class _QuestionsView extends StatelessWidget {
  const _QuestionsView();

  Future<void> _openForm(
    BuildContext context, {
    DetailsQuestionModel? question,
    required QuestionPersonType personType,
    required int nextOrder,
  }) async {
    final cubit = context.read<DetailsQuestionsCubit>();

    final result = await showQuestionFormSheet(
      context,
      initial: question,
      personType: personType,
      nextOrder: nextOrder,
    );
    if (result == null) return;

    if (result.create case final body?) {
      await cubit.create(body);
    } else if (result.update case final body?) {
      await cubit.update(id: question!.id, body: body);
    }
  }

  Future<void> _delete(
    BuildContext context,
    DetailsQuestionModel question,
  ) async {
    final cubit = context.read<DetailsQuestionsCubit>();

    // A question somebody has answered cannot be deleted — the cubit says so
    // in the server's own words. No point confirming an action that will come
    // back rejected.
    if (!question.canDelete) {
      await cubit.delete(question);
      return;
    }

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف السؤال',
      message: 'سيُحذف "${question.label}" نهائياً. متابعة؟',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.delete(question);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.users);

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.detailsQuestionsScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'أسئلة إضافية',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<DetailsQuestionsCubit, DetailsQuestionsState>(
          listenWhen: (previous, current) =>
              current is DetailsQuestionsActionSuccess ||
              current is DetailsQuestionsActionError,
          listener: (context, state) {
            switch (state) {
              case DetailsQuestionsActionSuccess(:final message):
                showToast(message: message, state: ToastState.success);
              case DetailsQuestionsActionError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! DetailsQuestionsActionSuccess &&
              current is! DetailsQuestionsActionError,
          builder: (context, state) {
            final personType = state is DetailsQuestionsLoaded
                ? state.personType
                : context.read<DetailsQuestionsCubit>().personType;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (final type in QuestionPersonType.values)
                        ChoiceChip(
                          label: Text(type.label),
                          selected: personType == type,
                          onSelected: (_) => context
                              .read<DetailsQuestionsCubit>()
                              .load(personType: type),
                        ),
                    ],
                  ),
                ),

                Expanded(
                  child: switch (state) {
                    DetailsQuestionsLoaded(:final questions) =>
                      questions.isEmpty
                          ? const _EmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              itemCount: questions.length,
                              itemBuilder: (context, index) => _QuestionCard(
                                question: questions[index],
                                onEdit: canEdit
                                    ? () => _openForm(
                                        context,
                                        question: questions[index],
                                        personType: personType,
                                        nextOrder:
                                            questions[index].displayOrder ??
                                            index,
                                      )
                                    : null,
                                onDelete: canEdit
                                    ? () => _delete(context, questions[index])
                                    : null,
                              ),
                            ),
                    DetailsQuestionsError(:final message) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                      ),
                    ),
                    _ => const Center(
                      child: CustomCircleProgressIndiacatorWidget(),
                    ),
                  },
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !canEdit
          ? null
          : Builder(
              builder: (context) {
                final state = context
                    .watch<DetailsQuestionsCubit>()
                    .state;
                final loaded = state is DetailsQuestionsLoaded ? state : null;

                return GlassAddButton(
                  label: 'إضافة سؤال',
                  // Always extended: this list is short enough that the button
                  // never sits on top of rows the user is reading, so
                  // collapsing it would only cost the label.
                  isExtended: true,
                  onPressed: () => _openForm(
                    context,
                    personType:
                        loaded?.personType ??
                        context.read<DetailsQuestionsCubit>().personType,
                    nextOrder: loaded?.questions.length ?? 0,
                  ),
                );
              },
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    this.onEdit,
    this.onDelete,
  });

  final DetailsQuestionModel question;

  /// Null without permission — the actions are left off rather than shown
  /// disabled.
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.label,
                  style: AppTextStyles.font14MediumText.copyWith(
                    // A retired question is greyed rather than hidden: it
                    // stops being asked, but the answers already filed under
                    // it still need somewhere to be explained from.
                    color: question.isActive
                        ? glass.onGlass
                        : glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    _Tag(
                      label: question.type?.label ?? '—',
                      color: glass.info,
                    ),
                    if (question.isRequired)
                      _Tag(label: 'إلزامي', color: glass.warning),
                    if (!question.isActive)
                      _Tag(label: 'معطّل', color: glass.onGlassMuted),
                  ],
                ),
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'تعديل',
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: glass.onGlassMuted),
            ),
          if (onDelete != null)
            IconButton(
              // Kept enabled even when the server will refuse: pressing it is
              // how the user finds out *why*, in the server's own words.
              tooltip: question.canDelete
                  ? 'حذف'
                  : (question.deleteMessage ?? 'لا يمكن الحذف'),
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: question.canDelete ? glass.error : glass.onGlassMuted,
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
        border: Border.all(color: color.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline,
              size: 48,
              color: glass.onGlassMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد أسئلة لهذه الفئة',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:dental_lab_app/features/details_questions/logic/person_answers/person_answers_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One person's answers to the laboratory's custom questions.
///
/// Every active question is rendered, not only the answered ones — a form that
/// showed only existing answers could never collect a new one, which is the
/// state every person is in the day a question is added.
Future<void> showPersonAnswersSheet(
  BuildContext context, {
  required String personId,
  required bool isDoctor,
  required String personName,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<PersonAnswersCubit>()
        ..load(personId: personId, isDoctor: isDoctor),
      child: _PersonAnswersSheet(personName: personName),
    ),
  );
}

class _PersonAnswersSheet extends StatefulWidget {
  const _PersonAnswersSheet({required this.personName});

  final String personName;

  @override
  State<_PersonAnswersSheet> createState() => _PersonAnswersSheetState();
}

class _PersonAnswersSheetState extends State<_PersonAnswersSheet> {
  /// One controller per non-file question, built when the questions arrive.
  final _controllers = <String, TextEditingController>{};

  /// Yes/no answers, which are a switch rather than a field.
  final _bools = <String, bool>{};

  /// Date answers, kept as DateTime so the picker has something to open on.
  final _dates = <String, DateTime>{};

  bool _seeded = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Fills the form from what the person has already answered. Runs once —
  /// re-seeding after a save would fight the user's own typing.
  void _seed(PersonAnswersLoaded state) {
    if (_seeded) return;
    _seeded = true;

    for (final question in state.questions) {
      final answer = state.answers[question.id];

      switch (question.type) {
        case DetailsQuestionType.yesNo:
          _bools[question.id] = answer?.boolValue ?? false;
        case DetailsQuestionType.date:
          final parsed = ApiTime.parseDate(answer?.value);
          if (parsed != null) _dates[question.id] = parsed;
        case DetailsQuestionType.fileUpload:
          // Files have their own endpoint; nothing to seed into a field.
          break;
        case _:
          _controllers[question.id] = TextEditingController(
            text: answer?.value ?? '',
          );
      }
    }
  }

  Future<void> _pickDate(String questionId) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dates[questionId] ?? now,
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null) return;

    setState(() => _dates[questionId] = picked);
  }

  Future<void> _pickFile(BuildContext context, String questionId) async {
    final cubit = context.read<PersonAnswersCubit>();

    final result = await FilePicker.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return;

    await cubit.uploadFile(questionId: questionId, filePath: path);
  }

  void _save(BuildContext context, PersonAnswersLoaded state) {
    // Every non-file question is sent, not only the edited ones: the endpoint
    // replaces the person's answer set, so a question left out is cleared.
    final values = <String, String?>{};

    for (final question in state.questions) {
      if (question.type?.isFile ?? false) continue;

      values[question.id] = switch (question.type) {
        DetailsQuestionType.yesNo => '${_bools[question.id] ?? false}',
        DetailsQuestionType.date =>
          _dates[question.id] == null
              ? null
              : ApiTime.formatDate(_dates[question.id]!),
        _ => _controllers[question.id]?.text,
      };
    }

    context.read<PersonAnswersCubit>().save(values);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocConsumer<PersonAnswersCubit, PersonAnswersState>(
      listenWhen: (previous, current) =>
          current is PersonAnswersSaved ||
          current is PersonAnswersActionError,
      listener: (context, state) {
        switch (state) {
          case PersonAnswersSaved():
            showToast(message: 'تم حفظ الإجابات', state: ToastState.success);
          case PersonAnswersActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! PersonAnswersSaved &&
          current is! PersonAnswersActionError,
      builder: (context, state) {
        if (state is PersonAnswersLoaded) _seed(state);

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أسئلة إضافية',
                style: AppTextStyles.font16MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              Text(
                widget.personName,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              switch (state) {
                PersonAnswersLoaded(:final questions) => questions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Text(
                          'لا توجد أسئلة لهذه الفئة',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                      )
                    : Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Reported, never enforced: these questions are
                              // usually added after the people were, so half
                              // the directory is legitimately incomplete on
                              // day one and blocking the save would make the
                              // form unusable.
                              if (state.missingRequired.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Text(
                                    'ناقص ${state.missingRequired.length} '
                                    'سؤال إلزامي',
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: glass.warning),
                                  ),
                                ),

                              for (final question in questions)
                                _QuestionField(
                                  question: question,
                                  answer: state.answers[question.id],
                                  controller: _controllers[question.id],
                                  boolValue: _bools[question.id],
                                  dateValue: _dates[question.id],
                                  onBoolChanged: (value) => setState(
                                    () => _bools[question.id] = value,
                                  ),
                                  onPickDate: () => _pickDate(question.id),
                                  onPickFile: () =>
                                      _pickFile(context, question.id),
                                ),
                            ],
                          ),
                        ),
                      ),
                PersonAnswersError(:final message) => Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: CustomCircleProgressIndiacatorWidget(),
                ),
              },

              if (state is PersonAnswersLoaded &&
                  state.questions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                CustomButtonWidget(
                  buttonText: 'حفظ',
                  onPressed: state.isBusy
                      ? null
                      : () => _save(context, state),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _QuestionField extends StatelessWidget {
  const _QuestionField({
    required this.question,
    required this.answer,
    required this.controller,
    required this.boolValue,
    required this.dateValue,
    required this.onBoolChanged,
    required this.onPickDate,
    required this.onPickFile,
  });

  final DetailsQuestionModel question;
  final PersonAnswerModel? answer;
  final TextEditingController? controller;
  final bool? boolValue;
  final DateTime? dateValue;

  final ValueChanged<bool> onBoolChanged;
  final VoidCallback onPickDate;
  final VoidCallback onPickFile;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question.label,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              if (question.isRequired)
                Text(
                  '*',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.warning,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),

          switch (question.type) {
            DetailsQuestionType.yesNo => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: boolValue ?? false,
              onChanged: onBoolChanged,
              title: Text(
                (boolValue ?? false) ? 'نعم' : 'لا',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ),
            DetailsQuestionType.date => OutlinedButton.icon(
              onPressed: onPickDate,
              icon: const Icon(Icons.event, size: 16),
              label: Text(
                dateValue == null
                    ? 'اختر تاريخاً'
                    : ApiTime.formatDate(dateValue!),
              ),
            ),
            DetailsQuestionType.fileUpload => Row(
              children: [
                Expanded(
                  child: Text(
                    // A file already uploaded is named, so the user knows
                    // whether picking one replaces something.
                    answer?.filePath?.split('/').last ?? 'لا يوجد ملف',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onPickFile,
                  icon: const Icon(Icons.attach_file, size: 16),
                  label: Text(answer?.filePath == null ? 'رفع' : 'استبدال'),
                ),
              ],
            ),
            _ => AppTextFormField(
              controller: controller ?? TextEditingController(),
              hintText: 'الإجابة',
              keyboardType: question.type == DetailsQuestionType.number
                  ? const TextInputType.numberWithOptions(decimal: true)
                  : TextInputType.text,
              validator: (_) => null,
            ),
          },

          // Files upload on their own endpoint, so the save button below does
          // not cover them — said, rather than left to be discovered.
          if (question.type?.isFile ?? false)
            Text(
              'يُرفع فوراً عند الاختيار',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
        ],
      ),
    );
  }
}

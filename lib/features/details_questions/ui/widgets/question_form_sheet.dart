import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:flutter/material.dart';

/// What the sheet hands back — exactly one of the two is set.
///
/// Two request shapes rather than one, because they are genuinely different:
/// the create carries `personType` and the update deliberately does not.
typedef QuestionFormResult = ({
  CreateDetailsQuestionRequestModel? create,
  UpdateDetailsQuestionRequestModel? update,
});

/// Creates or edits one custom question. [initial] null means create.
Future<QuestionFormResult?> showQuestionFormSheet(
  BuildContext context, {
  DetailsQuestionModel? initial,
  required QuestionPersonType personType,
  required int nextOrder,
}) {
  return showGlassBottomSheet<QuestionFormResult>(
    context: context,
    builder: (_) => _QuestionFormSheet(
      initial: initial,
      personType: personType,
      nextOrder: nextOrder,
    ),
  );
}

class _QuestionFormSheet extends StatefulWidget {
  const _QuestionFormSheet({
    this.initial,
    required this.personType,
    required this.nextOrder,
  });

  final DetailsQuestionModel? initial;
  final QuestionPersonType personType;
  final int nextOrder;

  @override
  State<_QuestionFormSheet> createState() => _QuestionFormSheetState();
}

class _QuestionFormSheetState extends State<_QuestionFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _textController = TextEditingController(
    text: widget.initial?.questionText ?? '',
  );
  late final _textArController = TextEditingController(
    text: widget.initial?.questionTextAr ?? '',
  );
  late final _orderController = TextEditingController(
    text: '${widget.initial?.displayOrder ?? widget.nextOrder}',
  );

  late DetailsQuestionType _type =
      widget.initial?.type ?? DetailsQuestionType.text;
  late bool _isRequired = widget.initial?.isRequired ?? false;
  late bool _isActive = widget.initial?.isActive ?? true;

  bool get _isEditing => widget.initial != null;

  /// Whether changing the answer type would strand answers already given.
  ///
  /// `canDelete` is the server's own signal that somebody has answered — the
  /// same fact that blocks a delete. Retyping a question from Text to Number
  /// leaves those answers unreadable under the new type, so the picker is
  /// locked rather than left to surprise someone.
  bool get _typeIsLocked => _isEditing && !(widget.initial?.canDelete ?? true);

  @override
  void dispose() {
    _textController.dispose();
    _textArController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final order = int.tryParse(_orderController.text.trim());
    final text = _textController.text.trim();
    final textAr = _textArController.text.trim();

    Navigator.of(context).pop(
      _isEditing
          ? (
              create: null,
              update: UpdateDetailsQuestionRequestModel(
                questionText: text,
                questionTextAr: textAr.isEmpty ? null : textAr,
                type: _type,
                isRequired: _isRequired,
                displayOrder: order,
                isActive: _isActive,
              ),
            )
          : (
              create: CreateDetailsQuestionRequestModel(
                personType: widget.personType,
                questionText: text,
                questionTextAr: textAr.isEmpty ? null : textAr,
                type: _type,
                isRequired: _isRequired,
                displayOrder: order,
              ),
              update: null,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'تعديل السؤال' : 'إضافة سؤال',
                style: AppTextStyles.font16MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              Text(
                // Named, and fixed once created: the answers already filed
                // belong to the people it was asked of.
                'يُسأل لـ: ${widget.personType.label}',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              AppTextFormField(
                controller: _textArController,
                hintText: 'نص السؤال (عربي)',
                validator: (_) => null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextFormField(
                controller: _textController,
                hintText: 'نص السؤال (إنجليزي)',
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'النص الإنجليزي مطلوب'
                    : null,
              ),

              const SizedBox(height: AppSpacing.md),
              Text(
                'نوع الإجابة',
                style: AppTextStyles.font14MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final type in DetailsQuestionType.values)
                    ChoiceChip(
                      label: Text(type.label),
                      selected: _type == type,
                      onSelected: _typeIsLocked
                          ? null
                          : (_) => setState(() => _type = type),
                    ),
                ],
              ),
              if (_typeIsLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'لا يمكن تغيير النوع — يوجد إجابات مسجّلة على هذا السؤال',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.warning,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),
              AppTextFormField(
                controller: _orderController,
                hintText: 'ترتيب العرض',
                keyboardType: TextInputType.number,
                validator: (value) {
                  final parsed = int.tryParse(value?.trim() ?? '');
                  if (parsed == null || parsed < 0) return 'أدخل رقماً صحيحاً';
                  return null;
                },
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isRequired,
                onChanged: (value) => setState(() => _isRequired = value),
                title: Text(
                  'إلزامي',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                subtitle: Text(
                  // Said plainly, because "required" here is a prompt rather
                  // than a gate — the questions are usually added after the
                  // people were.
                  'يُنبَّه عند نقصه، لكنه لا يمنع الحفظ',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ),

              if (_isEditing)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                  title: Text(
                    'مفعّل',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                  subtitle: Text(
                    // The safe alternative to deleting, which the server
                    // refuses once anybody has answered.
                    _isActive
                        ? 'يظهر في نماذج الإجابة'
                        : 'يختفي من النماذج، والإجابات المسجّلة تبقى',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),

              const SizedBox(height: AppSpacing.md),
              CustomButtonWidget(buttonText: 'حفظ', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

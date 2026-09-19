import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/badge_variant.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/stage_assignees_field.dart';
import 'package:dental_lab_app/core/widgets/stage_assignees_sheet.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/case_priority_form_fields.dart'
    show kBadgeVariants;
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_enums.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:flutter/material.dart';

/// Creates or edits one case-workflow stage.
///
/// Returns the request body; the caller sends it. [initial] null means create.
///
/// Built from the same pieces as every other form in the app — `AppTextFormField`
/// with a leading icon, the shared label, the glass switch tile and
/// `kBadgeVariants` — so a stage form reads as the same product as a priority
/// form rather than as a bare Material sheet.
Future<SaveCaseStageRequestModel?> showWorkflowStageFormSheet(
  BuildContext context, {
  CaseStageModel? initial,
  required int nextOrder,
  List<CaseStageModel> allStages = const [],
}) {
  return showGlassBottomSheet<SaveCaseStageRequestModel>(
    context: context,
    builder: (_) => _StageFormSheet(
      initial: initial,
      nextOrder: nextOrder,
      allStages: allStages,
    ),
  );
}

class _StageFormSheet extends StatefulWidget {
  const _StageFormSheet({
    this.initial,
    required this.nextOrder,
    required this.allStages,
  });

  final CaseStageModel? initial;
  final int nextOrder;

  /// The lab's doctor-facing buckets. This stage's internal name stays as it
  /// is; the category is what the doctor is shown in its place.

  /// The whole catalogue, so the rework and branch pickers can scope their
  /// options the way the server validates them: same pipeline, and strictly
  /// earlier or strictly later in the running order.
  final List<CaseStageModel> allStages;

  @override
  State<_StageFormSheet> createState() => _StageFormSheetState();
}

class _StageFormSheetState extends State<_StageFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nameArController;
  late final TextEditingController _orderController;

  late RouteStageAppliesTo _appliesTo;
  late CaseStageTiming _timing;
  String? _sendBackToStageId;
  String? _nextStageId;
  late bool _isExternal;
  late bool _isOptional;
  late bool _requiresReason;
  late bool _isActive;
  String? _badgeVariant;

  /// Who may work the stage. Edited through the shared sheet so the case
  /// workflow and the restoration routes answer it the same way.
  late StageAssignees _assignees;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    _nameController = TextEditingController(text: initial?.name ?? '');
    _nameArController = TextEditingController(text: initial?.nameAr ?? '');
    _orderController = TextEditingController(
      text: '${initial?.order ?? widget.nextOrder}',
    );

    _appliesTo = _selectableIntake(initial?.appliesTo);
    _timing = initial?.timing ?? CaseStageTiming.beforeRestorations;
    _sendBackToStageId = initial?.sendBackToStageId;
    _nextStageId = initial?.nextStageId;
    _isExternal = initial?.isExternal ?? false;
    _isOptional = initial?.isOptional ?? false;
    _requiresReason = initial?.requiresReason ?? false;
    _isActive = initial?.isActive ?? true;
    _badgeVariant = initial?.badgeVariant;
    _assignees = (
      departmentIds: initial?.departmentIds ?? const [],
      userIds: initial?.userIds ?? const [],
      excludedUserIds: initial?.excludedUserIds ?? const [],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  /// The order this stage is being saved with — the picker must scope against
  /// what the user typed, not against what the stage was loaded with.
  int get _currentOrder =>
      int.tryParse(_orderController.text.trim()) ??
      widget.initial?.order ??
      widget.nextOrder;

  /// Stages a rejection may send the work back to: same pipeline, strictly
  /// earlier. Scoped here the way the server validates it, so a bad pick is
  /// impossible rather than answered with a 400.
  List<CaseStageModel> get _earlierStages => [
    for (final stage in widget.allStages)
      if (stage.id != widget.initial?.id &&
          stage.appliesTo == _appliesTo &&
          stage.order < _currentOrder)
        stage,
  ];

  /// Stages this one may jump forward to: same pipeline, strictly later.
  List<CaseStageModel> get _laterStages => [
    for (final stage in widget.allStages)
      if (stage.id != widget.initial?.id &&
          stage.appliesTo == _appliesTo &&
          stage.order > _currentOrder)
        stage,
  ];

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      SaveCaseStageRequestModel(
        name: _nameController.text.trim(),
        nameAr: _nameArController.text.trim(),
        order:
            int.tryParse(_orderController.text.trim()) ??
            widget.initial?.order ??
            widget.nextOrder,
        appliesTo: _appliesTo,
        timing: _timing,
        sendBackToStageId: _sendBackToStageId,
        nextStageId: _nextStageId,
        isExternal: _isExternal,
        isOptional: _isOptional,
        requiresReason: _requiresReason,
        isActive: _isActive,
        badgeVariant: _badgeVariant,
        departmentIds: _assignees.departmentIds,
        userIds: _assignees.userIds,
        excludedUserIds: _assignees.excludedUserIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'تعديل المرحلة' : 'مرحلة جديدة',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 24),

              const _Label('الاسم بالعربية'),
              AppTextFormField(
                controller: _nameArController,
                hintText: 'أدخل اسم المرحلة بالعربية',
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.translate_outlined,
                  color: glass.onGlassMuted,
                ),
                // Optional on the API, but it is the label the whole app shows,
                // so leaving it out means the stage reads in English on every
                // board and badge.
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم بالعربية مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              const _Label('الاسم بالإنجليزية'),
              AppTextFormField(
                controller: _nameController,
                hintText: 'أدخل اسم المرحلة بالإنجليزية',
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.account_tree_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              const _Label('ترتيب العرض'),
              AppTextFormField(
                controller: _orderController,
                hintText: 'الأصغر يظهر أولاً',
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                prefixIcon: Icon(
                  Icons.sort_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return null;
                  return int.tryParse(value.trim()) == null
                      ? 'الرجاء إدخال رقم صحيح'
                      : null;
                },
              ),
              const SizedBox(height: 20),

              const _Label('موقعها من الإنتاج'),
              const SizedBox(height: 4),
              Text(
                'مرحلة "بعد الإنتاج" لا تُفتح حتى تنتهي كل تعويضات الحالة — '
                'هذا هو الحاجز الذي يفصل نصفَي المسار.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in CaseStageTiming.values)
                    ChoiceChip(
                      label: Text(value.arabicLabel),
                      selected: _timing == value,
                      onSelected: (_) => setState(() => _timing = value),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              const _Label('طريقة الاستلام'),
              const SizedBox(height: 4),
              // The intake fork: this decides whether the stage is cut onto
              // the case at all, exactly as it does on a restoration route.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in RouteStageAppliesTo.selectable)
                    ChoiceChip(
                      label: Text(value.label),
                      selected: _appliesTo == value,
                      onSelected: (_) => setState(() => _appliesTo = value),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              const _Label('اللون'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final variant in kBadgeVariants)
                    ChoiceChip(
                      label: Text(variant.label),
                      selected: _badgeVariant == variant.value,
                      avatar: CircleAvatar(
                        backgroundColor: badgeVariantColor(
                          context,
                          variant.value,
                        ),
                        radius: 8,
                      ),
                      // Tapping the selected swatch clears it — the field is
                      // optional and a choice you cannot undo is a trap.
                      onSelected: (_) => setState(
                        () => _badgeVariant = _badgeVariant == variant.value
                            ? null
                            : variant.value,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              const _SectionTitle('سلوك المرحلة'),
              const SizedBox(height: 4),
              Text(
                'هذه المفاتيح هي ما يقرأه التطبيق — لا يُشتق أي سلوك من اسم '
                'المرحلة.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: 12),

              // No "starting stage" switch: the API has no such field, and the
              // one that used to be here saved nothing — the flow is ordered
              // by "ترتيب العرض" above, and the case begins at the lowest one
              // that applies to its intake.
              _SwitchTile(
                label: 'خارج المخبر',
                description: 'يتوقف عدّاد مدة الإنجاز أثناءها',
                value: _isExternal,
                onChanged: (value) => setState(() => _isExternal = value),
              ),
              const SizedBox(height: 12),
              _SwitchTile(
                label: 'مرحلة اختيارية',
                description: 'لا تُضاف تلقائياً — يُسأل عنها عند إنشاء كل حالة',
                value: _isOptional,
                onChanged: (value) => setState(() => _isOptional = value),
              ),
              const SizedBox(height: 12),
              _SwitchTile(
                label: 'تتطلب سبباً',
                description: 'لا يمكن النقل إليها بدون نص مكتوب',
                value: _requiresReason,
                onChanged: (value) => setState(() => _requiresReason = value),
              ),

              // Only offered when editing: a stage created deactivated would be
              // invisible the moment it is saved.
              if (_isEditing) ...[
                const SizedBox(height: 12),
                _SwitchTile(
                  label: 'مفعّلة',
                  description:
                      'المعطّلة تختفي من الاختيارات وتبقى على الحالات الحالية',
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],

              const SizedBox(height: 24),
              const _Label('إعادة إلى'),
              _StageRefPicker(
                stages: _earlierStages,
                value: _sendBackToStageId,
                emptyLabel: 'غير محددة',
                hint:
                    'المرحلة التي يُعاد إليها العمل عند الرفض. اتركها بلا '
                    'تحديد لتُعرض كل المراحل السابقة بدلاً من ذلك.',
                onChanged: (id) => setState(() => _sendBackToStageId = id),
              ),
              const SizedBox(height: 20),
              const _Label('المرحلة التالية'),
              _StageRefPicker(
                stages: _laterStages,
                value: _nextStageId,
                emptyLabel: 'غير محددة',
                hint:
                    'تتجاوز المرحلة التالية الافتراضية حسب الترتيب. اتركها '
                    'بلا تحديد إلا إذا كان على هذا الرقم مرحلتان تتشاركانه ولا '
                    'تلتقيان في نفس المرحلة التالية.',
                onChanged: (id) => setState(() => _nextStageId = id),
              ),

              const SizedBox(height: 24),
              const _Label('من ينفّذها'),
              StageAssigneesField(
                assignees: _assignees,
                onEdit: () async {
                  final picked = await showStageAssigneesSheet(
                    context,
                    initial: _assignees,
                  );
                  if (picked != null) setState(() => _assignees = picked);
                },
              ),

              const SizedBox(height: 24),
              CustomButtonWidget(
                onPressed: _submit,
                buttonText: _isEditing ? 'حفظ التعديلات' : 'إضافة المرحلة',
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(text, style: AppTextStyles.font16MediumText),
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, style: AppTextStyles.font14MediumText),
    ),
  );
}

/// The app's glass switch row. Carries a description line the priority form's
/// version does not have — these flags change behaviour in ways their labels
/// alone do not convey.
class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.value,
    required this.onChanged,
    this.description,
  });

  final String label;
  final String? description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                Text(label, style: AppTextStyles.font14MediumText),
                if (description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    description!,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// The intake a stage form should open on.
///
/// A stage saved before the API retired `any` still carries it; the picker no
/// longer offers it, so the form opens on the impression head rather than on a
/// chip the user cannot see selected. Nothing is lost silently — the stage is
/// resaved with whichever head the user confirms.
RouteStageAppliesTo _selectableIntake(RouteStageAppliesTo? saved) =>
    saved == null || saved == RouteStageAppliesTo.any
    ? RouteStageAppliesTo.traditionalOnly
    : saved;

/// Picks another stage of the same route — the rework target or the forward
/// override.
///
/// "غير محددة" is a real answer, not an empty state: an undeclared rework
/// target means the server offers every earlier stage instead, and an
/// undeclared next stage means plain `order` sequencing applies.
class _StageRefPicker extends StatelessWidget {
  const _StageRefPicker({
    required this.stages,
    required this.value,
    required this.emptyLabel,
    required this.hint,
    required this.onChanged,
  });

  final List<CaseStageModel> stages;
  final String? value;
  final String emptyLabel;
  final String hint;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    // A value pointing at a stage that is no longer eligible — the user just
    // changed the order or the intake — reads as "not declared" rather than
    // staying selected on an option that is no longer offered.
    final selected = stages.any((s) => s.id == value) ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stages.isEmpty)
          Text(
            'لا توجد مرحلة صالحة لهذا الاختيار بعد',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          )
        else
          // Chips, like every other choice in this sheet — the intake, the
          // timing, the badge. A dropdown opened a bare overlay that belonged
          // to no theme and mispositioned itself in RTL.
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(emptyLabel),
                selected: selected == null,
                onSelected: (_) => onChanged(null),
              ),
              for (final stage in stages)
                ChoiceChip(
                  label: Text(
                    '${stage.order + 1}. ${stage.displayName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: selected == stage.id,
                  onSelected: (_) => onChanged(stage.id),
                ),
            ],
          ),
        const SizedBox(height: 6),
        Text(
          hint,
          style: AppTextStyles.font12RegularHint.copyWith(
            color: glass.onGlassMuted,
          ),
        ),
      ],
    );
  }
}

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/stage_assignees_field.dart';
import 'package:dental_lab_app/core/widgets/stage_assignees_sheet.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter/material.dart';

/// What the sheet produced. Exactly one of the two is set — create and update
/// are different request shapes on this endpoint, and collapsing them would
/// mean sending "leave alone" fields on a create.
class WorkflowStageFormResult {
  const WorkflowStageFormResult.create(this.create) : update = null;
  const WorkflowStageFormResult.update(this.update) : create = null;

  final CreateWorkflowStageRequestModel? create;
  final UpdateWorkflowStageRequestModel? update;
}

/// Creates or edits one stage of a restoration type's route.
///
/// Built from the same pieces as every other form in the app — `AppTextFormField`
/// with a leading icon, the shared label, the glass switch tile — so it reads
/// as the same product as the case-workflow and priority forms.
///
/// Expected duration is not asked here any more — it lives on the
/// restoration type itself, one row per priority level, next to the type's
/// pricing.
Future<WorkflowStageFormResult?> showRestorationStageFormSheet(
  BuildContext context, {
  CaseWorkflowStageModel? initial,
  required String restorationTypeId,
  required int nextOrder,
  List<CaseWorkflowStageModel> allStages = const [],
}) {
  return showGlassBottomSheet<WorkflowStageFormResult>(
    context: context,
    builder: (_) => _StageFormSheet(
      initial: initial,
      restorationTypeId: restorationTypeId,
      nextOrder: nextOrder,
      allStages: allStages,
    ),
  );
}

class _StageFormSheet extends StatefulWidget {
  const _StageFormSheet({
    this.initial,
    required this.restorationTypeId,
    required this.nextOrder,
    required this.allStages,
  });

  final CaseWorkflowStageModel? initial;
  final String restorationTypeId;
  final int nextOrder;

  /// The route this stage belongs to, so the rework and branch pickers can
  /// scope their options the way the server validates them: same pipeline,
  /// and strictly earlier or strictly later in the running order.
  final List<CaseWorkflowStageModel> allStages;

  @override
  State<_StageFormSheet> createState() => _StageFormSheetState();
}

class _StageFormSheetState extends State<_StageFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nameArController;
  late final TextEditingController _keyController;
  late final TextEditingController _orderController;

  late RouteStageAppliesTo _appliesTo;

  /// Who may work the stage — the same three id lists the case workflow uses.
  late StageAssignees _assignees;
  late bool _isCheckpoint;
  late bool _isExternal;
  late bool _isOptional;
  late bool _isActive;
  String? _sendBackToStageId;
  String? _nextStageId;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    _nameController = TextEditingController(text: initial?.name ?? '');
    _nameArController = TextEditingController(text: initial?.nameAr ?? '');
    _keyController = TextEditingController(text: initial?.key ?? '');
    _orderController = TextEditingController(
      text: '${initial?.order ?? widget.nextOrder}',
    );

    _appliesTo = _selectableIntake(initial?.appliesTo);
    _assignees = (
      departmentIds: [for (final d in initial?.departments ?? const []) d.id],
      userIds: [for (final u in initial?.users ?? const []) u.id],
      excludedUserIds: [
        for (final u in initial?.excludedUsers ?? const []) u.id,
      ],
    );
    _isCheckpoint = initial?.isCheckpoint ?? false;
    _isExternal = initial?.isExternal ?? false;
    _isOptional = initial?.isOptional ?? false;
    _isActive = initial?.isActive ?? true;
    _sendBackToStageId = initial?.sendBackToStageId;
    _nextStageId = initial?.nextStageId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _keyController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  /// The order this stage is being saved with — the pickers scope against what
  /// the user typed, not against what the stage was loaded with.
  int get _currentOrder =>
      int.tryParse(_orderController.text.trim()) ??
      widget.initial?.order ??
      widget.nextOrder;

  /// Stages a rejection may send the unit back to: same pipeline, strictly
  /// earlier. Scoped the way the server validates it, so a bad pick is
  /// impossible rather than answered with a 400.
  List<CaseWorkflowStageModel> get _earlierStages => [
    for (final stage in widget.allStages)
      if (stage.id != widget.initial?.id &&
          stage.appliesTo == _appliesTo &&
          stage.order < _currentOrder)
        stage,
  ];

  /// Stages this one may jump forward to: same pipeline, strictly later.
  List<CaseWorkflowStageModel> get _laterStages => [
    for (final stage in widget.allStages)
      if (stage.id != widget.initial?.id &&
          stage.appliesTo == _appliesTo &&
          stage.order > _currentOrder)
        stage,
  ];
  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final order =
        int.tryParse(_orderController.text.trim()) ??
        widget.initial?.order ??
        widget.nextOrder;
    final key = _keyController.text.trim();

    if (_isEditing) {
      Navigator.of(context).pop(
        WorkflowStageFormResult.update(
          UpdateWorkflowStageRequestModel(
            name: _nameController.text.trim(),
            nameAr: _nameArController.text.trim(),
            key: key,
            order: order,
            isActive: _isActive,
            isCheckpoint: _isCheckpoint,
            isExternal: _isExternal,
            isOptional: _isOptional,
            sendBackToStageId: _sendBackToStageId,
            nextStageId: _nextStageId,
            // The update endpoint reads an omitted field as "leave alone", so
            // clearing a link has to be said out loud.
            clearSendBackTo: _sendBackToStageId == null,
            clearNextStage: _nextStageId == null,
            appliesTo: _appliesTo,
            departmentIds: _assignees.departmentIds,
            userIds: _assignees.userIds,
            excludedUserIds: _assignees.excludedUserIds,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      WorkflowStageFormResult.create(
        CreateWorkflowStageRequestModel(
          name: _nameController.text.trim(),
          restorationTypeId: widget.restorationTypeId,
          nameAr: _nameArController.text.trim(),
          key: key.isEmpty ? null : key,
          order: order,
          isCheckpoint: _isCheckpoint,
          isExternal: _isExternal,
          isOptional: _isOptional,
          sendBackToStageId: _sendBackToStageId,
          nextStageId: _nextStageId,
          appliesTo: _appliesTo,
          departmentIds: _assignees.departmentIds,
          userIds: _assignees.userIds,
          excludedUserIds: _assignees.excludedUserIds,
        ),
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
                _isEditing ? 'تعديل مرحلة التصنيع' : 'مرحلة تصنيع جديدة',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 24),

              const _Label('الاسم بالعربية'),
              AppTextFormField(
                controller: _nameArController,
                hintText: 'مثال: التصميم',
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.translate_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم بالعربية مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              const _Label('الاسم بالإنجليزية'),
              AppTextFormField(
                controller: _nameController,
                hintText: 'مثال: Design',
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.precision_manufacturing_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              const _Label('المعرّف الثابت'),
              AppTextFormField(
                controller: _keyController,
                hintText: 'يُستخدم لربط أسباب الرفض بهذه المرحلة (اختياري)',
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(Icons.key_outlined, color: glass.onGlassMuted),
                validator: (_) => null,
              ),
              const SizedBox(height: 20),

              const _Label('ترتيب العرض'),
              AppTextFormField(
                controller: _orderController,
                hintText: 'الأصغر يظهر أولاً',
                textInputAction: TextInputAction.next,
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

              const SizedBox(height: 24),
              const _SectionTitle('متى تُضاف هذه المرحلة'),
              const SizedBox(height: 4),
              Text(
                'هذان الشرطان يقرران إن كانت المرحلة تُقصّ على الحالة أصلاً.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: 12),

              const _Label('طريقة الاستلام'),
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

              const SizedBox(height: 24),
              const _SectionTitle('سلوك المرحلة'),
              const SizedBox(height: 12),

              // No "start"/"final"/"wait all" switches: the API has no such
              // fields — a route is ordered by "ترتيب العرض" alone, and the
              // switches that used to be here saved nothing.
              _SwitchTile(
                label: 'نقطة فحص',
                description: 'يمكن رفضها وإرجاع العمل بسبب مُرمَّز',
                value: _isCheckpoint,
                onChanged: (value) => setState(() => _isCheckpoint = value),
              ),
              const SizedBox(height: 12),
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
              if (_isEditing) ...[
                const SizedBox(height: 12),
                _SwitchTile(
                  label: 'مفعّلة',
                  description:
                      'المعطّلة تخرج من المسار وتبقى على التعويضات الحالية',
                  value: _isActive,
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],

              const SizedBox(height: 24),
              const _SectionTitle('الرجوع للخلف / التقدّم للأمام'),
              const SizedBox(height: 12),
              const _Label('إعادة إلى'),
              _StageRefPicker(
                stages: _earlierStages,
                value: _sendBackToStageId,
                hint:
                    'المرحلة التي تُعاد إليها الوحدة عند الرفض. اتركها بلا '
                    'تحديد لتُعرض كل المراحل السابقة بدلاً من ذلك.',
                onChanged: (id) => setState(() => _sendBackToStageId = id),
              ),
              const SizedBox(height: 20),
              const _Label('المرحلة التالية'),
              _StageRefPicker(
                stages: _laterStages,
                value: _nextStageId,
                hint:
                    'تتجاوز المرحلة التالية الافتراضية حسب الترتيب. اتركها بلا '
                    'تحديد إلا إذا كان على هذا الرقم مرحلتان تتشاركانه ولا '
                    'تلتقيان في نفس المرحلة التالية.',
                onChanged: (id) => setState(() => _nextStageId = id),
              ),

              const SizedBox(height: 24),
              const _SectionTitle('من ينفّذها'),
              const SizedBox(height: 12),
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

              const SizedBox(height: 8),
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
/// Chips, like every other choice in this sheet. "غير محددة" is a real answer:
/// an undeclared rework target means the server offers every earlier stage
/// instead, and an undeclared next stage means plain `order` sequencing.
class _StageRefPicker extends StatelessWidget {
  const _StageRefPicker({
    required this.stages,
    required this.value,
    required this.hint,
    required this.onChanged,
  });

  final List<CaseWorkflowStageModel> stages;
  final String? value;
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('غير محددة'),
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

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/data/models/save_department_request_model.dart';
import 'package:dental_lab_app/features/departments/ui/widgets/department_stages_picker.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:flutter/material.dart';

/// Creates or edits a department, including the restoration stages it owns.
///
/// One sheet rather than a screen plus a separate "link stages" screen: the
/// stages are the point of a department, and a department created without them
/// is a box nothing is ever handed to.
Future<SaveDepartmentRequestModel?> showDepartmentFormSheet(
  BuildContext context, {
  DepartmentModel? initial,
  required List<DepartmentModel> allDepartments,
  required List<RestorationTypeModel> types,
  required List<EmployeeModel> employees,
  Map<String, String> ownerByStageId = const {},
}) {
  return showGlassBottomSheet<SaveDepartmentRequestModel>(
    context: context,
    builder: (_) => _DepartmentFormSheet(
      initial: initial,
      allDepartments: allDepartments,
      types: types,
      employees: employees,
      ownerByStageId: ownerByStageId,
    ),
  );
}

class _DepartmentFormSheet extends StatefulWidget {
  const _DepartmentFormSheet({
    this.initial,
    required this.allDepartments,
    required this.types,
    required this.employees,
    required this.ownerByStageId,
  });

  final DepartmentModel? initial;

  /// Candidates for the parent picker.
  final List<DepartmentModel> allDepartments;

  /// Carries each type's stages, so the picker needs no second request.
  final List<RestorationTypeModel> types;

  final List<EmployeeModel> employees;

  /// Stage id → the department that already owns it. Handed straight to the
  /// picker, which greys those stages out.
  final Map<String, String> ownerByStageId;

  @override
  State<_DepartmentFormSheet> createState() => _DepartmentFormSheetState();
}

class _DepartmentFormSheetState extends State<_DepartmentFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _nameArController;
  late final TextEditingController _descriptionController;

  late bool _isActive;
  String? _parentId;
  late Set<String> _stageIds;
  late Set<String> _employeeIds;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;

    _nameController = TextEditingController(text: initial?.name ?? '');
    _nameArController = TextEditingController(text: initial?.nameAr ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );

    _isActive = initial?.isActive ?? true;
    _parentId = initial?.parentId;
    _stageIds = {for (final stage in initial?.stages ?? const []) stage.id};
    _employeeIds = {
      for (final employee in initial?.employees ?? const [])
        ?employee.employeeId,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// A department may not be its own parent, nor sit under one of its own
  /// children — either would make the tree a loop.
  List<DepartmentModel> get _parentCandidates => [
    for (final department in widget.allDepartments)
      if (department.id != widget.initial?.id)
        if (department.parentId != widget.initial?.id) department,
  ];

  /// Every stage in the lab, by id — so chosen stages can be named back
  /// without another request.
  Map<String, ({String stage, String type})> get _stageLabels => {
    for (final type in widget.types)
      for (final stage in type.stages)
        stage.id: (stage: stage.displayName, type: type.displayName),
  };

  Future<void> _pickStages() async {
    final result = await showDepartmentStagesPicker(
      context,
      types: widget.types,
      selectedIds: _stageIds,
      ownerByStageId: widget.ownerByStageId,
    );
    if (result == null || !mounted) return;

    setState(() => _stageIds = result);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      SaveDepartmentRequestModel(
        name: _nameController.text.trim(),
        nameAr: _nameArController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        parentId: _parentId,
        // Always sent, empty included: the save replaces the membership, and
        // an omitted list would make "unlink them all" do nothing.
        stageIds: _stageIds.toList(),
        employeeIds: _employeeIds.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final labels = _stageLabels;

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
                _isEditing ? 'تعديل القسم' : 'قسم جديد',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: 24),

              const _Label('الاسم بالعربية'),
              AppTextFormField(
                controller: _nameArController,
                hintText: 'مثال: التشطيب',
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.translate_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (_) => null,
              ),
              const SizedBox(height: 20),

              const _Label('الاسم بالإنجليزية'),
              AppTextFormField(
                controller: _nameController,
                hintText: 'مثال: Finishing',
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.apartment_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم مطلوب'
                    : null,
              ),
              const SizedBox(height: 20),

              const _Label('الوصف'),
              AppTextFormField(
                controller: _descriptionController,
                hintText: 'اختياري',
                maxLines: 2,
                prefixIcon: Icon(
                  Icons.notes_outlined,
                  color: glass.onGlassMuted,
                ),
                validator: (_) => null,
              ),
              const SizedBox(height: 20),

              const _Label('القسم الأعلى'),
              _ParentPicker(
                candidates: _parentCandidates,
                selectedId: _parentId,
                onChanged: (value) => setState(
                  // Tapping the selected chip clears it — a top-level
                  // department is the common answer.
                  () => _parentId = _parentId == value ? null : value,
                ),
              ),

              const SizedBox(height: 24),
              const _SectionTitle('مراحل التعويضات'),
              const SizedBox(height: 4),
              Text(
                'هذه هي المراحل التي يستلمها القسم في الإنتاج. '
                'قسم بلا مراحل لن يصله عمل.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              const SizedBox(height: 12),
              _StageSummary(
                stageIds: _stageIds,
                labels: labels,
                onPick: _pickStages,
                onRemove: (id) => setState(() => _stageIds.remove(id)),
              ),

              const SizedBox(height: 24),
              const _SectionTitle('الموظفون'),
              const SizedBox(height: 12),
              if (widget.employees.isEmpty)
                Text(
                  'لا يوجد موظفون بعد.',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final employee in widget.employees)
                      FilterChip(
                        label: Text(employee.fullName),
                        selected: _employeeIds.contains(employee.id),
                        onSelected: (selected) => setState(
                          () => selected
                              ? _employeeIds.add(employee.id)
                              : _employeeIds.remove(employee.id),
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 20),
              SwitchListTile(
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'قسم فعّال',
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                subtitle: Text(
                  'القسم المعطّل يبقى على العمل الجاري ولا يستلم جديداً',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ),

              const SizedBox(height: 24),
              CustomButtonWidget(buttonText: 'حفظ', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// The chosen stages, named — a count alone ("٤ مراحل") is not something a
/// user can check before saving.
class _StageSummary extends StatelessWidget {
  const _StageSummary({
    required this.stageIds,
    required this.labels,
    required this.onPick,
    required this.onRemove,
  });

  final Set<String> stageIds;
  final Map<String, ({String stage, String type})> labels;
  final VoidCallback onPick;
  final ValueChanged<String> onRemove;

  /// A stage whose restoration type has since been deleted still has to
  /// render: dropping it silently would unlink it on the next save.
  String _labelFor(String id) {
    final label = labels[id];
    if (label == null) return 'مرحلة غير معروفة';
    return '${label.stage} · ${label.type}';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stageIds.isEmpty)
          Text(
            'لم تُربط أي مرحلة بعد',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in stageIds)
                InputChip(
                  label: Text(_labelFor(id)),
                  onDeleted: () => onRemove(id),
                ),
            ],
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onPick,
          icon: const Icon(Icons.link),
          label: const Text('اختيار المراحل'),
        ),
      ],
    );
  }
}

class _ParentPicker extends StatelessWidget {
  const _ParentPicker({
    required this.candidates,
    required this.selectedId,
    required this.onChanged,
  });

  final List<DepartmentModel> candidates;
  final String? selectedId;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (candidates.isEmpty) {
      return Text(
        'لا توجد أقسام أخرى',
        style: AppTextStyles.font12RegularHint.copyWith(
          color: context.glass.onGlassMuted,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final department in candidates)
          ChoiceChip(
            label: Text(department.displayName),
            selected: selectedId == department.id,
            onSelected: (_) => onChanged(department.id),
          ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: AppTextStyles.font14RegularSecondary.copyWith(
        color: context.glass.onGlass,
      ),
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTextStyles.font16MediumText.copyWith(
      color: context.glass.onGlass,
    ),
  );
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_type_form/restoration_type_form_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_type_form/restoration_type_form_state.dart';
import 'package:dental_lab_app/features/restoration_types/ui/widgets/restoration_type_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit restoration-type screen. Pass [initialRestorationType] to edit.
class RestorationTypeFormPage extends StatelessWidget {
  const RestorationTypeFormPage({super.key, this.initialRestorationType});

  final RestorationTypeModel? initialRestorationType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RestorationTypeFormCubit>(),
      child: _RestorationTypeFormView(
        initialRestorationType: initialRestorationType,
      ),
    );
  }
}

class _RestorationTypeFormView extends StatefulWidget {
  const _RestorationTypeFormView({this.initialRestorationType});

  final RestorationTypeModel? initialRestorationType;

  @override
  State<_RestorationTypeFormView> createState() =>
      _RestorationTypeFormViewState();
}

class _RestorationTypeFormViewState extends State<_RestorationTypeFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialRestorationType?.name ?? '',
  );
  late final _nameArController = TextEditingController(
    text: widget.initialRestorationType?.nameAr ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialRestorationType?.description ?? '',
  );
  late final _defaultPriceController = TextEditingController(
    text: widget.initialRestorationType?.defaultPrice.toString() ?? '',
  );
  late final _transparencyController = TextEditingController(
    text: widget.initialRestorationType?.transparency?.toString() ?? '',
  );
  late final _lowDurationController = TextEditingController(
    text:
        widget.initialRestorationType?.lowPriorityDurationMinutes?.toString() ??
        '',
  );
  late final _normalDurationController = TextEditingController(
    text:
        widget.initialRestorationType?.normalPriorityDurationMinutes
            ?.toString() ??
        '',
  );
  late final _highDurationController = TextEditingController(
    text:
        widget.initialRestorationType?.highPriorityDurationMinutes
            ?.toString() ??
        '',
  );
  late final _urgentDurationController = TextEditingController(
    text:
        widget.initialRestorationType?.urgentPriorityDurationMinutes
            ?.toString() ??
        '',
  );

  late int _pricingType = widget.initialRestorationType?.pricingType ?? 1;
  late bool _isActive = widget.initialRestorationType?.isActive ?? true;

  /// Stages picked while creating — the API accepts them inline on create.
  final List<CreateRestorationTypeStageRequestModel> _stages = [];

  /// Stages for the type being edited — pre-filled from the type's current
  /// stages (keeping their [id] so the update call matches/updates them in
  /// place) and edited locally. The whole list is sent as a full replace
  /// when saving.
  late final List<UpdateRestorationTypeStageRequestModel> _editStages = [
    for (final s in widget.initialRestorationType?.stages ?? const [])
      UpdateRestorationTypeStageRequestModel(
        id: s.id,
        name: s.name ?? '',
        order: s.order,
        isFinal: s.isFinal,
        isActive: s.isActive,
      ),
  ];

  bool get _isEditing => widget.initialRestorationType != null;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _defaultPriceController.dispose();
    _transparencyController.dispose();
    _lowDurationController.dispose();
    _normalDurationController.dispose();
    _highDurationController.dispose();
    _urgentDurationController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  double? _optionalDouble(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : double.tryParse(value);
  }

  int? _optionalInt(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  Future<void> _onAddStage() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddStageDialog(),
    );
    if (name == null) return;

    setState(() {
      _stages.add(
        CreateRestorationTypeStageRequestModel(
          name: name,
          order: _stages.length + 1,
        ),
      );
    });
  }

  void _onRemoveStage(int index) {
    setState(() {
      _stages.removeAt(index);
      _reorderStages();
    });
  }

  /// Only one stage can be the final one.
  void _onToggleStageFinal(int index) {
    setState(() {
      final wasFinal = _stages[index].isFinal;
      for (var i = 0; i < _stages.length; i++) {
        _stages[i] = CreateRestorationTypeStageRequestModel(
          name: _stages[i].name,
          order: _stages[i].order,
          isFinal: i == index ? !wasFinal : false,
        );
      }
    });
  }

  void _reorderStages() {
    for (var i = 0; i < _stages.length; i++) {
      _stages[i] = CreateRestorationTypeStageRequestModel(
        name: _stages[i].name,
        order: i + 1,
        isFinal: _stages[i].isFinal,
      );
    }
  }

  Future<void> _onAddEditStage() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddStageDialog(),
    );
    if (name == null) return;

    setState(() {
      _editStages.add(
        UpdateRestorationTypeStageRequestModel(
          name: name,
          order: _editStages.length + 1,
        ),
      );
    });
  }

  void _onRemoveEditStage(int index) {
    setState(() {
      _editStages.removeAt(index);
      _reorderEditStages();
    });
  }

  /// Only one stage can be the final one.
  void _onToggleEditStageFinal(int index) {
    setState(() {
      final wasFinal = _editStages[index].isFinal;
      for (var i = 0; i < _editStages.length; i++) {
        _editStages[i] = UpdateRestorationTypeStageRequestModel(
          id: _editStages[i].id,
          name: _editStages[i].name,
          order: _editStages[i].order,
          isFinal: i == index ? !wasFinal : false,
          isActive: _editStages[i].isActive,
        );
      }
    });
  }

  void _reorderEditStages() {
    for (var i = 0; i < _editStages.length; i++) {
      _editStages[i] = UpdateRestorationTypeStageRequestModel(
        id: _editStages[i].id,
        name: _editStages[i].name,
        order: i + 1,
        isFinal: _editStages[i].isFinal,
        isActive: _editStages[i].isActive,
      );
    }
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final hasStages = _isEditing ? _editStages.isNotEmpty : _stages.isNotEmpty;
    if (!hasStages) {
      ShowToast(
        message: 'يجب إضافة مرحلة واحدة على الأقل',
        state: toastState.error,
      );
      return;
    }

    final cubit = context.read<RestorationTypeFormCubit>();
    final defaultPrice =
        double.tryParse(_defaultPriceController.text.trim()) ?? 0;

    if (_isEditing) {
      cubit.updateRestorationType(
        id: widget.initialRestorationType!.id,
        updateRequestBody: UpdateRestorationTypeRequestModel(
          name: _nameController.text.trim(),
          nameAr: _optional(_nameArController),
          description: _optional(_descriptionController),
          transparency: _optionalDouble(_transparencyController),
          defaultPrice: defaultPrice,
          pricingType: _pricingType,
          isActive: _isActive,
          lowPriorityDurationMinutes: _optionalInt(_lowDurationController),
          normalPriorityDurationMinutes: _optionalInt(
            _normalDurationController,
          ),
          highPriorityDurationMinutes: _optionalInt(_highDurationController),
          urgentPriorityDurationMinutes: _optionalInt(
            _urgentDurationController,
          ),
          stages: _editStages,
        ),
      );
    } else {
      cubit.createRestorationType(
        CreateRestorationTypeRequestModel(
          name: _nameController.text.trim(),
          nameAr: _optional(_nameArController),
          description: _optional(_descriptionController),
          transparency: _optionalDouble(_transparencyController),
          defaultPrice: defaultPrice,
          pricingType: _pricingType,
          lowPriorityDurationMinutes: _optionalInt(_lowDurationController),
          normalPriorityDurationMinutes: _optionalInt(
            _normalDurationController,
          ),
          highPriorityDurationMinutes: _optionalInt(_highDurationController),
          urgentPriorityDurationMinutes: _optionalInt(
            _urgentDurationController,
          ),
          stages: _stages,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل التعويض' : 'إضافة تعويض',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<RestorationTypeFormCubit, RestorationTypeFormState>(
          listener: (context, state) {
            switch (state) {
              case RestorationTypeFormSuccess():
                ShowToast(
                  message: _isEditing
                      ? 'تم حفظ التعديلات'
                      : 'تمت إضافة التعويض',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case RestorationTypeFormError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 600;
                final contentWidth = isWide ? 560.0 : constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: RestorationTypeFormFields(
                        formKey: _formKey,
                        nameController: _nameController,
                        nameArController: _nameArController,
                        descriptionController: _descriptionController,
                        defaultPriceController: _defaultPriceController,
                        transparencyController: _transparencyController,
                        lowDurationController: _lowDurationController,
                        normalDurationController: _normalDurationController,
                        highDurationController: _highDurationController,
                        urgentDurationController: _urgentDurationController,
                        pricingType: _pricingType,
                        onPricingTypeChanged: (value) =>
                            setState(() => _pricingType = value),
                        isEditing: _isEditing,
                        isActive: _isActive,
                        onActiveChanged: (value) =>
                            setState(() => _isActive = value),
                        stages: _stages,
                        onAddStage: _onAddStage,
                        onRemoveStage: _onRemoveStage,
                        onToggleStageFinal: _onToggleStageFinal,
                        editStages: _editStages,
                        onAddEditStage: _onAddEditStage,
                        onRemoveEditStage: _onRemoveEditStage,
                        onToggleEditStageFinal: _onToggleEditStageFinal,
                        isSubmitting: state is RestorationTypeFormSubmitting,
                        onSave: _onSavePressed,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Asks for a stage name. Owns its controller so it isn't disposed while the
/// dialog is still animating out.
class _AddStageDialog extends StatefulWidget {
  const _AddStageDialog();

  @override
  State<_AddStageDialog> createState() => _AddStageDialogState();
}

class _AddStageDialogState extends State<_AddStageDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة مرحلة', style: AppTextStyles.font18MediumText),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: AppTextFormField(
            controller: _nameController,
            hintText: 'اسم المرحلة (مثال: التصميم)',
            prefixIcon: Icon(
              Icons.timeline_outlined,
              color: context.glass.onGlassMuted,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'اسم المرحلة مطلوب'
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onAdd, child: const Text('إضافة')),
      ],
    );
  }
}

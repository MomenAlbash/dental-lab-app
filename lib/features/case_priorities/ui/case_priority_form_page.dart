import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/save_case_priority_request_model.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priority_form/case_priority_form_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priority_form/case_priority_form_state.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/case_priority_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit case-priority screen. Pass [initialPriority] to edit.
class CasePriorityFormPage extends StatelessWidget {
  const CasePriorityFormPage({super.key, this.initialPriority});

  final CasePriorityModel? initialPriority;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CasePriorityFormCubit>(),
      child: _CasePriorityFormView(initialPriority: initialPriority),
    );
  }
}

class _CasePriorityFormView extends StatefulWidget {
  const _CasePriorityFormView({this.initialPriority});

  final CasePriorityModel? initialPriority;

  @override
  State<_CasePriorityFormView> createState() => _CasePriorityFormViewState();
}

class _CasePriorityFormViewState extends State<_CasePriorityFormView> {
  final _formKey = GlobalKey<FormState>();

  late final _nameController = TextEditingController(
    text: widget.initialPriority?.name ?? '',
  );
  late final _nameArController = TextEditingController(
    text: widget.initialPriority?.nameAr ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialPriority?.description ?? '',
  );
  late final _displayOrderController = TextEditingController(
    text: widget.initialPriority?.displayOrder.toString() ?? '',
  );
  late final _freePerMonthController = TextEditingController(
    text: widget.initialPriority?.freePerMonth.toString() ?? '',
  );
  late final _surchargeController = TextEditingController(
    text: widget.initialPriority?.surcharge.toString() ?? '',
  );

  late String _badgeVariant =
      widget.initialPriority?.badgeVariant ?? kBadgeVariants.first.value;
  late bool _isDefault = widget.initialPriority?.isDefault ?? false;
  late bool _isUnlimited = widget.initialPriority?.isUnlimited ?? false;
  late bool _isActive = widget.initialPriority?.isActive ?? true;

  bool get _isEditing => widget.initialPriority != null;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    _freePerMonthController.dispose();
    _surchargeController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final body = SaveCasePriorityRequestModel(
      name: _nameController.text.trim(),
      nameAr: _optional(_nameArController),
      description: _optional(_descriptionController),
      displayOrder: int.tryParse(_displayOrderController.text.trim()) ?? 0,
      isDefault: _isDefault,
      isUnlimited: _isUnlimited,
      // An unlimited priority has no free allowance to speak of; sending the
      // stale number back would leave a misleading value on the record.
      freePerMonth: _isUnlimited
          ? 0
          : (int.tryParse(_freePerMonthController.text.trim()) ?? 0),
      surcharge: double.tryParse(_surchargeController.text.trim()) ?? 0,
      badgeVariant: _badgeVariant,
      isActive: _isActive,
    );

    final cubit = context.read<CasePriorityFormCubit>();

    if (_isEditing) {
      cubit.updateCasePriority(
        id: widget.initialPriority!.id,
        saveRequestBody: body,
      );
    } else {
      cubit.createCasePriority(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل الأولوية' : 'إضافة أولوية',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<CasePriorityFormCubit, CasePriorityFormState>(
          listener: (context, state) {
            switch (state) {
              case CasePriorityFormSuccess():
                ShowToast(
                  message: _isEditing
                      ? 'تم حفظ التعديلات'
                      : 'تمت إضافة الأولوية',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case CasePriorityFormError(:final message):
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
                      child: CasePriorityFormFields(
                        formKey: _formKey,
                        nameController: _nameController,
                        nameArController: _nameArController,
                        descriptionController: _descriptionController,
                        displayOrderController: _displayOrderController,
                        freePerMonthController: _freePerMonthController,
                        surchargeController: _surchargeController,
                        badgeVariant: _badgeVariant,
                        onBadgeVariantChanged: (value) =>
                            setState(() => _badgeVariant = value),
                        isDefault: _isDefault,
                        onDefaultChanged: (value) =>
                            setState(() => _isDefault = value),
                        isUnlimited: _isUnlimited,
                        onUnlimitedChanged: (value) =>
                            setState(() => _isUnlimited = value),
                        isActive: _isActive,
                        onActiveChanged: (value) =>
                            setState(() => _isActive = value),
                        isEditing: _isEditing,
                        isSubmitting: state is CasePriorityFormSubmitting,
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

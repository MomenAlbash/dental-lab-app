import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
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
  late final _displayOrderController = TextEditingController(
    text: widget.initialRestorationType?.displayOrder?.toString() ?? '',
  );

  late int _pricingType = widget.initialRestorationType?.pricingType ?? 1;
  late bool _showInClinicApp =
      widget.initialRestorationType?.showInClinicApp ?? true;
  late bool _isActive = widget.initialRestorationType?.isActive ?? true;

  bool get _isEditing => widget.initialRestorationType != null;

  @override
  void dispose() {
    _nameController.dispose();
    _nameArController.dispose();
    _descriptionController.dispose();
    _defaultPriceController.dispose();
    _transparencyController.dispose();
    _displayOrderController.dispose();
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

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
          showInClinicApp: _showInClinicApp,
          isActive: _isActive,
          displayOrder: _optionalInt(_displayOrderController),
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
          showInClinicApp: _showInClinicApp,
          displayOrder: _optionalInt(_displayOrderController),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل التعويض' : 'إضافة تعويض',
          style: AppTextStyles.font18MediumText,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<RestorationTypeFormCubit, RestorationTypeFormState>(
          listener: (context, state) {
            switch (state) {
              case RestorationTypeFormSuccess():
                ShowToast(
                  message: _isEditing ? 'تم حفظ التعديلات' : 'تمت إضافة التعويض',
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
                        displayOrderController: _displayOrderController,
                        pricingType: _pricingType,
                        onPricingTypeChanged: (value) =>
                            setState(() => _pricingType = value),
                        showInClinicApp: _showInClinicApp,
                        onShowInClinicAppChanged: (value) =>
                            setState(() => _showInClinicApp = value),
                        isEditing: _isEditing,
                        isActive: _isActive,
                        onActiveChanged: (value) =>
                            setState(() => _isActive = value),
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

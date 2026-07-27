import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/create_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/update_clinic_request_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_state.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit clinic screen. Pass [initialClinic] to open in edit mode.
///
/// The form submission is driven by [ClinicFormCubit]; the city dropdown is
/// fed by the standalone [CitiesCubit] — the two concerns stay separate.
class ClinicFormPage extends StatelessWidget {
  const ClinicFormPage({super.key, this.initialClinic});

  final ClinicModel? initialClinic;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ClinicFormCubit>()),
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
      ],
      child: _ClinicFormView(initialClinic: initialClinic),
    );
  }
}

class _ClinicFormView extends StatefulWidget {
  const _ClinicFormView({this.initialClinic});

  final ClinicModel? initialClinic;

  @override
  State<_ClinicFormView> createState() => _ClinicFormViewState();
}

class _ClinicFormViewState extends State<_ClinicFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialClinic?.name ?? '',
  );
  late final _codeController = TextEditingController(
    text: widget.initialClinic?.code ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialClinic?.phoneNumber ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.initialClinic?.email ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialClinic?.address ?? '',
  );
  late final _websiteController = TextEditingController(
    text: widget.initialClinic?.websiteUrl ?? '',
  );

  late String? _cityId = widget.initialClinic?.cityId;

  bool get _isEditing => widget.initialClinic != null;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  /// Optional fields are sent as `null` rather than an empty string so the
  /// API stores "not set" instead of a blank value.
  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<ClinicFormCubit>();

    if (_isEditing) {
      cubit.updateClinic(
        id: widget.initialClinic!.id,
        updateClinicRequestBody: UpdateClinicRequestModel(
          name: _nameController.text.trim(),
          code: _optional(_codeController),
          phoneNumber: _optional(_phoneController),
          email: _optional(_emailController),
          address: _optional(_addressController),
          cityId: _cityId,
          websiteUrl: _optional(_websiteController),
        ),
      );
    } else {
      cubit.createClinic(
        CreateClinicRequestModel(
          name: _nameController.text.trim(),
          code: _optional(_codeController),
          phoneNumber: _optional(_phoneController),
          email: _optional(_emailController),
          address: _optional(_addressController),
          cityId: _cityId,
          websiteUrl: _optional(_websiteController),
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
          _isEditing ? 'تعديل العيادة' : 'إضافة عيادة',
          style: AppTextStyles.font18MediumText,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ClinicFormCubit, ClinicFormState>(
          listener: (context, state) {
            switch (state) {
              case ClinicFormSuccess():
                ShowToast(
                  message: _isEditing ? 'تم حفظ التعديلات' : 'تمت إضافة العيادة',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case ClinicFormError(:final message):
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
                      child: ClinicFormFields(
                        formKey: _formKey,
                        nameController: _nameController,
                        codeController: _codeController,
                        addressController: _addressController,
                        phoneController: _phoneController,
                        emailController: _emailController,
                        websiteController: _websiteController,
                        cityId: _cityId,
                        onCityChanged: (value) =>
                            setState(() => _cityId = value),
                        isSubmitting: state is ClinicFormSubmitting,
                        isEditing: _isEditing,
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

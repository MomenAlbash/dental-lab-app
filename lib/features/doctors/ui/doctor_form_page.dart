import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/models/create_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_form/doctor_form_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_form/doctor_form_state.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit doctor screen. Pass [initialDoctor] to open in edit mode.
///
/// Submission is driven by [DoctorFormCubit]; the city and clinic pickers are
/// fed by the standalone [CitiesCubit] and [ClinicsCubit] — each concern stays
/// in its own cubit.
class DoctorFormPage extends StatelessWidget {
  const DoctorFormPage({super.key, this.initialDoctor});

  final DoctorModel? initialDoctor;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DoctorFormCubit>()),
        BlocProvider(create: (_) => getIt<CitiesCubit>()..getCities()),
        BlocProvider(create: (_) => getIt<ClinicsCubit>()..getClinics()),
      ],
      child: _DoctorFormView(initialDoctor: initialDoctor),
    );
  }
}

class _DoctorFormView extends StatefulWidget {
  const _DoctorFormView({this.initialDoctor});

  final DoctorModel? initialDoctor;

  @override
  State<_DoctorFormView> createState() => _DoctorFormViewState();
}

class _DoctorFormViewState extends State<_DoctorFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: widget.initialDoctor?.firstName ?? '',
  );
  late final _lastNameController = TextEditingController(
    text: widget.initialDoctor?.lastName ?? '',
  );
  late final _emailController = TextEditingController(
    text: widget.initialDoctor?.email ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialDoctor?.phoneNumber ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.initialDoctor?.address ?? '',
  );

  late DoctorGender _gender = widget.initialDoctor?.gender ?? DoctorGender.male;
  late DateTime? _dateOfBirth = _parseDate(widget.initialDoctor?.dateOfBirth);
  late String? _cityId = widget.initialDoctor?.cityId;
  late String? _clinicId = widget.initialDoctor?.clinicId;
  late bool _isActive = widget.initialDoctor?.isActive ?? true;

  bool get _isEditing => widget.initialDoctor != null;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  /// `yyyy-MM-dd` — the format the API's `dateOfBirth` field expects.
  String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(1930),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<DoctorFormCubit>();

    if (_isEditing) {
      cubit.updateDoctor(
        id: widget.initialDoctor!.id,
        updateDoctorRequestBody: UpdateDoctorRequestModel(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _optional(_emailController),
          phoneNumber: _optional(_phoneController),
          address: _optional(_addressController),
          gender: _gender.apiValue,
          dateOfBirth: _formatDate(_dateOfBirth),
          cityId: _cityId,
          clinicId: _clinicId,
          isActive: _isActive,
        ),
      );
    } else {
      cubit.createDoctor(
        CreateDoctorRequestModel(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _optional(_emailController),
          phoneNumber: _optional(_phoneController),
          address: _optional(_addressController),
          gender: _gender.apiValue,
          dateOfBirth: _formatDate(_dateOfBirth),
          cityId: _cityId,
          clinicId: _clinicId,
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
          _isEditing ? 'تعديل الدكتور' : 'إضافة دكتور',
          style: AppTextStyles.font18MediumText,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<DoctorFormCubit, DoctorFormState>(
          listener: (context, state) {
            switch (state) {
              case DoctorFormSuccess():
                ShowToast(
                  message: _isEditing
                      ? 'تم حفظ التعديلات'
                      : 'تمت إضافة الدكتور',
                  state: toastState.success,
                );
                Navigator.of(context).pop(true);
              case DoctorFormError(:final message):
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
                      child: DoctorFormFields(
                        formKey: _formKey,
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                        emailController: _emailController,
                        phoneController: _phoneController,
                        addressController: _addressController,
                        gender: _gender,
                        onGenderChanged: (value) =>
                            setState(() => _gender = value),
                        dateOfBirth: _formatDate(_dateOfBirth),
                        onPickDate: _pickDateOfBirth,
                        cityId: _cityId,
                        onCityChanged: (value) =>
                            setState(() => _cityId = value),
                        clinicId: _clinicId,
                        onClinicChanged: (value) =>
                            setState(() => _clinicId = value),
                        isSubmitting: state is DoctorFormSubmitting,
                        isEditing: _isEditing,
                        isActive: _isActive,
                        onActiveChanged: (value) =>
                            setState(() => _isActive = value),
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

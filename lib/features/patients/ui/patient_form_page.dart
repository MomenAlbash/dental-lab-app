import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_save_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/core/widgets/unsaved_changes_guard.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_state.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add-patient screen (`POST /api/clinic/Patients`). Only `doctorId` and
/// `firstName` are required by the API.
class PatientFormPage extends StatelessWidget {
  const PatientFormPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<PatientFormCubit>()),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
      ],
      child: const _PatientFormView(),
    );
  }
}

class _PatientFormView extends StatefulWidget {
  const _PatientFormView();

  @override
  State<_PatientFormView> createState() => _PatientFormViewState();
}

class _PatientFormViewState extends State<_PatientFormView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  String? _doctorId;
  PatientGender _gender = PatientGender.male;
  DateTime? _dateOfBirth;

  @override
  void initState() {
    super.initState();
    // The preview mirrors the name as it is typed.
    _firstNameController.addListener(_onNameChanged);
    _lastNameController.addListener(_onNameChanged);
  }

  void _onNameChanged() => setState(() {});

  @override
  void dispose() {
    _firstNameController.removeListener(_onNameChanged);
    _lastNameController.removeListener(_onNameChanged);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
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
      initialDate: _dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1930),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  /// Resolved fresh at save time rather than cached in state: the clinic
  /// always follows whichever doctor is currently selected.
  String? _clinicIdFor(String doctorId) {
    final doctorsState = context.read<DoctorsCubit>().state;
    if (doctorsState is! DoctorsLoaded) return null;
    for (final doctor in doctorsState.doctors) {
      if (doctor.id == doctorId) return doctor.clinicId;
    }
    return null;
  }

  /// Whether anything has been entered — asked when the user tries to leave,
  /// so a discarded entry is never silent. Create-only, so everything is
  /// compared against the empty defaults the form opens with.
  bool get _isDirty =>
      isTextDirty(_firstNameController) ||
      isTextDirty(_lastNameController) ||
      isTextDirty(_phoneController) ||
      isTextDirty(_notesController) ||
      _doctorId != null ||
      _gender != PatientGender.male ||
      _dateOfBirth != null;

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final doctorId = _doctorId;
    if (doctorId == null) {
      ShowToast(message: 'الرجاء اختيار الطبيب', state: toastState.error);
      return;
    }

    context.read<PatientFormCubit>().createPatient(
      CreatePatientRequestModel(
        doctorId: doctorId,
        clinicId: _clinicIdFor(doctorId),
        firstName: _firstNameController.text.trim(),
        lastName: _optional(_lastNameController),
        gender: _gender.apiValue,
        dateOfBirth: _formatDate(_dateOfBirth),
        phoneNumber: _optional(_phoneController),
        notes: _optional(_notesController),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: () => _isDirty,
      child: GlassScaffold(
        appBar: GlassAppBar(
          title: Text(
            'إضافة مريض',
            style: AppTextStyles.font18MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<PatientFormCubit, PatientFormState>(
          builder: (context, state) => GlassSaveBar(
            isSubmitting: state is PatientFormSubmitting,
            label: 'إضافة المريض',
            onSave: _onSavePressed,
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<PatientFormCubit, PatientFormState>(
            listener: (context, state) {
              switch (state) {
                case PatientFormSuccess():
                  ShowToast(
                    message: 'تمت إضافة المريض',
                    state: toastState.success,
                  );
                  Navigator.of(context).pop(true);
                case PatientFormError(:final message):
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
                      padding: EdgeInsets.fromLTRB(
                        isWide ? 32 : 20,
                        20,
                        isWide ? 32 : 20,
                        // Clears the pinned save bar.
                        110,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: contentWidth),
                        child: BlocBuilder<DoctorsCubit, DoctorsState>(
                          builder: (context, doctorsState) {
                            String? clinicName;
                            if (doctorsState is DoctorsLoaded &&
                                _doctorId != null) {
                              for (final doctor in doctorsState.doctors) {
                                if (doctor.id == _doctorId) {
                                  clinicName = doctor.clinicName;
                                  break;
                                }
                              }
                            }

                            return PatientFormFields(
                              formKey: _formKey,
                              firstNameController: _firstNameController,
                              lastNameController: _lastNameController,
                              phoneController: _phoneController,
                              notesController: _notesController,
                              gender: _gender,
                              onGenderChanged: (value) =>
                                  setState(() => _gender = value),
                              dateOfBirth: _formatDate(_dateOfBirth),
                              onPickDate: _pickDateOfBirth,
                              doctorId: _doctorId,
                              onDoctorChanged: (value) =>
                                  setState(() => _doctorId = value),
                              clinicName: clinicName,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

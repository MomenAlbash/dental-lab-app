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
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_state.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit patient screen (`POST /api/clinic/Patients`, `PUT
/// /api/clinic/Patients/{id}`). Pass [initialPatient] to open in edit mode.
/// Only `doctorId` and `firstName` are required by the API.
class PatientFormPage extends StatelessWidget {
  const PatientFormPage({super.key, this.initialPatient});

  final PatientModel? initialPatient;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<PatientFormCubit>()),
        BlocProvider(create: (_) => getIt<DoctorsCubit>()..getDoctors()),
      ],
      child: _PatientFormView(initialPatient: initialPatient),
    );
  }
}

class _PatientFormView extends StatefulWidget {
  const _PatientFormView({this.initialPatient});

  final PatientModel? initialPatient;

  @override
  State<_PatientFormView> createState() => _PatientFormViewState();
}

class _PatientFormViewState extends State<_PatientFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameController = TextEditingController(
    text: widget.initialPatient?.firstName ?? '',
  );
  late final _lastNameController = TextEditingController(
    text: widget.initialPatient?.lastName ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialPatient?.phoneNumber ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.initialPatient?.notes ?? '',
  );

  late String? _doctorId = widget.initialPatient?.doctorId;
  late PatientGender _gender =
      widget.initialPatient?.gender ?? PatientGender.male;

  /// The API sends `dateOfBirth` as `yyyy-MM-dd`; anything it cannot parse
  /// leaves the picker empty rather than failing the screen.
  late DateTime? _dateOfBirth = DateTime.tryParse(
    widget.initialPatient?.dateOfBirth ?? '',
  );

  bool get _isEditing => widget.initialPatient != null;

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

  /// Whether anything differs from what the form opened with — asked when the
  /// user tries to leave, so a discarded entry is never silent. On a create
  /// that baseline is the empty defaults; on an edit it is the patient.
  bool get _isDirty {
    final initial = widget.initialPatient;
    return isTextDirty(_firstNameController, initial?.firstName) ||
        isTextDirty(_lastNameController, initial?.lastName) ||
        isTextDirty(_phoneController, initial?.phoneNumber) ||
        isTextDirty(_notesController, initial?.notes) ||
        _doctorId != initial?.doctorId ||
        _gender != (initial?.gender ?? PatientGender.male) ||
        _formatDate(_dateOfBirth) != initial?.dateOfBirth;
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final doctorId = _doctorId;
    if (doctorId == null) {
      showToast(message: 'الرجاء اختيار الطبيب', state: ToastState.error);
      return;
    }

    final body = CreatePatientRequestModel(
      doctorId: doctorId,
      clinicId: _clinicIdFor(doctorId),
      firstName: _firstNameController.text.trim(),
      lastName: _optional(_lastNameController),
      gender: _gender.apiValue,
      dateOfBirth: _formatDate(_dateOfBirth),
      phoneNumber: _optional(_phoneController),
      notes: _optional(_notesController),
    );

    final cubit = context.read<PatientFormCubit>();

    if (_isEditing) {
      cubit.updatePatient(
        id: widget.initialPatient!.id,
        patientRequestBody: body,
      );
    } else {
      cubit.createPatient(body);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      isDirty: () => _isDirty,
      child: GlassScaffold(
        appBar: GlassAppBar(
          title: Text(
            _isEditing ? 'تعديل المريض' : 'إضافة مريض',
            style: AppTextStyles.font18MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<PatientFormCubit, PatientFormState>(
          builder: (context, state) => GlassSaveBar(
            isSubmitting: state is PatientFormSubmitting,
            label: _isEditing ? 'حفظ التعديلات' : 'إضافة المريض',
            onSave: _onSavePressed,
          ),
        ),
        body: SafeArea(
          child: BlocConsumer<PatientFormCubit, PatientFormState>(
            listener: (context, state) {
              switch (state) {
                case PatientFormSuccess():
                  showToast(
                    message: _isEditing
                        ? 'تم حفظ التعديلات'
                        : 'تمت إضافة المريض',
                    state: ToastState.success,
                  );
                  Navigator.of(context).pop(true);
                case PatientFormError(:final message):
                  showToast(message: message, state: ToastState.error);
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

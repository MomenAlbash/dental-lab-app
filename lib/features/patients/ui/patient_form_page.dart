import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
  String? _clinicId;
  PatientGender _gender = PatientGender.male;
  DateTime? _dateOfBirth;

  @override
  void dispose() {
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

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_doctorId == null) {
      ShowToast(message: 'الرجاء اختيار الطبيب', state: toastState.error);
      return;
    }

    context.read<PatientFormCubit>().createPatient(
      CreatePatientRequestModel(
        doctorId: _doctorId!,
        clinicId: _clinicId,
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
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('إضافة مريض', style: AppTextStyles.font18MediumText),
      ),
      body: SafeArea(
        child: BlocConsumer<PatientFormCubit, PatientFormState>(
          listener: (context, state) {
            switch (state) {
              case PatientFormSuccess():
                ShowToast(message: 'تمت إضافة المريض', state: toastState.success);
                Navigator.of(context).pop(true);
              case PatientFormError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            final isSubmitting = state is PatientFormSubmitting;

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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Label('الطبيب'),
                            BlocBuilder<DoctorsCubit, DoctorsState>(
                              builder: (context, state) {
                                final doctors =
                                    state is DoctorsLoaded ? state.doctors : null;

                                if (doctors != null && doctors.isEmpty) {
                                  return _NoDoctorsNotice(
                                    onAddDoctor: () async {
                                      final added = await context.push<bool>(
                                        Routes.doctorFormScreen,
                                      );
                                      if (added == true && context.mounted) {
                                        context.read<DoctorsCubit>().getDoctors();
                                      }
                                    },
                                  );
                                }

                                return CaseLookupDropdown(
                                  value: _doctorId,
                                  icon: Icons.medical_services_outlined,
                                  hintText: state is DoctorsLoading
                                      ? 'جارٍ تحميل الأطباء...'
                                      : 'اختر الطبيب',
                                  items: doctors
                                      ?.map(
                                        (d) => DropdownMenuItem(
                                          value: d.id,
                                          child: Text(d.fullName),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) => setState(() {
                                    _doctorId = value;
                                    _clinicId = null;
                                    if (value != null && doctors != null) {
                                      for (final d in doctors) {
                                        if (d.id == value) {
                                          _clinicId = d.clinicId;
                                          break;
                                        }
                                      }
                                    }
                                  }),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const _Label('العيادة'),
                            BlocBuilder<DoctorsCubit, DoctorsState>(
                              builder: (context, state) {
                                final doctors =
                                    state is DoctorsLoaded ? state.doctors : null;
                                DoctorModel? selectedDoctor;
                                if (doctors != null && _doctorId != null) {
                                  for (final d in doctors) {
                                    if (d.id == _doctorId) {
                                      selectedDoctor = d;
                                      break;
                                    }
                                  }
                                }

                                final String hintText;
                                if (_doctorId == null) {
                                  hintText = 'اختر الطبيب أولاً';
                                } else if (selectedDoctor?.clinicName == null) {
                                  hintText = 'الطبيب غير مرتبط بعيادة';
                                } else {
                                  hintText = '';
                                }

                                return _ReadOnlyField(
                                  icon: Icons.local_hospital_outlined,
                                  text: selectedDoctor?.clinicName ?? hintText,
                                  isPlaceholder: selectedDoctor?.clinicName == null,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const _Label('الاسم الأول'),
                            AppTextFormField(
                              controller: _firstNameController,
                              hintText: 'أدخل الاسم الأول',
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColorsManger.textSecondary,
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'الاسم الأول مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            const _Label('الاسم الأخير'),
                            AppTextFormField(
                              controller: _lastNameController,
                              hintText: 'أدخل الاسم الأخير (اختياري)',
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.person_outline,
                                color: AppColorsManger.textSecondary,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 16),
                            const _Label('الجنس'),
                            SegmentedButton<PatientGender>(
                              segments: PatientGender.values
                                  .map(
                                    (g) => ButtonSegment(
                                      value: g,
                                      label: Text(g.arabicLabel),
                                    ),
                                  )
                                  .toList(),
                              selected: {_gender},
                              showSelectedIcon: false,
                              onSelectionChanged: (s) =>
                                  setState(() => _gender = s.first),
                            ),
                            const SizedBox(height: 16),
                            const _Label('تاريخ الميلاد'),
                            InkWell(
                              onTap: _pickDateOfBirth,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColorsManger.moreLightGray,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.cake_outlined,
                                      color: AppColorsManger.textSecondary,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _formatDate(_dateOfBirth) ??
                                          'اختر تاريخ الميلاد (اختياري)',
                                      style: _dateOfBirth == null
                                          ? AppTextStyles.font14RegularSecondary
                                          : AppTextStyles.font14MediumText,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const _Label('رقم الهاتف'),
                            AppTextFormField(
                              controller: _phoneController,
                              hintText: 'أدخل رقم الهاتف (اختياري)',
                              textInputAction: TextInputAction.next,
                              prefixIcon: const Icon(
                                Icons.phone_outlined,
                                color: AppColorsManger.textSecondary,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 16),
                            const _Label('ملاحظات'),
                            AppTextFormField(
                              controller: _notesController,
                              hintText: 'ملاحظات (اختياري)',
                              textInputAction: TextInputAction.done,
                              prefixIcon: const Icon(
                                Icons.notes_outlined,
                                color: AppColorsManger.textSecondary,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 24),
                            if (isSubmitting)
                              const Center(child: CircularProgressIndicator())
                            else
                              CustomButtonWidget(
                                onPressed: _onSavePressed,
                                buttonText: 'إضافة المريض',
                                textColor: Colors.white,
                                backgroundColor: AppColorsManger.primary,
                              ),
                          ],
                        ),
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

/// Non-interactive field — used for the clinic once it's derived from the
/// selected doctor, since there's nothing left for the user to pick.
class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.icon,
    required this.text,
    this.isPlaceholder = false,
  });

  final IconData icon;
  final String text;
  final bool isPlaceholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColorsManger.moreLightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColorsManger.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: isPlaceholder
                  ? AppTextStyles.font14RegularSecondary
                  : AppTextStyles.font14MediumText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown instead of the doctor dropdown when the lab has no doctors yet —
/// picking one is required, so this is a dead end without a way out.
class _NoDoctorsNotice extends StatelessWidget {
  const _NoDoctorsNotice({required this.onAddDoctor});

  final VoidCallback onAddDoctor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsManger.moreLightGray,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColorsManger.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ما في أطباء مسجّلين بعد — لازم تضيف طبيب أولاً',
                  style: AppTextStyles.font14RegularSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAddDoctor,
            icon: const Icon(Icons.add),
            label: const Text('إضافة طبيب'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: AppTextStyles.font14MediumText),
      ),
    );
  }
}

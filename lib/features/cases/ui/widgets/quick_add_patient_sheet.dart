import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/patients/data/models/create_patient_request_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Creates a patient without leaving the case form, and returns it.
///
/// `POST /api/clinic/Patients` only requires `firstName` and `doctorId`, and
/// the case form has already asked for the doctor — so a name is all that is
/// left to collect. Anything else the patient record can carry is left for the
/// full patient screen; this exists so a walk-in patient does not interrupt
/// the case being written.
Future<PatientModel?> showQuickAddPatientSheet({
  required BuildContext context,
  required String doctorId,
  required String? clinicId,
}) {
  return showGlassBottomSheet<PatientModel>(
    context: context,
    builder: (sheetContext) => BlocProvider(
      create: (_) => getIt<PatientFormCubit>(),
      child: _QuickAddPatientForm(doctorId: doctorId, clinicId: clinicId),
    ),
  );
}

class _QuickAddPatientForm extends StatefulWidget {
  const _QuickAddPatientForm({required this.doctorId, required this.clinicId});

  final String doctorId;
  final String? clinicId;

  @override
  State<_QuickAddPatientForm> createState() => _QuickAddPatientFormState();
}

class _QuickAddPatientFormState extends State<_QuickAddPatientForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final lastName = _lastNameController.text.trim();

    context.read<PatientFormCubit>().createPatient(
      CreatePatientRequestModel(
        doctorId: widget.doctorId,
        clinicId: widget.clinicId,
        firstName: _firstNameController.text.trim(),
        lastName: lastName.isEmpty ? null : lastName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return BlocConsumer<PatientFormCubit, PatientFormState>(
      listener: (context, state) {
        switch (state) {
          case PatientFormSuccess(:final patient):
            showToast(message: 'تمت إضافة المريض', state: ToastState.success);
            Navigator.of(context).pop(patient);
          case PatientFormError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state is PatientFormSubmitting;

        return Padding(
          // Lifts the sheet above the keyboard, which covers the field it is
          // asking the user to type in otherwise.
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'مريض جديد',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'الاسم كافي — باقي البيانات فيك تكمّلها لاحقاً من شاشة المرضى',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextFormField(
                    controller: _firstNameController,
                    hintText: 'الاسم الأول',
                    textInputAction: TextInputAction.next,
                    prefixIcon: Icon(
                      Icons.person_outline,
                      color: glass.onGlassMuted,
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'الاسم الأول مطلوب'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextFormField(
                    controller: _lastNameController,
                    hintText: 'الكنية (اختياري)',
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icon(
                      Icons.badge_outlined,
                      color: glass.onGlassMuted,
                    ),
                    validator: (_) => null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: isSubmitting ? null : _onSavePressed,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      isSubmitting ? 'جارٍ الحفظ...' : 'إضافة المريض',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

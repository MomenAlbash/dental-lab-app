import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Patient detail screen — view-only.
class PatientDetailPage extends StatelessWidget {
  const PatientDetailPage({super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PatientDetailsCubit>()..getPatient(patientId),
      child: const _PatientDetailView(),
    );
  }
}

class _PatientDetailView extends StatelessWidget {
  const _PatientDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('تفاصيل المريض', style: AppTextStyles.font18MediumText),
      ),
      body: SafeArea(
        child: BlocBuilder<PatientDetailsCubit, PatientDetailsState>(
          builder: (context, state) {
            return switch (state) {
              PatientDetailsLoaded(:final patient) => _PatientDetailBody(
                patient: patient,
              ),
              PatientDetailsError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary,
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
        ),
      ),
    );
  }
}

class _PatientDetailBody extends StatelessWidget {
  const _PatientDetailBody({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColorsManger.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            size: 36,
                            color: AppColorsManger.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          patient.fullName.isEmpty ? '—' : patient.fullName,
                          style: AppTextStyles.font20BoldText,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColorsManger.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColorsManger.border),
                    ),
                    child: Column(
                      children: [
                        DetailInfoRowWidget(
                          icon: Icons.medical_services_outlined,
                          label: 'الطبيب',
                          value: patient.doctorName ?? '',
                        ),
                        const Divider(height: 1, color: AppColorsManger.divider),
                        DetailInfoRowWidget(
                          icon: Icons.local_hospital_outlined,
                          label: 'العيادة',
                          value: patient.clinicName ?? '',
                        ),
                        const Divider(height: 1, color: AppColorsManger.divider),
                        DetailInfoRowWidget(
                          icon: Icons.folder_outlined,
                          label: 'عدد الحالات',
                          value: '${patient.caseCount}',
                        ),
                        const Divider(height: 1, color: AppColorsManger.divider),
                        DetailInfoRowWidget(
                          icon: Icons.wc_outlined,
                          label: 'الجنس',
                          value: patient.gender?.arabicLabel ?? '',
                        ),
                        const Divider(height: 1, color: AppColorsManger.divider),
                        DetailInfoRowWidget(
                          icon: Icons.cake_outlined,
                          label: 'تاريخ الميلاد',
                          value: patient.dateOfBirth ?? '',
                        ),
                        const Divider(height: 1, color: AppColorsManger.divider),
                        DetailInfoRowWidget(
                          icon: Icons.phone_outlined,
                          label: 'رقم الهاتف',
                          value: patient.phoneNumber ?? '',
                        ),
                      ],
                    ),
                  ),
                  if (patient.notes != null && patient.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        'ملاحظات',
                        style: AppTextStyles.font16MediumText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      patient.notes!,
                      style: AppTextStyles.font14RegularSecondary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

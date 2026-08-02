import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The patients list body — reads the shared [PatientsCubit] from the page.
class PatientsListBody extends StatelessWidget {
  const PatientsListBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatientsCubit, PatientsState>(
      builder: (context, state) {
        return switch (state) {
          PatientsLoaded(:final patients) =>
            patients.isEmpty ? _Empty() : _PatientsList(patients: patients),
          PatientsError(:final message) => Center(
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
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'لا يوجد مرضى بعد',
        style: AppTextStyles.font14RegularSecondary,
      ),
    );
  }
}

class _PatientsList extends StatelessWidget {
  const _PatientsList({required this.patients});

  final List<PatientModel> patients;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 700.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: RefreshIndicator(
              onRefresh: () => context.read<PatientsCubit>().getPatients(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final patient = patients[index];
                  return PatientListItemWidget(
                    fullName: patient.fullName,
                    doctorName: patient.doctorName ?? '',
                    clinicName: patient.clinicName ?? '',
                    caseCount: patient.caseCount,
                    onTap: () => context.push(
                      Routes.patientDetailScreen,
                      extra: patient.id,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

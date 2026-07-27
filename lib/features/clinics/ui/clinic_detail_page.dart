import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_state.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_details_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Clinic detail screen — mirrors `ClinicDto`: contact info, code, city and
/// website.
class ClinicDetailPage extends StatelessWidget {
  const ClinicDetailPage({super.key, required this.clinicId});

  final String clinicId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ClinicDetailsCubit>()..getClinicById(clinicId),
      child: const _ClinicDetailView(),
    );
  }
}

class _ClinicDetailView extends StatelessWidget {
  const _ClinicDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClinicDetailsCubit, ClinicDetailsState>(
      builder: (context, state) {
        final clinic = state is ClinicDetailsLoaded ? state.clinic : null;

        return Scaffold(
          backgroundColor: AppColorsManger.background,
          appBar: AppBar(
            title: Text('تفاصيل العيادة', style: AppTextStyles.font18MediumText),
            actions: [
              if (clinic != null)
                IconButton(
                  onPressed: () async {
                    await context.push(
                      Routes.clinicFormScreen,
                      extra: clinic,
                    );
                    if (context.mounted) {
                      context.read<ClinicDetailsCubit>().getClinicById(
                        clinic.id,
                      );
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              ClinicDetailsLoaded(:final clinic) => ClinicDetailsBody(
                clinic: clinic,
              ),
              ClinicDetailsError(:final message) => Center(
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
            },
          ),
        );
      },
    );
  }
}

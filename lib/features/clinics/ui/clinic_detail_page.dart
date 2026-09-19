import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_state.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_hero_header.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_info_tiles.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_quick_actions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

        // No `appBar` once loaded: the body supplies its own collapsing
        // SliverAppBar, matching the doctor/patient detail screens.
        return GlassScaffold(
          appBar: clinic != null
              ? null
              : GlassAppBar(
                  title: Text(
                    'تفاصيل العيادة',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: context.glass.onGlass,
                    ),
                  ),
                ),
          body: switch (state) {
            ClinicDetailsLoaded(:final clinic) => _ClinicDetailBody(
              clinic: clinic,
            ),
            ClinicDetailsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: context.glass.onGlassMuted,
                  ),
                ),
              ),
            ),
            _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
          },
        );
      },
    );
  }
}

class _ClinicDetailBody extends StatelessWidget {
  const _ClinicDetailBody({required this.clinic});

  final ClinicModel clinic;

  /// Replaces the clinic's logo, then refetches.
  ///
  /// The upload answers with the stored path, but the detail cubit is asked
  /// again rather than the answer being spliced in: two holders of the same
  /// record, one quietly newer, is how a screen starts disagreeing with itself.
  Future<void> _changeLogo(BuildContext context) async {
    final cubit = context.read<ClinicDetailsCubit>();

    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    final uploaded = await getIt<ClinicsRepo>().uploadImage(
      id: clinic.id,
      filePath: path,
    );

    await uploaded.fold(
      (failure) async =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) async {
        showToast(message: 'تم تحديث الشعار', state: ToastState.success);
        await cubit.getClinicById(clinic.id);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.doctor);

    return CustomScrollView(
      slivers: [
        ClinicSliverHeader(
          clinic: clinic,
          onChangeLogo: canEdit ? () => _changeLogo(context) : null,
          onEdit: () async {
            await context.push(Routes.clinicFormScreen, extra: clinic);
            if (context.mounted) {
              context.read<ClinicDetailsCubit>().getClinicById(clinic.id);
            }
          },
        ),
        SliverToBoxAdapter(
          child: AdaptiveDetailSections(
            main: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle('المعلومات'),
                  const SizedBox(height: AppSpacing.md),
                  ClinicInfoTiles(clinic: clinic)
                      .animate(delay: AppMotion.stagger * 2)
                      .fadeIn(duration: AppMotion.base)
                      .slideY(
                        begin: 0.06,
                        duration: AppMotion.base,
                        curve: AppMotion.enter,
                      ),
                ],
              ),
            ],
            side: [
              ClinicQuickActions(clinic: clinic)
                  .animate()
                  .fadeIn(duration: AppMotion.base)
                  .slideY(
                    begin: 0.15,
                    duration: AppMotion.base,
                    curve: AppMotion.enter,
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          text,
          style: AppTextStyles.font16MediumText.copyWith(color: glass.onGlass),
        ),
      ],
    );
  }
}

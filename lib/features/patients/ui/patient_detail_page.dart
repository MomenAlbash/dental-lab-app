import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_state.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_hero_header.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_info_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

/// Patient detail screen — view-only (patients are managed by the clinic
/// side, so there is no edit action here).
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
    return BlocBuilder<PatientDetailsCubit, PatientDetailsState>(
      builder: (context, state) {
        final patient = state is PatientDetailsLoaded ? state.patient : null;

        // No `appBar` once loaded: the body supplies its own collapsing
        // SliverAppBar, matching the doctor detail screen.
        return GlassScaffold(
          appBar: patient != null
              ? null
              : GlassAppBar(
                  title: Text(
                    'تفاصيل المريض',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: context.glass.onGlass,
                    ),
                  ),
                ),
          body: switch (state) {
            PatientDetailsLoaded(:final patient) => _PatientDetailBody(
              patient: patient,
            ),
            PatientDetailsError(:final message) => Center(
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

class _PatientDetailBody extends StatelessWidget {
  const _PatientDetailBody({required this.patient});

  final PatientModel patient;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        PatientSliverHeader(patient: patient),
        SliverToBoxAdapter(
          child: AdaptiveDetailSections(
            main: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionTitle('المعلومات'),
                  const SizedBox(height: AppSpacing.md),
                  PatientInfoTiles(patient: patient)
                      .animate(delay: AppMotion.stagger * 2)
                      .fadeIn(duration: AppMotion.base)
                      .slideY(
                        begin: 0.06,
                        duration: AppMotion.base,
                        curve: AppMotion.enter,
                      ),
                ],
              ),
              if ((patient.notes ?? '').trim().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle('ملاحظات'),
                    const SizedBox(height: AppSpacing.md),
                    _NotesCard(notes: patient.notes!.trim())
                        .animate(delay: AppMotion.stagger * 4)
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
              if ((patient.phoneNumber ?? '').trim().isNotEmpty)
                _CallButton(phoneNumber: patient.phoneNumber!.trim())
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

/// A single, prominent call action — a patient has one contact channel, so a
/// row of icon tiles (like the doctor screen's four) would be mostly empty
/// space. This reads as the primary action it is.
class _CallButton extends StatefulWidget {
  const _CallButton({required this.phoneNumber});

  final String phoneNumber;

  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  Future<void> _call() async {
    try {
      final launched = await launchUrl(
        Uri.parse('tel:${widget.phoneNumber}'),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ShowToast(message: 'تعذّر بدء الاتصال', state: toastState.error);
      }
    } catch (_) {
      ShowToast(message: 'تعذّر بدء الاتصال', state: toastState.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _call,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: glass.surfaceGradient,
              borderRadius: radius,
              border: Border.all(color: glass.strokeColor),
              boxShadow: glass.shadows,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.glass.success.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    Icons.call_outlined,
                    color: context.glass.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'اتصال بالمريض',
                        style: AppTextStyles.font14MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.phoneNumber,
                        style: AppTextStyles.font13MediumPrimary,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: glass.onGlassMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Text(
        notes,
        style: AppTextStyles.font14RegularSecondary.copyWith(
          color: glass.onGlass,
          height: 1.6,
        ),
      ),
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_details/laboratory_details_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_details/laboratory_details_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Laboratory detail screen — mirrors `LaboratoryDto`: contact info plus
/// user/doctor/case counts.
class LaboratoryDetailPage extends StatelessWidget {
  const LaboratoryDetailPage({super.key, required this.laboratoryId});

  final String laboratoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<LaboratoryDetailsCubit>()..getLaboratoryById(laboratoryId),
      child: const _LaboratoryDetailView(),
    );
  }
}

class _LaboratoryDetailView extends StatelessWidget {
  const _LaboratoryDetailView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LaboratoryDetailsCubit, LaboratoryDetailsState>(
      builder: (context, state) {
        final laboratory = state is LaboratoryDetailsLoaded
            ? state.laboratory
            : null;

        return GlassScaffold(
          appBar: GlassAppBar(
            title: Text(
              'تفاصيل المخبر',
              style: AppTextStyles.font18MediumText.copyWith(
                color: context.glass.onGlass,
              ),
            ),
            actions: [
              if (laboratory != null)
                IconButton(
                  onPressed: () async {
                    await context.push(
                      Routes.laboratoryFormScreen,
                      extra: laboratory,
                    );
                    if (context.mounted) {
                      context.read<LaboratoryDetailsCubit>().getLaboratoryById(
                        laboratory.id,
                      );
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              LaboratoryDetailsLoaded(:final laboratory) =>
                LaboratoryDetailsBody(laboratory: laboratory),
              LaboratoryDetailsError(:final message) => Center(
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
          ),
        );
      },
    );
  }
}

/// Shared between the laboratory details screen and "مختبري".
class LaboratoryDetailsBody extends StatelessWidget {
  const LaboratoryDetailsBody({
    super.key,
    required this.laboratory,
    this.subtitle,
    this.footer,
  });

  final LaboratoryModel laboratory;

  /// Replaces the status badge under the name when provided.
  final Widget? subtitle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: context.glass.brandGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  laboratory.name ?? '—',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font20BoldText,
                ),
                const SizedBox(height: 4),
                subtitle ?? _StatusBadge(isActive: laboratory.isActive),
              ],
            ),
          ),
          AdaptiveDetailSections(
            main: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: context.glass.surfaceGradient,
                  borderRadius: BorderRadius.circular(AppRadius.glass),
                  border: Border.all(color: context.glass.strokeColor),
                  boxShadow: context.glass.shadows,
                ),
                child: Column(
                  children: [
                    DetailInfoRowWidget(
                      icon: Icons.location_on_outlined,
                      label: 'العنوان',
                      value: laboratory.address ?? '',
                    ),
                    Divider(height: 1, color: context.glass.strokeColor),
                    DetailInfoRowWidget(
                      icon: Icons.phone_outlined,
                      label: 'رقم الهاتف',
                      value: laboratory.phoneNumber ?? '',
                    ),
                  ],
                ),
              ),
              ?footer,
            ],
            // The three counts read as a scoreboard for the lab, so they sit
            // together beside the details rather than above them.
            side: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.people_outline,
                      label: 'المستخدمين',
                      value: '${laboratory.userCount}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.medical_services_outlined,
                      label: 'الأطباء',
                      value: '${laboratory.doctorCount}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.folder_outlined,
                      label: 'الحالات',
                      value: '${laboratory.caseCount}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.glass.success : context.glass.onGlassMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'مفعّل' : 'موقوف',
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.strokeColor),
        boxShadow: context.glass.shadows,
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.font20BoldText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: context.glass.onGlassMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
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

        return Scaffold(
          backgroundColor: AppColorsManger.background,
          appBar: AppBar(
            title: Text(
              'تفاصيل المخبر',
              style: AppTextStyles.font18MediumText,
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
              LaboratoryDetailsLoaded(:final laboratory) => LaboratoryDetailsBody(
                laboratory: laboratory,
              ),
              LaboratoryDetailsError(:final message) => Center(
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
                            Icons.science_outlined,
                            size: 36,
                            color: AppColorsManger.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          laboratory.name ?? '—',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.font20BoldText,
                        ),
                        const SizedBox(height: 4),
                        subtitle ??
                            _StatusBadge(isActive: laboratory.isActive),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  const SizedBox(height: 24),
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
                          icon: Icons.location_on_outlined,
                          label: 'العنوان',
                          value: laboratory.address ?? '',
                        ),
                        const Divider(
                          height: 1,
                          color: AppColorsManger.divider,
                        ),
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColorsManger.success : AppColorsManger.textHint;
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
        color: AppColorsManger.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsManger.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColorsManger.primary),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.font20BoldText),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.font12RegularHint,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_details/laboratory_details_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_details/laboratory_details_state.dart';
import 'package:dental_lab_app/features/laboratories/ui/laboratory_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// "مختبري" — the admin's own default laboratory, per
/// `GET /api/clinic/Laboratories/own`. An admin can still create and operate
/// other laboratories (see the Laboratories list), but this is the one their
/// account belongs to.
class MyLaboratoryPage extends StatelessWidget {
  const MyLaboratoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LaboratoryDetailsCubit>()..getOwnLaboratory(),
      child: const _MyLaboratoryView(),
    );
  }
}

class _MyLaboratoryView extends StatelessWidget {
  const _MyLaboratoryView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LaboratoryDetailsCubit, LaboratoryDetailsState>(
      builder: (context, state) {
        final laboratory = state is LaboratoryDetailsLoaded
            ? state.laboratory
            : null;

        return Scaffold(
          backgroundColor: AppColorsManger.background,
          drawer: const AppDrawerWidget(
            currentRoute: Routes.myLaboratoryScreen,
          ),
          appBar: AppBar(
            title: Text('مختبري', style: AppTextStyles.font18MediumText),
            actions: [
              if (laboratory != null)
                IconButton(
                  onPressed: () async {
                    await context.push(
                      Routes.laboratoryFormScreen,
                      extra: laboratory,
                    );
                    if (context.mounted) {
                      context.read<LaboratoryDetailsCubit>().getOwnLaboratory();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: SafeArea(
            child: switch (state) {
              LaboratoryDetailsLoaded(:final laboratory) =>
                LaboratoryDetailsBody(
                  laboratory: laboratory,
                  subtitle: Text(
                    'المخبر الافتراضي لحسابك',
                    style: AppTextStyles.font13MediumPrimary,
                  ),
                  footer: const _SwitchLaboratoryFooter(),
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

class _SwitchLaboratoryFooter extends StatelessWidget {
  const _SwitchLaboratoryFooter();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColorsManger.primarySurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: AppColorsManger.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'يمكنك إنشاء مخبر آخر والتعامل مع النظام كمخبر مختلف من صفحة المخابر.',
                  style: AppTextStyles.font13MediumPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => context.push(Routes.laboratoriesListScreen),
          icon: const Icon(Icons.science_outlined),
          label: const Text('عرض جميع المخابر'),
        ),
      ],
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LaboratorySelectionPage extends StatelessWidget {
  const LaboratorySelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LaboratorySelectionCubit>()..loadLaboratories(),
      child: const _LaboratorySelectionView(),
    );
  }
}

class _LaboratorySelectionView extends StatelessWidget {
  const _LaboratorySelectionView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LaboratorySelectionCubit, LaboratorySelectionState>(
      listener: (context, state) {
        switch (state) {
          case LaboratorySelectionConfirmed():
          case LaboratorySelectionSkipped():
            context.go(Routes.homeScreen);
          case LaboratorySelectionError(:final message):
            ShowToast(message: message, state: toastState.error);
          default:
            break;
        }
      },
      builder: (context, state) {
        final showsPicker = state is LaboratorySelectionLoaded;

        return Scaffold(
          backgroundColor: AppColorsManger.background,
          appBar: showsPicker
              ? AppBar(
                  title: Text(
                    'اختيار المخبر',
                    style: AppTextStyles.font18MediumText,
                  ),
                  automaticallyImplyLeading: false,
                )
              : null,
          body: SafeArea(
            child: switch (state) {
              LaboratorySelectionLoaded(
                :final laboratories,
                :final selectedId,
              ) =>
                _LaboratoryList(
                  laboratories: laboratories,
                  selectedId: selectedId,
                ),
              LaboratorySelectionError(:final message) => Center(
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

class _LaboratoryList extends StatelessWidget {
  const _LaboratoryList({required this.laboratories, required this.selectedId});

  final List<LaboratoryModel> laboratories;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 560.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 20,
                    20,
                    isWide ? 32 : 20,
                    8,
                  ),
                  child: Text(
                    'اختر المخبر الذي تريد العمل عليه',
                    style: AppTextStyles.font14RegularSecondary,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 8,
                    ),
                    itemCount: laboratories.length,
                    itemBuilder: (context, index) {
                      final laboratory = laboratories[index];
                      return _LaboratoryCard(
                        laboratory: laboratory,
                        isSelected: laboratory.id == selectedId,
                        onTap: () => context
                            .read<LaboratorySelectionCubit>()
                            .selectLaboratory(laboratory),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LaboratoryCard extends StatelessWidget {
  const _LaboratoryCard({
    required this.laboratory,
    required this.isSelected,
    required this.onTap,
  });

  final LaboratoryModel laboratory;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColorsManger.primarySurface
            : AppColorsManger.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColorsManger.primary : AppColorsManger.border,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColorsManger.primarySurface,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.science_outlined,
                    color: AppColorsManger.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        laboratory.name ?? '—',
                        style: AppTextStyles.font16MediumText,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (laboratory.address?.isEmpty ?? true)
                            ? 'بدون عنوان'
                            : laboratory.address!,
                        style: AppTextStyles.font12RegularHint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: AppColorsManger.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

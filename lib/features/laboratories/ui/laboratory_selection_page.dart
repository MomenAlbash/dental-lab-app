import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
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
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      builder: (context, state) {
        final showsPicker = state is LaboratorySelectionLoaded;

        return GlassScaffold(
          appBar: showsPicker
              ? GlassAppBar(
                  title: Text(
                    'اختيار المخابر',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: context.glass.onGlass,
                    ),
                  ),
                  centerTitle: true,
                  // Opened again to change the scope, it can go back; right
                  // after login there is nowhere to go back to.
                  leading: context.canPop() ? null : const SizedBox.shrink(),
                )
              : null,
          body: SafeArea(
            child: switch (state) {
              final LaboratorySelectionLoaded loaded => _LaboratoryList(
                state: loaded,
              ),
              LaboratorySelectionError(:final message) => Center(
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

class _LaboratoryList extends StatelessWidget {
  const _LaboratoryList({required this.state});

  final LaboratorySelectionLoaded state;

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
                    // Several at once is a view, not a merge: each record
                    // still belongs to one laboratory, and adding one asks
                    // which.
                    'اختر مخبراً أو أكثر — تُعرض بيانات المخابر المختارة معاً',
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: context.glass.onGlassMuted,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 12),
                  child: CheckboxListTile(
                    value: state.allSelected,
                    onChanged: (_) =>
                        context.read<LaboratorySelectionCubit>().toggleAll(),
                    title: const Text('كل المخابر'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 8,
                    ),
                    itemCount: state.laboratories.length,
                    itemBuilder: (context, index) {
                      final laboratory = state.laboratories[index];
                      return _LaboratoryCard(
                        laboratory: laboratory,
                        isSelected: state.selectedIds.contains(laboratory.id),
                        onTap: () => context
                            .read<LaboratorySelectionCubit>()
                            .toggle(laboratory.id),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 20,
                    8,
                    isWide ? 32 : 20,
                    16,
                  ),
                  child: FilledButton(
                    onPressed: state.canConfirm
                        ? context.read<LaboratorySelectionCubit>().confirm
                        : null,
                    child: Text(
                      state.canConfirm
                          ? 'متابعة (${state.selectedIds.length})'
                          : 'اختر مخبراً واحداً على الأقل',
                    ),
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
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isSelected ? accent.withValues(alpha: 0.12) : null,
            gradient: isSelected ? null : glass.surfaceGradient,
            border: Border.all(
              color: isSelected ? accent : glass.strokeColor,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: glass.brandGradient,
                      ),
                      child: const Icon(
                        Icons.science_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            laboratory.name ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.font16MediumText.copyWith(
                              color: glass.onGlass,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            (laboratory.address?.isEmpty ?? true)
                                ? 'بدون عنوان'
                                : laboratory.address!,
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) Icon(Icons.check_circle, color: accent),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

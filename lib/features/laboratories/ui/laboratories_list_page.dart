import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_state.dart';
import 'package:dental_lab_app/features/laboratories/ui/widgets/laboratory_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// An admin owns one lab by default (see "مختبري") but can create and switch
/// into operating as a different one, per `/api/clinic/Laboratories`.
class LaboratoriesListPage extends StatelessWidget {
  const LaboratoriesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LaboratoriesCubit>()..getLaboratories(),
      child: const _LaboratoriesListView(),
    );
  }
}

class _LaboratoriesListView extends StatelessWidget {
  const _LaboratoriesListView();

  Future<void> _confirmDelete(
    BuildContext context,
    LaboratoryModel laboratory,
  ) async {
    final cubit = context.read<LaboratoriesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المخبر',
      message: 'هل أنت متأكد من حذف مخبر "${laboratory.name ?? ''}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteLaboratory(laboratory.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.laboratoriesListScreen),
      appBar: AppBar(
        title: Text('المخابر', style: AppTextStyles.font18MediumText),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.laboratoryFormScreen);
            if (context.mounted) {
              context.read<LaboratoriesCubit>().getLaboratories();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<LaboratoriesCubit, LaboratoriesState>(
          listener: (context, state) {
            switch (state) {
              case LaboratoryDeleted():
                ShowToast(message: 'تم حذف المخبر', state: toastState.success);
              case LaboratoryDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! LaboratoryDeleted &&
              current is! LaboratoryDeleteError,
          builder: (context, state) {
            return switch (state) {
              LaboratoriesLoaded(:final laboratories) =>
                laboratories.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد مخابر بعد',
                          style: AppTextStyles.font14RegularSecondary,
                        ),
                      )
                    : _LaboratoriesList(
                        laboratories: laboratories,
                        activeLaboratoryId: context
                            .read<LaboratoriesCubit>()
                            .activeLaboratoryId,
                        onDelete: (laboratory) =>
                            _confirmDelete(context, laboratory),
                      ),
              LaboratoriesError(:final message) => Center(
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

class _LaboratoriesList extends StatelessWidget {
  const _LaboratoriesList({
    required this.laboratories,
    required this.activeLaboratoryId,
    required this.onDelete,
  });

  final List<LaboratoryModel> laboratories;
  final String? activeLaboratoryId;
  final ValueChanged<LaboratoryModel> onDelete;

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
              onRefresh: () =>
                  context.read<LaboratoriesCubit>().getLaboratories(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                itemCount: laboratories.length,
                itemBuilder: (context, index) {
                  final laboratory = laboratories[index];
                  return LaboratoryListItemWidget(
                    name: laboratory.name ?? '—',
                    address: laboratory.address ?? '',
                    isActive: laboratory.isActive,
                    isCurrent: laboratory.id == activeLaboratoryId,
                    onTap: () => context.push(
                      Routes.laboratoryDetailScreen,
                      extra: laboratory.id,
                    ),
                    onEdit: () async {
                      await context.push(
                        Routes.laboratoryFormScreen,
                        extra: laboratory,
                      );
                      if (context.mounted) {
                        context.read<LaboratoriesCubit>().getLaboratories();
                      }
                    },
                    onDelete: () => onDelete(laboratory),
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

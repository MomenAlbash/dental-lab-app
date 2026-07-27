import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/stages/stages_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/stages/stages_state.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/widgets/stages_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class CaseWorkflowStagesListPage extends StatelessWidget {
  const CaseWorkflowStagesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<StagesCubit>()..getStages(),
      child: const _StagesListView(),
    );
  }
}

class _StagesListView extends StatelessWidget {
  const _StagesListView();

  Future<void> _confirmDelete(
    BuildContext context,
    CaseWorkflowStageModel stage,
  ) async {
    final cubit = context.read<StagesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المرحلة',
      message: 'هل أنت متأكد من حذف مرحلة "${stage.name ?? ''}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteStage(stage.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(
        currentRoute: Routes.caseWorkflowStagesListScreen,
      ),
      appBar: AppBar(
        title: Text('مراحل الحالات', style: AppTextStyles.font18MediumText),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.caseWorkflowStageFormScreen);
            if (context.mounted) {
              context.read<StagesCubit>().getStages();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<StagesCubit, StagesState>(
          listener: (context, state) {
            switch (state) {
              case StageDeleted():
                ShowToast(message: 'تم حذف المرحلة', state: toastState.success);
              case StageDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! StageDeleted && current is! StageDeleteError,
          builder: (context, state) {
            return switch (state) {
              StagesLoaded(:final stages) =>
                stages.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد مراحل بعد',
                          style: AppTextStyles.font14RegularSecondary,
                        ),
                      )
                    : StagesListView(
                        stages: stages,
                        onDelete: (stage) => _confirmDelete(context, stage),
                      ),
              StagesError(:final message) => Center(
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

import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/stages/stages_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/widgets/case_workflow_stage_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The stages list section: the ordered stages with pull-to-refresh.
class StagesListView extends StatelessWidget {
  const StagesListView({
    super.key,
    required this.stages,
    required this.onDelete,
  });

  final List<CaseWorkflowStageModel> stages;
  final ValueChanged<CaseWorkflowStageModel> onDelete;

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
              onRefresh: () => context.read<StagesCubit>().getStages(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];
                  return CaseWorkflowStageListItemWidget(
                    name: stage.name ?? '—',
                    order: stage.order,
                    isActive: stage.isActive,
                    isFinal: stage.isFinal,
                    onEdit: () async {
                      await context.push(
                        Routes.caseWorkflowStageFormScreen,
                        extra: stage,
                      );
                      if (context.mounted) {
                        context.read<StagesCubit>().getStages();
                      }
                    },
                    onDelete: () => onDelete(stage),
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

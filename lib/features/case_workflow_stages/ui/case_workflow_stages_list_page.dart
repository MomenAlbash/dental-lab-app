import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/widgets/case_workflow_stage_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Case workflow stages list screen — design only for now (no Cubit / API
/// wiring yet). Shows the ordered stages a case moves through inside the lab
/// (e.g. تصميم، طحن...).
class CaseWorkflowStagesListPage extends StatefulWidget {
  const CaseWorkflowStagesListPage({super.key});

  @override
  State<CaseWorkflowStagesListPage> createState() => _CaseWorkflowStagesListPageState();
}

class _CaseWorkflowStagesListPageState extends State<CaseWorkflowStagesListPage> {
  // Placeholder data until the workflow-stages Cubit/repository are wired in.
  final List<Map<String, dynamic>> _stages = [
    {'name': 'التصميم', 'order': 1, 'isActive': true, 'isFinal': false},
    {'name': 'الطحن', 'order': 2, 'isActive': true, 'isFinal': false},
    {'name': 'التلميع', 'order': 3, 'isActive': true, 'isFinal': false},
    {'name': 'التسليم', 'order': 4, 'isActive': true, 'isFinal': true},
  ];

  Future<void> _confirmDelete(int index) async {
    final stage = _stages[index];
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المرحلة',
      message: 'هل أنت متأكد من حذف مرحلة "${stage['name']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _stages.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.caseWorkflowStagesListScreen),
      appBar: AppBar(title: Text('مراحل الحالات', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.caseWorkflowStageFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;

            if (_stages.isEmpty) {
              return Center(
                child: Text('لا يوجد مراحل بعد', style: AppTextStyles.font14RegularSecondary),
              );
            }

            final sortedStages = [..._stages]
              ..sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 16,
                  ),
                  itemCount: sortedStages.length,
                  itemBuilder: (context, index) {
                    final stage = sortedStages[index];
                    final originalIndex = _stages.indexOf(stage);
                    return CaseWorkflowStageListItemWidget(
                      name: stage['name'] as String,
                      order: stage['order'] as int,
                      isActive: stage['isActive'] as bool,
                      isFinal: stage['isFinal'] as bool,
                      onEdit: () =>
                          context.push(Routes.caseWorkflowStageFormScreen, extra: stage),
                      onDelete: () => _confirmDelete(originalIndex),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

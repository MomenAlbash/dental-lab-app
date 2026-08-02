import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The cases list tab body — reads the shared [CasesCubit] from the shell.
class CasesListBody extends StatelessWidget {
  const CasesListBody({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    CaseListItemModel caseItem,
  ) async {
    final cubit = context.read<CasesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الحالة',
      message: 'هل أنت متأكد من حذف حالة "${caseItem.patientName ?? ''}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteCase(caseItem.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CasesCubit, CasesState>(
      listener: (context, state) {
        switch (state) {
          case CaseDeleted():
            ShowToast(message: 'تم حذف الحالة', state: toastState.success);
          case CaseDeleteError(:final message):
            ShowToast(message: message, state: toastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! CaseDeleted && current is! CaseDeleteError,
      builder: (context, state) {
        return switch (state) {
          CasesLoaded(:final cases) =>
            cases.isEmpty
                ? _Empty()
                : _CasesList(
                    cases: cases,
                    onDelete: (c) => _confirmDelete(context, c),
                  ),
          CasesError(:final message) => Center(
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
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'لا يوجد حالات بعد',
        style: AppTextStyles.font14RegularSecondary,
      ),
    );
  }
}

class _CasesList extends StatelessWidget {
  const _CasesList({required this.cases, required this.onDelete});

  final List<CaseListItemModel> cases;
  final ValueChanged<CaseListItemModel> onDelete;

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
              onRefresh: () => context.read<CasesCubit>().getCases(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                itemCount: cases.length,
                itemBuilder: (context, index) {
                  final caseItem = cases[index];
                  return CaseListItemWidget(
                    caseNumber: caseItem.caseNumber ?? '',
                    patientName: caseItem.patientName ?? '',
                    doctorName: caseItem.doctorName ?? '',
                    stageName: caseItem.caseStatusLabel,
                    priority: caseItem.priority,
                    onTap: () async {
                      await context.push(
                        Routes.caseDetailScreen,
                        extra: caseItem.id,
                      );
                      if (context.mounted) {
                        context.read<CasesCubit>().getCases();
                      }
                    },
                    onDelete: () => onDelete(caseItem),
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

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:dental_lab_app/features/payroll/logic/payroll/payroll_cubit.dart';
import 'package:dental_lab_app/features/payroll/logic/payroll/payroll_state.dart';
import 'package:dental_lab_app/features/payroll/ui/widgets/salary_statement_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Payslips, and running payroll to produce them.
///
/// There is no period picker: payroll runs for whatever standard window each
/// employee's own pay cycle resolves to around an **anchor date**, so a weekly
/// and a monthly employee generated together get different periods. The screen
/// picks a day, not a range.
class PayrollPage extends StatelessWidget {
  const PayrollPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PayrollCubit>()..load(),
      child: const _PayrollView(),
    );
  }
}

class _PayrollView extends StatelessWidget {
  const _PayrollView();

  Future<void> _generate(BuildContext context) async {
    final cubit = context.read<PayrollCubit>();

    final picked = await showDatePicker(
      context: context,
      initialDate: cubit.anchorDate,
      firstDate: DateTime(cubit.anchorDate.year - 2),
      lastDate: DateTime.now(),
      helpText: 'اختر يوماً ضمن الفترة المطلوبة',
    );
    if (picked == null || !context.mounted) return;

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'توليد كشوف الرواتب',
      message:
          'ستُولَّد كشوف لكل موظف له نظام راتب فعّال، عن الفترة التي يقع فيها '
          '${ApiTime.formatDate(picked)} حسب دورة راتب كل موظف.',
      confirmText: 'توليد',
    );
    if (confirmed != true) return;

    await cubit.generate(anchorDate: picked);
  }

  Future<void> _approve(BuildContext context, SalaryStatementModel s) async {
    final cubit = context.read<PayrollCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'اعتماد كشف الراتب',
      message:
          'بعد الاعتماد تُغلق أيام الفترة: أي بصمة أو تعديل حضور يقع ضمنها '
          'سيُرفض حتى يُعاد الكشف إلى مسودة.',
      confirmText: 'اعتماد',
    );
    if (confirmed != true) return;

    await cubit.approve(s.id);
  }

  Future<void> _delete(BuildContext context, SalaryStatementModel s) async {
    final cubit = context.read<PayrollCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المسودة',
      message: 'يمكن توليدها من جديد في أي وقت.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.delete(s.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.payroll);

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.payrollScreen),
      appBar: GlassAppBar(
        title: Text(
          'الرواتب',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          IconButton(
            tooltip: 'أجور المراحل',
            icon: const Icon(Icons.stacked_bar_chart),
            onPressed: () => context.push(Routes.stagePayScreen),
          ),
          if (canEdit)
            IconButton(
              tooltip: 'توليد كشوف الرواتب',
              icon: const Icon(Icons.playlist_add_check),
              onPressed: () => _generate(context),
            ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<PayrollCubit, PayrollState>(
          listenWhen: (previous, current) =>
              current is PayrollActionSuccess || current is PayrollActionError,
          listener: (context, state) {
            switch (state) {
              case PayrollActionSuccess(:final message):
                showToast(message: message, state: ToastState.success);
              case PayrollActionError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! PayrollActionSuccess &&
              current is! PayrollActionError,
          builder: (context, state) => switch (state) {
            PayrollLoaded() => Column(
              children: [
                const _StatusFilterRow(),
                if (state.uncovered.isNotEmpty) _CoverageBanner(state: state),
                Expanded(
                  child: state.statements.isEmpty
                      ? const _EmptyState()
                      : RefreshIndicator(
                          onRefresh: () => context.read<PayrollCubit>().load(),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              0,
                              AppSpacing.lg,
                              AppSpacing.lg,
                            ),
                            itemCount: state.statements.length,
                            itemBuilder: (context, index) {
                              final statement = state.statements[index];
                              return _StatementCard(
                                statement: statement,
                                onOpen: () => showSalaryStatementSheet(
                                  context,
                                  statement: statement,
                                ),
                                onApprove: canEdit && statement.isDraft
                                    ? () => _approve(context, statement)
                                    : null,
                                onMarkPaid:
                                    canEdit &&
                                        statement.status ==
                                            SalaryStatementStatus.approved
                                    ? () => context
                                          .read<PayrollCubit>()
                                          .markPaid(statement.id)
                                    : null,
                                onRevert:
                                    canEdit &&
                                        statement.status !=
                                            SalaryStatementStatus.draft
                                    ? () => context.read<PayrollCubit>().revert(
                                        statement.id,
                                      )
                                    : null,
                                onDelete: canEdit && statement.canDelete
                                    ? () => _delete(context, statement)
                                    : null,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
            PayrollError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ),
            ),
            _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
          },
        ),
      ),
    );
  }
}

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cubit = context.watch<PayrollCubit>();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final status in SalaryStatementStatus.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: FilterChip(
                selected: cubit.statusFilter == status,
                showCheckmark: false,
                label: Text(status.label),
                labelStyle: AppTextStyles.font12RegularHint.copyWith(
                  color: cubit.statusFilter == status
                      ? Theme.of(context).colorScheme.primary
                      : glass.onGlassMuted,
                ),
                onSelected: (_) => cubit.toggleStatus(status),
              ),
            ),
        ],
      ),
    );
  }
}

/// Who has no payslip yet for their own current period.
///
/// Read beside the statements rather than instead of them: "three payslips
/// exist" and "two people are still unpaid" are different questions, and only
/// the second one needs acting on.
class _CoverageBanner extends StatelessWidget {
  const _CoverageBanner({required this.state});

  final PayrollLoaded state;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          Icon(Icons.pending_actions, size: 18, color: glass.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${state.uncovered.length} موظف بلا كشف راتب لهذه الفترة بعد',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatementCard extends StatelessWidget {
  const _StatementCard({
    required this.statement,
    required this.onOpen,
    this.onApprove,
    this.onMarkPaid,
    this.onRevert,
    this.onDelete,
  });

  final SalaryStatementModel statement;
  final VoidCallback onOpen;
  final VoidCallback? onApprove;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onRevert;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final statusColor = switch (statement.status) {
      SalaryStatementStatus.paid => glass.success,
      SalaryStatementStatus.approved => glass.info,
      SalaryStatementStatus.draft || null => glass.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(AppRadius.glass),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statement.employeeName ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.font14MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    Text(
                      // Never a bare number: the lab pays in more than one
                      // currency, and two payslips side by side are only told
                      // apart by the code beside the figure.
                      statement.format(statement.netAmount),
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        statement.periodLabel,
                        style: AppTextStyles.font12RegularHint.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ),
                    Text(
                      statement.status?.label ?? '—',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                if (onApprove != null ||
                    onMarkPaid != null ||
                    onRevert != null ||
                    onDelete != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      if (onApprove != null)
                        FilledButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('اعتماد'),
                        ),
                      if (onMarkPaid != null)
                        OutlinedButton.icon(
                          onPressed: onMarkPaid,
                          icon: const Icon(Icons.payments_outlined, size: 16),
                          label: const Text('تعليم كمدفوع'),
                        ),
                      if (onRevert != null)
                        TextButton.icon(
                          onPressed: onRevert,
                          icon: const Icon(Icons.undo, size: 16),
                          label: const Text('إرجاع لمسودة'),
                        ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: statement.deleteMessage ?? 'حذف المسودة',
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: glass.error,
                          ),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: glass.onGlassMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد كشوف رواتب',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'اختر يوماً ضمن الفترة من زر التوليد أعلى الشاشة',
              textAlign: TextAlign.center,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

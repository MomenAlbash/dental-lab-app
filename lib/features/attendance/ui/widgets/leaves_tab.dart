import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/logic/leaves/leaves_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/leaves/leaves_state.dart';
import 'package:dental_lab_app/features/attendance/ui/widgets/leave_form_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The leave queue.
///
/// Pending requests lead, because deciding them is the only thing on this
/// screen somebody is waiting on. Approving one re-judges every day it covers,
/// which is why the decision is a first-class action here rather than
/// something buried in a detail screen.
class LeavesTab extends StatelessWidget {
  const LeavesTab({super.key});

  Future<void> _decide(
    BuildContext context,
    LeaveModel leave, {
    required bool approve,
  }) async {
    final cubit = context.read<LeavesCubit>();

    // Approving is confirmed too, not just rejecting: it clears absences
    // already recorded against those days, and can put a draft payslip out of
    // step with its own attendance.
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: approve ? 'الموافقة على الإجازة' : 'رفض الإجازة',
      message: approve
          ? 'ستُحتسب أيام ${leave.periodLabel} كإجازة ويُعاد حساب الحضور فيها.'
          : 'سيُرفض الطلب ويبقى الحضور كما هو.',
      confirmText: approve ? 'موافقة' : 'رفض',
      isDestructive: !approve,
    );
    if (confirmed != true) return;

    await cubit.decide(id: leave.id, approve: approve);
  }

  Future<void> _delete(BuildContext context, LeaveModel leave) async {
    final cubit = context.read<LeavesCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الإجازة',
      message:
          'سيُعاد حساب كل يوم كانت تغطّيه، وقد تعود أيام الغياب للظهور.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.deleteLeave(leave.id);
  }

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<LeavesCubit>();

    final request = await showLeaveFormSheet(context);
    if (request == null) return;

    await cubit.createLeave(request);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final permissions = getIt<SessionCubit>().state;

    // `Leaves:FullAccess` is what decides somebody else's request. Without it
    // the server scopes the list to the caller's own leaves anyway, so the
    // decision buttons are simply not drawn.
    final canDecide = permissions.canEdit(PermissionName.leaves);
    final canCreate =
        canDecide || permissions.canEdit(PermissionName.attendance);

    return BlocConsumer<LeavesCubit, LeavesState>(
      listenWhen: (previous, current) =>
          current is LeavesActionSuccess || current is LeavesActionError,
      listener: (context, state) {
        switch (state) {
          case LeavesActionSuccess(:final message):
            showToast(message: message, state: ToastState.success);
          case LeavesActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! LeavesActionSuccess && current is! LeavesActionError,
      builder: (context, state) {
        return Stack(
          children: [
            Column(
              children: [
                const _StatusFilterRow(),
                Expanded(
                  child: switch (state) {
                    LeavesLoaded(:final leaves) =>
                      leaves.isEmpty
                          ? const _EmptyState()
                          : RefreshIndicator(
                              onRefresh: () =>
                                  context.read<LeavesCubit>().load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.lg,
                                  0,
                                  AppSpacing.lg,
                                  80,
                                ),
                                itemCount: leaves.length,
                                itemBuilder: (context, index) {
                                  final leave = leaves[index];
                                  return _LeaveCard(
                                    leave: leave,
                                    onApprove: canDecide && leave.isPending
                                        ? () => _decide(
                                            context,
                                            leave,
                                            approve: true,
                                          )
                                        : null,
                                    onReject: canDecide && leave.isPending
                                        ? () => _decide(
                                            context,
                                            leave,
                                            approve: false,
                                          )
                                        : null,
                                    onDelete: canDecide && leave.canDelete
                                        ? () => _delete(context, leave)
                                        : null,
                                  );
                                },
                              ),
                            ),
                    LeavesError(:final message) => Center(
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
                    _ => const Center(
                      child: CustomCircleProgressIndiacatorWidget(),
                    ),
                  },
                ),
              ],
            ),
            if (canCreate)
              Positioned(
                bottom: AppSpacing.lg,
                left: AppSpacing.lg,
                child: FloatingActionButton.extended(
                  heroTag: 'leaves-add',
                  onPressed: () => _create(context),
                  icon: const Icon(Icons.add),
                  label: const Text('تسجيل إجازة'),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Pending / approved / rejected, each with its own count.
class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final cubit = context.watch<LeavesCubit>();
    final selected = cubit.statusFilter;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (final status in LeaveStatus.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: FilterChip(
                selected: selected == status,
                showCheckmark: false,
                label: Text(status.label),
                labelStyle: AppTextStyles.font12RegularHint.copyWith(
                  color: selected == status
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

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.leave,
    this.onApprove,
    this.onReject,
    this.onDelete,
  });

  final LeaveModel leave;

  /// Null unless the request is still pending **and** the user may decide it.
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final statusColor = switch (leave.status) {
      LeaveStatus.approved => glass.success,
      LeaveStatus.rejected => glass.error,
      LeaveStatus.pending || null => glass.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(
          color: leave.isPending ? statusColor : glass.strokeColor,
          width: leave.isPending ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  leave.employeeName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              Text(
                leave.status?.label ?? '—',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [
              leave.periodLabel,
              '${leave.dayCount} يوم',
              if (leave.windowLabel != null) leave.windowLabel!,
            ].join(' · '),
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          if (leave.reason?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 2),
            Text(
              leave.reason!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
          if (leave.affectsDraftSalary) ...[
            const SizedBox(height: 4),
            Text(
              'ضمن مسودة كشف راتب — أعد توليد الرواتب بعد القرار',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            ),
          ],
          if (onApprove != null || onReject != null || onDelete != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (onApprove != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('موافقة'),
                    ),
                  ),
                if (onApprove != null && onReject != null)
                  const SizedBox(width: AppSpacing.sm),
                if (onReject != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('رفض'),
                    ),
                  ),
                if (onDelete != null)
                  IconButton(
                    tooltip: leave.canDelete
                        ? 'حذف الإجازة'
                        : (leave.deleteMessage ?? 'لا يمكن الحذف'),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: glass.error,
                    ),
                    onPressed: leave.canDelete ? onDelete : null,
                  ),
              ],
            ),
          ],
        ],
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
              Icons.beach_access_outlined,
              size: 48,
              color: glass.onGlassMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد إجازات بهذا التصنيف',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/logic/holidays/holidays_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The days the laboratory does not work.
///
/// Adding one excuses every employee it covers on that date; removing one puts
/// those days back on the books. Both re-judge attendance, which is why each
/// carries its own warning rather than behaving like an ordinary list edit.
class HolidaysTab extends StatelessWidget {
  const HolidaysTab({super.key});

  Future<void> _create(BuildContext context) async {
    final cubit = context.read<HolidaysCubit>();

    final request = await showDialog<SaveHolidayRequestModel>(
      context: context,
      builder: (_) => const _HolidayFormDialog(),
    );
    if (request == null) return;

    await cubit.create(request);
  }

  Future<void> _delete(BuildContext context, HolidayModel holiday) async {
    final cubit = context.read<HolidaysCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف العطلة',
      message:
          'سيعود هذا اليوم يوم عمل ويُعاد حساب حضور كل من كانت تشمله العطلة.',
      confirmText: 'حذف',
      isDestructive: true,
    );
    if (confirmed != true) return;

    await cubit.delete(holiday.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.attendance,
    );

    return BlocConsumer<HolidaysCubit, HolidaysState>(
      listenWhen: (previous, current) =>
          current is HolidaysActionSuccess || current is HolidaysActionError,
      listener: (context, state) {
        switch (state) {
          case HolidaysActionSuccess(:final message):
            showToast(message: message, state: ToastState.success);
          case HolidaysActionError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      buildWhen: (previous, current) =>
          current is! HolidaysActionSuccess && current is! HolidaysActionError,
      builder: (context, state) {
        return Stack(
          children: [
            switch (state) {
              HolidaysLoaded(:final holidays) =>
                holidays.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: () => context.read<HolidaysCubit>().load(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.md,
                            AppSpacing.lg,
                            80,
                          ),
                          itemCount: holidays.length,
                          itemBuilder: (context, index) => _HolidayCard(
                            holiday: holidays[index],
                            onDelete: canEdit
                                ? () => _delete(context, holidays[index])
                                : null,
                          ),
                        ),
                      ),
              HolidaysError(:final message) => Center(
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
            if (canEdit)
              Positioned(
                bottom: AppSpacing.lg,
                left: AppSpacing.lg,
                child: FloatingActionButton.extended(
                  heroTag: 'holidays-add',
                  onPressed: () => _create(context),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة عطلة'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HolidayCard extends StatelessWidget {
  const _HolidayCard({required this.holiday, this.onDelete});

  final HolidayModel holiday;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 18, color: glass.info),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  [
                    holiday.date == null
                        ? '—'
                        : ApiTime.formatDate(holiday.date!),
                    // A lab-wide closure says so rather than printing a count
                    // nobody can check at a glance.
                    if (holiday.allEmployees)
                      'كل الموظفين'
                    else
                      '${holiday.employeeCount} موظف',
                  ].join(' · '),
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                if (holiday.affectsDraftSalary)
                  Text(
                    'ضمن مسودة كشف راتب — أعد توليد الرواتب',
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.warning,
                    ),
                  ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: holiday.canDelete
                  ? 'حذف العطلة'
                  : (holiday.deleteMessage ?? 'لا يمكن الحذف'),
              icon: Icon(Icons.delete_outline, size: 18, color: glass.error),
              onPressed: holiday.canDelete ? onDelete : null,
            ),
        ],
      ),
    );
  }
}

/// A holiday is lab-wide by default — that is what the word usually means, and
/// the per-employee case is the exception worth an extra tap.
class _HolidayFormDialog extends StatefulWidget {
  const _HolidayFormDialog();

  @override
  State<_HolidayFormDialog> createState() => _HolidayFormDialogState();
}

class _HolidayFormDialogState extends State<_HolidayFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year - 2),
      lastDate: DateTime(_date.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      SaveHolidayRequestModel(
        name: _nameController.text.trim(),
        date: _date,
        allEmployees: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة عطلة', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextFormField(
                controller: _nameController,
                hintText: 'اسم العطلة (مثال: عيد الفطر)',
                prefixIcon: Icon(
                  Icons.flag_outlined,
                  color: context.glass.onGlassMuted,
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'الاسم مطلوب'
                    : null,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickDate,
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: context.glass.onGlassMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ApiTime.formatDate(_date),
                      style: AppTextStyles.font14MediumText,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'تُطبَّق على كل موظفي المختبر',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: context.glass.onGlassMuted,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _submit, child: const Text('حفظ')),
      ],
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
            Icon(Icons.flag_outlined, size: 48, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا توجد عطل مسجّلة',
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

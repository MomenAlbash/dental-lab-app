import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:flutter/material.dart';

/// Where this employee stands with the laboratory, and what can be done about
/// it.
///
/// Terminating is dated and **keeps the person**: their attendance, payslips
/// and case history are all still real, so the row goes grey rather than
/// disappearing — and the reason it says so on the card is that a greyed-out
/// name with no explanation reads as a bug.
class EmployeeEmploymentCard extends StatelessWidget {
  const EmployeeEmploymentCard({
    super.key,
    required this.employee,
    required this.isBusy,
    required this.onTerminate,
    required this.onReinstate,
    required this.onChangePhoto,
    required this.onOpenNotes,
    required this.onOpenWorkAndPay,
  });

  final EmployeeModel employee;
  final bool isBusy;

  final VoidCallback onTerminate;
  final VoidCallback onReinstate;
  final VoidCallback onChangePhoto;
  final VoidCallback onOpenNotes;

  /// Their shift, their pay and the terminal codes they punch on.
  final VoidCallback onOpenWorkAndPay;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final permissions = getIt<SessionCubit>().state;
    final canEdit = permissions.canEdit(PermissionName.users);
    final canSeeWork = permissions.canRead(PermissionName.attendance);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                employee.isActive
                    ? Icons.verified_user_outlined
                    : Icons.person_off_outlined,
                size: 18,
                color: employee.isActive ? glass.success : glass.onGlassMuted,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  employee.isActive ? 'على رأس العمل' : 'انتهى عمله',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              if (employee.isRepresentative)
                Text(
                  'مندوب',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.info,
                  ),
                ),
            ],
          ),

          if (employee.stabilizationDate != null)
            _Line(
              label: 'تاريخ التثبيت',
              value: ApiTime.formatDate(employee.stabilizationDate!),
            ),
          if (employee.terminationDate != null)
            _Line(
              label: 'تاريخ إنهاء العمل',
              value: ApiTime.formatDate(employee.terminationDate!),
            ),

          _Line(
            label: 'حساب الدخول',
            // Three states, not two: no login at all is a different thing
            // from one that exists but is suspended, and only one of them is
            // somebody's mistake.
            value: switch ((employee.hasLogin, employee.userIsActive)) {
              (false, _) => 'لا يوجد',
              (true, false) => 'موقوف',
              (true, _) => employee.username ?? 'مفعّل',
            },
          ),
          if (employee.userRoleName?.trim().isNotEmpty ?? false)
            _Line(label: 'الدور', value: employee.userRoleName!),

          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (canEdit)
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onChangePhoto,
                  icon: const Icon(Icons.photo_camera_outlined, size: 16),
                  label: const Text('الصورة'),
                ),
              OutlinedButton.icon(
                onPressed: isBusy ? null : onOpenNotes,
                icon: const Icon(Icons.sticky_note_2_outlined, size: 16),
                label: const Text('الملاحظات'),
              ),
              if (canSeeWork)
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onOpenWorkAndPay,
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: const Text('الدوام والراتب'),
                ),
              if (canEdit)
                if (employee.isActive)
                  OutlinedButton.icon(
                    onPressed: isBusy ? null : onTerminate,
                    icon: Icon(Icons.logout, size: 16, color: glass.error),
                    label: Text(
                      'إنهاء العمل',
                      style: TextStyle(color: glass.error),
                    ),
                  )
                else
                  FilledButton.icon(
                    onPressed: isBusy ? null : onReinstate,
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('إعادة التعيين'),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlass,
            ),
          ),
        ],
      ),
    );
  }
}

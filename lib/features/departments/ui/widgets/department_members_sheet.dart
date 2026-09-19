import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/departments/data/models/department_user_model.dart';
import 'package:dental_lab_app/features/departments/data/repos/departments_repo.dart';
import 'package:flutter/material.dart';

/// Who a department brings into a stage's pool.
///
/// Read-only here: membership follows the employee's department on their own
/// record, so this screen answers "who would this stage reach" rather than
/// offering to change it in a second place.
Future<void> showDepartmentMembersSheet(
  BuildContext context, {
  required String departmentId,
  required String departmentName,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _DepartmentMembersSheet(
      departmentId: departmentId,
      departmentName: departmentName,
    ),
  );
}

class _DepartmentMembersSheet extends StatefulWidget {
  const _DepartmentMembersSheet({
    required this.departmentId,
    required this.departmentName,
  });

  final String departmentId;
  final String departmentName;

  @override
  State<_DepartmentMembersSheet> createState() =>
      _DepartmentMembersSheetState();
}

class _DepartmentMembersSheetState extends State<_DepartmentMembersSheet> {
  List<DepartmentUserModel>? _users;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<DepartmentsRepo>().getUsers(widget.departmentId);
    if (!mounted) return;

    result.fold(
      (failure) => setState(() => _error = failure.errorMessage),
      (users) => setState(() => _users = users),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final users = _users;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'موظفو القسم',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          Text(
            widget.departmentName,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          if (_error != null)
            Text(
              _error!,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.error,
              ),
            )
          else if (users == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (users.isEmpty)
            Text(
              // A stage pointed at an empty department reaches nobody — worth
              // saying plainly rather than showing a blank list.
              'لا يوجد موظفون في هذا القسم — أي مرحلة تشير إليه لن تصل إلى أحد',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            )
          else
            for (final user in users) _MemberRow(user: user),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.user});

  final DepartmentUserModel user;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            user.isSupervisor
                ? Icons.supervisor_account_outlined
                : Icons.person_outline,
            size: 18,
            // A suspended login is greyed, not hidden: it is the explanation
            // for why somebody the lab expects on a stage is not picking work
            // up.
            color: user.isActive ? glass.onGlassMuted : glass.strokeColor,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font14MediumText.copyWith(
                color: user.isActive ? glass.onGlass : glass.onGlassMuted,
              ),
            ),
          ),
          if (user.isSupervisor)
            Text(
              'مشرف',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          else if (!user.isActive)
            Text(
              'حساب موقوف',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.warning,
              ),
            ),
        ],
      ),
    );
  }
}

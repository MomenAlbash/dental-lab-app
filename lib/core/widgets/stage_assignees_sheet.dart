import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_cubit.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_state.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Who may work a stage: whole departments, named people, and people carved
/// back out of an assigned department.
typedef StageAssignees = ({
  List<String> departmentIds,
  List<String> userIds,
  List<String> excludedUserIds,
});

/// Edits a stage's assignment.
///
/// Shared by the case-workflow editor and the restoration-route editor because
/// both save the same three id lists (`departmentIds`, `userIds`,
/// `excludedUserIds`) — answering the question two different ways in two
/// screens is how a lab ends up unable to say who owns a stage.
///
/// The two pools are additive: everybody in every listed department **plus**
/// every listed person, minus the excluded ones.
Future<StageAssignees?> showStageAssigneesSheet(
  BuildContext context, {
  required StageAssignees initial,
}) {
  return showGlassBottomSheet<StageAssignees>(
    context: context,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DepartmentsCubit>()..load()),
        BlocProvider(create: (_) => getIt<UsersCubit>()..getUsers()),
      ],
      child: _StageAssigneesSheet(initial: initial),
    ),
  );
}

class _StageAssigneesSheet extends StatefulWidget {
  const _StageAssigneesSheet({required this.initial});

  final StageAssignees initial;

  @override
  State<_StageAssigneesSheet> createState() => _StageAssigneesSheetState();
}

class _StageAssigneesSheetState extends State<_StageAssigneesSheet> {
  late final Set<String> _departmentIds = {...widget.initial.departmentIds};
  late final Set<String> _userIds = {...widget.initial.userIds};
  late final Set<String> _excludedUserIds = {...widget.initial.excludedUserIds};

  void _toggle(Set<String> set, String id) {
    setState(() => set.contains(id) ? set.remove(id) : set.add(id));
  }

  /// A person cannot be both named and excluded — the two would cancel out and
  /// the lab would have no way to tell which one it meant.
  void _toggleUser(String id) {
    setState(() {
      if (_userIds.remove(id)) return;
      _excludedUserIds.remove(id);
      _userIds.add(id);
    });
  }

  void _toggleExcluded(String id) {
    setState(() {
      if (_excludedUserIds.remove(id)) return;
      _userIds.remove(id);
      _excludedUserIds.add(id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'من ينفّذ هذه المرحلة',
                  style: AppTextStyles.font18MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'الأقسام والأشخاص يُجمعان معاً: كل من في الأقسام المحددة، '
                  'زائد الأشخاص المحددين، ناقص المستثنين.',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(AppSpacing.cardPadding),
              children: [
                const _SectionLabel('الأقسام'),
                BlocBuilder<DepartmentsCubit, DepartmentsState>(
                  builder: (context, state) {
                    if (state is! DepartmentsLoaded) {
                      return const _Placeholder(text: 'جارٍ تحميل الأقسام...');
                    }
                    final active = [
                      for (final d in state.departments)
                        if (d.isActive) d,
                    ];
                    if (active.isEmpty) {
                      return const _Placeholder(text: 'لا توجد أقسام معرّفة');
                    }

                    return _ChipGrid(
                      children: [
                        for (final department in active)
                          _pickChip(
                            label: _departmentLabel(department),
                            isSelected: _departmentIds.contains(department.id),
                            onTap: () => _toggle(_departmentIds, department.id),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                BlocBuilder<UsersCubit, UsersState>(
                  builder: (context, state) {
                    if (state is! UsersLoaded) {
                      return const _Placeholder(
                        text: 'جارٍ تحميل المستخدمين...',
                      );
                    }
                    // Doctors hold accounts too, and a doctor is never a
                    // technician working a bench stage.
                    final staff = [
                      for (final user in state.users)
                        if (!user.type.isDoctor) user,
                    ];
                    if (staff.isEmpty) {
                      return const _Placeholder(text: 'لا يوجد مستخدمون');
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel('أشخاص محددون'),
                        _ChipGrid(
                          children: [
                            for (final user in staff)
                              _pickChip(
                                label: _userLabel(user),
                                isSelected: _userIds.contains(user.id),
                                onTap: () => _toggleUser(user.id),
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _SectionLabel('مستثنون من الأقسام'),
                        _ChipGrid(
                          children: [
                            for (final user in staff)
                              _pickChip(
                                label: _userLabel(user),
                                isSelected: _excludedUserIds.contains(user.id),
                                onTap: () => _toggleExcluded(user.id),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: CustomButtonWidget(
              buttonText: 'حفظ الإسناد',
              onPressed: () => Navigator.of(context).pop((
                departmentIds: _departmentIds.toList(),
                userIds: _userIds.toList(),
                excludedUserIds: _excludedUserIds.toList(),
              )),
            ),
          ),
        ],
      ),
    );
  }

  static String _departmentLabel(DepartmentModel department) {
    final label = department.displayName;
    return label.isEmpty ? '—' : label;
  }

  static String _userLabel(UserModel user) {
    final name = user.linkedName.trim();
    if (name.isNotEmpty) return name;
    return user.username?.trim().isNotEmpty == true ? user.username! : '—';
  }

  Widget _pickChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ChipGrid extends StatelessWidget {
  const _ChipGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.font14MediumText.copyWith(
          color: context.glass.onGlass,
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.font12RegularHint.copyWith(
        color: context.glass.onGlassMuted,
      ),
    );
  }
}

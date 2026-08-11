import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_summary_strip.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/ui/widgets/user_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Which subset of the loaded users the list is showing.
enum UserStatusFilter { all, active, inactive }

/// The users list: a summary strip that doubles as a status filter, then the
/// rows — mirrors [DoctorsListView].
class UsersListView extends StatefulWidget {
  const UsersListView({
    super.key,
    required this.users,
    required this.onDelete,
    this.scrollController,
  });

  final List<UserModel> users;
  final ValueChanged<UserModel> onDelete;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  State<UsersListView> createState() => _UsersListViewState();
}

class _UsersListViewState extends State<UsersListView> {
  UserStatusFilter _status = UserStatusFilter.all;

  List<UserModel> get _visible => switch (_status) {
    UserStatusFilter.all => widget.users,
    UserStatusFilter.active =>
      widget.users.where((user) => user.isActive).toList(),
    UserStatusFilter.inactive =>
      widget.users.where((user) => !user.isActive).toList(),
  };

  @override
  Widget build(BuildContext context) {
    final activeCount = widget.users.where((user) => user.isActive).length;
    final visible = _visible;

    return Builder(
      builder: (context) {
        // The strip keeps a phone-ish inset on a phone and a roomier one from
        // tablet up; the rows are laid out by AdaptiveCollection, which fills
        // the width rather than capping it.
        final horizontal =
            AdaptiveLayout.of(context) == AdaptiveFormFactor.mobile
            ? AppSpacing.lg
            : AppSpacing.xl;

        return Column(
          children: [
            if (widget.users.isNotEmpty)
              Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      AppSpacing.md,
                      horizontal,
                      AppSpacing.md,
                    ),
                    child: GlassSummaryStrip<UserStatusFilter>(
                      tiles: [
                        GlassSummaryTileData(
                          value: UserStatusFilter.all,
                          label: 'الكل',
                          count: widget.users.length,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        GlassSummaryTileData(
                          value: UserStatusFilter.active,
                          label: 'مفعّل',
                          count: activeCount,
                          color: context.glass.success,
                        ),
                        GlassSummaryTileData(
                          value: UserStatusFilter.inactive,
                          label: 'موقوف',
                          count: widget.users.length - activeCount,
                          color: context.glass.onGlassMuted,
                        ),
                      ],
                      selected: _status,
                      onSelected: (value) => setState(() => _status = value),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: AppMotion.base)
                  .slideY(
                    begin: -0.12,
                    duration: AppMotion.base,
                    curve: AppMotion.enter,
                  ),
            Expanded(
              child: visible.isEmpty
                  ? _EmptyState(status: _status)
                  : AdaptiveCollection<UserModel>(
                      items: visible,
                      scrollController: widget.scrollController,
                      onRefresh: () => context.read<UsersCubit>().getUsers(),
                      itemBuilder: (context, user, _) => UserListItemWidget(
                        username: user.username ?? '—',
                        roleName: user.roleName ?? '',
                        isDoctorType: user.type.isDoctor,
                        isActive: user.isActive,
                        isAdmin: user.isAdmin,
                        onTap: () async {
                          await context.push(
                            Routes.userDetailScreen,
                            extra: user.id,
                          );
                          if (context.mounted) {
                            context.read<UsersCubit>().getUsers();
                          }
                        },
                        onDelete: () => widget.onDelete(user),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.status});

  final UserStatusFilter status;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isFiltered = status != UserStatusFilter.all;

    final (IconData icon, String title, String hint) = isFiltered
        ? (
            Icons.filter_alt_off_outlined,
            'لا يوجد مستخدمين بهذه الحالة',
            'اضغط "الكل" لعرض الجميع',
          )
        : (
            Icons.person_outline,
            'لا يوجد مستخدمين بعد',
            'أضف أول مستخدم بالضغط على زر الإضافة',
          );

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(icon, size: 40, color: glass.onGlassMuted),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

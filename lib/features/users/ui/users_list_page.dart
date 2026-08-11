import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_filter_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:dental_lab_app/features/users/ui/widgets/user_filters_sheet.dart';
import 'package:dental_lab_app/features/users/ui/widgets/users_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class UsersListPage extends StatelessWidget {
  const UsersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<UsersCubit>()..getUsers(),
      child: const _UsersListView(),
    );
  }
}

class _UsersListView extends StatefulWidget {
  const _UsersListView();

  @override
  State<_UsersListView> createState() => _UsersListViewState();
}

class _UsersListViewState extends State<_UsersListView> {
  final _scrollController = ScrollController();

  /// Last successfully loaded users, kept so a refresh can show the existing
  /// rows instead of replacing them with the loading skeleton.
  List<UserModel>? _lastUsers;

  /// The add button collapses to an icon once the user starts scrolling, so a
  /// wide button never sits on top of the rows they are reading.
  bool _addButtonExtended = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldExtend = _scrollController.offset < 40;
    if (shouldExtend == _addButtonExtended) return;
    setState(() => _addButtonExtended = shouldExtend);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(UserModel user) async {
    final cubit = context.read<UsersCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المستخدم',
      message: 'هل أنت متأكد من حذف المستخدم "${user.username ?? ''}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deleteUser(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.usersListScreen),
      appBar: GlassAppBar(
        title: Text(
          'المستخدمين',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          BlocBuilder<UsersCubit, UsersState>(
            builder: (context, state) {
              final activeCount = context
                  .read<UsersCubit>()
                  .filters
                  .activeCount;
              return GlassFilterButton(
                activeCount: activeCount,
                onPressed: () => openUserFiltersSheet(context),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة مستخدم',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.userFormScreen);
                if (context.mounted) {
                  context.read<UsersCubit>().getUsers();
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      ),
      body: SafeArea(
        child: BlocConsumer<UsersCubit, UsersState>(
          listener: (context, state) {
            switch (state) {
              case UserDeleted():
                ShowToast(
                  message: 'تم حذف المستخدم',
                  state: toastState.success,
                );
              case UserDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! UserDeleted && current is! UserDeleteError,
          builder: (context, state) {
            if (state is UsersLoaded) _lastUsers = state.users;

            // A refresh emits UsersLoading. Swapping the list out for the
            // skeleton at that moment unmounts the RefreshIndicator mid-pull,
            // which made pull-to-refresh look like it did nothing. Once we
            // have data, keep showing it and let the indicator run.
            final users = switch (state) {
              UsersLoaded(:final users) => users,
              UsersLoading() => _lastUsers,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, users)) {
                (_, final List<UserModel> loaded) => UsersListView(
                  key: const ValueKey('users-loaded'),
                  users: loaded,
                  scrollController: _scrollController,
                  onDelete: _confirmDelete,
                ),
                (UsersError(:final message), null) => Center(
                  key: const ValueKey('users-error'),
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
                _ => const Padding(
                  key: ValueKey('users-loading'),
                  padding: EdgeInsets.only(top: 24),
                  child: GlassListSkeleton(),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

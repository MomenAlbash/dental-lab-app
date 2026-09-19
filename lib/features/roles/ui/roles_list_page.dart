import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_state.dart';
import 'package:dental_lab_app/features/roles/ui/widgets/role_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class RolesListPage extends StatelessWidget {
  const RolesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RolesCubit>()..getRoles(),
      child: const _RolesListView(),
    );
  }
}

class _RolesListView extends StatefulWidget {
  const _RolesListView();

  @override
  State<_RolesListView> createState() => _RolesListViewState();
}

class _RolesListViewState extends State<_RolesListView> {
  /// Last successfully loaded roles, kept so a refresh (or a delete's own
  /// loading tick) shows the existing rows instead of a skeleton.
  List<RoleModel>? _lastRoles;

  bool get _canEdit =>
      getIt<SessionCubit>().state.canEdit(PermissionName.roles);

  Future<void> _openForm({RoleModel? role}) async {
    final saved = await context.push<RoleModel>(
      Routes.roleFormScreen,
      extra: role,
    );
    if (saved != null && mounted) {
      context.read<RolesCubit>().getRoles();
    }
  }

  Future<void> _confirmDelete(RoleModel role) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الدور',
      message: 'هل أنت متأكد من حذف دور "${role.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;
    await context.read<RolesCubit>().deleteRole(role.id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = _canEdit;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.rolesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الأدوار',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'إضافة دور',
              isExtended: true,
              onPressed: () => _openForm(),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocConsumer<RolesCubit, RolesState>(
          listener: (context, state) {
            if (state is RolesActionError) {
              showToast(message: state.message, state: ToastState.error);
            }
          },
          buildWhen: (_, current) => current is! RolesActionError,
          builder: (context, state) {
            if (state is RolesLoaded) _lastRoles = state.roles;

            final roles = switch (state) {
              RolesLoaded(:final roles) => roles,
              RolesLoading() => _lastRoles,
              _ => null,
            };

            if (roles != null) {
              return roles.isEmpty
                  ? const _EmptyState()
                  : AdaptiveCollection<RoleModel>(
                      items: roles,
                      itemBuilder: (context, role, _) => RoleListItemWidget(
                        name: role.name ?? '',
                        description: role.description ?? '',
                        permissionsCount: role.permissions.length,
                        onEdit: canEdit ? () => _openForm(role: role) : null,
                        onDelete: canEdit ? () => _confirmDelete(role) : null,
                      ),
                    );
            }

            if (state is RolesError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              );
            }

            return const GlassListSkeleton();
          },
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
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد أدوار بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول دور بالضغط على زر الإضافة',
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

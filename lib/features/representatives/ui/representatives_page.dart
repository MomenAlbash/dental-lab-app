import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_list_item_widget.dart';
import 'package:dental_lab_app/features/representatives/logic/agents_cubit.dart';
import 'package:dental_lab_app/features/representatives/ui/agent_team_sheet.dart';
import 'package:dental_lab_app/features/users/data/models/user_filters_model.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_state.dart';
import 'package:dental_lab_app/features/users/ui/widgets/users_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Field staff in two tabs: the representatives (users flagged
/// `isRepresentative`) and the agents above them (employees flagged
/// `isAgent`).
class RepresentativesPage extends StatelessWidget {
  const RepresentativesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<UsersCubit>()
            ..applyFilters(const UserFiltersModel(representativesOnly: true)),
        ),
        BlocProvider(create: (_) => getIt<AgentsCubit>()..getAgents()),
      ],
      child: DefaultTabController(
        length: 2,
        child: Builder(
          builder: (context) {
            final glass = context.glass;
            return GlassScaffold(
              drawer: const AppDrawerWidget(
                currentRoute: Routes.representativesScreen,
              ),
              appBar: GlassAppBar(
                title: Text(
                  'المندوبون والوكلاء',
                  style: AppTextStyles.font18MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
              ),
              body: SafeArea(
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'المندوبون'),
                        Tab(text: 'الوكلاء'),
                      ],
                    ),
                    const Expanded(
                      child: TabBarView(
                        children: [_RepresentativesTab(), _AgentsTab()],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RepresentativesTab extends StatelessWidget {
  const _RepresentativesTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersCubit, UsersState>(
      buildWhen: (_, current) =>
          current is UsersLoading ||
          current is UsersLoaded ||
          current is UsersError,
      builder: (context, state) => switch (state) {
        UsersLoaded(:final users) when users.isEmpty => const _Message(
          'لا يوجد مندوبون',
        ),
        UsersLoaded(:final users) => UsersListView(
          users: users,
          onDelete: (user) async {
            final cubit = context.read<UsersCubit>();
            final confirmed = await ConfirmDialogWidget.show(
              context,
              title: 'حذف المستخدم',
              message: 'هل أنت متأكد من حذف المستخدم "${user.username ?? ''}"؟',
              confirmText: 'حذف',
              isDestructive: true,
            );
            if (confirmed == true) await cubit.deleteUser(user.id);
          },
        ),
        UsersError(:final message) => _Message(message),
        _ => const GlassListSkeleton(),
      },
    );
  }
}

class _AgentsTab extends StatelessWidget {
  const _AgentsTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgentsCubit, AgentsState>(
      builder: (context, state) => switch (state) {
        AgentsLoaded(:final agents) when agents.isEmpty => const _Message(
          'لا يوجد وكلاء',
        ),
        AgentsLoaded(:final agents) => AdaptiveCollection(
          items: agents,
          onRefresh: () => context.read<AgentsCubit>().getAgents(),
          itemBuilder: (context, agent, _) => EmployeeListItemWidget(
            fullName: agent.fullName,
            initials: agent.initials,
            code: agent.code ?? '',
            phoneNumber: agent.phoneNumber ?? '',
            onTap: () => showAgentTeamSheet(context, agent),
            onEdit: () async {
              await context.push(Routes.employeeFormScreen, extra: agent);
              if (context.mounted) context.read<AgentsCubit>().getAgents();
            },
          ),
        ),
        AgentsError(:final message) => _Message(message),
        AgentsLoading() => const GlassListSkeleton(),
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyles.font14RegularSecondary.copyWith(
            color: context.glass.onGlassMuted,
          ),
        ),
      ),
    );
  }
}

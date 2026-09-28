import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/representatives/logic/agent_team_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Shows who reports to [agent] now, with a way into the agent's own file.
Future<void> showAgentTeamSheet(BuildContext context, EmployeeModel agent) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => getIt<AgentTeamCubit>()..load(agent.userId),
      child: _AgentTeamSheet(agent: agent, pageContext: context),
    ),
  );
}

class _AgentTeamSheet extends StatelessWidget {
  const _AgentTeamSheet({required this.agent, required this.pageContext});

  final EmployeeModel agent;

  /// The page under the sheet — navigation goes through it, since the sheet
  /// closes first.
  final BuildContext pageContext;

  void _open(BuildContext context, String route, String id) {
    Navigator.of(context).pop();
    pageContext.push(route, extra: id);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => GlassSheetSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                agent.fullName.isEmpty ? '—' : agent.fullName,
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              subtitle: Text(
                'فريق المندوبين الحالي',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              trailing: TextButton.icon(
                onPressed: () =>
                    _open(context, Routes.employeeDetailScreen, agent.id),
                icon: const Icon(Icons.badge_outlined),
                label: const Text('ملف الموظف'),
              ),
            ),
            Divider(height: 1, color: glass.strokeColor),
            Expanded(
              child: BlocBuilder<AgentTeamCubit, AgentTeamState>(
                builder: (context, state) => switch (state) {
                  AgentTeamLoading() => const GlassListSkeleton(),
                  AgentTeamError(:final message) => _Note(message),
                  AgentTeamLoaded(:final team) when team.isEmpty =>
                    const _Note('لا يوجد مندوبون تابعون لهذا الوكيل'),
                  AgentTeamLoaded(:final team) => ListView.builder(
                    controller: scrollController,
                    itemCount: team.length,
                    itemBuilder: (context, i) {
                      final spell = team[i];
                      return ListTile(
                        leading: const Icon(Icons.two_wheeler_outlined),
                        title: Text(
                          spell.representativeLabel,
                          style: AppTextStyles.font14MediumText.copyWith(
                            color: glass.onGlass,
                          ),
                        ),
                        subtitle: Text(
                          spell.periodLabel,
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: glass.onGlassMuted,
                          ),
                        ),
                        onTap: () => _open(
                          context,
                          Routes.userDetailScreen,
                          spell.representativeUserId,
                        ),
                      );
                    },
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

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

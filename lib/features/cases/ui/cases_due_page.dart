import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/cases_due_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The "المواعيد" nav-bar tab.
///
/// There is no real appointment-booking API yet — `CaseAppointments` is a
/// route the client had built ahead of the backend, and the live server
/// 404s on it (verified directly: no `Appointments`/`CaseAppointments` tag
/// exists in the current swagger at all). Until the backend ships it, this
/// tab reads the one schedule that already works: every open case's
/// due date (`GET /Cases`, grouped client-side by `dueDate` — the API has no
/// due-date filter of its own, same reason `CaseFiltersModel` dropped one).
class CasesDueTab extends StatelessWidget {
  const CasesDueTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SessionCubit, Permissions>(
      bloc: getIt<SessionCubit>(),
      builder: (context, permissions) {
        final canRead = permissions.canRead(PermissionName.cases);

        return MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (_) {
                final cubit = getIt<CasesCubit>();
                if (canRead) cubit.getCases();
                return cubit;
              },
            ),
            BlocProvider(
              create: (_) {
                final cubit = getIt<CasePrioritiesCubit>();
                if (canRead) cubit.getCasePriorities();
                return cubit;
              },
            ),
          ],
          child: _CasesDueView(canRead: canRead),
        );
      },
    );
  }
}

class _CasesDueView extends StatelessWidget {
  const _CasesDueView({required this.canRead});

  final bool canRead;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.homeScreen),
      appBar: GlassAppBar(
        title: Text(
          'المواعيد',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(child: canRead ? const CasesDueBody() : const _NoAccess()),
    );
  }
}

class _NoAccess extends StatelessWidget {
  const _NoAccess();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 40, color: glass.onGlassMuted),
            const SizedBox(height: AppSpacing.md),
            Text(
              'لا تملك صلاحية عرض الحالات',
              textAlign: TextAlign.center,
              style: AppTextStyles.font16MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'راجع مدير المخبر لمنحك صلاحية الحالات.',
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

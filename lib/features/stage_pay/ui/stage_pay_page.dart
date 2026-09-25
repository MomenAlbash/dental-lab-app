import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/ui/widgets/stage_earnings_tab.dart';
import 'package:dental_lab_app/features/stage_pay/ui/widgets/stage_rates_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Stage-based pay: the price of each production stage, and what finishing
/// them earned. Reached from payroll, where stage pay ends up on a payslip.
class StagePayPage extends StatelessWidget {
  const StagePayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(PermissionName.payroll);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<StageRatesCubit>()..load()),
        BlocProvider(create: (_) => getIt<StageEarningsCubit>()..init()),
      ],
      child: DefaultTabController(
        length: 2,
        child: GlassScaffold(
          appBar: GlassAppBar(
            title: Text(
              'أجور المراحل',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            bottom: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: glass.onGlassMuted,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'أسعار المراحل'),
                Tab(text: 'المستحقات'),
              ],
            ),
          ),
          body: SafeArea(
            child: TabBarView(
              children: [
                StageRatesTab(canEdit: canEdit),
                const StageEarningsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

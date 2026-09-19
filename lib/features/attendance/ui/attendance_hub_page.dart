import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/holidays/holidays_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/leaves/leaves_cubit.dart';
import 'package:dental_lab_app/features/attendance/ui/widgets/daily_attendance_tab.dart';
import 'package:dental_lab_app/features/attendance/ui/widgets/holidays_tab.dart';
import 'package:dental_lab_app/features/attendance/ui/widgets/leaves_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Attendance: the day, the leaves that excuse parts of it, and the holidays
/// that excuse all of it.
///
/// One screen with three tabs rather than three drawer rows — they are the
/// same question asked at three scales, and a user checking why someone was
/// marked absent moves between them constantly.
///
/// Shifts and payroll live on their own screens: those are configuration and
/// money, not "who was here today".
class AttendanceHubPage extends StatelessWidget {
  const AttendanceHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final permissions = getIt<SessionCubit>().state;

    // Tabs disappear rather than sitting disabled when the user holds nothing
    // for them — the same rule the drawer follows.
    final canReadAttendance = permissions.canRead(PermissionName.attendance);
    final canReadLeaves =
        permissions.canRead(PermissionName.leaves) || canReadAttendance;

    final tabs = <({String label, Widget view})>[
      if (canReadAttendance)
        (label: 'اليومي', view: const DailyAttendanceTab()),
      if (canReadLeaves) (label: 'الإجازات', view: const LeavesTab()),
      if (canReadAttendance) (label: 'العطل', view: const HolidaysTab()),
    ];

    if (tabs.isEmpty) {
      return GlassScaffold(
        drawer: const AppDrawerWidget(currentRoute: Routes.attendanceHubScreen),
        appBar: GlassAppBar(
          title: Text(
            'الحضور',
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'لا تملك صلاحية عرض الحضور',
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DailyAttendanceCubit>()..load()),
        BlocProvider(create: (_) => getIt<LeavesCubit>()..load()),
        BlocProvider(create: (_) => getIt<HolidaysCubit>()..load()),
      ],
      child: DefaultTabController(
        length: tabs.length,
        child: GlassScaffold(
          drawer: const AppDrawerWidget(
            currentRoute: Routes.attendanceHubScreen,
          ),
          appBar: GlassAppBar(
            title: Text(
              'الحضور',
              style: AppTextStyles.font18MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
            bottom: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: glass.onGlassMuted,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: [for (final tab in tabs) Tab(text: tab.label)],
            ),
          ),
          body: SafeArea(
            child: TabBarView(children: [for (final tab in tabs) tab.view]),
          ),
        ),
      ),
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_cubit.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The home tab: the laboratory's dashboard.
class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardCubit>()..loadEssentials(),
      child: const DashboardBody(),
    );
  }
}

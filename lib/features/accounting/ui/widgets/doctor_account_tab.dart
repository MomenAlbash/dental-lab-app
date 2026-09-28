import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/features/accounting/logic/doctor_statement/doctor_statement_cubit.dart';
import 'package:dental_lab_app/features/accounting/ui/doctor_statement_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// A doctor's account on their own page — the statement the accounting
/// section shows, without going there and picking the doctor again.
///
/// Its own cubit, created when the tab is first opened.
class DoctorAccountTab extends StatelessWidget {
  const DoctorAccountTab({super.key, required this.doctorId});

  final String doctorId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DoctorStatementCubit>()..getStatement(doctorId),
      child: Builder(
        builder: (context) => RefreshIndicator(
          onRefresh: () =>
              context.read<DoctorStatementCubit>().getStatement(doctorId),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.screen),
            children: const [DoctorStatementView()],
          ),
        ),
      ),
    );
  }
}

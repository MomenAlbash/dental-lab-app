import 'dart:async';

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_filters_sheet.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patients_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PatientsListPage extends StatelessWidget {
  const PatientsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PatientsCubit>()..getPatients(),
      child: const _PatientsListView(),
    );
  }
}

class _PatientsListView extends StatefulWidget {
  const _PatientsListView();

  @override
  State<_PatientsListView> createState() => _PatientsListViewState();
}

class _PatientsListViewState extends State<_PatientsListView> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<PatientsCubit>().getPatients(search: value.trim());
    });
  }

  Future<void> _addPatient() async {
    final created = await context.push<bool>(Routes.patientFormScreen);
    if (created == true && mounted) {
      context.read<PatientsCubit>().getPatients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.patientsListScreen),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPatient,
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      appBar: AppBar(
        title: Text('المرضى', style: AppTextStyles.font18MediumText),
        actions: [
          BlocBuilder<PatientsCubit, PatientsState>(
            builder: (context, state) {
              final activeCount = context.read<PatientsCubit>().filters.activeCount;
              return IconButton(
                onPressed: () => openPatientFiltersSheet(context),
                icon: Badge(
                  label: Text('$activeCount'),
                  isLabelVisible: activeCount > 0,
                  child: const Icon(Icons.filter_list),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث عن مريض بالاسم',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColorsManger.moreLightGray,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const Expanded(child: PatientsListBody()),
          ],
        ),
      ),
    );
  }
}

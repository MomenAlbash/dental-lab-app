import 'dart:async';

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_filter_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_state.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_filters_sheet.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patients_list_body.dart'
    show PatientCaseFilter, PatientCaseFilterStrip, PatientsListBody;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  final _scrollController = ScrollController();
  Timer? _debounce;
  bool _addButtonExtended = true;
  String _searchQuery = '';
  PatientCaseFilter _caseFilter = PatientCaseFilter.all;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Drives the clear (x) button; the debounced fetch itself is separate.
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldExtend = _scrollController.offset < 40;
    if (shouldExtend == _addButtonExtended) return;
    setState(() => _addButtonExtended = shouldExtend);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
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
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.patientsListScreen),
      appBar: GlassAppBar(
        title: Text(
          'المرضى',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          BlocBuilder<PatientsCubit, PatientsState>(
            builder: (context, state) {
              final activeCount = context
                  .read<PatientsCubit>()
                  .filters
                  .activeCount;
              return GlassFilterButton(
                activeCount: activeCount,
                onPressed: () => openPatientFiltersSheet(context),
              );
            },
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'إضافة مريض',
            isExtended: _addButtonExtended,
            onPressed: _addPatient,
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Strip above search, matching the doctors screen's layout: the
            // filter is the first thing the user sees, the search field
            // right under it.
            Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.xs,
                  ),
                  child: Column(
                    children: [
                      PatientCaseFilterStrip(
                        selected: _caseFilter,
                        onSelected: (value) =>
                            setState(() => _caseFilter = value),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextFormField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        hintText: 'ابحث عن مريض بالاسم',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح البحث',
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: glass.onGlassMuted,
                                ),
                              ),
                        validator: (_) => null,
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: AppMotion.base)
                .slideY(
                  begin: -0.12,
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                ),
            Expanded(
              child: PatientsListBody(
                caseFilter: _caseFilter,
                scrollController: _scrollController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

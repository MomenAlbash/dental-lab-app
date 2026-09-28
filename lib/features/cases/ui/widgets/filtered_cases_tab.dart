import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/laboratory_scope.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/laboratory_picker_dialog.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/cases_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// One record's cases — the ordinary cases list (phase tabs, date segment,
/// paging, bulk delivery) with [filters] set, plus "add a case" for that
/// record.
///
/// Its own [CasesCubit], created when the tab is first shown: opening a
/// doctor or a patient should not also cost a case search nobody may look at.
class FilteredCasesTab extends StatelessWidget {
  const FilteredCasesTab({
    super.key,
    required this.filters,
    this.formExtra,
    this.laboratoryId,
  });

  final CaseFiltersModel filters;

  /// Handed to the case form so it starts with this record picked — a
  /// `DoctorModel` or a `PatientModel`. Null opens it empty (a clinic: the
  /// form picks a doctor, and the clinic comes with them).
  final Object? formExtra;

  /// The record's own laboratory. A new case belongs there, so with several
  /// laboratories in view the form is pinned to it without asking.
  final String? laboratoryId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CasesCubit>()..applyFilters(filters)),
        BlocProvider(
          create: (_) => getIt<CasePrioritiesCubit>()..getCasePriorities(),
        ),
      ],
      child: _FilteredCasesView(
        formExtra: formExtra,
        laboratoryId: laboratoryId,
      ),
    );
  }
}

class _FilteredCasesView extends StatelessWidget {
  const _FilteredCasesView({this.formExtra, this.laboratoryId});

  final Object? formExtra;
  final String? laboratoryId;

  Future<void> _addCase(BuildContext context) async {
    final cubit = context.read<CasesCubit>();
    Future<bool?> open() =>
        context.push<bool>(Routes.caseFormScreen, extra: formExtra);

    final laboratoryId = this.laboratoryId;
    final created = laboratoryId != null && LaboratoryScope.isMulti
        ? await LaboratoryScope.runPinned(laboratoryId, open)
        : await openInLaboratory(context, open);

    if (created == true && context.mounted) await cubit.getCases();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = getIt<SessionCubit>().state.canEdit(PermissionName.cases);

    return Stack(
      children: [
        const Positioned.fill(child: CasesListBody()),
        if (canAdd)
          PositionedDirectional(
            end: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: SafeArea(
              child: GlassAddButton(
                label: 'إضافة حالة',
                isExtended: true,
                onPressed: () => _addCase(context),
              ),
            ),
          ),
      ],
    );
  }
}

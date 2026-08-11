import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/badge_variant.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// One case as it appears in any collection of cases.
///
/// The phone list and the tablet grid arrange cases differently but show the
/// same card and open it the same way, so that part lives here rather than
/// being written twice and drifting apart.
class CaseCollectionItem extends StatelessWidget {
  const CaseCollectionItem({
    super.key,
    required this.caseItem,
    required this.priorityVariant,
    required this.onDelete,
  });

  final CaseListItemModel caseItem;

  /// The `badgeVariant` of this case's priority, resolved by the collection
  /// from the priorities list — the case row itself only carries the id.
  final String? priorityVariant;

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return CaseListItemWidget(
      caseNumber: caseItem.caseNumber ?? '',
      patientName: caseItem.patientName ?? '',
      doctorName: caseItem.doctorName ?? '',
      stageName: caseItem.caseStatusLabel,
      priorityLabel: caseItem.priorityLabel,
      priorityColor: badgeVariantColor(context, priorityVariant),
      onTap: () async {
        await context.push(Routes.caseDetailScreen, extra: caseItem.id);
        // The detail screen can change a case's stage or delete it, so the
        // list refetches rather than showing what it had before.
        if (context.mounted) context.read<CasesCubit>().getCases();
      },
      onDelete: onDelete,
    );
  }
}

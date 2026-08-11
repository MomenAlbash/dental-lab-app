import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/case_priority_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The case priorities list section with pull-to-refresh.
class CasePrioritiesListView extends StatelessWidget {
  const CasePrioritiesListView({
    super.key,
    required this.priorities,
    required this.onDelete,
    this.scrollController,
  });

  final List<CasePriorityModel> priorities;
  final ValueChanged<CasePriorityModel> onDelete;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveCollection<CasePriorityModel>(
      items: priorities,
      scrollController: scrollController,
      onRefresh: () => context.read<CasePrioritiesCubit>().getCasePriorities(
        includeInactive: true,
      ),
      itemBuilder: (context, priority, _) => CasePriorityListItemWidget(
        priority: priority,
        onEdit: () async {
          await context.push(Routes.casePriorityFormScreen, extra: priority);
          if (context.mounted) {
            context.read<CasePrioritiesCubit>().getCasePriorities(
              includeInactive: true,
            );
          }
        },
        onDelete: () => onDelete(priority),
      ),
    );
  }
}

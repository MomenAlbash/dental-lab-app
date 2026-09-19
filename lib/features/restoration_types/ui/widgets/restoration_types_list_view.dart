import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/restoration_route_editor_page.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/ui/widgets/restoration_type_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The restoration types list section with pull-to-refresh.
class RestorationTypesListView extends StatelessWidget {
  const RestorationTypesListView({
    super.key,
    required this.types,
    required this.onDelete,
    required this.onCopy,
    this.scrollController,
  });

  final List<RestorationTypeModel> types;
  final ValueChanged<RestorationTypeModel> onDelete;
  final ValueChanged<RestorationTypeModel> onCopy;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveCollection<RestorationTypeModel>(
      items: types,
      scrollController: scrollController,
      onRefresh: () =>
          context.read<RestorationTypesCubit>().getRestorationTypes(),
      itemBuilder: (context, type, _) => RestorationTypeListItemWidget(
        name: type.displayName,
        priceLabel: type.catalogPriceLabel,
        isActive: type.isActive,
        stagesCount: type.stages.length,
        onTap: () => context.push(
          Routes.restorationRouteEditorScreen,
          extra: RestorationRouteEditorArgs(
            restorationTypeId: type.id,
            restorationTypeName: type.displayName,
          ),
        ),
        onEdit: () async {
          await context.push(Routes.restorationTypeFormScreen, extra: type);
          if (context.mounted) {
            context.read<RestorationTypesCubit>().getRestorationTypes();
          }
        },
        onDelete: () => onDelete(type),
        onCopy: () => onCopy(type),
      ),
    );
  }
}

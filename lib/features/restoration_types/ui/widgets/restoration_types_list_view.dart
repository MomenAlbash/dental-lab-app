import 'package:dental_lab_app/core/router/routes.dart';
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
  });

  final List<RestorationTypeModel> types;
  final ValueChanged<RestorationTypeModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 700.0 : constraints.maxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: contentWidth),
            child: RefreshIndicator(
              onRefresh: () =>
                  context.read<RestorationTypesCubit>().getRestorationTypes(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                itemCount: types.length,
                itemBuilder: (context, index) {
                  final type = types[index];
                  return RestorationTypeListItemWidget(
                    name: type.displayName,
                    defaultPrice: type.defaultPrice,
                    isActive: type.isActive,
                    stagesCount: type.stages.length,
                    onEdit: () async {
                      await context.push(
                        Routes.restorationTypeFormScreen,
                        extra: type,
                      );
                      if (context.mounted) {
                        context
                            .read<RestorationTypesCubit>()
                            .getRestorationTypes();
                      }
                    },
                    onDelete: () => onDelete(type),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/ui/widgets/price_tier_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The price tiers list section with pull-to-refresh.
class PriceTiersListView extends StatelessWidget {
  const PriceTiersListView({
    super.key,
    required this.tiers,
    required this.onDelete,
  });

  final List<PriceTierModel> tiers;
  final ValueChanged<PriceTierModel> onDelete;

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
                  context.read<PriceTiersCubit>().getPriceTiers(),
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 16,
                  vertical: 16,
                ),
                itemCount: tiers.length,
                itemBuilder: (context, index) {
                  final tier = tiers[index];
                  return PriceTierListItemWidget(
                    name: tier.name ?? '—',
                    description: tier.description,
                    isActive: tier.isActive,
                    pricedRestorationCount: tier.pricedRestorationCount,
                    totalRestorationTypeCount: tier.totalRestorationTypeCount,
                    onEdit: () async {
                      await context.push(
                        Routes.priceTierFormScreen,
                        extra: tier,
                      );
                      if (context.mounted) {
                        context.read<PriceTiersCubit>().getPriceTiers();
                      }
                    },
                    onEditPrices: () async {
                      await context.push(
                        Routes.priceTierPricesScreen,
                        extra: tier,
                      );
                      if (context.mounted) {
                        context.read<PriceTiersCubit>().getPriceTiers();
                      }
                    },
                    onDelete: () => onDelete(tier),
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

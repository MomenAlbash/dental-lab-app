import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
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
    this.scrollController,
  });

  final List<PriceTierModel> tiers;
  final ValueChanged<PriceTierModel> onDelete;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return AdaptiveCollection<PriceTierModel>(
      items: tiers,
      scrollController: scrollController,
      onRefresh: () => context.read<PriceTiersCubit>().getPriceTiers(),
      // Taller than the default card: this one carries a description line and
      // a pricing-progress row on top of the usual name and badges.
      cardHeight: 156,
      itemBuilder: (context, tier, _) => PriceTierListItemWidget(
        name: tier.name ?? '—',
        description: tier.description,
        isActive: tier.isActive,
        pricedRestorationCount: tier.pricedRestorationCount,
        totalRestorationTypeCount: tier.totalRestorationTypeCount,
        onTap: () async {
          await context.push(Routes.priceTierDetailsScreen, extra: tier);
          if (context.mounted) {
            context.read<PriceTiersCubit>().getPriceTiers();
          }
        },
        onEdit: () async {
          await context.push(Routes.priceTierFormScreen, extra: tier);
          if (context.mounted) {
            context.read<PriceTiersCubit>().getPriceTiers();
          }
        },
        onEditPrices: () async {
          await context.push(Routes.priceTierPricesScreen, extra: tier);
          if (context.mounted) {
            context.read<PriceTiersCubit>().getPriceTiers();
          }
        },
        onDelete: () => onDelete(tier),
      ),
    );
  }
}

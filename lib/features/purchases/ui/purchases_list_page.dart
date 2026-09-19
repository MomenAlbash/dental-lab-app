import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/purchases/data/models/purchase_model.dart';
import 'package:dental_lab_app/features/purchases/logic/purchases/purchases_cubit.dart';
import 'package:dental_lab_app/features/purchases/logic/purchases/purchases_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Inventory purchases (`GET /Purchases`) — every time the lab bought stock
/// from a supplier. Read-only history: a purchase is recorded and never
/// edited or deleted, since it already moved real stock the moment it landed.
class PurchasesListPage extends StatelessWidget {
  const PurchasesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PurchasesCubit>()..getPurchases(),
      child: const _PurchasesListView(),
    );
  }
}

class _PurchasesListView extends StatelessWidget {
  const _PurchasesListView();

  Future<void> _openForm(BuildContext context) async {
    final result = await context.push<PurchaseModel>(Routes.purchaseFormScreen);
    if (result != null && context.mounted) {
      context.read<PurchasesCubit>().getPurchases();
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.inventory,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.purchasesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'مشتريات المخزون',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: canEdit
          ? GlassAddButton(
              label: 'تسجيل شراء',
              isExtended: true,
              onPressed: () => _openForm(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            )
          : null,
      body: SafeArea(
        child: BlocBuilder<PurchasesCubit, PurchasesState>(
          builder: (context, state) {
            return switch (state) {
              PurchasesLoaded(:final purchases) =>
                purchases.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<PurchaseModel>(
                        items: purchases,
                        cardHeight: 104,
                        onRefresh: () =>
                            context.read<PurchasesCubit>().getPurchases(),
                        itemBuilder: (context, purchase, _) =>
                            _PurchaseListItem(purchase: purchase),
                      ),
              PurchasesError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا توجد مشتريات بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'سجّل أول عملية شراء بالضغط على الزر',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

class _PurchaseListItem extends StatelessWidget {
  const _PurchaseListItem({required this.purchase});

  final PurchaseModel purchase;

  static String _date(DateTime? date) {
    if (date == null) return '؟';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;
    final amountLabel = purchase.currency == null
        ? purchase.amount.toStringAsFixed(2)
        : purchase.currency!.format(purchase.amount);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                purchase.inventoryItemName ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                [
                                  purchase.supplierName ?? '—',
                                  _date(purchase.purchaseDate),
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              amountLabel,
                              style: AppTextStyles.font14MediumText.copyWith(
                                color: glass.onGlass,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${purchase.quantity.toStringAsFixed(2)} ${purchase.inventoryItemUnit ?? ''}',
                              style: AppTextStyles.font12RegularHint.copyWith(
                                color: glass.onGlassMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

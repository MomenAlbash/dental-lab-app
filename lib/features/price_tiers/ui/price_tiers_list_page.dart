import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_state.dart';
import 'package:dental_lab_app/features/price_tiers/ui/widgets/price_tiers_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class PriceTiersListPage extends StatelessWidget {
  const PriceTiersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PriceTiersCubit>()..getPriceTiers(),
      child: const _PriceTiersListView(),
    );
  }
}

class _PriceTiersListView extends StatefulWidget {
  const _PriceTiersListView();

  @override
  State<_PriceTiersListView> createState() => _PriceTiersListViewState();
}

class _PriceTiersListViewState extends State<_PriceTiersListView> {
  final _scrollController = ScrollController();

  /// Last successfully loaded tiers, kept so a refresh can show the existing
  /// rows instead of replacing them with the loading skeleton.
  List<PriceTierModel>? _lastTiers;

  /// The add button collapses to an icon once the user starts scrolling, so a
  /// wide button never sits on top of the rows they are reading.
  bool _addButtonExtended = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final shouldExtend = _scrollController.offset < 40;
    if (shouldExtend == _addButtonExtended) return;
    setState(() => _addButtonExtended = shouldExtend);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context, PriceTierModel tier) async {
    final cubit = context.read<PriceTiersCubit>();

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الشريحة السعرية',
      message: 'هل أنت متأكد من حذف شريحة "${tier.name ?? '—'}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true) {
      await cubit.deletePriceTier(tier.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.priceTiersListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الشرائح السعرية',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: Builder(
        builder: (context) =>
            GlassAddButton(
              label: 'إضافة شريحة',
              isExtended: _addButtonExtended,
              onPressed: () async {
                await context.push(Routes.priceTierFormScreen);
                if (context.mounted) {
                  context.read<PriceTiersCubit>().getPriceTiers();
                }
              },
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      ),
      body: SafeArea(
        child: BlocConsumer<PriceTiersCubit, PriceTiersState>(
          listener: (context, state) {
            switch (state) {
              case PriceTierDeleted():
                ShowToast(
                  message: 'تم حذف الشريحة السعرية',
                  state: toastState.success,
                );
              case PriceTierDeleteError(:final message):
                ShowToast(message: message, state: toastState.error);
              default:
                break;
            }
          },
          buildWhen: (previous, current) =>
              current is! PriceTierDeleted && current is! PriceTierDeleteError,
          builder: (context, state) {
            if (state is PriceTiersLoaded) _lastTiers = state.tiers;

            final tiers = switch (state) {
              PriceTiersLoaded(:final tiers) => tiers,
              PriceTiersLoading() => _lastTiers,
              _ => null,
            };

            return AnimatedSwitcher(
              duration: AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: switch ((state, tiers)) {
                (_, final List<PriceTierModel> loaded) => _PriceTiersBody(
                  key: const ValueKey('price-tiers-loaded'),
                  tiers: loaded,
                  scrollController: _scrollController,
                  onDelete: (tier) => _confirmDelete(context, tier),
                ),
                (PriceTiersError(:final message), null) => Center(
                  key: const ValueKey('price-tiers-error'),
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
                _ => const Padding(
                  key: ValueKey('price-tiers-loading'),
                  padding: EdgeInsets.only(top: 24),
                  child: GlassListSkeleton(),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

class _PriceTiersBody extends StatelessWidget {
  const _PriceTiersBody({
    super.key,
    required this.tiers,
    required this.onDelete,
    this.scrollController,
  });

  final List<PriceTierModel> tiers;
  final ValueChanged<PriceTierModel> onDelete;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    if (tiers.isEmpty) return _EmptyState();

    return PriceTiersListView(
      tiers: tiers,
      scrollController: scrollController,
      onDelete: onDelete,
    );
  }
}

class _EmptyState extends StatelessWidget {
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
                    Icons.sell_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد شرائح سعرية بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول شريحة بالضغط على زر الإضافة',
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

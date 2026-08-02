import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_state.dart';
import 'package:dental_lab_app/features/price_tiers/ui/widgets/price_tiers_list_view.dart';
import 'package:flutter/material.dart';
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

class _PriceTiersListView extends StatelessWidget {
  const _PriceTiersListView();

  Future<void> _confirmDelete(
    BuildContext context,
    PriceTierModel tier,
  ) async {
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
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(
        currentRoute: Routes.priceTiersListScreen,
      ),
      appBar: AppBar(
        title: Text('الشرائح السعرية', style: AppTextStyles.font18MediumText),
      ),
      floatingActionButton: Builder(
        builder: (context) => FloatingActionButton(
          onPressed: () async {
            await context.push(Routes.priceTierFormScreen);
            if (context.mounted) {
              context.read<PriceTiersCubit>().getPriceTiers();
            }
          },
          backgroundColor: AppColorsManger.primary,
          child: const Icon(Icons.add, color: Colors.white),
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
              current is! PriceTierDeleted &&
              current is! PriceTierDeleteError,
          builder: (context, state) {
            return switch (state) {
              PriceTiersLoaded(:final tiers) =>
                tiers.isEmpty
                    ? Center(
                        child: Text(
                          'لا يوجد شرائح سعرية بعد',
                          style: AppTextStyles.font14RegularSecondary,
                        ),
                      )
                    : PriceTiersListView(
                        tiers: tiers,
                        onDelete: (tier) => _confirmDelete(context, tier),
                      ),
              PriceTiersError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary,
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

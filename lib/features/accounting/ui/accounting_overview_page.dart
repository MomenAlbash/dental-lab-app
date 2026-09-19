import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/features/accounting/data/models/accounting_statistics_model.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/accounting/logic/accounting_statistics/accounting_statistics_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/accounting_statistics/accounting_statistics_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The accounting landing screen — headline counts plus one card per
/// currency (amounts are never summed across currencies).
class AccountingOverviewPage extends StatelessWidget {
  const AccountingOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountingStatisticsCubit>()..getStatistics(),
      child: const _AccountingOverviewView(),
    );
  }
}

class _AccountingOverviewView extends StatelessWidget {
  const _AccountingOverviewView();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.accountingOverviewScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'المحاسبة',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(Routes.invoicesListScreen),
            child: const Text('الفواتير'),
          ),
        ],
      ),
      body: SafeArea(
        child:
            BlocBuilder<AccountingStatisticsCubit, AccountingStatisticsState>(
              builder: (context, state) {
                return switch (state) {
                  AccountingStatisticsLoaded(:final statistics) =>
                    _StatisticsBody(statistics: statistics),
                  AccountingStatisticsError(:final message) => Center(
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
                  _ => const Center(
                    child: CustomCircleProgressIndiacatorWidget(),
                  ),
                };
              },
            ),
      ),
    );
  }
}

class _StatisticsBody extends StatelessWidget {
  const _StatisticsBody({required this.statistics});

  final AccountingStatisticsModel statistics;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        _CountRow(statistics: statistics),
        const SizedBox(height: AppSpacing.sectionGap),
        const GlassSectionTitle('حسب العملة'),
        const SizedBox(height: AppSpacing.sm),
        if (statistics.currencies.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'لا توجد بيانات محاسبية بعد',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: context.glass.onGlassMuted,
                ),
              ),
            ),
          )
        else
          for (final currency in statistics.currencies)
            _CurrencyCard(stats: currency),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.statistics});

  final AccountingStatisticsModel statistics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CountTile(
            icon: Icons.receipt_long_outlined,
            label: 'الفواتير',
            value: statistics.invoiceCount,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CountTile(
            icon: Icons.payments_outlined,
            label: 'الدفعات',
            value: statistics.paymentCount,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _CountTile(
            icon: Icons.hourglass_empty_outlined,
            label: 'بانتظار التحقق',
            value: statistics.pendingPaymentCount,
            color: context.glass.warning,
          ),
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$value',
            style: AppTextStyles.font20BoldText.copyWith(color: glass.onGlass),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font12RegularHint.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyCard extends StatelessWidget {
  const _CurrencyCard({required this.stats});

  final AccountingCurrencyStatisticsModel stats;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final currency = stats.currency;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
        boxShadow: glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currency?.name ?? currency?.code ?? 'عملة غير معروفة',
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AmountRow(
            label: 'الفواتير',
            amount: stats.invoiced,
            currency: currency,
          ),
          _AmountRow(label: 'المدفوع', amount: stats.paid, currency: currency),
          _AmountRow(
            label: 'المتبقي',
            amount: stats.outstanding,
            currency: currency,
            color: stats.outstanding > 0 ? glass.warning : null,
          ),
          _AmountRow(
            label: 'دفعات موثّقة',
            amount: stats.verifiedPayments,
            currency: currency,
          ),
          _AmountRow(
            label: 'دفعات بانتظار التحقق',
            amount: stats.pendingPayments,
            currency: currency,
            color: stats.pendingPayments > 0 ? glass.warning : null,
          ),
          _AmountRow(
            label: 'المصاريف',
            amount: stats.expenses,
            currency: currency,
          ),
          const Divider(height: 20),
          _AmountRow(
            label: 'صافي النقد',
            amount: stats.netCash,
            currency: currency,
            emphasize: true,
            color: stats.netCash >= 0 ? glass.success : glass.error,
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    required this.currency,
    this.color,
    this.emphasize = false,
  });

  final String label;
  final double amount;
  final CurrencyModel? currency;
  final Color? color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final labelStyle = AppTextStyles.font14RegularSecondary.copyWith(
      color: glass.onGlassMuted,
    );
    final valueStyle =
        (emphasize
                ? AppTextStyles.font16MediumText
                : AppTextStyles.font14MediumText)
            .copyWith(color: color ?? glass.onGlass);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: labelStyle),
          const Spacer(),
          Text(
            currency == null
                ? amount.toStringAsFixed(2)
                : currency!.format(amount),
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}

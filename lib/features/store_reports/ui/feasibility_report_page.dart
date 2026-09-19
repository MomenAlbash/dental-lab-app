import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_breakdown_bars.dart';
import 'package:dental_lab_app/features/store_reports/data/models/monthly_feasibility_model.dart';
import 'package:dental_lab_app/features/store_reports/logic/feasibility/feasibility_cubit.dart';
import 'package:dental_lab_app/features/store_reports/logic/feasibility/feasibility_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// الجدوى الاقتصادية الشهرية (`GET /store/feasibility`) — revenue, cost and
/// the running cash position, one series per currency since money in
/// different currencies can never be netted into one number.
class FeasibilityReportPage extends StatelessWidget {
  const FeasibilityReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeasibilityCubit>()..load(),
      child: const _FeasibilityReportView(),
    );
  }
}

class _FeasibilityReportView extends StatefulWidget {
  const _FeasibilityReportView();

  @override
  State<_FeasibilityReportView> createState() => _FeasibilityReportViewState();
}

class _FeasibilityReportViewState extends State<_FeasibilityReportView> {
  /// Which currency's series is showing. Reset whenever the list reloads
  /// with a different shape, since an old index could point past the end.
  int _currencyIndex = 0;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(
        currentRoute: Routes.feasibilityReportScreen,
      ),
      appBar: GlassAppBar(
        title: Text(
          'الجدوى الاقتصادية',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<FeasibilityCubit, FeasibilityState>(
          builder: (context, state) {
            return switch (state) {
              FeasibilityLoaded(:final feasibility, :final months) =>
                _ReportBody(
                  feasibility: feasibility,
                  months: months,
                  currencyIndex: _currencyIndex,
                  onCurrencyChanged: (index) =>
                      setState(() => _currencyIndex = index),
                  onMonthsChanged: (value) =>
                      context.read<FeasibilityCubit>().load(months: value),
                ),
              FeasibilityError(:final message) => Center(
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

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.feasibility,
    required this.months,
    required this.currencyIndex,
    required this.onCurrencyChanged,
    required this.onMonthsChanged,
  });

  final MonthlyFeasibilityModel feasibility;
  final int months;
  final int currencyIndex;
  final ValueChanged<int> onCurrencyChanged;
  final ValueChanged<int> onMonthsChanged;

  static const _monthOptions = [3, 6, 12, 24];

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final series = feasibility.currencies;

    if (series.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'لا توجد بيانات كافية بعد لحساب الجدوى الاقتصادية',
            textAlign: TextAlign.center,
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ),
      );
    }

    final selectedIndex = currencyIndex < series.length ? currencyIndex : 0;
    final selected = series[selectedIndex];
    // Newest first for the list; the API's own order is assumed
    // chronological but not guaranteed, so this is sorted defensively rather
    // than trusted blindly.
    final points = [...selected.points]
      ..sort((a, b) {
        final aMonth = a.month;
        final bMonth = b.month;
        if (aMonth == null || bMonth == null) return 0;
        return bMonth.compareTo(aMonth);
      });
    final latest = points.firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screen),
      children: [
        SegmentedButton<int>(
          segments: [
            for (final option in _monthOptions)
              ButtonSegment(value: option, label: Text('$option شهر')),
          ],
          selected: {months},
          showSelectedIcon: false,
          onSelectionChanged: (s) => onMonthsChanged(s.first),
        ),
        if (series.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            children: [
              for (var i = 0; i < series.length; i++)
                ChoiceChip(
                  label: Text(
                    series[i].currency?.name ?? series[i].currency?.code ?? '—',
                  ),
                  selected: selectedIndex == i,
                  onSelected: (_) => onCurrencyChanged(i),
                ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (latest == null)
          Text(
            'لا توجد بيانات لهذه العملة بعد',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          )
        else ...[
          _CashPositionCard(point: latest, currency: selected.currency),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: glass.surfaceGradient,
              border: Border.all(color: glass.strokeColor),
              borderRadius: BorderRadius.circular(AppRadius.glass),
            ),
            child: DashboardBreakdownBars(
              bars: [
                BreakdownBar(
                  label: 'الإيرادات',
                  value: latest.revenue,
                  color: glass.success,
                  valueLabel: _formatAmount(selected.currency, latest.revenue),
                ),
                BreakdownBar(
                  label: 'المصاريف',
                  value: latest.expenses,
                  color: glass.error,
                  valueLabel: _formatAmount(selected.currency, latest.expenses),
                ),
                BreakdownBar(
                  label: 'المشتريات',
                  value: latest.purchases,
                  color: glass.warning,
                  valueLabel: _formatAmount(
                    selected.currency,
                    latest.purchases,
                  ),
                ),
                BreakdownBar(
                  label: 'الرواتب',
                  value: latest.payrollCost,
                  color: glass.info,
                  valueLabel: _formatAmount(
                    selected.currency,
                    latest.payrollCost,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('السجل الشهري', style: AppTextStyles.font16MediumText),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < points.length; i++) ...[
            _MonthRow(point: points[i], currency: selected.currency),
            if (i != points.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

String _formatAmount(CurrencyModel? currency, double value) {
  if (currency == null) return value.toStringAsFixed(0);
  return currency.format(value);
}

class _CashPositionCard extends StatelessWidget {
  const _CashPositionCard({required this.point, required this.currency});

  final MonthlyFeasibilityPointModel point;
  final CurrencyModel? currency;

  static String _monthLabel(DateTime? month) {
    if (month == null) return '؟';
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isPositive = point.cumulativeCash >= 0;
    final color = isPositive ? glass.success : glass.error;
    final amount = _formatAmount(currency, point.cumulativeCash);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_outlined
                    : Icons.trending_down_outlined,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                'الصندوق حتى ${_monthLabel(point.month)}',
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: AppTextStyles.font24BoldText.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({required this.point, required this.currency});

  final MonthlyFeasibilityPointModel point;
  final CurrencyModel? currency;

  static String _monthLabel(DateTime? month) {
    if (month == null) return '؟';
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isPositive = point.netProfit >= 0;
    final color = isPositive ? glass.success : glass.error;
    final netProfitLabel = _formatAmount(currency, point.netProfit);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.surfaceColor,
        border: Border.all(color: glass.strokeColor),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _monthLabel(point.month),
              style: AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
          Text(
            netProfitLabel,
            style: AppTextStyles.font14MediumText.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

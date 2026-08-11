import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/currencies/ui/widgets/currency_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Currencies list screen — design only for now (no Cubit / API wiring
/// yet). Every restoration type's cost is priced in one of these
/// currencies, so they must be defined first, per `/api/clinic/Currencies`.
class CurrenciesListPage extends StatefulWidget {
  const CurrenciesListPage({super.key});

  @override
  State<CurrenciesListPage> createState() => _CurrenciesListPageState();
}

class _CurrenciesListPageState extends State<CurrenciesListPage> {
  // Placeholder data until the currencies Cubit/repository are wired in.
  final List<Map<String, dynamic>> _currencies = [
    {'name': 'ليرة سورية', 'code': 'SYP', 'symbol': 'ل.س'},
    {'name': 'دولار أمريكي', 'code': 'USD', 'symbol': r'$'},
    {'name': 'يورو', 'code': 'EUR', 'symbol': '€'},
  ];

  Future<void> _confirmDelete(Map<String, dynamic> currency) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف العملة',
      message: 'هل أنت متأكد من حذف عملة "${currency['name']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _currencies.remove(currency));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.currenciesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'العملات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'إضافة عملة',
            isExtended: true,
            onPressed: () => context.push(Routes.currencyFormScreen),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
      body: SafeArea(
        child: _currencies.isEmpty
            ? _EmptyState()
            : AdaptiveCollection<Map<String, dynamic>>(
                items: _currencies,
                itemBuilder: (context, currency, _) => CurrencyListItemWidget(
                  name: currency['name'] as String,
                  code: currency['code'] as String,
                  symbol: currency['symbol'] as String,
                  onTap: () => context.push(
                    Routes.currencyDetailScreen,
                    extra: currency,
                  ),
                  onEdit: () =>
                      context.push(Routes.currencyFormScreen, extra: currency),
                  onDelete: () => _confirmDelete(currency),
                ),
              ),
      ),
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
                    Icons.attach_money_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد عملات بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول عملة بالضغط على زر الإضافة',
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

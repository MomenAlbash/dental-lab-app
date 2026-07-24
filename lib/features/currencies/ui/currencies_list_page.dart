import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/currencies/ui/widgets/currency_list_item_widget.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.currenciesListScreen),
      appBar: AppBar(title: Text('العملات', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.currencyFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;

            if (_currencies.isEmpty) {
              return Center(
                child: Text('لا يوجد عملات بعد', style: AppTextStyles.font14RegularSecondary),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 16,
                  ),
                  itemCount: _currencies.length,
                  itemBuilder: (context, index) {
                    final currency = _currencies[index];
                    return CurrencyListItemWidget(
                      name: currency['name'] as String,
                      code: currency['code'] as String,
                      symbol: currency['symbol'] as String,
                      onTap: () =>
                          context.push(Routes.currencyDetailScreen, extra: currency),
                      onEdit: () => context.push(Routes.currencyFormScreen, extra: currency),
                      onDelete: () => _confirmDelete(currency),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Currency detail screen — design only for now (no Cubit / API wiring
/// yet). Mirrors `CurrencyDto`: name, code, symbol.
class CurrencyDetailPage extends StatelessWidget {
  const CurrencyDetailPage({super.key, required this.currency});

  final Map<String, dynamic> currency;

  @override
  Widget build(BuildContext context) {
    final symbol = currency['symbol'] as String? ?? '';
    final code = currency['code'] as String;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'تفاصيل العملة',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                context.push(Routes.currencyFormScreen, extra: currency),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 560.0 : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: context.glass.brandGradient,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                symbol.isEmpty ? code : symbol,
                                style: AppTextStyles.font24BoldText.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              currency['name'] as String,
                              style: AppTextStyles.font20BoldText.copyWith(
                                color: context.glass.onGlass,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        decoration: BoxDecoration(
                          gradient: context.glass.surfaceGradient,
                          borderRadius: BorderRadius.circular(AppRadius.glass),
                          border: Border.all(color: context.glass.strokeColor),
                          boxShadow: context.glass.shadows,
                        ),
                        child: Column(
                          children: [
                            DetailInfoRowWidget(
                              icon: Icons.tag_outlined,
                              label: 'الرمز الدولي (الكود)',
                              value: code,
                            ),
                            Divider(
                              height: 1,
                              color: context.glass.strokeColor,
                            ),
                            DetailInfoRowWidget(
                              icon: Icons.currency_exchange_outlined,
                              label: 'رمز العملة',
                              value: symbol,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

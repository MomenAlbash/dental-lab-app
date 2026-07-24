import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// "مختبري" — the admin's own default laboratory context, per
/// `GET /api/clinic/Laboratories/own` (`ClinicLaboratoryDto`). An admin can
/// still create and operate other laboratories (see the Laboratories list),
/// but this is the one they're scoped to by default. Design only for now —
/// no Cubit / API wiring yet.
class MyLaboratoryPage extends StatelessWidget {
  const MyLaboratoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder data until the laboratories Cubit/repository are wired in.
    final myLaboratory = {
      'name': 'مخبر الابتسامة الذهبية',
      'address': 'المزة، دمشق',
      'phoneNumber': '0112223344',
    };

    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.myLaboratoryScreen),
      appBar: AppBar(
        title: Text('مختبري', style: AppTextStyles.font18MediumText),
        actions: [
          IconButton(
            onPressed: () =>
                context.push(Routes.laboratoryFormScreen, extra: myLaboratory),
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
                              decoration: const BoxDecoration(
                                color: AppColorsManger.primarySurface,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.science_outlined,
                                size: 36,
                                color: AppColorsManger.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              myLaboratory['name']!,
                              style: AppTextStyles.font20BoldText,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'المخبر الافتراضي لحسابك',
                              style: AppTextStyles.font13MediumPrimary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColorsManger.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColorsManger.border),
                        ),
                        child: Column(
                          children: [
                            DetailInfoRowWidget(
                              icon: Icons.location_on_outlined,
                              label: 'العنوان',
                              value: myLaboratory['address'] ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.phone_outlined,
                              label: 'رقم الهاتف',
                              value: myLaboratory['phoneNumber'] ?? '',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColorsManger.primarySurface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: AppColorsManger.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'يمكنك إنشاء مخبر آخر والتعامل مع النظام كمخبر مختلف من صفحة المخابر.',
                                style: AppTextStyles.font13MediumPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () => context.push(Routes.laboratoriesListScreen),
                        icon: const Icon(Icons.science_outlined),
                        label: const Text('عرض جميع المخابر'),
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

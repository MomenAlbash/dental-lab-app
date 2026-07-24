import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Clinic detail screen — design only for now (no Cubit / API wiring yet).
/// Mirrors `ClinicDto`: contact info, city, price tier (with its own
/// active flag), and the doctor/patient counts.
class ClinicDetailPage extends StatelessWidget {
  const ClinicDetailPage({super.key, required this.clinic});

  final Map<String, dynamic> clinic;

  @override
  Widget build(BuildContext context) {
    final isActive = clinic['isActive'] as bool;
    final priceTierName = clinic['priceTierName'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('تفاصيل العيادة', style: AppTextStyles.font18MediumText),
        actions: [
          IconButton(
            onPressed: () => context.push(Routes.clinicFormScreen, extra: clinic),
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
                                Icons.local_hospital_outlined,
                                size: 36,
                                color: AppColorsManger.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              clinic['name'] as String,
                              style: AppTextStyles.font20BoldText,
                            ),
                            const SizedBox(height: 4),
                            _StatusBadge(isActive: isActive),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.medical_services_outlined,
                              label: 'الأطباء',
                              value: '${clinic['doctorCount']}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.people_outline,
                              label: 'المرضى',
                              value: '${clinic['patientCount'] ?? 0}',
                            ),
                          ),
                        ],
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
                              value: clinic['address'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.phone_outlined,
                              label: 'رقم الهاتف',
                              value: clinic['phoneNumber'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.email_outlined,
                              label: 'البريد الإلكتروني',
                              value: clinic['email'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.location_city_outlined,
                              label: 'المدينة',
                              value: clinic['cityName'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.sell_outlined,
                              label: 'فئة التسعير',
                              value: priceTierName,
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColorsManger.success : AppColorsManger.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'مفعّلة' : 'موقوفة',
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorsManger.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColorsManger.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColorsManger.primary),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.font20BoldText),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.font12RegularHint),
        ],
      ),
    );
  }
}

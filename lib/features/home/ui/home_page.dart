import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The home dashboard content (no Scaffold — [MainShellPage] supplies it).
class HomeBody extends StatelessWidget {
  const HomeBody({super.key});

  @override
  Widget build(BuildContext context) {
    final laboratoryName =
        CacheHelper.getData(key: CacheKeys.laboratoryName) as String?;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 560.0 : constraints.maxWidth;

        return Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 32 : 20,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: context.glass.accentSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'مرحباً بك',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font24BoldText,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    (laboratoryName == null || laboratoryName.isEmpty)
                        ? 'تم تسجيل الدخول بنجاح'
                        : 'أنت تعمل الآن على: $laboratoryName',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: context.glass.onGlassMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.folder_outlined,
                          label: 'الحالات',
                          onTap: () => context.push(Routes.casesListScreen),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.add_circle_outline,
                          label: 'إضافة حالة',
                          onTap: () => context.push(Routes.caseFormScreen),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.glass.accentSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'هذه شاشة مبدئية — سيتم بناء محتوى لوحة التحكم لاحقاً. استخدم القائمة الجانبية للتنقل بين الميزات.',
                            style: AppTextStyles.font13MediumPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        context.push(Routes.laboratorySelectionScreen),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('تغيير المخبر'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Container(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 12,
                ),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.font14MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

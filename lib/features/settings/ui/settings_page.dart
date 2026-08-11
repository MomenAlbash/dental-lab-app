import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/font_scale_cubit.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Reference data the lab sets up once and rarely touches again.
///
/// These used to sit in the drawer next to the daily work, where they cost a
/// row each and made the list long enough to scroll. Behind one entry they are
/// still two taps away, and the drawer stays about what the user does every
/// day.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final entries = <_SettingsEntry>[
      _SettingsEntry(
        icon: Icons.attach_money_outlined,
        label: 'العملات',
        description: 'العملات المستخدمة في التسعير',
        route: Routes.currenciesListScreen,
        color: Theme.of(context).colorScheme.primary,
      ),
      _SettingsEntry(
        icon: Icons.public_outlined,
        label: 'الدول',
        description: 'الدول التي تتبع لها المدن',
        route: Routes.countriesListScreen,
        color: glass.info,
      ),
      _SettingsEntry(
        icon: Icons.location_city_outlined,
        label: 'المدن',
        description: 'المدن المرتبطة بالعيادات والأطباء',
        route: Routes.citiesListScreen,
        color: glass.success,
      ),
    ];

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'الإعدادات',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;
          final contentWidth = isWide ? 560.0 : constraints.maxWidth;
          final horizontal = isWide ? 32.0 : AppSpacing.screen;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.xl,
                  horizontal,
                  AppSpacing.xl,
                ),
                children: [
                  const _SectionTitle('العرض'),
                  const SizedBox(height: AppSpacing.md),
                  const _FontScaleSelector(),
                  const SizedBox(height: AppSpacing.xl),
                  const _SectionTitle('البيانات الأساسية'),
                  const SizedBox(height: AppSpacing.md),
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    _SettingsCard(entry: entries[i])
                        .animate(delay: AppMotion.staggerFor(i))
                        .fadeIn(duration: AppMotion.base)
                        .slideY(
                          begin: 0.08,
                          duration: AppMotion.base,
                          curve: AppMotion.enter,
                        ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Heading above a run of related settings.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font16MediumText.copyWith(
              color: context.glass.onGlass,
            ),
          ),
        ),
      ],
    );
  }
}

/// Picks the app-wide text size.
///
/// Each option is rendered at the size it applies, so the choice is visible
/// before it is made rather than something to try and undo.
class _FontScaleSelector extends StatelessWidget {
  const _FontScaleSelector();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;

    return BlocBuilder<FontScaleCubit, FontScale>(
      builder: (context, current) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            border: Border.all(color: glass.strokeColor),
            boxShadow: glass.shadows,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.format_size, size: 20, color: glass.onGlassMuted),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'حجم الخط',
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  for (final scale in FontScale.values) ...[
                    if (scale != FontScale.values.first)
                      const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _FontScaleOption(
                        scale: scale,
                        isSelected: scale == current,
                        accent: accent,
                        onTap: () =>
                            context.read<FontScaleCubit>().setScale(scale),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'يُطبَّق فوق إعداد الخط في جهازك، ولا يلغيه.',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FontScaleOption extends StatelessWidget {
  const _FontScaleOption({
    required this.scale,
    required this.isSelected,
    required this.accent,
    required this.onTap,
  });

  final FontScale scale;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.md + 2);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? accent.withValues(alpha: 0.14)
                : glass.mutedSurface,
            borderRadius: radius,
            border: Border.all(
              color: isSelected ? accent : glass.strokeColor,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'أ',
                // Sized off the option's own factor rather than the live
                // setting, so the three previews stay different from each
                // other whichever one is active.
                textScaler: TextScaler.noScaling,
                style: AppTextStyles.font16MediumText.copyWith(
                  fontSize: 16 * scale.factor,
                  color: isSelected ? accent : glass.onGlass,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                scale.arabicLabel,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: isSelected ? accent : glass.onGlassMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsEntry {
  const _SettingsEntry({
    required this.icon,
    required this.label,
    required this.description,
    required this.route,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String description;
  final String route;
  final Color color;
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.entry});

  final _SettingsEntry entry;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        // Pushed, not replaced: leaving one of these should come back here.
        onTap: () => context.push(entry.route),
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: radius,
            border: Border.all(color: glass.strokeColor),
            boxShadow: glass.shadows,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.md + 2),
                  color: entry.color.withValues(alpha: 0.14),
                ),
                child: Icon(entry.icon, size: 20, color: entry.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.label,
                      style: AppTextStyles.font16MediumText.copyWith(
                        color: glass.onGlass,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: glass.onGlassMuted),
            ],
          ),
        ),
      ),
    );
  }
}

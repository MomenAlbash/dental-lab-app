import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Placeholder body for a screen that is reachable from navigation but not
/// built yet.
///
/// A shared widget rather than a copy per screen: the tabs that use it are
/// stubs on purpose, and when one is implemented its stub is deleted — nothing
/// should have to be kept in sync in the meantime.
class ComingSoonBody extends StatelessWidget {
  const ComingSoonBody({
    super.key,
    required this.icon,
    required this.title,
    this.footer,
  });

  final IconData icon;

  /// The name of the screen being announced, e.g. `'المواعيد'`.
  final String title;

  /// Optional action kept alive under the message — used where the stub
  /// replaced a screen that carried something the user still needs.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          // Body text stays capped and centred at every width — a message
          // stretched across a tablet is harder to read, not easier.
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: glass.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: glass.primaryDark),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.font24BoldText.copyWith(
                  color: glass.onGlass,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'سوف تُنفَّذ لاحقاً',
                textAlign: TextAlign.center,
                style: AppTextStyles.font14RegularSecondary.copyWith(
                  color: glass.onGlassMuted,
                ),
              ),
              if (footer != null) ...[
                const SizedBox(height: AppSpacing.xl),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

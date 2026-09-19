import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_state.dart';
import 'package:flutter/material.dart';

/// Renders one [DashboardSection] through all four of its states.
///
/// Every section of this screen loads and fails on its own, so without this
/// the idle/loading/error/empty handling would be written out eight times —
/// and the eighth copy is where the empty case quietly goes missing.
class DashboardSectionShell<T> extends StatelessWidget {
  const DashboardSectionShell({
    super.key,
    required this.title,
    required this.section,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'لا يوجد شيء لعرضه',
    this.skeletonRows = 3,
    this.trailing,
  });

  final String title;
  final DashboardSection<T> section;

  /// Builds the loaded state. Only called with data.
  final Widget Function(BuildContext context, T value) builder;

  final VoidCallback onRetry;

  /// Whether the loaded value counts as empty. Defaults to treating an empty
  /// [List] as empty; a section whose value is not a list must say so itself.
  final bool Function(T value)? isEmpty;

  final String emptyMessage;

  /// How many placeholder rows to shimmer while loading — set it to roughly
  /// the section's real height so the page does not jump when data lands.
  final int skeletonRows;

  /// Action rendered at the end of the heading row.
  final Widget? trailing;

  bool _valueIsEmpty(T value) {
    final predicate = isEmpty;
    if (predicate != null) return predicate(value);
    return value is List && value.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionTitle(title, trailing: trailing),
        const SizedBox(height: AppSpacing.md),
        switch (section) {
          // Idle looks the same as loading: a deferred section is only idle in
          // the instant before its request goes out, and flashing an empty
          // state in that gap would read as "there is nothing here".
          SectionIdle<T>() ||
          SectionLoading<T>() => _Skeleton(rows: skeletonRows),
          SectionError<T>(:final message) => _SectionError(
            message: message,
            onRetry: onRetry,
          ),
          SectionData<T>(:final value) =>
            _valueIsEmpty(value)
                ? _SectionEmpty(message: emptyMessage)
                : builder(context, value),
        },
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton({required this.rows});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.sm),
          const GlassSkeletonBox(height: 44),
        ],
      ],
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xl,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: glass.mutedSurface,
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyles.font13MediumPrimary.copyWith(
          color: glass.onGlassMuted,
        ),
      ),
    );
  }
}

/// One section's failure, contained to that section — the rest of the
/// dashboard keeps whatever it managed to load.
class _SectionError extends StatelessWidget {
  const _SectionError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: glass.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: glass.error, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.font13MediumPrimary.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('إعادة')),
        ],
      ),
    );
  }
}

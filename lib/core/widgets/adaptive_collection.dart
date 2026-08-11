import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// A pull-to-refresh collection of cards that is a list on a phone and a grid
/// from tablet up.
///
/// Every list screen in the app shows the same thing — a column of glass
/// cards — and every one of them needs the same second shape on a tablet, so
/// the two layouts live here once instead of being written per feature. The
/// card itself is [itemBuilder]'s business; this only decides how many fit
/// across and how they scroll.
class AdaptiveCollection<T> extends StatelessWidget {
  const AdaptiveCollection({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onRefresh,
    this.scrollController,
    this.cardHeight = 132,
    this.maxCardWidth = 460,
    this.bottomPadding = 96,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Runs on pull-to-refresh — usually the cubit's fetch. Omitted by the few
  /// screens whose data is not fetched, which get no pull gesture rather than
  /// one that does nothing.
  final Future<void> Function()? onRefresh;

  /// Owned by the page, which watches it to collapse the add button.
  final ScrollController? scrollController;

  /// The grid needs a row height up front, so cards that are taller than the
  /// default (extra badge rows, a second subtitle) pass their own. Scaled by
  /// the user's text setting at build time, never used raw — a card frozen at
  /// its design height clips itself at larger text sizes.
  final double cardHeight;

  /// Cards stop growing past this and a new column starts instead, so the
  /// same widget goes 2-up on a tablet and 3-up on a desktop window without
  /// anyone counting columns per breakpoint.
  final double maxCardWidth;

  /// Room under the last card for the floating add button.
  final double bottomPadding;

  Widget _item(BuildContext context, int index) {
    return itemBuilder(context, items[index], index)
        .animate(delay: AppMotion.staggerFor(index))
        .fadeIn(duration: AppMotion.base)
        .slideY(begin: 0.08, duration: AppMotion.base, curve: AppMotion.enter);
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout.tabletUp(
      mobileLayout: (context) => _Refreshable(
        onRefresh: onRefresh,
        child: ListView.builder(
          controller: scrollController,
          // Without this a list shorter than the viewport cannot overscroll,
          // so the pull gesture never reaches the RefreshIndicator and
          // refreshing silently does nothing.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: bottomPadding,
          ),
          itemCount: items.length,
          itemBuilder: _item,
        ),
      ),
      tabletLayout: (context) => _Refreshable(
        onRefresh: onRefresh,
        child: GridView.builder(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(
            left: AppSpacing.xl,
            right: AppSpacing.xl,
            bottom: bottomPadding,
          ),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxCardWidth,
            mainAxisExtent: MediaQuery.textScalerOf(context).scale(cardHeight),
            crossAxisSpacing: AppSpacing.gridGap,
            // The cards carry their own bottom margin, so the grid does not
            // add a second gap between rows.
            mainAxisSpacing: 0,
          ),
          itemCount: items.length,
          itemBuilder: _item,
        ),
      ),
    );
  }
}

class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.onRefresh, required this.child});

  final Future<void> Function()? onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onRefresh = this.onRefresh;
    if (onRefresh == null) return child;
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}

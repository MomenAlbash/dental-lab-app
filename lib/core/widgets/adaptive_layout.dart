import 'package:flutter/material.dart';

/// The widths the app changes shape at.
///
/// These are layout switches, not styling switches: the design system stays
/// identical across them (see CLAUDE.md Section C.1 — one look on every
/// platform). What changes is how many things fit side by side.
class AppBreakpoints {
  AppBreakpoints._();

  /// Below this the app is a phone: one column, modal drawer, one screen at a
  /// time.
  static const double tablet = 600;

  /// At and above this there is room for a third column or a permanently
  /// visible navigation pane.
  static const double desktop = 900;
}

/// Which of the three shapes the surrounding constraints call for.
enum AdaptiveFormFactor { mobile, tablet, desktop }

/// Picks one of three layouts from the width it is given.
///
/// Tablet is a first-class target, not a stretched phone, so the two layouts
/// are written separately rather than being the same tree with different
/// paddings — a list that becomes a grid, or a page that becomes a
/// list-plus-detail, cannot be expressed by tweaking numbers.
///
/// It measures its own constraints rather than the window, so it composes:
/// an [AdaptiveLayout] placed inside a detail pane sees the pane's width and
/// picks the phone layout, which is the correct answer there.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    required this.mobileLayout,
    required this.tabletLayout,
    required this.desktopLayout,
    super.key,
  });

  /// Convenience for the common case where a screen has nothing extra to do
  /// with the third column: desktop reuses the tablet layout.
  const AdaptiveLayout.tabletUp({
    required this.mobileLayout,
    required WidgetBuilder tabletLayout,
    super.key,
  }) : tabletLayout = tabletLayout,
       desktopLayout = tabletLayout;

  final WidgetBuilder mobileLayout;
  final WidgetBuilder tabletLayout;
  final WidgetBuilder desktopLayout;

  /// The form factor at [width]. Exposed so a widget that already has a
  /// [LayoutBuilder] can branch on the same thresholds instead of hardcoding
  /// 600 and 900 again.
  static AdaptiveFormFactor formFactorFor(double width) {
    if (width < AppBreakpoints.tablet) return AdaptiveFormFactor.mobile;
    if (width < AppBreakpoints.desktop) return AdaptiveFormFactor.tablet;
    return AdaptiveFormFactor.desktop;
  }

  /// The form factor of the nearest enclosing layout box.
  static AdaptiveFormFactor of(BuildContext context) =>
      formFactorFor(MediaQuery.sizeOf(context).width);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return switch (formFactorFor(constraints.maxWidth)) {
          AdaptiveFormFactor.mobile => mobileLayout(context),
          AdaptiveFormFactor.tablet => tabletLayout(context),
          AdaptiveFormFactor.desktop => desktopLayout(context),
        };
      },
    );
  }
}

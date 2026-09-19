import 'dart:ui';

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';

/// One tab in [AppBottomNavBar].
class AppBottomNavDestination {
  const AppBottomNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;

  /// Filled counterpart, shown while the tab is the active one.
  final IconData selectedIcon;

  /// Read by screen readers and shown as the long-press tooltip. The bar itself
  /// is icon-only (see the class doc), so this is the only place the tab is
  /// named.
  final String label;
}

/// The app's floating bottom navigation pill.
///
/// A rounded bar hovering above the page rather than a stock
/// [BottomNavigationBar] docked to the edge: it matches the glass design
/// system, and it lets the primary action — the raised `+` in the middle —
/// break out above the bar, which is the whole point. Creating a case is what
/// this app is for, so that button is deliberately the largest, highest-
/// contrast thing on screen.
///
/// Icon-only by design. Labels under four slots at a large text scale either
/// wrap or clip; the tooltip and the semantics label carry the name instead,
/// so the bar keeps one fixed height at every text setting.
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.onPrimaryAction,
    required this.primaryActionLabel,
  });

  /// Must hold an even number of tabs — the `+` is inserted into the middle,
  /// so an odd count would leave it off-centre.
  final List<AppBottomNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  /// Always shown — hiding it left a visibly unbalanced gap in the middle of
  /// the bar. A caller without permission to act on it should still pass a
  /// callback, just one that explains why instead of proceeding (see
  /// [MainShellPage._addCase]).
  final VoidCallback onPrimaryAction;
  final String primaryActionLabel;

  /// Height of the pill itself, excluding the part of the `+` that rises above
  /// it. Chrome, not layout: it holds a single row of fixed-size icons, so it
  /// does not scale with the viewport.
  static const double barHeight = 64;

  /// Diameter of the raised primary action.
  static const double _primarySize = 58;

  /// How far the `+` sits above the pill's top edge.
  static const double _primaryLift = 14;

  static const double _horizontalMargin = AppSpacing.lg;

  /// Total vertical space the bar occupies, including the raised button and
  /// the gap below the pill. A page hosting the bar must inset its content by
  /// this much plus the system inset, or its last row ends up underneath.
  static const double totalHeight = barHeight + _primaryLift + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    assert(
      destinations.length.isEven,
      'The raised + is placed in the middle, so the tabs must split evenly '
      'either side of it.',
    );

    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.full);
    final half = destinations.length ~/ 2;

    final bar = Container(
      height: barHeight,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass.blurSigma,
            sigmaY: glass.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: glass.surfaceGradient,
              border: Border.all(color: glass.strokeColor),
              borderRadius: radius,
            ),
            // The tabs' ink needs a Material to splash on, and the bar is
            // hosted in a Stack above the page rather than in a Scaffold slot
            // — so there is no Material ancestor to inherit. Transparent, so
            // the glass fill painted just above still shows through.
            child: Material(
              type: MaterialType.transparency,
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++) ...[
                    // The gap the raised + occupies. It is a sibling of the
                    // tabs rather than a Stack overlay so the tabs never sit
                    // under it and lose taps near their inner edge.
                    if (i == half) const SizedBox(width: _primarySize),
                    Expanded(
                      child: _NavItem(
                        destination: destinations[i],
                        isSelected: i == currentIndex,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _horizontalMargin,
        0,
        _horizontalMargin,
        AppSpacing.md,
      ),
      child: SizedBox(
        // Room for the button to overhang the pill without being clipped.
        height: barHeight + _primaryLift,
        child: Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            bar,
            Positioned(
              bottom: barHeight - _primarySize + _primaryLift,
              child: _PrimaryAction(
                label: primaryActionLabel,
                onPressed: onPrimaryAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final AppBottomNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final color = isSelected ? glass.primaryDark : glass.onGlassMuted;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: Tooltip(
        message: destination.label,
        child: InkResponse(
          onTap: onTap,
          radius: 28,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  key: ValueKey(isSelected),
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              // The active tab is marked by a short underline as well as the
              // tint, so selection is not carried by colour alone.
              AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.enter,
                height: 3,
                width: isSelected ? 18 : 0,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised `+`. Same brand gradient and press-scale as `GlassAddButton`,
/// shaped as a circle because it is docked into the bar rather than floating
/// over a list.
class _PrimaryAction extends StatefulWidget {
  const _PrimaryAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_PrimaryAction> createState() => _PrimaryActionState();
}

class _PrimaryActionState extends State<_PrimaryAction> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Semantics(
      button: true,
      label: widget.label,
      child: Tooltip(
        message: widget.label,
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1.0,
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          child: Container(
            width: AppBottomNavBar._primarySize,
            height: AppBottomNavBar._primarySize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glass.glowColor,
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: glass.brandGradient),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onPressed,
                    onTapDown: (_) => _setPressed(true),
                    onTapUp: (_) => _setPressed(false),
                    onTapCancel: () => _setPressed(false),
                    child: const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

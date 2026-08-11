import 'package:flutter/animation.dart';

/// Motion tokens. Every animation in the app reads its duration and curve from
/// here so timing stays consistent and can be tuned in one place — no magic
/// millisecond literals scattered across widgets.
class AppMotion {
  AppMotion._();

  /// Micro-feedback: focus glow, icon tint, press scale.
  static const Duration fast = Duration(milliseconds: 150);

  /// Default: cross-fades, state switches, entrances.
  static const Duration base = Duration(milliseconds: 250);

  /// Deliberate: page transitions, sheet reveals.
  static const Duration slow = Duration(milliseconds: 400);

  /// Delay applied per item in a staggered list entrance.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Maximum number of list items that receive a stagger delay. Beyond this
  /// every item uses the same delay, otherwise long lists would leave the
  /// bottom rows invisible for seconds.
  static const int maxStaggerItems = 10;

  /// Standard easing for entrances and settles.
  static const Curve enter = Curves.easeOutCubic;

  /// Slight overshoot, used sparingly (FAB, selection indicator).
  static const Curve emphasized = Curves.easeOutBack;

  /// Returns the stagger delay for [index], capped at [maxStaggerItems].
  static Duration staggerFor(int index) {
    final capped = index < maxStaggerItems ? index : maxStaggerItems;
    return stagger * capped;
  }
}

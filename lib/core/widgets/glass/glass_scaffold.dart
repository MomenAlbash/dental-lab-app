import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:flutter/material.dart';

/// A [Scaffold] painted over the themed glass backdrop.
///
/// The gradient plus the two soft corner glows are what make translucent panes
/// actually look like glass — over a flat white page they just look grey. The
/// inner [Scaffold] is transparent so the backdrop shows through everywhere,
/// including behind the blurred app bar.
///
/// It also keeps [body] clear of the system navigation bar. From Android 15
/// (`targetSdk` 35+) edge-to-edge is mandatory and cannot be opted out of, so
/// every screen draws underneath the back/home buttons; a page that does not
/// account for the inset ends up with its last section trapped under them.
/// Handling it here rather than per screen means a new page gets it for free
/// — see [applyBottomInset].
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    this.body,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.resizeToAvoidBottomInset,
    this.extendBodyBehindAppBar = false,
    this.applyBottomInset = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool? resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;

  /// Whether [body] is inset above the system navigation bar. Leave it on
  /// unless a screen deliberately paints to the bottom edge — the backdrop
  /// itself always does, since it sits outside the [Scaffold], so the area
  /// behind the buttons keeps its gradient either way.
  ///
  /// Only the bottom edge is taken: the top is left to each screen, because
  /// the detail screens' collapsing headers are meant to run under the status
  /// bar. A screen that already wraps its body in its own [SafeArea] is
  /// unaffected — the inner one finds the padding already consumed.
  final bool applyBottomInset;

  /// Width of the pinned navigation column on tablet and up. Wide enough for
  /// the drawer's rows at a large text scale, narrow enough to leave the page
  /// the majority of the screen.
  static const double _pinnedNavWidth = 280;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    final content = body == null || !applyBottomInset
        ? body
        : SafeArea(top: false, left: false, right: false, child: body!);

    Widget scaffold({Widget? drawer}) => Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      body: content,
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: glass.backdropGradient),
      child: Stack(
        children: [
          Positioned.fill(child: _BackdropGlows(color: glass.backdropGlow)),
          // On a phone the drawer is a modal route reached by the hamburger.
          // From tablet up it is a column that never leaves: there is room for
          // it, and hiding navigation behind a tap on a screen this size is
          // the main thing that makes a tablet build feel like a blown-up
          // phone. Passing `drawer: null` to the Scaffold also drops the
          // hamburger, which would otherwise open a second copy.
          if (drawer == null)
            scaffold()
          else
            AdaptiveLayout.tabletUp(
              mobileLayout: (_) => scaffold(drawer: drawer),
              tabletLayout: (_) => Row(
                children: [
                  SizedBox(
                    width: _pinnedNavWidth,
                    child: _PinnedNav(child: drawer!),
                  ),
                  Expanded(child: scaffold()),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Hosts the drawer as a fixed column.
///
/// [Drawer] expects to sit in a [Scaffold] slot, so it is given its own —
/// transparent, with no body — rather than being unwrapped. That keeps the
/// drawer widget itself identical in both modes instead of forking it.
class _PinnedNav extends StatelessWidget {
  const _PinnedNav({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.transparent, body: child);
  }
}

/// Two large, very soft radial glows. Sized off the shortest side so they scale
/// sensibly from a 360dp phone up to a tablet instead of using fixed pixels.
class _BackdropGlows extends StatelessWidget {
  const _BackdropGlows({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.9;

        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -size * 0.35,
                right: -size * 0.25,
                child: _Glow(size: size, color: color),
              ),
              Positioned(
                bottom: -size * 0.4,
                left: -size * 0.3,
                child: _Glow(size: size * 0.85, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

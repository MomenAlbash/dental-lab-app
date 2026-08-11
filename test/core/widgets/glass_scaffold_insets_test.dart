import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Height of a 3-button Android navigation bar. From Android 15 edge-to-edge
/// is mandatory, so the app paints this area and the buttons sit on top of it.
const double _navigationBar = 48;
const double _screenHeight = 800;

void main() {
  /// Drives the real view rather than an injected MediaQuery, so the padding
  /// reaches the widgets exactly the way the platform delivers it.
  void useAndroidNavigationBar(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, _screenHeight);
    tester.view.padding = const FakeViewPadding(bottom: _navigationBar);
    tester.view.viewPadding = const FakeViewPadding(bottom: _navigationBar);
    addTearDown(tester.view.reset);
  }

  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

  Finder bottomMarker() => find.byKey(const ValueKey('marker'));

  Widget marker() => Align(
    alignment: Alignment.bottomCenter,
    child: Container(
      key: const ValueKey('marker'),
      height: 40,
      color: Colors.red,
    ),
  );

  testWidgets('the body is kept clear of the navigation bar', (tester) async {
    // Regression: detail screens ended with their last section trapped under
    // the back/home buttons.
    useAndroidNavigationBar(tester);

    await tester.pumpWidget(wrap(GlassScaffold(body: marker())));

    expect(
      tester.getRect(bottomMarker()).bottom,
      _screenHeight - _navigationBar,
    );
  });

  testWidgets('the backdrop still paints behind the navigation bar', (
    tester,
  ) async {
    // Insetting the body must not shrink the gradient — the strip behind the
    // buttons should keep its colour instead of going blank.
    useAndroidNavigationBar(tester);

    await tester.pumpWidget(wrap(const GlassScaffold(body: SizedBox())));

    expect(
      tester.getRect(find.byType(DecoratedBox).first).bottom,
      _screenHeight,
    );
  });

  testWidgets('a screen can opt out of the inset', (tester) async {
    useAndroidNavigationBar(tester);

    await tester.pumpWidget(
      wrap(GlassScaffold(applyBottomInset: false, body: marker())),
    );

    expect(tester.getRect(bottomMarker()).bottom, _screenHeight);
  });

  testWidgets('a body with its own SafeArea is not padded twice', (
    tester,
  ) async {
    useAndroidNavigationBar(tester);

    await tester.pumpWidget(
      wrap(GlassScaffold(body: SafeArea(child: marker()))),
    );

    // Exactly one inset: the inner SafeArea finds it already consumed.
    expect(
      tester.getRect(bottomMarker()).bottom,
      _screenHeight - _navigationBar,
    );
  });

  testWidgets('nothing is inset on a device without a navigation bar', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, _screenHeight);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(GlassScaffold(body: marker())));

    expect(tester.getRect(bottomMarker()).bottom, _screenHeight);
  });
}

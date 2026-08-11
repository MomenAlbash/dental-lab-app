import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _page() => MaterialApp(
  theme: AppTheme.light,
  home: const GlassScaffold(
    appBar: GlassAppBar(title: Text('عنوان')),
    drawer: Drawer(child: Text('التنقل')),
    body: Text('المحتوى'),
  ),
);

Future<void> _pumpAt(WidgetTester tester, Size size, Widget app) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a phone hides navigation behind the hamburger', (tester) async {
    await _pumpAt(tester, const Size(360, 800), _page());

    expect(find.text('التنقل'), findsNothing);
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();

    expect(find.text('التنقل'), findsOneWidget);
  });

  testWidgets('a tablet keeps navigation on screen and drops the hamburger', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(834, 1112), _page());

    // Visible without any interaction — this is the change that stops the
    // tablet build reading as a blown-up phone.
    expect(find.text('التنقل'), findsOneWidget);
    // A hamburger here would open a second copy of the same drawer.
    expect(find.byTooltip('Open navigation menu'), findsNothing);
    expect(find.text('المحتوى'), findsOneWidget);
  });

  testWidgets('a page without a drawer is unaffected at tablet width', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      const Size(834, 1112),
      MaterialApp(
        theme: AppTheme.light,
        home: const GlassScaffold(
          appBar: GlassAppBar(title: Text('عنوان')),
          body: Text('المحتوى'),
        ),
      ),
    );

    expect(find.text('المحتوى'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

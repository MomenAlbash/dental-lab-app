import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _sections({bool withSide = true}) => AdaptiveDetailSections(
  main: const [Text('المعلومات'), Text('المرفقات')],
  side: withSide ? const [Text('إجراءات')] : const [],
);

Future<void> _pumpAt(WidgetTester tester, Size size, Widget child) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a phone stacks the sections, actions first', (tester) async {
    await _pumpAt(tester, const Size(360, 900), _sections());

    final actions = tester.getTopLeft(find.text('إجراءات'));
    final info = tester.getTopLeft(find.text('المعلومات'));

    // One column: everything shares a left edge and runs top to bottom.
    expect(actions.dx, info.dx);
    // Something waiting on the user comes before what they came to read.
    expect(actions.dy, lessThan(info.dy));
  });

  testWidgets('a tablet puts the actions beside the information', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 900), _sections());

    final actions = tester.getTopLeft(find.text('إجراءات'));
    final info = tester.getTopLeft(find.text('المعلومات'));

    // Side by side: same top, different columns.
    expect(actions.dy, info.dy);
    expect(actions.dx, isNot(info.dx));
  });

  testWidgets('main sections stay stacked within their own column', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 900), _sections());

    final info = tester.getTopLeft(find.text('المعلومات'));
    final files = tester.getTopLeft(find.text('المرفقات'));

    expect(files.dx, info.dx);
    expect(files.dy, greaterThan(info.dy));
  });

  testWidgets('with no side sections the information keeps the full width', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(1024, 900), _sections(withSide: false));

    final width = tester.getSize(find.byType(AdaptiveDetailSections)).width;
    final infoWidth = tester.getSize(find.text('المعلومات')).width;

    // No empty column reserved beside it: the text lays out across most of
    // the page rather than three fifths of it.
    expect(infoWidth, greaterThan(width * 0.6));
  });
}

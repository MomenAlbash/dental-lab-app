import 'package:dental_lab_app/core/helper/feature_hints.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/features/home/ui/widgets/scanner_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, {required bool introduce}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(actions: [ScannerActionButton(introduce: introduce)]),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
  });

  testWidgets('introduces the scanner the first time', (tester) async {
    await _pump(tester, introduce: true);
    expect(find.text('لاقط الباركود'), findsOneWidget);
  });

  testWidgets('"فهمت" hides the hint and remembers it', (tester) async {
    await _pump(tester, introduce: true);
    await tester.tap(find.text('فهمت'));
    await tester.pump();

    expect(find.text('لاقط الباركود'), findsNothing);
    expect(FeatureHint.barcodeScanner.isSeen, isTrue);
  });

  testWidgets('a hint already seen does not come back', (tester) async {
    await FeatureHint.barcodeScanner.markSeen();
    await _pump(tester, introduce: true);
    expect(find.text('لاقط الباركود'), findsNothing);
  });

  testWidgets('no hint when not asked to introduce (admins)', (tester) async {
    await _pump(tester, introduce: false);
    expect(find.text('لاقط الباركود'), findsNothing);
  });
}

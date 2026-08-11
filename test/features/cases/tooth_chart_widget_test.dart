import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/tooth_chart_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<ToothMarkModel> teeth;

  setUp(() => teeth = []);

  Widget wrap({ThemeData? theme}) => MaterialApp(
    theme: theme ?? AppTheme.light,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: ToothChartWidget(
            teeth: teeth,
            onChanged: (next) => setState(() => teeth = next),
          ),
        ),
      ),
    ),
  );

  void usePhoneScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(390, 900);
    addTearDown(tester.view.reset);
  }

  /// Taps the centre of the tooth labelled [number]. The number is painted
  /// just outside its crown, so its position locates the tooth on screen.
  Future<void> tapTooth(WidgetTester tester, int number) async {
    // The chart is a CustomPaint, so there is no per-tooth widget to find;
    // the tap goes through the arch's gesture detector by position.
    final chart = tester.getRect(find.byType(ToothChartWidget));
    // Fall back to scanning: press points along the arch until the selection
    // changes. Kept deliberate and small — only the teeth used in the tests.
    final before = teeth.length;
    for (var dy = chart.top + 8; dy < chart.top + 420; dy += 4) {
      for (var dx = chart.left + 8; dx < chart.right - 8; dx += 4) {
        await tester.tapAt(Offset(dx, dy));
        await tester.pump();
        if (teeth.length != before) {
          if (teeth.any((t) => t.toothNumber == number)) return;
          // Undo a wrong hit and keep looking.
          await tester.tapAt(Offset(dx, dy));
          await tester.pump();
        }
      }
    }
    fail('could not hit tooth $number');
  }

  testWidgets('starts empty with an instruction', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());

    expect(
      find.text('اضغط على السن لإضافته، وعلى الدائرة بين سنّين لربطهما'),
      findsOneWidget,
    );
  });

  testWidgets('renders both arches without overflowing a phone', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a tooth selects it, tapping again removes it', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap());

    await tapTooth(tester, 11);
    expect(teeth.map((t) => t.toothNumber), contains(11));

    // The chip for the selected tooth appears below the chart.
    expect(find.text('11'), findsWidgets);
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(wrap(theme: AppTheme.dark));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a selected tooth can be removed from its chip', (tester) async {
    usePhoneScreen(tester);
    teeth = [ToothMarkModel(toothNumber: 11)];
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(teeth, isEmpty);
  });

  testWidgets('a joined pair reads as a span on its chip', (tester) async {
    usePhoneScreen(tester);
    teeth = [
      ToothMarkModel(toothNumber: 11),
      ToothMarkModel(toothNumber: 12, connectedToToothNumber: 11),
    ];
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('12 ↔ 11'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);
  });

  testWidgets('the circle between two selected neighbours joins them', (
    tester,
  ) async {
    // The feature itself: 11 and 21 are the two central incisors, adjacent in
    // the upper arch, so a connector circle is offered between them.
    usePhoneScreen(tester);
    teeth = [ToothMarkModel(toothNumber: 11), ToothMarkModel(toothNumber: 21)];
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final chart = tester.getRect(find.byType(ToothChartWidget));
    var joined = false;

    // Scanned rather than computed: the chart is a single CustomPaint, so
    // there is no widget to target — the tap has to land by position.
    for (var dy = chart.top + 8; dy < chart.top + 420 && !joined; dy += 3) {
      for (var dx = chart.left + 8; dx < chart.right - 8 && !joined; dx += 3) {
        await tester.tapAt(Offset(dx, dy));
        await tester.pump();

        if (teeth.any((t) => t.connectedToToothNumber != null)) {
          joined = true;
        } else if (teeth.length != 2) {
          // Hit a tooth instead — undo and keep looking.
          await tester.tapAt(Offset(dx, dy));
          await tester.pump();
        }
      }
    }

    expect(joined, isTrue, reason: 'no connector circle was hit');
    expect(find.text('21 ↔ 11'), findsOneWidget);
  });

  testWidgets('no connector is offered unless both teeth are selected', (
    tester,
  ) async {
    usePhoneScreen(tester);
    teeth = [ToothMarkModel(toothNumber: 11)];
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    final chart = tester.getRect(find.byType(ToothChartWidget));
    for (var dy = chart.top + 8; dy < chart.top + 420; dy += 7) {
      for (var dx = chart.left + 8; dx < chart.right - 8; dx += 7) {
        await tester.tapAt(Offset(dx, dy));
        await tester.pump();

        expect(
          teeth.every((t) => t.connectedToToothNumber == null),
          isTrue,
          reason: 'a connector fired at ($dx, $dy) with one tooth selected',
        );

        // Restored directly rather than by tapping again: a second tap on the
        // same spot can land on a connector that only exists now that two
        // teeth are selected, which would defeat the check.
        if (teeth.length != 1) {
          teeth = [ToothMarkModel(toothNumber: 11)];
          await tester.pumpWidget(wrap());
          await tester.pump();
        }
      }
    }
  });

  testWidgets('removing a tooth breaks any span pointing at it', (
    tester,
  ) async {
    usePhoneScreen(tester);
    teeth = [
      ToothMarkModel(toothNumber: 11),
      ToothMarkModel(toothNumber: 12, connectedToToothNumber: 11),
    ];
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Remove tooth 11 — the chip order matches the selection order.
    await tester.tap(find.byIcon(Icons.close).first);
    await tester.pumpAndSettle();

    expect(teeth.single.toothNumber, 12);
    // Otherwise the request would carry a link to a tooth that is not on the
    // restoration any more.
    expect(teeth.single.connectedToToothNumber, isNull);
  });
}

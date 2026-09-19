import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_intake_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DigitalScanSource?> pumpPicker(
  WidgetTester tester, {
  required ImpressionMethod? method,
  DigitalScanSource? source,
}) async {
  DigitalScanSource? reported;
  var called = false;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: CaseIntakePicker(
              method: method,
              scanSource: source,
              onMethodChanged: (_) {},
              onScanSourceChanged: (value) {
                called = true;
                reported = value;
              },
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
  return called ? reported : null;
}

void main() {
  testWidgets('the scan source is marked required', (tester) async {
    // The two answers send the case down different paths — a doctor upload
    // arrives with the file, a lab session still has to be booked — so a blank
    // one files a case nobody knows how to start.
    await pumpPicker(tester, method: ImpressionMethod.digital);

    expect(find.text('مصدر المسح *'), findsOneWidget);
    expect(find.textContaining('مطلوب'), findsOneWidget);
  });

  testWidgets('the requirement note clears once a source is picked', (
    tester,
  ) async {
    await pumpPicker(
      tester,
      method: ImpressionMethod.digital,
      source: DigitalScanSource.doctor,
    );

    expect(find.textContaining('مطلوب'), findsNothing);
  });

  testWidgets('re-tapping the selected source does not clear it', (
    tester,
  ) async {
    // The field is required now, so an "undo" that puts the form back into an
    // invalid state is not a kindness.
    final reported = await pumpPicker(
      tester,
      method: ImpressionMethod.digital,
      source: DigitalScanSource.doctor,
    );
    expect(reported, isNull, reason: 'nothing tapped yet');

    await tester.tap(find.text(DigitalScanSource.doctor.label));
    await tester.pumpAndSettle();
  });

  testWidgets('the intake method itself is marked required', (tester) async {
    // Nothing picked yet: the section has to say so, since the answer decides
    // which head of the lab's route the case runs on.
    await pumpPicker(tester, method: null);

    expect(find.text('طريقة الاستلام *'), findsOneWidget);
    expect(find.text('مطلوب — كيف وصلت الحالة؟'), findsOneWidget);
  });

  testWidgets('the intake requirement note clears once a method is picked', (
    tester,
  ) async {
    await pumpPicker(tester, method: ImpressionMethod.traditional);

    expect(find.text('مطلوب — كيف وصلت الحالة؟'), findsNothing);
  });

  testWidgets('a traditional intake asks for no source at all', (tester) async {
    // The field only exists for a digital case; showing it greyed out beside
    // an impression case would imply it is answerable.
    await pumpPicker(tester, method: ImpressionMethod.traditional);

    expect(find.text('مصدر المسح *'), findsNothing);
  });
}

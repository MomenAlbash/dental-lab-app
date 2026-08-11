import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_hero_header.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_info_tiles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

PatientModel _patient({String? phone = '0991234567', String? notes}) {
  return PatientModel(
    id: 'p-1',
    firstName: 'خالد',
    lastName: 'العلي',
    gender: PatientGender.male,
    dateOfBirth: '1990-01-01',
    phoneNumber: phone,
    notes: notes,
    caseCount: 4,
    doctor: DoctorModel(id: 'd-1', firstName: 'أحمد', lastName: 'الخطيب'),
    clinic: ClinicModel(id: 'c-1', name: 'عيادة النور'),
  );
}

void main() {
  Widget wrap(Widget slotHeader, {ThemeData? theme}) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            slotHeader,
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: PatientInfoTiles(patient: _patient()),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 800)),
          ],
        ),
      ),
    );
  }

  testWidgets('shows the name exactly once at rest', (tester) async {
    // Regression class: the doctor header once rendered the name twice
    // (panel + collapsed title). This is the same mechanism reused here.
    await tester.pumpWidget(wrap(PatientSliverHeader(patient: _patient())));
    await tester.pumpAndSettle();

    // Only the name is asserted single — the doctor's name legitimately
    // appears twice (header chip + info tile below).
    expect(find.text('خالد العلي'), findsOneWidget);
    expect(find.text('4 حالة'), findsOneWidget);
  });

  testWidgets('collapsing the header does not overflow at any scroll offset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(PatientSliverHeader(patient: _patient())));
    await tester.pumpAndSettle();

    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -25));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('info tiles show doctor, clinic, gender and date of birth', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(PatientSliverHeader(patient: _patient())));
    await tester.pumpAndSettle();

    expect(find.textContaining('أحمد'), findsNWidgets(2)); // header + tile
    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.text('ذكر'), findsOneWidget);
    expect(find.text('1990-01-01'), findsOneWidget);
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    await tester.pumpWidget(
      wrap(PatientSliverHeader(patient: _patient()), theme: AppTheme.dark),
    );
    await tester.pumpAndSettle();

    expect(find.text('خالد العلي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/ui/patient_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/back_navigation.dart';

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

void main() {
  const dialogTitle = 'تجاهل التعديلات؟';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    final doctorsRepo = _MockDoctorsRepo();
    when(() => doctorsRepo.getDoctors()).thenAnswer(
      (_) async => Right<Failure, List<DoctorModel>>([
        DoctorModel(id: 'd1', firstName: 'أحمد', lastName: 'الخطيب'),
      ]),
    );

    await getIt.reset();
    getIt.registerFactory<PatientFormCubit>(
      () => PatientFormCubit(_MockPatientsRepo()),
    );
    getIt.registerFactory<DoctorsCubit>(() => DoctorsCubit(doctorsRepo));
  });

  tearDown(() => getIt.reset());

  Widget wrap() => MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PatientFormPage())),
            child: const Text('فتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> openForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap());
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
    expect(find.text('إضافة مريض'), findsOneWidget);
  }

  testWidgets('an untouched form leaves without asking', (tester) async {
    await openForm(tester);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('typing a name makes leaving ask first', (tester) async {
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'خالد');
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
    expect(find.text('إضافة مريض'), findsOneWidget);
  });

  testWidgets('whitespace alone does not count as an entry', (tester) async {
    await openForm(tester);

    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('changing only the gender still asks', (tester) async {
    await openForm(tester);

    // Below the fold at 360dp — an un-scrolled tap would silently miss.
    await tester.ensureVisible(find.text('أنثى'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('أنثى'));
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
  });
}

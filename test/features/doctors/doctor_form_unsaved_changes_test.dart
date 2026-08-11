import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/cities/data/repos/cities_repo.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_form/doctor_form_cubit.dart';
import 'package:dental_lab_app/features/doctors/ui/doctor_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/back_navigation.dart';

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockCitiesRepo extends Mock implements CitiesRepo {}

class _MockClinicsRepo extends Mock implements ClinicsRepo {}

void main() {
  const dialogTitle = 'تجاهل التعديلات؟';

  final doctor = DoctorModel(
    id: 'd1',
    firstName: 'أحمد',
    lastName: 'الخطيب',
    phoneNumber: '0991234567',
    clinicId: 'c1',
    isActive: true,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    final citiesRepo = _MockCitiesRepo();
    when(
      () => citiesRepo.getCities(),
    ).thenAnswer((_) async => Right<Failure, List<CityModel>>(const []));
    final clinicsRepo = _MockClinicsRepo();
    when(() => clinicsRepo.getClinics()).thenAnswer(
      (_) async => Right<Failure, List<ClinicModel>>([
        ClinicModel(id: 'c1', name: 'عيادة النور'),
        ClinicModel(id: 'c2', name: 'عيادة الشفاء'),
      ]),
    );

    await getIt.reset();
    getIt.registerFactory<DoctorFormCubit>(
      () => DoctorFormCubit(_MockDoctorsRepo()),
    );
    getIt.registerFactory<CitiesCubit>(() => CitiesCubit(citiesRepo));
    getIt.registerFactory<ClinicsCubit>(() => ClinicsCubit(clinicsRepo));
  });

  tearDown(() => getIt.reset());

  /// Hosts the form behind a "home" screen so leaving it is observable.
  Widget wrap({DoctorModel? initial}) => MaterialApp(
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
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DoctorFormPage(initialDoctor: initial),
              ),
            ),
            child: const Text('فتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> openForm(WidgetTester tester, {DoctorModel? initial}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(initial: initial));
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('an untouched edit form leaves without asking', (tester) async {
    // Regression: controllers seeded from the model must not read as edits.
    await openForm(tester, initial: doctor);
    expect(find.text('تعديل الدكتور'), findsOneWidget);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('typing one character makes leaving ask first', (tester) async {
    await openForm(tester, initial: doctor);

    await tester.enterText(find.byType(TextFormField).first, 'أحمد محمد');
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
    expect(find.text('تعديل الدكتور'), findsOneWidget);
  });

  testWidgets('typing then reverting leaves without asking', (tester) async {
    await openForm(tester, initial: doctor);
    final firstName = find.byType(TextFormField).first;

    await tester.enterText(firstName, 'أحمدx');
    await tester.pumpAndSettle();
    await tester.enterText(firstName, 'أحمد');
    await tester.pumpAndSettle();

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('changing only a non-text field still asks', (tester) async {
    await openForm(tester, initial: doctor);

    // The gender selector — no typing involved.
    await tester.tap(find.text('أنثى'));
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
  });

  testWidgets('an empty create form leaves without asking', (tester) async {
    await openForm(tester);
    expect(find.text('إضافة دكتور'), findsOneWidget);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });
}

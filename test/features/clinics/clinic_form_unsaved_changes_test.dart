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
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_cubit.dart';
import 'package:dental_lab_app/features/clinics/ui/clinic_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/back_navigation.dart';

class _MockClinicsRepo extends Mock implements ClinicsRepo {}

class _MockCitiesRepo extends Mock implements CitiesRepo {}

void main() {
  const dialogTitle = 'تجاهل التعديلات؟';

  final clinic = ClinicModel(
    id: 'c1',
    name: 'عيادة النور',
    code: 'NR-1',
    phoneNumber: '0991234567',
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    final citiesRepo = _MockCitiesRepo();
    when(
      () => citiesRepo.getCities(),
    ).thenAnswer((_) async => Right<Failure, List<CityModel>>(const []));

    await getIt.reset();
    getIt.registerFactory<ClinicFormCubit>(
      () => ClinicFormCubit(_MockClinicsRepo()),
    );
    getIt.registerFactory<CitiesCubit>(() => CitiesCubit(citiesRepo));
  });

  tearDown(() => getIt.reset());

  Widget wrap({ClinicModel? initial}) => MaterialApp(
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
                builder: (_) => ClinicFormPage(initialClinic: initial),
              ),
            ),
            child: const Text('فتح'),
          ),
        ),
      ),
    ),
  );

  Future<void> openForm(WidgetTester tester, {ClinicModel? initial}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(initial: initial));
    await tester.tap(find.text('فتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty create form leaves without asking', (tester) async {
    // Regression: the controllers are seeded with `?? ''`, which must read as
    // clean rather than as "changed from null to empty".
    await openForm(tester);
    expect(find.text('إضافة عيادة'), findsOneWidget);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('an untouched edit form leaves without asking', (tester) async {
    await openForm(tester, initial: clinic);
    expect(find.text('تعديل العيادة'), findsOneWidget);

    await systemBack(tester);

    expect(find.text(dialogTitle), findsNothing);
    expect(find.text('فتح'), findsOneWidget);
  });

  testWidgets('typing into a field makes leaving ask first', (tester) async {
    await openForm(tester, initial: clinic);

    await tester.enterText(find.byType(TextFormField).first, 'عيادة الشفاء');
    await tester.pumpAndSettle();
    await systemBack(tester);

    expect(find.text(dialogTitle), findsOneWidget);
    expect(find.text('تعديل العيادة'), findsOneWidget);
  });

  testWidgets('discarding leaves, keeping stays', (tester) async {
    await openForm(tester, initial: clinic);
    await tester.enterText(find.byType(TextFormField).first, 'عيادة الشفاء');
    await tester.pumpAndSettle();

    await systemBack(tester);
    await tester.tap(find.text('متابعة التعديل'));
    await tester.pumpAndSettle();
    expect(find.text('تعديل العيادة'), findsOneWidget);

    await systemBack(tester);
    await tester.tap(find.text('خروج بدون حفظ'));
    await tester.pumpAndSettle();
    expect(find.text('فتح'), findsOneWidget);
  });
}

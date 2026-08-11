import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/ui/clinics_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockClinicsRepo extends Mock implements ClinicsRepo {}

ClinicModel _clinic(String id, String name) => ClinicModel(id: id, name: name);

void main() {
  late _MockClinicsRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    repo = _MockClinicsRepo();
    await getIt.reset();
    // The page resolves its cubit from the service locator; the drawer pulls
    // the ThemeCubit from it too.
    getIt.registerFactory<ClinicsCubit>(() => ClinicsCubit(repo));
    getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
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
    home: const ClinicsListPage(),
  );

  testWidgets('keeps the rows on screen while a refresh is in flight', (
    tester,
  ) async {
    // Same regression as the doctors/patients features: ClinicsLoading must
    // not swap the list out for the skeleton mid-pull, or pull-to-refresh
    // looks like it does nothing.
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final clinics = [_clinic('1', 'عيادة النور')];

    when(
      () => repo.getClinics(),
    ).thenAnswer((_) async => Right<Failure, List<ClinicModel>>(clinics));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);

    final pending = Completer<Either<Failure, List<ClinicModel>>>();
    when(() => repo.getClinics()).thenAnswer((_) => pending.future);

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1200);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.byType(GlassListSkeleton), findsNothing);

    pending.complete(Right<Failure, List<ClinicModel>>(clinics));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('عيادة النور'), findsOneWidget);
    verify(() => repo.getClinics()).called(2);
  });

  testWidgets('shows the skeleton only on the first load', (tester) async {
    final completer = Completer<Either<Failure, List<ClinicModel>>>();
    when(() => repo.getClinics()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('عيادة النور'), findsNothing);

    completer.complete(
      Right<Failure, List<ClinicModel>>([_clinic('1', 'عيادة النور')]),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('عيادة النور'), findsOneWidget);
  });
}

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/ui/doctors_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

DoctorModel _doctor(String id, String first, String last) =>
    DoctorModel(id: id, firstName: first, lastName: last);

void main() {
  late _MockDoctorsRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();

    repo = _MockDoctorsRepo();
    await getIt.reset();
    // The page resolves its cubit from the service locator; the drawer pulls
    // the ThemeCubit from it too.
    getIt.registerFactory<DoctorsCubit>(() => DoctorsCubit(repo));
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
    home: const DoctorsListPage(),
  );

  testWidgets('keeps the rows on screen while a refresh is in flight', (
    tester,
  ) async {
    // Regression: DoctorsLoading swapped the list out for the skeleton, which
    // unmounted the RefreshIndicator mid-pull — refreshing appeared to do
    // nothing at all.
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final doctors = [_doctor('1', 'أحمد', 'الخطيب')];

    when(
      () => repo.getDoctors(),
    ).thenAnswer((_) async => Right<Failure, List<DoctorModel>>(doctors));

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('أحمد الخطيب'), findsOneWidget);

    // Hold the next fetch open so the loading state is observable.
    final pending = Completer<Either<Failure, List<DoctorModel>>>();
    when(() => repo.getDoctors()).thenAnswer((_) => pending.future);

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1200);
    await tester.pump();
    // Past the AnimatedSwitcher's cross-fade: before that the outgoing child
    // is still mounted, so the row would be found even when it is on its way
    // out — the assertion has to run after the swap has settled.
    await tester.pump(const Duration(milliseconds: 600));

    // Mid-refresh the rows must still be there, not replaced by the skeleton.
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.byType(GlassListSkeleton), findsNothing);

    pending.complete(Right<Failure, List<DoctorModel>>(doctors));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('أحمد الخطيب'), findsOneWidget);
    verify(() => repo.getDoctors()).called(2);
  });

  testWidgets('shows the skeleton only on the first load', (tester) async {
    final completer = Completer<Either<Failure, List<DoctorModel>>>();
    when(() => repo.getDoctors()).thenAnswer((_) => completer.future);

    await tester.pumpWidget(wrap());
    await tester.pump();

    // Nothing loaded yet, so the placeholder is correct here.
    expect(find.text('أحمد الخطيب'), findsNothing);

    completer.complete(
      Right<Failure, List<DoctorModel>>([_doctor('1', 'أحمد', 'الخطيب')]),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('أحمد الخطيب'), findsOneWidget);
  });
}

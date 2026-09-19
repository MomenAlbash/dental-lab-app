import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/doctor_quota/doctor_quota_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_excluded_representatives/doctor_excluded_representatives_cubit.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_details_body.dart';
import 'package:dental_lab_app/features/zones/data/repos/zones_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

DoctorModel _doctor({
  String? phone = '0991234567',
  String? email = 'a@b.com',
  String? address = 'المزة، دمشق',
}) {
  return DoctorModel(
    id: 'd-1',
    firstName: 'أحمد',
    lastName: 'الخطيب',
    phoneNumber: phone,
    email: email,
    address: address,
    gender: DoctorGender.male,
    dateOfBirth: '1985-04-12',
    city: CityModel(id: 'c1', name: 'دمشق'),
    clinic: ClinicModel(id: 'cl1', name: 'عيادة النور'),
  );
}

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

class _MockPriceTiersRepo extends Mock implements PriceTiersRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockZonesRepo extends Mock implements ZonesRepo {}

void main() {
  // The body now carries the doctor's priority allowances, which resolve their
  // cubit and the session off the locator. Registered here rather than made
  // optional in the widget: a quota section that silently renders nothing when
  // DI is missing would hide the same failure in the real app.
  setUp(() async {
    final repo = _MockCasePrioritiesRepo();
    when(() => repo.getDoctorPriorityQuota(any())).thenAnswer(
      (_) async =>
          right(DoctorPriorityQuotaModel.fromJson(const {'doctorId': 'd-1'})),
    );

    // Awaited: `reset` is asynchronous, and registering into the cascade
    // behind it lets the reset land afterwards and wipe what was just
    // registered.
    final tiersRepo = _MockPriceTiersRepo();
    when(
      () => tiersRepo.getPriceTiers(),
    ).thenAnswer((_) async => right(const <PriceTierModel>[]));

    // The excluded-representatives section resolves its own cubit off the
    // locator too — the fixture doctor has no zoneId, so only the exclusion
    // list itself needs a stub.
    final doctorsRepo = _MockDoctorsRepo();
    when(
      () => doctorsRepo.getExcludedRepresentatives(any()),
    ).thenAnswer((_) async => right(const []));
    final zonesRepo = _MockZonesRepo();

    await getIt.reset();
    getIt
      ..registerLazySingleton<SessionCubit>(
        () => SessionCubit(
          initial: const Permissions(isAdmin: true, granted: {}),
        ),
      )
      ..registerFactory<DoctorQuotaCubit>(() => DoctorQuotaCubit(repo))
      ..registerLazySingleton<PriceTiersRepo>(() => tiersRepo)
      ..registerFactory<DoctorExcludedRepresentativesCubit>(
        () => DoctorExcludedRepresentativesCubit(doctorsRepo, zonesRepo),
      );
  });

  tearDown(() => getIt.reset());

  Widget wrap(DoctorModel doctor, {ThemeData? theme}) {
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
        body: DoctorDetailsBody(
          doctor: doctor,
          isBusy: false,
          onEdit: () {},
          onOpenAnswers: () {},
          onAddFile: () {},
          onDeleteFile: (_) {},
          onOpenFile: (_) {},
          onApprove: (_) {},
          onReject: (_) {},
          onPriceTierChanged: (_) {},
        ),
      ),
    );
  }

  testWidgets('renders identity, actions and info tiles at 360dp', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(_doctor()));
    await tester.pumpAndSettle();

    // Exactly once: FlexibleSpaceBar owns the name, the panel must not repeat
    // it. Regression guard — it was rendered twice.
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('نشط'), findsOneWidget);

    // Quick actions.
    expect(find.text('اتصال'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('بريد'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);

    // Info tiles.
    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.text('دمشق'), findsOneWidget);
    expect(find.text('1985-04-12'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsing the header does not overflow at any scroll offset', (
    tester,
  ) async {
    // Regression: the identity panel used to be laid out against the header's
    // shrinking height and overflowed its column part-way through the collapse.
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(_doctor()));
    await tester.pumpAndSettle();

    // Drag in small steps so intermediate collapse fractions are rendered,
    // not just the fully collapsed end state.
    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -25));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to initials when there is no photo', (tester) async {
    await tester.pumpWidget(wrap(_doctor()));
    await tester.pumpAndSettle();

    expect(find.text('أا'), findsOneWidget);
  });

  testWidgets('shows the empty attachments drop zone', (tester) async {
    await tester.pumpWidget(wrap(_doctor()));
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد مرفقات'), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
  });

  testWidgets('renders without exceptions when contact data is missing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(_doctor(phone: null, email: null, address: null)),
    );
    await tester.pumpAndSettle();

    // Disabled tiles keep the row's shape rather than disappearing.
    expect(find.text('اتصال'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives a 2.0x text scale at 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: wrap(_doctor()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in the dark theme', (tester) async {
    await tester.pumpWidget(wrap(_doctor(), theme: AppTheme.dark));
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

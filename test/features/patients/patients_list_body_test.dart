import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patients_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPatientsRepo extends Mock implements PatientsRepo {}

PatientModel _patient(
  String id,
  String first,
  String last, {
  int caseCount = 0,
  PatientGender gender = PatientGender.male,
  String? phone,
  String? doctorName,
  String? clinicName,
}) {
  return PatientModel(
    id: id,
    firstName: first,
    lastName: last,
    caseCount: caseCount,
    gender: gender,
    phoneNumber: phone,
    doctor: doctorName == null
        ? null
        : DoctorModel(id: 'd-$id', firstName: doctorName, lastName: ''),
    clinic: clinicName == null
        ? null
        : ClinicModel(id: 'c-$id', name: clinicName),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(PatientFiltersModel.empty);
  });

  late _MockPatientsRepo repo;
  late PatientsCubit cubit;

  setUp(() {
    repo = _MockPatientsRepo();
    cubit = PatientsCubit(repo);
  });

  tearDown(() => cubit.close());

  Widget wrap({
    ThemeData? theme,
    PatientCaseFilter caseFilter = PatientCaseFilter.all,
  }) {
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
        body: BlocProvider.value(
          value: cubit,
          child: PatientsListBody(caseFilter: caseFilter),
        ),
      ),
    );
  }

  testWidgets('renders patient rows with doctor, clinic and case count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        _patient(
          '1',
          'خالد',
          'العلي',
          caseCount: 3,
          doctorName: 'أحمد',
          clinicName: 'عيادة النور',
          phone: '0991234567',
        ),
      ]),
    );

    await cubit.getPatients();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('خالد العلي'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.textContaining('أحمد'), findsOneWidget);
    expect(find.textContaining('عيادة النور'), findsOneWidget);
    expect(find.text('0991234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives a 2.0x text scale at 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        _patient(
          '1',
          'خالد',
          'العلي',
          caseCount: 12,
          doctorName: 'أحمد الطويل جداً جداً',
          clinicName: 'عيادة النور للأسنان والتجميل',
          phone: '0991234567',
        ),
      ]),
    );

    await cubit.getPatients();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: wrap(),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('caseFilter.linked shows only patients with cases', (
    tester,
  ) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        _patient('1', 'خالد', 'العلي', caseCount: 3),
        _patient('2', 'سارة', 'العلي', caseCount: 0),
      ]),
    );

    await cubit.getPatients();
    await tester.pumpWidget(wrap(caseFilter: PatientCaseFilter.linked));
    await tester.pumpAndSettle();

    expect(find.text('خالد العلي'), findsOneWidget);
    expect(find.text('سارة العلي'), findsNothing);
  });

  testWidgets('caseFilter.unlinked shows only patients without cases', (
    tester,
  ) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        _patient('1', 'خالد', 'العلي', caseCount: 3),
        _patient('2', 'سارة', 'العلي', caseCount: 0),
      ]),
    );

    await cubit.getPatients();
    await tester.pumpWidget(wrap(caseFilter: PatientCaseFilter.unlinked));
    await tester.pumpAndSettle();

    expect(find.text('خالد العلي'), findsNothing);
    expect(find.text('سارة العلي'), findsOneWidget);
  });

  testWidgets('a case filter with no matches explains itself', (tester) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        _patient('1', 'خالد', 'العلي', caseCount: 3),
      ]),
    );

    await cubit.getPatients();
    await tester.pumpWidget(wrap(caseFilter: PatientCaseFilter.unlinked));
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد مرضى غير مرتبطين بحالة'), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no patients', (
    tester,
  ) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => Right<Failure, List<PatientModel>>(const []));

    await cubit.getPatients();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد مرضى بعد'), findsOneWidget);
  });

  testWidgets('keeps the rows on screen while a refresh is in flight', (
    tester,
  ) async {
    // Same regression as the doctors feature: DoctorsLoading/PatientsLoading
    // must not swap the list out for the skeleton mid-pull, or
    // pull-to-refresh looks like it does nothing.
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final patients = [_patient('1', 'خالد', 'العلي')];
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => Right<Failure, List<PatientModel>>(patients));

    await cubit.getPatients();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('خالد العلي'), findsOneWidget);

    final pending = Completer<Either<Failure, List<PatientModel>>>();
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) => pending.future);

    unawaited(cubit.getPatients());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('خالد العلي'), findsOneWidget);
    expect(find.byType(GlassListSkeleton), findsNothing);

    pending.complete(Right<Failure, List<PatientModel>>(patients));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        _patient('1', 'خالد', 'العلي', gender: PatientGender.female),
      ]),
    );

    await cubit.getPatients();
    await tester.pumpWidget(wrap(theme: AppTheme.dark));
    await tester.pumpAndSettle();

    expect(find.text('خالد العلي'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patients_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPatientsRepo extends Mock implements PatientsRepo {}

PatientModel _patient(String id, {int caseCount = 0}) {
  return PatientModel(
    id: id,
    firstName: 'مريض',
    lastName: id,
    caseCount: caseCount,
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
    PatientCaseFilter selected = PatientCaseFilter.all,
    ValueChanged<PatientCaseFilter>? onSelected,
  }) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: PatientCaseFilterStrip(
            selected: selected,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('stays empty until patients have loaded', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('الكل'), findsNothing);
  });

  testWidgets('hides itself when there are no patients at all', (tester) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => Right<Failure, List<PatientModel>>(const []));

    await cubit.getPatients();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('الكل'), findsNothing);
  });

  testWidgets('shows total, linked and unlinked counts', (tester) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, List<PatientModel>>([
        _patient('1', caseCount: 3),
        _patient('2', caseCount: 0),
        _patient('3', caseCount: 1),
      ]),
    );

    await cubit.getPatients();
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('مرتبط بحالة'), findsOneWidget);
    expect(find.text('غير مرتبط'), findsOneWidget);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('patient-case-filter-all')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('patient-case-filter-linked')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('patient-case-filter-unlinked')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping a tile reports the tapped filter', (tester) async {
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async =>
          Right<Failure, List<PatientModel>>([_patient('1', caseCount: 1)]),
    );
    await cubit.getPatients();

    PatientCaseFilter? tapped;
    await tester.pumpWidget(wrap(onSelected: (value) => tapped = value));
    await tester.pumpAndSettle();

    await tester.tap(find.text('غير مرتبط'));
    await tester.pump();

    expect(tapped, PatientCaseFilter.unlinked);
  });

  testWidgets('keeps showing counts while a refresh is in flight', (
    tester,
  ) async {
    // Same rationale as the body's own cache: the strip lives above the list
    // and must not blank out mid-pull-to-refresh.
    when(
      () => repo.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async =>
          Right<Failure, List<PatientModel>>([_patient('1', caseCount: 1)]),
    );
    await cubit.getPatients();

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    expect(find.text('الكل'), findsOneWidget);

    unawaited(cubit.getPatients());
    await tester.pump();

    expect(find.text('الكل'), findsOneWidget);
    await tester.pumpAndSettle();
  });
}

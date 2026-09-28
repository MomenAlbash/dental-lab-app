import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/cases_page_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_cubit.dart';
import 'package:dental_lab_app/features/patients/ui/patient_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

void main() {
  setUpAll(() => registerFallbackValue(CaseFiltersModel.empty));

  testWidgets('on a small phone, a patient\'s cases are a tab away', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    await getIt.reset();
    addTearDown(getIt.reset);

    final patients = _MockPatientsRepo();
    when(() => patients.getPatientById('p-1')).thenAnswer(
      (_) async => Right<Failure, PatientModel>(
        PatientModel(id: 'p-1', firstName: 'سامي', lastName: 'العلي'),
      ),
    );
    final cases = _MockCasesRepo();
    when(
      () => cases.getCasesPage(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, CasesPageModel>(
        CasesPageModel(
          items: [CaseListItemModel(id: 'k1', caseNumber: '555')],
          pageSize: 30,
          totalCount: 1,
        ),
      ),
    );
    when(
      () => cases.getPhaseCounts(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async =>
          Right<Failure, CasePhaseCountsModel>(CasePhaseCountsModel.empty),
    );
    when(
      () => cases.getSlaCounts(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, CaseSlaCountsModel>(CaseSlaCountsModel.empty),
    );
    final priorities = _MockCasePrioritiesRepo();
    when(
      () => priorities.getCasePriorities(
        includeInactive: any(named: 'includeInactive'),
      ),
    ).thenAnswer(
      (_) async => const Right<Failure, List<CasePriorityModel>>([]),
    );
    getIt
      ..registerLazySingleton<SessionCubit>(
        () => SessionCubit(
          initial: const Permissions(isAdmin: true, granted: {}),
        ),
      )
      ..registerFactory<PatientDetailsCubit>(
        () => PatientDetailsCubit(patients),
      )
      ..registerFactory<CasesCubit>(() => CasesCubit(cases))
      ..registerFactory<CasePrioritiesCubit>(
        () => CasePrioritiesCubit(priorities),
      );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const PatientDetailPage(patientId: 'p-1'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('التفاصيل'), findsOneWidget);

    await tester.tap(find.text('الحالات'));
    await tester.pumpAndSettle();

    final filters =
        verify(
              () => cases.getCasesPage(
                search: any(named: 'search'),
                filters: captureAny(named: 'filters'),
                page: any(named: 'page'),
                pageSize: any(named: 'pageSize'),
              ),
            ).captured.last
            as CaseFiltersModel;
    expect(filters.patientId, 'p-1');
    expect(find.textContaining('555'), findsOneWidget);
    expect(find.text('إضافة حالة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

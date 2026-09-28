import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/cases_page_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/global_search/data/recent_items_repo.dart';
import 'package:dental_lab_app/features/global_search/logic/global_search_cubit.dart';
import 'package:dental_lab_app/features/global_search/logic/global_search_state.dart';
import 'package:dental_lab_app/features/global_search/ui/global_search_page.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockPatientsRepo extends Mock implements PatientsRepo {}

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

void main() {
  late _MockCasesRepo cases;
  late _MockPatientsRepo patients;
  late _MockDoctorsRepo doctors;

  setUpAll(() {
    registerFallbackValue(CaseFiltersModel.empty);
    registerFallbackValue(PatientFiltersModel.empty);
  });

  void answer({
    List<CaseListItemModel> caseRows = const [],
    List<PatientModel> patientRows = const [],
    Either<Failure, List<DoctorModel>>? doctorResult,
  }) {
    when(
      () => cases.getCasesPage(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer(
      (_) async => Right(
        CasesPageModel(
          items: caseRows,
          pageSize: 5,
          totalCount: caseRows.length,
        ),
      ),
    );
    when(
      () => patients.getPatients(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer((_) async => Right(patientRows));
    when(
      () => doctors.searchDoctors(any()),
    ).thenAnswer((_) async => doctorResult ?? Right([]));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    cases = _MockCasesRepo();
    patients = _MockPatientsRepo();
    doctors = _MockDoctorsRepo();
  });

  GlobalSearchCubit cubit() {
    final c = GlobalSearchCubit(
      cases,
      patients,
      doctors,
      RecentItemsRepo(),
      debounce: Duration.zero,
    );
    addTearDown(c.close);
    return c;
  }

  test('one letter searches nothing', () async {
    answer();
    final search = cubit();

    search.onQueryChanged('أ');
    await Future<void>.delayed(Duration.zero);

    expect(search.state.isIdle, isTrue);
    verifyNever(() => doctors.searchDoctors(any()));
  });

  test('searches cases, patients and doctors on the server', () async {
    answer(
      caseRows: [CaseListItemModel(id: 'c1', caseNumber: '120')],
      patientRows: [PatientModel(id: 'p1', firstName: 'سامي')],
      doctorResult: Right([DoctorModel(id: 'd1', firstName: 'رامي')]),
    );
    final search = cubit();

    await search.search('سا');

    expect((search.state.cases as SectionResults).items.single.id, 'c1');
    expect((search.state.patients as SectionResults).items.single.id, 'p1');
    expect((search.state.doctors as SectionResults).items.single.id, 'd1');
    verify(() => doctors.searchDoctors('سا')).called(1);
    verify(
      () => cases.getCasesPage(
        search: 'سا',
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        pageSize: GlobalSearchCubit.perSection,
      ),
    ).called(1);
  });

  test('one section failing leaves the others', () async {
    answer(
      caseRows: [CaseListItemModel(id: 'c1')],
      doctorResult: Left(ServerFailure('لا صلاحية')),
    );
    final search = cubit();

    await search.search('12');

    expect(search.state.doctors, isA<SectionError<DoctorModel>>());
    expect(search.state.cases, isA<SectionResults<CaseListItemModel>>());
  });

  test('shows a handful, and says when there are more', () async {
    answer(patientRows: [for (var i = 0; i < 8; i++) PatientModel(id: 'p$i')]);
    final search = cubit();

    await search.search('مر');

    final section = search.state.patients as SectionResults<PatientModel>;
    expect(section.items, hasLength(GlobalSearchCubit.perSection));
    expect(section.hasMore, isTrue);
  });

  test('a slow answer for an older query is dropped', () async {
    answer();
    final slow = Completer<Either<Failure, List<DoctorModel>>>();
    when(() => doctors.searchDoctors('قد')).thenAnswer((_) => slow.future);
    when(
      () => doctors.searchDoctors('جديد'),
    ).thenAnswer((_) async => Right([DoctorModel(id: 'new')]));
    final search = cubit();

    final older = search.search('قد');
    await search.search('جديد');
    slow.complete(Right([DoctorModel(id: 'old')]));
    await older;

    expect(search.state.query, 'جديد');
    expect(
      (search.state.doctors as SectionResults<DoctorModel>).items.single.id,
      'new',
    );
  });

  testWidgets('on a small phone, results open from one box', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await CacheHelper.init();
    await getIt.reset();
    addTearDown(getIt.reset);
    answer(
      caseRows: [
        CaseListItemModel(id: 'c1', caseNumber: '120', patientName: 'سامي'),
      ],
      doctorResult: Right([DoctorModel(id: 'd1', firstName: 'سامر')]),
    );
    getIt.registerFactory<GlobalSearchCubit>(
      () => GlobalSearchCubit(
        cases,
        patients,
        doctors,
        RecentItemsRepo(),
        debounce: Duration.zero,
      ),
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
        home: const GlobalSearchPage(),
      ),
    );
    await tester.enterText(find.byType(TextField), 'سا');
    await tester.pumpAndSettle();

    expect(find.text('حالة 120'), findsOneWidget);
    expect(find.text('سامر'), findsOneWidget);
    // Patients found nothing, so the section takes no room.
    expect(find.text('المرضى'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  group('recently opened', () {
    RecentItem doctor(String id) =>
        RecentItem(kind: RecentItemKind.doctor, id: id, title: 'د. $id');

    test('shows what was opened before, newest first', () async {
      final search = cubit();
      await search.remember(doctor('a'));
      await search.remember(doctor('b'));

      final fresh = cubit()..loadRecent();

      expect(fresh.state.recent.map((r) => r.id), ['b', 'a']);
    });

    test('opening the same record again moves it up, not in twice', () async {
      final search = cubit();
      await search.remember(doctor('a'));
      await search.remember(doctor('b'));

      await search.remember(doctor('a'));

      expect(search.state.recent.map((r) => r.id), ['a', 'b']);
    });

    test('keeps only the last ten', () async {
      final search = cubit();
      for (var i = 0; i < 14; i++) {
        await search.remember(doctor('$i'));
      }

      expect(search.state.recent, hasLength(RecentItemsRepo.maxItems));
      expect(search.state.recent.first.id, '13');
    });

    test('survives a search and the box being cleared', () async {
      answer();
      final search = cubit();
      await search.remember(doctor('a'));

      await search.search('سا');
      search.onQueryChanged('');

      expect(search.state.isIdle, isTrue);
      expect(search.state.recent.single.id, 'a');
    });

    test('can be cleared', () async {
      final search = cubit();
      await search.remember(doctor('a'));

      await search.clearRecent();

      expect(search.state.recent, isEmpty);
      expect(RecentItemsRepo().load(), isEmpty);
    });
  });
}

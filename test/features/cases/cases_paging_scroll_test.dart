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
import 'package:dental_lab_app/features/cases/ui/widgets/cases_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

void main() {
  setUpAll(() => registerFallbackValue(CaseFiltersModel.empty));

  testWidgets('scrolling to the end of a small phone loads the next page', (
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
    getIt.registerLazySingleton<SessionCubit>(
      () =>
          SessionCubit(initial: const Permissions(isAdmin: true, granted: {})),
    );

    final repo = _MockCasesRepo();
    when(
      () => repo.getCasesPage(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((call) async {
      final page = call.namedArguments[#page] as int;
      return Right<Failure, CasesPageModel>(
        CasesPageModel(
          items: [
            for (var i = 0; i < 30; i++)
              CaseListItemModel(
                id: 'p$page-$i',
                caseNumber: 'P$page-$i',
                patientName: 'مريض',
              ),
          ],
          page: page,
          pageSize: 30,
          totalCount: 60,
        ),
      );
    });
    when(
      () => repo.getPhaseCounts(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
      ),
    ).thenAnswer(
      (_) async =>
          Right<Failure, CasePhaseCountsModel>(CasePhaseCountsModel.empty),
    );
    when(
      () => repo.getSlaCounts(
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
        home: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => CasesCubit(repo)..getCases()),
            BlocProvider(
              create: (_) =>
                  CasePrioritiesCubit(priorities)..getCasePriorities(),
            ),
          ],
          child: const Scaffold(body: CasesListBody()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(Scrollable).last,
      const Offset(0, -20000),
      3000,
    );
    await tester.pumpAndSettle();

    verify(
      () => repo.getCasesPage(
        search: any(named: 'search'),
        filters: any(named: 'filters'),
        page: 2,
        pageSize: any(named: 'pageSize'),
      ),
    ).called(1);
    expect(tester.takeException(), isNull);
  });
}

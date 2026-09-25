import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/deliver_directly_models.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/cases_list_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockCasePrioritiesRepo extends Mock implements CasePrioritiesRepo {}

CaseListItemModel _case(String id) => CaseListItemModel(
  id: id,
  caseNumber: 'C-$id',
  patientName: 'مريض $id',
  priorityId: 'p1',
);

void _stubList(_MockCasesRepo repo) {
  when(
    () => repo.getCases(
      search: any(named: 'search'),
      filters: any(named: 'filters'),
    ),
  ).thenAnswer(
    (_) async =>
        Right<Failure, List<CaseListItemModel>>([_case('1'), _case('2')]),
  );
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
}

const _results = [
  DeliverDirectlyResultModel(caseId: '1', caseNumber: 'C-1', delivered: true),
  DeliverDirectlyResultModel(
    caseId: '2',
    caseNumber: 'C-2',
    error: 'المرحلة تحتاج موافقة',
  ),
];

void main() {
  setUpAll(() {
    registerFallbackValue(CaseFiltersModel.empty);
    registerFallbackValue(CollectionMethod.none);
  });

  test('reads each case\'s outcome', () {
    final row = DeliverDirectlyResultModel.fromJson({
      'caseId': 'c1',
      'caseNumber': null,
      'delivered': false,
      'error': 'not found',
    });

    expect(row.caseNumber, isNull);
    expect(row.delivered, isFalse);
    expect(row.error, 'not found');
  });

  group('CasesCubit.deliverDirectly', () {
    late _MockCasesRepo repo;

    setUp(() {
      repo = _MockCasesRepo();
      _stubList(repo);
    });

    test('announces every case\'s outcome, then reloads', () async {
      when(
        () => repo.deliverDirectly(
          caseIds: ['1', '2'],
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async =>
            const Right<Failure, List<DeliverDirectlyResultModel>>(_results),
      );
      final cubit = CasesCubit(repo);
      addTearDown(cubit.close);
      final states = <CasesState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(sub.cancel);

      await cubit.deliverDirectly(['1', '2'], note: 'دفعة');
      // Stream events arrive a microtask later than the awaited call.
      await pumpEventQueue();

      final announced = states.whereType<CasesDeliveredDirectly>().single;
      expect(announced.results, hasLength(2));
      expect(states.last, isA<CasesLoaded>());
    });

    test('a failed call says so and sends nothing else', () async {
      when(
        () => repo.deliverDirectly(
          caseIds: any(named: 'caseIds'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async => Left<Failure, List<DeliverDirectlyResultModel>>(
          ServerFailure('refused'),
        ),
      );
      final cubit = CasesCubit(repo);
      addTearDown(cubit.close);
      final states = <CasesState>[];
      final sub = cubit.stream.listen(states.add);
      addTearDown(sub.cancel);

      await cubit.deliverDirectly(['1']);

      expect(states.whereType<CasesDeliverDirectlyError>(), hasLength(1));
      expect(states.whereType<CasesDeliveredDirectly>(), isEmpty);
    });
  });

  test('a single case sends how the work leaves the lab', () async {
    final repo = _MockCasesRepo();
    when(() => repo.getCaseById('c1')).thenAnswer(
      (_) async => Right<Failure, CaseDetailModel>(CaseDetailModel(id: 'c1')),
    );
    when(
      () => repo.deliverCaseDirectly(
        id: 'c1',
        note: any(named: 'note'),
        collectionMethod: any(named: 'collectionMethod'),
      ),
    ).thenAnswer((_) async => const Right<Failure, void>(null));
    final cubit = CaseDetailsCubit(repo);
    addTearDown(cubit.close);
    await cubit.getCase('c1');

    await cubit.deliverDirectly(
      collectionMethod: CollectionMethod.courierCollection,
    );

    verify(
      () => repo.deliverCaseDirectly(
        id: 'c1',
        note: null,
        collectionMethod: CollectionMethod.courierCollection,
      ),
    ).called(1);
  });

  testWidgets(
    'on a small phone, a long press picks cases and delivers them together',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await getIt.reset();
      addTearDown(getIt.reset);
      getIt.registerLazySingleton<SessionCubit>(
        () => SessionCubit(
          initial: const Permissions(isAdmin: true, granted: {}),
        ),
      );

      final repo = _MockCasesRepo();
      _stubList(repo);
      when(
        () => repo.deliverDirectly(
          caseIds: any(named: 'caseIds'),
          note: any(named: 'note'),
        ),
      ).thenAnswer(
        (_) async =>
            const Right<Failure, List<DeliverDirectlyResultModel>>(_results),
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

      await tester.longPress(find.textContaining('C-1'));
      await tester.pumpAndSettle();
      expect(find.text('1 محددة'), findsOneWidget);

      // Inside selection a plain tap picks rather than opening the case.
      await tester.tap(find.textContaining('C-2').first);
      await tester.pumpAndSettle();
      expect(find.text('2 محددة'), findsOneWidget);

      await tester.tap(find.text('تم التسليم').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تسليم'));
      await tester.pumpAndSettle();

      final sent =
          verify(
                () => repo.deliverDirectly(
                  caseIds: captureAny(named: 'caseIds'),
                  note: any(named: 'note'),
                ),
              ).captured.single
              as List<String>;
      expect(sent.toSet(), {'1', '2'});
      expect(find.text('سُلّمت 1 من 2'), findsOneWidget);
      expect(find.textContaining('المرحلة تحتاج موافقة'), findsOneWidget);
      expect(find.text('2 محددة'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}

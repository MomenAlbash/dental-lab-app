import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
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
  caseNumber: id,
  patientName: 'مريض $id',
  priorityId: 'p1',
  priorityNameAr: 'عادية',
);

Widget _wrap() {
  final casesRepo = _MockCasesRepo();
  when(
    () => casesRepo.getCases(
      search: any(named: 'search'),
      filters: any(named: 'filters'),
    ),
  ).thenAnswer(
    (_) async => Right<Failure, List<CaseListItemModel>>([
      for (var i = 1; i <= 6; i++) _case('$i'),
    ]),
  );

  final prioritiesRepo = _MockCasePrioritiesRepo();
  when(
    () => prioritiesRepo.getCasePriorities(
      includeInactive: any(named: 'includeInactive'),
    ),
  ).thenAnswer(
    (_) async => Right<Failure, List<CasePriorityModel>>(const [
      CasePriorityModel(id: 'p1', nameAr: 'عادية', badgeVariant: 'info'),
    ]),
  );

  return MaterialApp(
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
        BlocProvider(create: (_) => CasesCubit(casesRepo)..getCases()),
        BlocProvider(
          create: (_) =>
              CasePrioritiesCubit(prioritiesRepo)..getCasePriorities(),
        ),
      ],
      child: const Scaffold(body: CasesListBody()),
    ),
  );
}

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() {
    registerFallbackValue(CaseFiltersModel.empty);
  });

  testWidgets('a phone shows one case per row', (tester) async {
    await _pumpAt(tester, const Size(360, 800));

    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a tablet tiles the cases instead of stretching one column', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(834, 1112));

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tablet grid puts cases side by side', (tester) async {
    await _pumpAt(tester, const Size(834, 1112));

    // Two cards sharing a row is the whole point — same vertical position,
    // different horizontal one.
    final first = tester.getTopLeft(find.text('مريض 1'));
    final second = tester.getTopLeft(find.text('مريض 2'));

    expect(second.dy, first.dy);
    expect(second.dx, isNot(first.dx));
  });

  testWidgets('the status strip stays on both shapes', (tester) async {
    await _pumpAt(tester, const Size(834, 1112));
    expect(find.text('الكل'), findsOneWidget);

    await _pumpAt(tester, const Size(360, 800));
    expect(find.text('الكل'), findsOneWidget);
  });
}

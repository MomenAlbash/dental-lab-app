import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/send_back_models.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/breakage_loss/breakage_loss_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/restoration_move_sheet.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dental_lab_app/features/stage_pay/data/repos/stage_pay_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

class _MockStagePayRepo extends Mock implements StagePayRepo {}

class _MockEmployeesRepo extends Mock implements EmployeesRepo {}

void main() {
  setUpAll(() => registerFallbackValue(const SendBackReason()));

  group('BreakageLossDraft', () {
    test('record-only needs nobody', () {
      expect(const BreakageLossDraft().problem, isNull);
    });

    test('touching somebody\'s pay needs a somebody', () {
      const draft = BreakageLossDraft(payImpact: LossPayImpact.voidStagePay);

      expect(draft.problem, isNotNull);
      expect(draft.copyWith(responsibleEmployeeId: 'e1').problem, isNull);
    });

    test('a deduction must be above zero', () {
      const draft = BreakageLossDraft(
        responsibleEmployeeId: 'e1',
        payImpact: LossPayImpact.deductAmount,
      );

      expect(draft.problem, isNotNull);
      expect(draft.copyWith(deductionAmount: 40).problem, isNull);
    });

    test('sends the amount only when deducting', () {
      const draft = BreakageLossDraft(
        responsibleEmployeeId: 'e1',
        payImpact: LossPayImpact.voidStagePay,
        deductionAmount: 40,
      );

      expect(draft.toJson()['deductionAmount'], 0);
      expect(draft.toJson()['payImpact'], 2);
    });
  });

  group('SendBackReason', () {
    test('only a breakage carries a loss', () {
      const fit = SendBackReason(
        category: FailureReasonCategory.fit,
        loss: BreakageLossDraft(payImpact: LossPayImpact.voidStagePay),
      );

      expect(fit.toJson(), {'failureCategory': 1});
      // An incomplete loss on a non-breakage is ignored, not blocking.
      expect(fit.problem, isNull);
    });

    test('a breakage sends its loss', () {
      const breakage = SendBackReason(category: FailureReasonCategory.breakage);

      final json = breakage.toJson();
      expect(json['failureCategory'], 4);
      expect((json['loss'] as Map)['payImpact'], 1);
    });

    test('no reason adds nothing to the body', () {
      expect(const SendBackReason().toJson(), isEmpty);
    });
  });

  test('a refused trying line carries its own reason', () {
    final json = const TryingRejectLine(
      restorationId: 'r1',
      stageId: 's1',
      reason: SendBackReason(category: FailureReasonCategory.breakage),
    ).toJson();

    expect(json['restorationId'], 'r1');
    expect(json['failureCategory'], 4);
    expect(json.containsKey('loss'), isTrue);
  });

  test('LossPreviewModel reads the lost work and whose it was', () {
    final preview = LossPreviewModel.fromJson({
      'lostWorkValue': 180,
      'lostEarnings': [
        {'id': 'x', 'employeeId': 'e2', 'employeeName': 'سامي', 'amount': 180},
      ],
    });

    expect(preview.lostWorkValue, 180);
    expect(preview.lostEarnings.single.employeeId, 'e2');
  });

  group('BreakageLossCubit', () {
    late _MockStagePayRepo stagePay;
    late _MockEmployeesRepo employees;

    setUp(() {
      stagePay = _MockStagePayRepo();
      employees = _MockEmployeesRepo();
      when(() => employees.getEmployees()).thenAnswer(
        (_) async => Right<Failure, List<EmployeeModel>>([
          EmployeeModel(id: 'e1', firstName: 'أحمد'),
          EmployeeModel(id: 'e2', firstName: 'سامي'),
        ]),
      );
    });

    Future<BreakageLossReady> load() async {
      final cubit = BreakageLossCubit(stagePay, employees);
      addTearDown(cubit.close);
      await cubit.load(caseId: 'c1', restorationId: 'r1', targetStageId: 's1');
      return cubit.state as BreakageLossReady;
    }

    test('puts whoever lost stage pay first', () async {
      when(
        () => stagePay.getLossPreview(
          caseId: 'c1',
          restorationId: 'r1',
          targetStageId: 's1',
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, LossPreviewModel>(
          LossPreviewModel(
            lostWorkValue: 100,
            lostEarnings: [
              EmployeeStageEarningModel(id: 'x', employeeId: 'e2'),
            ],
          ),
        ),
      );

      final state = await load();

      expect(state.orderedEmployees.map((e) => e.id), ['e2', 'e1']);
    });

    test('a failed preview still lets the breakage be recorded', () async {
      when(
        () => stagePay.getLossPreview(
          caseId: any(named: 'caseId'),
          restorationId: any(named: 'restorationId'),
          targetStageId: any(named: 'targetStageId'),
        ),
      ).thenAnswer(
        (_) async => Left<Failure, LossPreviewModel>(ServerFailure('down')),
      );

      final state = await load();

      expect(state.preview, isNull);
      expect(state.employees, hasLength(2));
    });
  });

  test('a send-back passes its reason through to the server', () async {
    final repo = _MockCasesRepo();
    when(() => repo.getCaseById('c1')).thenAnswer(
      (_) async => Right<Failure, CaseDetailModel>(CaseDetailModel(id: 'c1')),
    );
    when(
      () => repo.setRestorationStage(
        caseId: any(named: 'caseId'),
        restorationId: any(named: 'restorationId'),
        stageId: any(named: 'stageId'),
        note: any(named: 'note'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => const Right<Failure, void>(null));
    final cubit = CaseDetailsCubit(repo);
    addTearDown(cubit.close);
    await cubit.getCase('c1');

    await cubit.setRestorationStage(
      restorationId: 'r1',
      stageId: 's1',
      reason: const SendBackReason(category: FailureReasonCategory.breakage),
    );

    final sent =
        verify(
              () => repo.setRestorationStage(
                caseId: 'c1',
                restorationId: 'r1',
                stageId: 's1',
                note: null,
                reason: captureAny(named: 'reason'),
              ),
            ).captured.single
            as SendBackReason;
    expect(sent.category, FailureReasonCategory.breakage);
  });

  testWidgets(
    'a breakage on a small phone waits for who is responsible before a pay cut',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(getIt.reset);

      final cases = _MockCasesRepo();
      when(
        () => cases.getForwardTargets(caseId: 'c1', restorationId: 'r1'),
      ).thenAnswer(
        (_) async => const Right<Failure, List<CaseWorkflowStageModel>>([]),
      );
      when(
        () => cases.getReworkTargets(caseId: 'c1', restorationId: 'r1'),
      ).thenAnswer(
        (_) async => const Right<Failure, List<CaseWorkflowStageModel>>([
          CaseWorkflowStageModel(id: 's1', nameAr: 'التصميم'),
        ]),
      );
      final stagePay = _MockStagePayRepo();
      when(
        () => stagePay.getLossPreview(
          caseId: 'c1',
          restorationId: 'r1',
          targetStageId: 's1',
        ),
      ).thenAnswer(
        (_) async => const Right<Failure, LossPreviewModel>(
          LossPreviewModel(lostWorkValue: 120),
        ),
      );
      final employees = _MockEmployeesRepo();
      when(
        () => employees.getEmployees(),
      ).thenAnswer((_) async => const Right<Failure, List<EmployeeModel>>([]));
      getIt.registerSingleton<CasesRepo>(cases);
      getIt.registerFactory<BreakageLossCubit>(
        () => BreakageLossCubit(stagePay, employees),
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
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showRestorationMoveSheet(
                    context,
                    caseId: 'c1',
                    restorationId: 'r1',
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('التصميم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('كسر'));
      await tester.pumpAndSettle();

      expect(find.text('قيمة العمل الضائع: 120.00'), findsOneWidget);

      await tester.ensureVisible(find.text('إلغاء أجر المراحل المُعادة'));
      await tester.tap(find.text('إلغاء أجر المراحل المُعادة'));
      await tester.pumpAndSettle();

      expect(find.text('حدّد المسؤول عن الكسر'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

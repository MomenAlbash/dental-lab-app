import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/scan_task/scan_task_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/scan_task/scan_task_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

/// A case as an ADMIN sees it: the restoration's `currentStage` is expanded.
final _adminCase = CaseDetailModel.fromJson(const {
  'id': 'case-1',
  'caseNumber': 'C-100',
  'patientName': 'أحمد علي',
  'impressionMethod': 1,
  'restorations': [
    {
      'id': 'rest-1',
      'restorationTypeId': 'type-1',
      'restorationNumber': 'R-9',
      'currentStageId': 'stage-design',
      'currentStage': {'id': 'stage-design', 'nameAr': 'التصميم', 'order': 10},
    },
  ],
});

/// The same case as a NON-ADMIN employee sees it: the API omits the expanded
/// `currentStage`, leaving only the id. This is the shape the screen has to
/// survive, and the reason the route is read to put a name on the stage.
final _restrictedCase = CaseDetailModel.fromJson(const {
  'id': 'case-1',
  'caseNumber': 'C-100',
  'impressionMethod': 1,
  'restorations': [
    {
      'id': 'rest-1',
      'restorationTypeId': 'type-1',
      'restorationNumber': 'R-9',
      'currentStageId': 'stage-design',
    },
  ],
});

CaseWorkflowStageModel _stage(String id, String nameAr, int order) =>
    CaseWorkflowStageModel.fromJson({
      'id': id,
      'nameAr': nameAr,
      'order': order,
    });

void main() {
  late _MockCasesRepo repo;
  late ScanTaskCubit cubit;

  setUp(() {
    repo = _MockCasesRepo();
    cubit = ScanTaskCubit(repo);

    // A default so a test that never mentions the route still runs; the
    // tests that care about it stub their own answer over this one.
    when(
      () => repo.getRestorationRoute(
        restorationTypeId: any(named: 'restorationTypeId'),
      ),
    ).thenAnswer((_) async => right(<CaseWorkflowStageModel>[]));
  });

  tearDown(() => cubit.close());

  void stubRoute(List<CaseWorkflowStageModel> stages) {
    when(
      () => repo.getRestorationRoute(
        restorationTypeId: any(named: 'restorationTypeId'),
      ),
    ).thenAnswer((_) async => right(stages));
  }

  void stubNext(List<CaseWorkflowStageModel> stages) {
    when(
      () => repo.getNextRestorationStages(
        restorationTypeId: any(named: 'restorationTypeId'),
        currentStageId: any(named: 'currentStageId'),
        intake: any(named: 'intake'),
      ),
    ).thenAnswer((_) async => right(stages));
  }

  void stubMove({Failure? failure}) {
    when(
      () => repo.setRestorationStage(
        caseId: any(named: 'caseId'),
        restorationId: any(named: 'restorationId'),
        stageId: any(named: 'stageId'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => failure == null ? right(null) : left(failure));
  }

  test('an expanded stage is named without reading the route', () async {
    stubNext([_stage('stage-mill', 'الطحن', 20)]);

    await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');

    final state = cubit.state as ScanTaskReady;
    expect(state.currentStageName, 'التصميم');
    // The route lookup costs a request; it must not fire when the response
    // already carried the name.
    verifyNever(
      () => repo.getRestorationRoute(
        restorationTypeId: any(named: 'restorationTypeId'),
      ),
    );
  });

  test('a stage the API left unexpanded is named from the route', () async {
    // The whole reason the route is fetched: a non-admin employee never
    // receives `currentStage`, and a technician cannot act on a stage the
    // screen refuses to name.
    stubRoute([
      _stage('stage-design', 'التصميم', 10),
      _stage('stage-mill', 'الطحن', 20),
    ]);
    stubNext([_stage('stage-mill', 'الطحن', 20)]);

    await cubit.load(caseDetail: _restrictedCase, restorationId: 'rest-1');

    expect((cubit.state as ScanTaskReady).currentStageName, 'التصميم');
  });

  test('the next step is announced alongside the current stage', () async {
    stubNext([_stage('stage-mill', 'الطحن', 20)]);

    await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');

    final state = cubit.state as ScanTaskReady;
    expect(state.hasNextStep, isTrue);
    expect(state.nextStageLabel, 'الطحن');
  });

  test(
    'parallel next stages are announced together, not as a choice',
    () async {
      // Stages sharing an `order` are entered at once. Offering them as options
      // would invent a decision the workflow does not have.
      stubNext([
        _stage('stage-mill', 'الطحن', 20),
        _stage('stage-color', 'التلوين', 20),
      ]);

      await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');

      expect((cubit.state as ScanTaskReady).nextStageLabel, 'الطحن + التلوين');
    },
  );

  test('a piece at the end of its route is offered no move', () async {
    stubNext(const []);

    await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');

    final state = cubit.state as ScanTaskReady;
    expect(state.hasNextStep, isFalse);
    expect(state.isAtEndOfRoute, isTrue);
  });

  test('completing the stage moves the piece onto the next step', () async {
    stubNext([_stage('stage-mill', 'الطحن', 20)]);
    stubMove();

    await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');
    await cubit.completeStage(note: 'تم');

    expect((cubit.state as ScanTaskReady).isDone, isTrue);
    verify(
      () => repo.setRestorationStage(
        caseId: 'case-1',
        restorationId: 'rest-1',
        stageId: 'stage-mill',
        note: 'تم',
      ),
    ).called(1);
  });

  test(
    'a 403 reads as "not your stage", carrying the server\'s words',
    () async {
      // The API exposes no way to know beforehand whether a stage is this
      // person's. The refusal IS the answer, and it names the stage — so it is
      // shown as information, never as a failed action.
      stubNext([_stage('stage-mill', 'الطحن', 20)]);
      stubMove(
        failure: ServerFailure(
          'المرحلة "الطحن" غير مسندة إليك',
          statusCode: 403,
        ),
      );

      await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');
      await cubit.completeStage();

      final state = cubit.state;
      expect(state, isA<ScanTaskReady>());
      expect(
        (state as ScanTaskReady).refusal,
        'المرحلة "الطحن" غير مسندة إليك',
      );
      expect(state.isDone, isFalse);
      expect(state.isSubmitting, isFalse);
    },
  );

  test('a failure that is not a 403 stays a real error', () async {
    // Only the permission refusal is a normal outcome. A server fault shown
    // as a calm "not your stage" would send the user away from work that is
    // actually theirs.
    stubNext([_stage('stage-mill', 'الطحن', 20)]);
    stubMove(failure: ServerFailure('تعذّر الاتصال', statusCode: 500));

    await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');
    await cubit.completeStage();

    expect(cubit.state, isA<ScanTaskError>());
  });

  test('a scan naming a piece the case does not carry says so', () async {
    await cubit.load(caseDetail: _adminCase, restorationId: 'rest-missing');

    expect(cubit.state, isA<ScanTaskError>());
  });

  test('the move is refused locally when there is no next step', () async {
    stubNext(const []);
    stubMove();

    await cubit.load(caseDetail: _adminCase, restorationId: 'rest-1');
    await cubit.completeStage();

    verifyNever(
      () => repo.setRestorationStage(
        caseId: any(named: 'caseId'),
        restorationId: any(named: 'restorationId'),
        stageId: any(named: 'stageId'),
        note: any(named: 'note'),
      ),
    );
  });
}

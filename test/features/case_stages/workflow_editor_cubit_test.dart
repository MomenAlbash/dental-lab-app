import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/route_problem_model.dart';
import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_editor_cubit.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCaseStagesRepo extends Mock implements CaseStagesRepo {}

const _stages = [
  CaseStageModel(id: 's1', nameAr: 'الاستلام'),
  CaseStageModel(id: 's2', nameAr: 'التصميم'),
];

void main() {
  late _MockCaseStagesRepo repo;
  late WorkflowEditorCubit cubit;

  setUp(() {
    repo = _MockCaseStagesRepo();
    cubit = WorkflowEditorCubit(repo);
  });

  tearDown(() => cubit.close());

  test(
    'load merges the stage list with the server\'s own validation',
    () async {
      // The route validity check is server-side now — there is no local graph
      // engine to re-derive it from an edge table the API no longer sends.
      when(() => repo.getCaseStages()).thenAnswer((_) async => right(_stages));
      when(() => repo.validateWorkflow()).thenAnswer(
        (_) async => right(const [
          RouteProblemModel(
            messageAr: 'لا يمكن الوصول إلى "التصميم"',
            stageId: 's2',
          ),
        ]),
      );

      await cubit.load();

      final state = cubit.state as WorkflowEditorLoaded;
      expect(state.stages, _stages);
      expect(state.hasErrors, isTrue);
      expect(
        state.issuesFor('s2').single.message,
        'لا يمكن الوصول إلى "التصميم"',
      );
      expect(state.issuesFor('s1'), isEmpty);
    },
  );

  test(
    'a validation failure leaves the workflow unannotated, not broken',
    () async {
      // Secondary data: the editor must still open on the stage list even when
      // the validate call itself fails.
      when(() => repo.getCaseStages()).thenAnswer((_) async => right(_stages));
      when(
        () => repo.validateWorkflow(),
      ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

      await cubit.load();

      final state = cubit.state as WorkflowEditorLoaded;
      expect(state.stages, _stages);
      expect(state.issues, isEmpty);
    },
  );

  test(
    'a failed stage fetch reports the error and never opens the editor',
    () async {
      when(
        () => repo.getCaseStages(),
      ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

      await cubit.load();

      expect(cubit.state, isA<WorkflowEditorError>());
      verifyNever(() => repo.validateWorkflow());
    },
  );
}

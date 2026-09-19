import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/route_editor/route_editor_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/route_editor/route_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWorkflowStagesRepo extends Mock implements WorkflowStagesRepo {}

Map<String, dynamic> stage(String id, {int order = 0}) => {
  'id': id,
  'nameAr': id,
  'order': order,
  'isActive': true,
};

RouteDefinitionModel route({
  List<Map<String, dynamic>> stages = const [],
  List<Map<String, dynamic>> problems = const [],
  bool isValid = true,
}) => RouteDefinitionModel.fromJson({
  'restorationTypeId': 'rt1',
  'stages': stages,
  'problems': problems,
  'isValid': isValid,
});

void main() {
  group('RouteDefinitionModel', () {
    test('carries no transitions any more — the DTO dropped the field', () {
      // `PUT /routing/routes/transitions` answered 404 and `RouteDefinitionDto`
      // no longer declares the property at all: the flow is the stages' own
      // `order`, nothing else.
      final loaded = route(stages: [stage('a'), stage('b', order: 1)]);

      expect(loaded.stages, hasLength(2));
      expect(loaded.isValid, isTrue);
    });

    test('problems are grouped by the stage they belong to', () {
      final loaded = route(
        stages: [stage('a')],
        problems: [
          {'stageId': 'a', 'messageAr': 'مشكلة'},
        ],
        isValid: false,
      );

      expect(loaded.problemsFor('a'), hasLength(1));
      expect(loaded.problemsFor('b'), isEmpty);
      expect(loaded.isValid, isFalse);
    });
  });

  group('RouteEditorCubit', () {
    late MockWorkflowStagesRepo repo;
    late RouteEditorCubit cubit;

    setUp(() {
      repo = MockWorkflowStagesRepo();
      cubit = RouteEditorCubit(repo);
    });

    tearDown(() => cubit.close());

    test('emits loading then loaded on a successful fetch', () async {
      // The cubit used to hold a draft edge set and commit it on its own
      // save endpoint; both are gone along with the edge table itself. What
      // is left to fetch is only the stages and the server's live verdict.
      when(
        () => repo.getRouteDefinition('rt1'),
      ).thenAnswer((_) async => right(route(stages: [stage('a')])));

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([isA<RouteEditorLoading>(), isA<RouteEditorLoaded>()]),
      );

      await cubit.load('rt1');
      await expectation;

      final loaded = cubit.state as RouteEditorLoaded;
      expect(loaded.route.stages, hasLength(1));
    });

    test('a failed fetch reports the error', () async {
      when(
        () => repo.getRouteDefinition('rt1'),
      ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

      await cubit.load('rt1');

      expect(cubit.state, isA<RouteEditorError>());
      expect((cubit.state as RouteEditorError).message, 'لا يوجد اتصال');
    });
  });
}

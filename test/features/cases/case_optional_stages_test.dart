import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_optional_stages_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves a fixed answer so the step can be driven without the two repos.
class _StubOptionalStagesCubit extends Cubit<OptionalStagesState>
    implements OptionalStagesCubit {
  _StubOptionalStagesCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('CreateCaseRequestModel', () {
    test('carries the previous case only when one was linked', () {
      final remake = CreateCaseRequestModel(
        patientId: 'p1',
        previousCaseId: 'c-old',
      ).toJson();
      final fresh = CreateCaseRequestModel(patientId: 'p1').toJson();

      expect(remake['previousCaseId'], 'c-old');
      // Absent rather than null: the field means "this repeats that case", and
      // a null would be a link to nothing.
      expect(fresh.containsKey('previousCaseId'), isFalse);
    });

    test('always sends the optional-stage answers, empty included', () {
      // An empty list is a real answer — "none of them" — and the server
      // cannot tell it from "never asked" if the key is missing.
      final none = CreateCaseRequestModel(patientId: 'p1').toJson();
      final some = CreateCaseRequestModel(
        patientId: 'p1',
        selectedStageIds: const ['s1', 's2'],
      ).toJson();

      expect(none['selectedCaseStagesIds'], isEmpty);
      expect(some['selectedCaseStagesIds'], ['s1', 's2']);
    });
  });

  group('stage requests', () {
    test('a workflow stage can be saved as optional', () {
      final json = CreateWorkflowStageRequestModel(
        name: 'Try-in',
        restorationTypeId: 't1',
        isOptional: true,
      ).toJson();

      expect(json['isOptional'], isTrue);
    });

    test('a case stage can be saved as optional', () {
      final json = SaveCaseStageRequestModel(
        name: 'Try-in',
        isOptional: true,
      ).toJson();

      expect(json['isOptional'], isTrue);
    });

    test('stages are not optional unless said so', () {
      expect(
        CreateWorkflowStageRequestModel(
          name: 'Design',
          restorationTypeId: 't1',
        ).toJson()['isOptional'],
        isFalse,
      );
      expect(
        SaveCaseStageRequestModel(name: 'Design').toJson()['isOptional'],
        isFalse,
      );
    });
  });

  group('CaseOptionalStagesStep', () {
    Widget wrap(
      OptionalStagesState state,
      ValueChanged<Map<String, bool>> onChanged, {
      Map<String, bool> answers = const {},
    }) {
      return MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: BlocProvider<OptionalStagesCubit>.value(
            value: _StubOptionalStagesCubit(state),
            child: SingleChildScrollView(
              child: CaseOptionalStagesStep(
                answers: answers,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      );
    }

    const stages = [
      OptionalStage(id: 's1', name: 'التجربة', isCaseStage: false),
      OptionalStage(id: 's2', name: 'التصوير', isCaseStage: true),
    ];

    testWidgets('asks one question per optional stage', (tester) async {
      await tester.pumpWidget(
        wrap(
          const OptionalStagesState(stages: stages, hasLoaded: true),
          (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('هل تريد "التجربة"؟'), findsOneWidget);
      expect(find.text('هل تريد "التصوير"؟'), findsOneWidget);
      expect(find.text('نعم'), findsNWidgets(2));
    });

    testWidgets('answering yes records a yes', (tester) async {
      Map<String, bool>? reported;
      await tester.pumpWidget(
        wrap(
          const OptionalStagesState(stages: stages, hasLoaded: true),
          (answers) => reported = answers,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('نعم').first);
      await tester.pumpAndSettle();

      expect(reported, {'s1': true});
    });

    testWidgets('answering no records a no, not an absence', (tester) async {
      // The distinction the whole step turns on: "no" is an answer the user
      // gave, and it has to be told apart from a question they never reached.
      Map<String, bool>? reported;
      await tester.pumpWidget(
        wrap(
          const OptionalStagesState(stages: stages, hasLoaded: true),
          (answers) => reported = answers,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('لا').first);
      await tester.pumpAndSettle();

      expect(reported, {'s1': false});
    });

    testWidgets('says so when the lab defined none', (tester) async {
      await tester.pumpWidget(
        wrap(const OptionalStagesState(hasLoaded: true), (_) {}),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('لا توجد مراحل اختيارية لهذه التعويضات'),
        findsOneWidget,
      );
    });

    testWidgets('a failed load is admitted, not shown as "none"', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const OptionalStagesState(hasLoaded: true, hasFailure: true),
          (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('تعذّر'), findsOneWidget);
    });
  });
}

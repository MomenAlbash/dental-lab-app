import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/stage_assignees_field.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('case stage request', () {
    test('assigns people through userIds, not employeeIds', () {
      // The old key matched no field on `SaveCaseStatusRequest`, so assigning
      // a stage to a named person never reached the server.
      final json = const SaveCaseStageRequestModel(
        name: 'Design',
        departmentIds: ['d1'],
        userIds: ['u1'],
        excludedUserIds: ['u2'],
      ).toJson();

      expect(json['departmentIds'], ['d1']);
      expect(json['userIds'], ['u1']);
      expect(json['excludedUserIds'], ['u2']);
      expect(json.containsKey('employeeIds'), isFalse);
    });

    test('has no fields the API does not declare', () {
      // `isStart`/`isFinal`/`joinMode`/`placement` used to exist here and
      // save nothing — the API has no such columns. They are gone from the
      // model entirely now rather than merely dropped from `toJson`, so
      // there is nothing left to try to send.
      final json = const SaveCaseStageRequestModel(name: 'Design').toJson();

      expect(json['order'], 0);
    });
  });

  group('stage models read the field names the API sends', () {
    test('a case stage reads userIds and excludedUserIds', () {
      final stage = CaseStageModel.fromJson(const {
        'id': 's1',
        'departmentIds': ['d1'],
        'userIds': ['u1'],
        'excludedUserIds': ['u2'],
      });

      expect(stage.departmentIds, ['d1']);
      expect(stage.userIds, ['u1']);
      expect(stage.excludedUserIds, ['u2']);
    });

    test('a restoration stage reads users and excludedUsers', () {
      final stage = CaseWorkflowStageModel.fromJson(const {
        'id': 's1',
        'users': [
          {'id': 'u1', 'name': 'Sara'},
        ],
        'excludedUsers': [
          {'id': 'u2', 'name': 'Omar'},
        ],
      });

      expect(stage.users.single.id, 'u1');
      expect(stage.excludedUsers.single.id, 'u2');
    });
  });

  group('StageAssigneesField', () {
    Widget wrap(Widget child) => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    );

    testWidgets('an unassigned stage says so instead of looking filled', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          StageAssigneesField(
            assignees: (
              departmentIds: const [],
              userIds: const [],
              excludedUserIds: const [],
            ),
            onEdit: () {},
          ),
        ),
      );

      expect(find.text('لم يُسنَد لأحد بعد'), findsOneWidget);
    });

    testWidgets('counts each pool separately', (tester) async {
      await tester.pumpWidget(
        wrap(
          StageAssigneesField(
            assignees: (
              departmentIds: const ['d1', 'd2'],
              userIds: const ['u1'],
              excludedUserIds: const ['u2'],
            ),
            onEdit: () {},
          ),
        ),
      );

      expect(find.text('2 قسم • 1 شخص • 1 مستثنى'), findsOneWidget);
    });

    testWidgets('tapping it opens the picker', (tester) async {
      var opened = false;
      await tester.pumpWidget(
        wrap(
          StageAssigneesField(
            assignees: (
              departmentIds: const [],
              userIds: const [],
              excludedUserIds: const [],
            ),
            onEdit: () => opened = true,
          ),
        ),
      );

      await tester.tap(find.byType(StageAssigneesField));
      await tester.pumpAndSettle();

      expect(opened, isTrue);
    });
  });

  group('restoration stage request', () {
    test('assigns people through userIds', () {
      final json = const CreateWorkflowStageRequestModel(
        name: 'Design',
        restorationTypeId: 't1',
        departmentIds: ['d1'],
        userIds: ['u1'],
        excludedUserIds: ['u2'],
      ).toJson();

      expect(json['departmentIds'], ['d1']);
      expect(json['userIds'], ['u1']);
      expect(json['excludedUserIds'], ['u2']);
      expect(json.containsKey('employeeIds'), isFalse);
    });
  });
}

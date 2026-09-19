import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CaseWorkflowStageModel', () {
    test('parses the intake gate and the flags', () {
      final stage = CaseWorkflowStageModel.fromJson(const {
        'id': 's1',
        'nameAr': 'التصميم',
        'name': 'Design',
        'key': 'design',
        'order': 2,
        'isCheckpoint': true,
        'isExternal': true,
        'appliesTo': 3,
      });

      expect(stage.displayName, 'التصميم');
      expect(stage.key, 'design');
      expect(stage.isCheckpoint, isTrue);
      expect(stage.isExternal, isTrue);
      expect(stage.appliesTo, RouteStageAppliesTo.digitalOnly);
    });

    test('a digital-only stage is pruned from a traditional case', () {
      final stage = CaseWorkflowStageModel.fromJson(const {
        'id': 's1',
        'appliesTo': 3,
      });

      expect(stage.appliesToIntake(ImpressionMethod.digital), isTrue);
      expect(stage.appliesToIntake(ImpressionMethod.traditional), isFalse);
    });

    test('parses the version-history fields', () {
      // Editing a stage that live restorations already point at forks it
      // rather than mutating in place — this is the number a save should
      // warn with before that happens.
      final stage = CaseWorkflowStageModel.fromJson(const {
        'id': 's2',
        'rootStageId': 'root1',
        'version': 3,
        'restorationCount': 5,
        'restorationsOnThisVersion': 2,
        'effectiveFrom': '2026-01-01T00:00:00.000Z',
        'effectiveTo': '2026-02-01T00:00:00.000Z',
      });

      expect(stage.rootStageId, 'root1');
      expect(stage.version, 3);
      expect(stage.restorationCount, 5);
      expect(stage.restorationsOnThisVersion, 2);
      expect(stage.effectiveFrom, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(stage.effectiveTo, DateTime.parse('2026-02-01T00:00:00.000Z'));
    });

    test('a version with no fork defaults to 1 and stays open-ended', () {
      final stage = CaseWorkflowStageModel.fromJson(const {'id': 's1'});

      expect(stage.version, 1);
      expect(stage.effectiveTo, isNull);
    });

    test('departments and employees are separate additive pools', () {
      final stage = CaseWorkflowStageModel.fromJson(const {
        'id': 's1',
        'departments': [
          {'id': 'd1', 'nameAr': 'الكونترول', 'isPrimary': true},
        ],
        'users': [
          {'id': 'e1', 'name': 'Sara'},
        ],
        'excludedUsers': [
          {'id': 'e2', 'name': 'Omar'},
        ],
      });

      // "Control, plus Sara" is one entry in each list, not a merged column.
      expect(stage.departments.single.label, 'الكونترول');
      expect(stage.departments.single.isPrimary, isTrue);
      // Read from `users`/`excludedUsers` — the names the API actually uses.
      expect(stage.users.single.label, 'Sara');
      expect(stage.excludedUsers.single.label, 'Omar');
    });
  });

  group('CreateWorkflowStageRequestModel', () {
    test('sends the numeric intake and the required type', () {
      final json = const CreateWorkflowStageRequestModel(
        name: 'Design',
        restorationTypeId: 'rt1',
        appliesTo: RouteStageAppliesTo.traditionalOnly,
      ).toJson();

      expect(json['restorationTypeId'], 'rt1');
      expect(json['appliesTo'], 2);
    });

    test('has no fields the API does not declare', () {
      // `isStart`, `isFinal`, `joinMode`, `assigneePolicy`,
      // `defaultAssigneeUserId` and `requiredOptionId` are gone from the
      // model entirely — the route is ordered by `order` alone, and per-stage
      // durations moved to the restoration type.
      final json = const CreateWorkflowStageRequestModel(
        name: 'Design',
        restorationTypeId: 'rt1',
      ).toJson();

      for (final key in const [
        'isStart',
        'isFinal',
        'joinMode',
        'assigneePolicy',
        'defaultAssigneeUserId',
        'requiredOptionId',
        'durations',
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
    });

    test('assigns people through userIds, not employeeIds', () {
      final json = const CreateWorkflowStageRequestModel(
        name: 'Design',
        restorationTypeId: 'rt1',
        userIds: ['u1'],
        excludedUserIds: ['u2'],
      ).toJson();

      expect(json['userIds'], ['u1']);
      expect(json['excludedUserIds'], ['u2']);
      expect(json.containsKey('employeeIds'), isFalse);
    });

    test('refuses a stage with no restoration type', () {
      expect(
        () => CreateWorkflowStageRequestModel(name: 'X', restorationTypeId: ''),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('UpdateWorkflowStageRequestModel', () {
    test('omits untouched fields so they are left alone', () {
      final json = const UpdateWorkflowStageRequestModel(
        name: 'Design',
      ).toJson();

      expect(json['name'], 'Design');
      expect(json.containsKey('isFinal'), isFalse);
      expect(json.containsKey('sendBackToStageId'), isFalse);
      expect(json.containsKey('nextStageId'), isFalse);
    });

    test('has no fields the API does not declare', () {
      final json = const UpdateWorkflowStageRequestModel(
        clearSendBackTo: true,
      ).toJson();

      for (final key in const [
        'isStart',
        'isFinal',
        'joinMode',
        'assigneePolicy',
        'requiredOptionId',
        'clearRequiredOption',
        'defaultAssigneeUserId',
        'clearDefaultAssignee',
        'durations',
      ]) {
        expect(json.containsKey(key), isFalse, reason: key);
      }
    });

    test('clears a link only when the flag says so', () {
      // An omitted `sendBackToStageId`/`nextStageId` means "leave alone" —
      // removing a link the lab already drew needs the explicit clear flag,
      // since a plain null cannot tell the two apart. The flag itself is
      // always sent, defaulting to false, so "leave it" is the honest default
      // rather than a silently-missing key.
      final untouched = const UpdateWorkflowStageRequestModel().toJson();
      expect(untouched['clearSendBackTo'], isFalse);
      expect(untouched['clearNextStage'], isFalse);

      final cleared = const UpdateWorkflowStageRequestModel(
        clearSendBackTo: true,
        clearNextStage: true,
      ).toJson();
      expect(cleared['clearSendBackTo'], isTrue);
      expect(cleared['clearNextStage'], isTrue);
    });

    test('a sent-but-empty pool means nobody, not "leave alone"', () {
      final json = const UpdateWorkflowStageRequestModel(
        departmentIds: [],
      ).toJson();

      expect(json.containsKey('departmentIds'), isTrue);
      expect(json['departmentIds'], isEmpty);
    });
  });
}

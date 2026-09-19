import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateWorkflowStageRequestModel', () {
    test('carries the rework target and the forward override', () {
      final json = CreateWorkflowStageRequestModel(
        name: 'Glazing',
        restorationTypeId: 'rt1',
        sendBackToStageId: 'earlier',
        nextStageId: 'later',
      ).toJson();

      expect(json['sendBackToStageId'], 'earlier');
      expect(json['nextStageId'], 'later');
    });

    test('sends explicit nulls so a link can be left undeclared', () {
      // Undeclared is meaningful here: the server then offers every earlier
      // stage as a rework target instead of a single declared one.
      final json = CreateWorkflowStageRequestModel(
        name: 'Glazing',
        restorationTypeId: 'rt1',
      ).toJson();

      expect(json.containsKey('sendBackToStageId'), isTrue);
      expect(json['sendBackToStageId'], isNull);
      expect(json['nextStageId'], isNull);
    });
  });

  group('UpdateWorkflowStageRequestModel', () {
    test('clearing the rework target has to be said out loud', () {
      // An omitted field reads as "leave alone" on this endpoint, so removing
      // a declared target needs its own flag.
      final json = const UpdateWorkflowStageRequestModel().toJson();

      expect(json['clearSendBackTo'], isFalse);
      expect(json.containsKey('sendBackToStageId'), isFalse);

      final cleared = const UpdateWorkflowStageRequestModel(
        clearSendBackTo: true,
      ).toJson();
      expect(cleared['clearSendBackTo'], isTrue);
    });
  });

  group('CaseWorkflowStageModel', () {
    test('reads both links back', () {
      final stage = CaseWorkflowStageModel.fromJson(const {
        'id': 's1',
        'nameAr': 'التزجيج',
        'sendBackToStageId': 'earlier',
        'nextStageId': 'later',
      });

      expect(stage.sendBackToStageId, 'earlier');
      expect(stage.nextStageId, 'later');
    });
  });
}

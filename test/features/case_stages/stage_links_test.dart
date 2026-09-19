import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveCaseStageRequestModel', () {
    test('carries the rework target and the forward override', () {
      final json = SaveCaseStageRequestModel(
        name: 'Control',
        sendBackToStageId: 'earlier',
        nextStageId: 'later',
      ).toJson();

      expect(json['sendBackToStageId'], 'earlier');
      expect(json['nextStageId'], 'later');
    });

    test('sends an explicit null so a declared link can be removed', () {
      // An omitted key reads as "leave alone" on this endpoint, which would
      // make a rework path impossible to undo once drawn.
      final json = SaveCaseStageRequestModel(name: 'Control').toJson();

      expect(json.containsKey('sendBackToStageId'), isTrue);
      expect(json['sendBackToStageId'], isNull);
      expect(json.containsKey('nextStageId'), isTrue);
      expect(json['nextStageId'], isNull);
    });
  });

  group('CaseStageModel', () {
    test('reads both links back', () {
      final stage = CaseStageModel.fromJson(const {
        'id': 's1',
        'nameAr': 'كونترول',
        'sendBackToStageId': 'earlier',
        'nextStageId': 'later',
      });

      expect(stage.sendBackToStageId, 'earlier');
      expect(stage.nextStageId, 'later');
    });

    test('an undeclared link is null, not an empty string', () {
      // Null is what tells the server "offer every earlier stage instead".
      final stage = CaseStageModel.fromJson(const {'id': 's1'});

      expect(stage.sendBackToStageId, isNull);
      expect(stage.nextStageId, isNull);
    });
  });
}

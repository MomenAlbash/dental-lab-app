import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wire values', () {
    test('ImpressionMethod matches the API', () {
      expect(ImpressionMethod.traditional.value, 1);
      expect(ImpressionMethod.digital.value, 2);
    });

    test('DigitalScanSource matches the API', () {
      expect(DigitalScanSource.doctor.value, 1);
      expect(DigitalScanSource.labScannerSession.value, 2);
    });

    test(
      'RouteStageAppliesTo is 1/2/3, not the 0/1/2 the spec document says',
      () {
        // The MD lists `Any 0 · Traditional 1 · Digital 2`. The live API says
        // otherwise, and following the document would shift every stage by one —
        // digital-only stages would be cut onto traditional cases.
        expect(RouteStageAppliesTo.any.value, 1);
        expect(RouteStageAppliesTo.traditionalOnly.value, 2);
        expect(RouteStageAppliesTo.digitalOnly.value, 3);
      },
    );

    test('CaseOptionScope matches the API', () {
      expect(CaseOptionScope.perCase.value, 1);
      expect(CaseOptionScope.perRestoration.value, 2);
    });
  });

  group('RouteStageAppliesTo.appliesTo', () {
    test('an unconditional stage is cut onto either intake', () {
      expect(
        RouteStageAppliesTo.any.appliesTo(ImpressionMethod.traditional),
        isTrue,
      );
      expect(
        RouteStageAppliesTo.any.appliesTo(ImpressionMethod.digital),
        isTrue,
      );
      expect(RouteStageAppliesTo.any.appliesTo(null), isTrue);
    });

    test('a traditional-only stage is pruned from a digital case', () {
      expect(
        RouteStageAppliesTo.traditionalOnly.appliesTo(ImpressionMethod.digital),
        isFalse,
      );
      expect(
        RouteStageAppliesTo.traditionalOnly.appliesTo(
          ImpressionMethod.traditional,
        ),
        isTrue,
      );
    });

    test('a digital-only stage is pruned from a traditional case', () {
      expect(
        RouteStageAppliesTo.digitalOnly.appliesTo(ImpressionMethod.traditional),
        isFalse,
      );
      expect(
        RouteStageAppliesTo.digitalOnly.appliesTo(ImpressionMethod.digital),
        isTrue,
      );
    });

    test('an unknown flag falls back to "any" rather than pruning a stage', () {
      // Showing a stage that should not be there is recoverable; silently
      // dropping a required one is not.
      expect(RouteStageAppliesTo.fromValue(99), RouteStageAppliesTo.any);
      expect(RouteStageAppliesTo.fromValue(null), RouteStageAppliesTo.any);
    });
  });

  group('CreateCaseRequestModel', () {
    test('sends the intake when it was chosen', () {
      final json = CreateCaseRequestModel(
        patientId: 'p1',
        impressionMethod: ImpressionMethod.digital,
        digitalScanSource: DigitalScanSource.labScannerSession,
      ).toJson();

      expect(json['impressionMethod'], 2);
      expect(json['digitalScanSource'], 2);
    });

    test('omits the intake keys entirely when it was not chosen', () {
      final json = CreateCaseRequestModel(patientId: 'p1').toJson();

      // Omitted, not null: the server keeps its own default, and null is not a
      // member of either enum.
      expect(json.containsKey('impressionMethod'), isFalse);
      expect(json.containsKey('digitalScanSource'), isFalse);
    });

    test('refuses a scan source on a traditional intake', () {
      expect(
        () => CreateCaseRequestModel(
          patientId: 'p1',
          impressionMethod: ImpressionMethod.traditional,
          digitalScanSource: DigitalScanSource.doctor,
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
  group('optional stages on the wire', () {
    // The API keeps the two lists apart: a case's own optional stages are the
    // request's `selectedCaseStagesIds`, a route's ride on the restoration
    // that runs them. Sending either in the other's place is dropped without
    // complaint, so the split is worth pinning down.
    test('a case stage answer goes out as selectedCaseStagesIds', () {
      final json = CreateCaseRequestModel(
        patientId: 'p1',
        selectedStageIds: const ['cs1', 'cs2'],
      ).toJson();

      expect(json['selectedCaseStagesIds'], ['cs1', 'cs2']);
      // The name it used to be sent under has no member on the request, which
      // is why every optional case stage was silently ignored.
      expect(json.containsKey('selectedStageIds'), isFalse);
    });

    test('a route stage answer rides on its own restoration', () {
      final json = CaseRestorationRequestModel(
        restorationTypeId: 'rt1',
        restorationTypeStageIds: const ['rs1'],
      ).toJson();

      expect(json['restorationTypeStageIds'], ['rs1']);
    });

    test('always sent, empty included', () {
      // An empty list is a real answer — "none of them" — and the server
      // cannot tell it from "never asked" if the key is missing.
      final caseJson = CreateCaseRequestModel(patientId: 'p1').toJson();
      final restorationJson = CaseRestorationRequestModel(
        restorationTypeId: 'rt1',
      ).toJson();

      expect(caseJson['selectedCaseStagesIds'], isEmpty);
      expect(restorationJson['restorationTypeStageIds'], isEmpty);
    });
  });
}

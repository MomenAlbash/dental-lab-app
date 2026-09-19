import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_enums.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_request_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wire values', () {
    test('ScannerSessionStatus matches the API', () {
      expect(ScannerSessionStatus.requested.value, 1);
      expect(ScannerSessionStatus.scheduled.value, 2);
      expect(ScannerSessionStatus.awaitingDoctorCompletion.value, 3);
      expect(ScannerSessionStatus.completed.value, 4);
      expect(ScannerSessionStatus.cancelled.value, 5);
      expect(ScannerSessionStatus.noShow.value, 6);
    });

    test('RepresentativeResponse matches the API', () {
      expect(RepresentativeResponse.pending.value, 1);
      expect(RepresentativeResponse.accepted.value, 2);
      expect(RepresentativeResponse.declined.value, 3);
    });

    test('ScannerReviewStatus matches the API', () {
      expect(ScannerReviewStatus.pendingReview.value, 1);
      expect(ScannerReviewStatus.approved.value, 2);
      expect(ScannerReviewStatus.redoRequested.value, 3);
    });
  });

  group('ScannerSessionStatus.isOpen', () {
    test('a session still expected to happen is open', () {
      expect(ScannerSessionStatus.requested.isOpen, isTrue);
      expect(ScannerSessionStatus.scheduled.isOpen, isTrue);
      expect(ScannerSessionStatus.awaitingDoctorCompletion.isOpen, isTrue);
    });

    test('finished and abandoned sessions are not', () {
      expect(ScannerSessionStatus.completed.isOpen, isFalse);
      expect(ScannerSessionStatus.cancelled.isOpen, isFalse);
      expect(ScannerSessionStatus.noShow.isOpen, isFalse);
    });
  });

  group('needsAttention', () {
    ScannerSessionModel session({
      int status = 2,
      String? assignedId,
      int? response,
    }) => ScannerSessionModel.fromJson({
      'id': 's1',
      'status': status,
      'assignedRepresentativeId': ?assignedId,
      'representativeResponse': ?response,
    });

    test('an open session with nobody assigned needs a dispatcher', () {
      expect(session().needsAttention, isTrue);
    });

    test('an open session whose representative declined needs one too', () {
      expect(session(assignedId: 'e1', response: 3).needsAttention, isTrue);
    });

    test('an accepted assignment does not', () {
      expect(session(assignedId: 'e1', response: 2).needsAttention, isFalse);
    });

    test('a pending answer is not yet a problem', () {
      expect(session(assignedId: 'e1', response: 1).needsAttention, isFalse);
    });

    test('a completed session never needs attention, assigned or not', () {
      // Chasing a session that already happened is noise on the board.
      expect(session(status: 4).needsAttention, isFalse);
      expect(session(status: 5).needsAttention, isFalse);
    });
  });

  group('coordinates', () {
    ScannerSessionModel at(double? lat, double? lng) =>
        ScannerSessionModel.fromJson({
          'id': 's1',
          'doctorLatitude': ?lat,
          'doctorLongitude': ?lng,
        });

    test('reads a real pair', () {
      expect(at(33.5, 36.3).coordinates, isNotNull);
      expect(at(33.5, 36.3).coordinates?.latitude, 33.5);
    });

    test('treats (0,0) as no location, not the Gulf of Guinea', () {
      expect(at(0, 0).coordinates, isNull);
    });

    test('needs both halves', () {
      expect(at(33.5, null).coordinates, isNull);
      expect(at(null, 36.3).coordinates, isNull);
    });
  });

  group('AssignRepresentativeRequestModel', () {
    test('always sends the key, so a null asks the server to auto-pick', () {
      // Not "unassign" — the endpoint has no such thing. A null representative
      // id tells the server to choose one itself (zone first, then whoever is
      // free and not vetoed), so the key must always be present.
      final json = const AssignRepresentativeRequestModel().toJson();

      expect(json.containsKey('representativeUserId'), isTrue);
      expect(json['representativeUserId'], isNull);
    });

    test('trims the note and drops a blank one', () {
      expect(
        const AssignRepresentativeRequestModel(
          representativeUserId: 'u1',
          note: '  عاجل  ',
        ).toJson(),
        {'representativeUserId': 'u1', 'note': 'عاجل'},
      );
      expect(
        const AssignRepresentativeRequestModel(
          representativeUserId: 'u1',
          note: '   ',
        ).toJson().containsKey('note'),
        isFalse,
      );
    });
  });

  group('SetScannerSessionStatusRequestModel', () {
    test('sends the numeric status', () {
      expect(
        const SetScannerSessionStatusRequestModel(
          status: ScannerSessionStatus.noShow,
        ).toJson(),
        {'status': 6},
      );
    });
  });
}

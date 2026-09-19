import 'package:dental_lab_app/features/excel_import/data/models/import_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImportEntityType', () {
    test('every entity has a wire value and a label', () {
      for (final type in ImportEntityType.values) {
        expect(type.wireValue, isNotEmpty);
        expect(type.label, isNotEmpty);
      }
    });

    test('matches the value the server echoes back, whatever its casing', () {
      // The path is written by hand, so the server may echo it differently.
      expect(ImportEntityType.fromWire('Doctors'), ImportEntityType.doctors);
      expect(ImportEntityType.fromWire('doctors'), ImportEntityType.doctors);
      expect(ImportEntityType.fromWire(' PATIENTS '), ImportEntityType.patients);
    });

    test('an entity this client does not know degrades to null', () {
      expect(ImportEntityType.fromWire('suppliers'), isNull);
      expect(ImportEntityType.fromWire(null), isNull);
      expect(ImportEntityType.fromWire(''), isNull);
    });
  });

  group('ImportSessionModel', () {
    test('a run with no completion time is still running', () {
      final session = ImportSessionModel.fromJson(const {
        'sessionId': 's1',
        'totalRows': 100,
        'processedRows': 40,
      });

      expect(session.isRunning, isTrue);
      expect(session.isFinished, isFalse);
      expect(session.progress, 0.4);
    });

    test('completion is read from completedAt, not from the status string', () {
      // `status` is an untyped free string this client must not pretend to
      // understand — a run with a completion time is over, whatever it is
      // called.
      final session = ImportSessionModel.fromJson(const {
        'sessionId': 's1',
        'status': 'SomethingUnexpected',
        'completedAt': '2026-09-12T10:00:00Z',
      });

      expect(session.isFinished, isTrue);
      expect(session.isRunning, isFalse);
    });

    test('the raw status is carried through for display', () {
      final session = ImportSessionModel.fromJson(const {
        'status': 'Processing',
      });

      expect(session.status, 'Processing');
    });

    test('an unknown total reports zero progress, never a division', () {
      final session = ImportSessionModel.fromJson(const {
        'processedRows': 5,
        'totalRows': 0,
      });

      expect(session.progress, 0);
    });

    test('progress is clamped when processed overshoots the total', () {
      final session = ImportSessionModel.fromJson(const {
        'processedRows': 120,
        'totalRows': 100,
      });

      expect(session.progress, 1.0);
    });

    test('a whole-run failure is distinct from failed rows', () {
      final failed = ImportSessionModel.fromJson(const {
        'failureReason': 'الملف غير صالح',
      });
      final partial = ImportSessionModel.fromJson(const {
        'successCount': 40,
        'failureCount': 7,
        'completedAt': '2026-09-12T10:00:00Z',
      });

      expect(failed.didFail, isTrue);
      // Nothing was imported, so it is not "running" either.
      expect(failed.isRunning, isFalse);

      expect(partial.didFail, isFalse);
      expect(partial.successCount, 40);
      expect(partial.failureCount, 7);
    });

    test('row errors keep their row numbers, which is the point', () {
      final session = ImportSessionModel.fromJson(const {
        'errors': [
          {'rowNumber': 12, 'message': 'رقم الهاتف مكرر'},
          {'rowNumber': 19, 'message': 'الاسم فارغ'},
        ],
      });

      expect(session.errors, hasLength(2));
      expect(session.errors.first.rowNumber, 12);
      expect(session.errors.first.displayMessage, 'رقم الهاتف مكرر');
    });

    test('an error with no message still reads as something', () {
      final error = ImportRowErrorModel.fromJson(const {'rowNumber': 3});

      expect(error.displayMessage, 'خطأ غير محدد');
    });

    test('the entity label falls back to the raw string when unknown', () {
      final known = ImportSessionModel.fromJson(const {
        'entityType': 'doctors',
      });
      final unknown = ImportSessionModel.fromJson(const {
        'entityType': 'suppliers',
      });

      expect(known.entityLabel, 'الأطباء');
      // A history row for an entity this client does not know still says what
      // it was.
      expect(unknown.entityLabel, 'suppliers');
    });

    test('a nameless file shows a dash rather than an empty row', () {
      final session = ImportSessionModel.fromJson(const {'sessionId': 's1'});

      expect(session.displayFileName, '—');
    });
  });
}

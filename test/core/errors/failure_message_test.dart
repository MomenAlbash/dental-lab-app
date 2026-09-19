import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ServerFailure.fromResponse', () {
    test('shows the server\'s own message on a 409', () {
      // The reason for a conflict is the one thing the user needs; a generic
      // "there was an error" makes the rejection unactionable.
      final failure = ServerFailure.fromResponse(409, const {
        'message': 'المرحلة مرتبطة بقسم آخر',
      });

      expect(failure.errorMessage, 'المرحلة مرتبطة بقسم آخر');
    });

    test('reads a ProblemDetails body', () {
      final failure = ServerFailure.fromResponse(400, const {
        'title': 'One or more validation errors occurred.',
        'errors': {
          'name': ['The Name field is required.'],
        },
      });

      // `title` wins over the field map: it is the sentence, not a fragment.
      expect(failure.errorMessage, 'One or more validation errors occurred.');
    });

    test('falls back to the field errors when there is no title', () {
      final failure = ServerFailure.fromResponse(400, const {
        'errors': {
          'name': ['الاسم مطلوب'],
          'parentId': ['قسم غير موجود'],
        },
      });

      expect(failure.errorMessage, contains('الاسم مطلوب'));
      expect(failure.errorMessage, contains('قسم غير موجود'));
    });

    test('accepts a plain string body', () {
      final failure = ServerFailure.fromResponse(409, 'Duplicate name');

      expect(failure.errorMessage, 'Duplicate name');
    });

    test('names the status rather than throwing on an unreadable body', () {
      // A `Response` object used to be passed here, which has no `operator []`
      // — every 400/401/403/409 threw a NoSuchMethodError instead of showing
      // the reason.
      final failure = ServerFailure.fromResponse(409, null);

      expect(failure.errorMessage, isNotEmpty);
    });

    test('an empty message does not produce an empty toast', () {
      final failure = ServerFailure.fromResponse(403, const {'message': '  '});

      expect(failure.errorMessage.trim(), isNotEmpty);
    });
  });
}

import 'package:dental_lab_app/features/notifications/data/models/notification_page_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPageModel.fromJson', () {
    test('reads the envelope the backend documents elsewhere', () {
      final page = NotificationPageModel.fromJson(const {
        'items': [
          {'id': 'n1', 'title': 'جاهز'},
          {'id': 'n2', 'title': 'متأخر'},
        ],
        'page': 2,
        'pageSize': 30,
        'totalCount': 70,
        'totalPages': 3,
      });

      expect(page.items, hasLength(2));
      expect(page.page, 2);
      expect(page.hasMore, isTrue);
    });

    test('the last page has no more', () {
      final page = NotificationPageModel.fromJson(const {
        'items': [],
        'page': 3,
        'totalPages': 3,
      });

      expect(page.hasMore, isFalse);
    });

    test('an unreadable envelope degrades to one page, never throws', () {
      // The endpoint declares no schema, so a differently-named envelope is a
      // real possibility. It must show what it can rather than error.
      final page = NotificationPageModel.fromJson(const {
        'data': [
          {'id': 'n1'},
        ],
        'total': 70,
      });

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('NotificationPageModel.fromList', () {
    test('a bare list is one complete page', () {
      final page = NotificationPageModel.fromList(const [
        {'id': 'n1'},
        {'id': 'n2'},
      ]);

      expect(page.items, hasLength(2));
      expect(page.totalCount, 2);
      expect(page.totalPages, 1);
      // Nothing to scroll for — offering a next page would spin forever.
      expect(page.hasMore, isFalse);
    });

    test('an empty list is still a valid page', () {
      final page = NotificationPageModel.fromList(const []);

      expect(page.items, isEmpty);
      expect(page.hasMore, isFalse);
    });
  });

  group('BroadcastAudience', () {
    test('every wire value maps to a labelled audience', () {
      for (final audience in BroadcastAudience.values) {
        expect(BroadcastAudience.fromValue(audience.value), audience);
        expect(audience.label, isNotEmpty);
      }
    });

    test('an unknown value degrades to null rather than a wrong audience', () {
      expect(BroadcastAudience.fromValue(9), isNull);
    });
  });

  group('BroadcastNotificationRequestModel', () {
    test('a blanket audience drops any user selection left behind', () {
      // A half-finished selection must not silently narrow a message meant
      // for everybody.
      final json = const BroadcastNotificationRequestModel(
        audience: BroadcastAudience.employees,
        title: 'صيانة',
        body: 'المخبر مسكّر بكرا',
        userIds: ['u1', 'u2'],
      ).toJson();

      expect(json['userIds'], isEmpty);
      expect(json['audience'], 1);
    });

    test('a specific-user broadcast carries its recipients', () {
      final json = const BroadcastNotificationRequestModel(
        audience: BroadcastAudience.specificUsers,
        title: 'تنبيه',
        body: 'راجع الطلب',
        userIds: ['u1'],
      ).toJson();

      expect(json['userIds'], ['u1']);
      expect(json['audience'], 3);
    });

    test('specific users with nobody chosen is not sendable', () {
      const request = BroadcastNotificationRequestModel(
        audience: BroadcastAudience.specificUsers,
        title: 'تنبيه',
        body: 'راجع الطلب',
      );

      expect(request.isValid, isFalse);
    });

    test('a blanket audience needs no recipients to be sendable', () {
      const request = BroadcastNotificationRequestModel(
        audience: BroadcastAudience.doctors,
        title: 'تنبيه',
        body: 'راجع الطلب',
      );

      expect(request.isValid, isTrue);
    });

    test('a whitespace-only title is not a title', () {
      const request = BroadcastNotificationRequestModel(
        audience: BroadcastAudience.employees,
        title: '   ',
        body: 'نص',
      );

      expect(request.isValid, isFalse);
    });

    test('an empty body is not sendable', () {
      const request = BroadcastNotificationRequestModel(
        audience: BroadcastAudience.employees,
        title: 'عنوان',
        body: '',
      );

      expect(request.isValid, isFalse);
    });
  });
}

import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationModel.fromJson', () {
    test('reads the confirmed payload field names', () {
      // Exact keys from a real `GET /Notifications` payload — see the
      // model's own doc comment. No multi-key guessing any more.
      final notification = NotificationModel.fromJson(const {
        'id': 'n1',
        'type': 1,
        'title': 'حالة جديدة',
        'body': 'تم استلام حالة جديدة',
        'relatedEntityId': 'case-1',
        'isRead': true,
        'createdAt': '2026-08-01T10:12:33.000Z',
      });

      expect(notification.id, 'n1');
      expect(notification.type, NotificationType.caseType);
      expect(notification.title, 'حالة جديدة');
      expect(notification.message, 'تم استلام حالة جديدة');
      expect(notification.relatedEntityId, 'case-1');
      expect(notification.isRead, isTrue);
      expect(
        notification.createdAt,
        DateTime.parse('2026-08-01T10:12:33.000Z'),
      );
    });

    test('an unknown type value reads as null rather than throwing', () {
      final notification = NotificationModel.fromJson(const {
        'id': 'n2',
        'type': 99,
      });

      expect(notification.type, isNull);
    });

    test('missing optional fields fall back instead of throwing', () {
      final notification = NotificationModel.fromJson(const {'id': 'n3'});

      expect(notification.id, 'n3');
      expect(notification.type, isNull);
      expect(notification.title, isNull);
      expect(notification.message, isNull);
      expect(notification.relatedEntityId, isNull);
      expect(notification.isRead, isFalse);
      expect(notification.createdAt, isNull);
    });
  });

  test('copyWith replaces only isRead', () {
    const notification = NotificationModel(
      id: 'n1',
      title: 'عنوان',
      message: 'رسالة',
      isRead: false,
    );

    final read = notification.copyWith(isRead: true);

    expect(read.isRead, isTrue);
    expect(read.id, 'n1');
    expect(read.title, 'عنوان');
    expect(read.message, 'رسالة');
  });
}

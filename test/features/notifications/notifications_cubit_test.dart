import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/data/repos/notifications_repo.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_cubit.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsRepo extends Mock implements NotificationsRepo {}

const _notifications = [
  NotificationModel(id: 'n1', title: 'الأولى', isRead: false),
  NotificationModel(id: 'n2', title: 'الثانية', isRead: true),
];

void main() {
  late _MockNotificationsRepo repo;
  late NotificationsCubit cubit;

  setUp(() {
    repo = _MockNotificationsRepo();

    // The cubit tries the paged endpoint first and falls back to the flat one.
    // These tests are about the flat path, so the page is failed by default —
    // which is exactly the real case this fallback exists for: a
    // `Notifications/paged` that answers in a shape the client cannot read.
    when(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('paged unavailable')));

    cubit = NotificationsCubit(repo);
  });

  tearDown(() => cubit.close());

  test('emits loading then loaded on a successful fetch', () async {
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => right(_notifications));

    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([isA<NotificationsLoading>(), isA<NotificationsLoaded>()]),
    );

    await cubit.getNotifications();
    await expectation;

    expect((cubit.state as NotificationsLoaded).notifications, _notifications);
  });

  test('emits the failure message when the fetch fails', () async {
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.getNotifications();

    expect(cubit.state, isA<NotificationsError>());
    expect((cubit.state as NotificationsError).message, 'لا يوجد اتصال');
  });

  test('marking a notification as read updates it optimistically', () async {
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => right(_notifications));
    when(() => repo.markAsRead('n1')).thenAnswer((_) async => right(null));

    await cubit.getNotifications();
    await cubit.markAsRead('n1');

    final state = cubit.state as NotificationsLoaded;
    expect(state.notifications.firstWhere((n) => n.id == 'n1').isRead, isTrue);
  });

  test('a failed mark-as-read rolls back and reports the error', () async {
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => right(_notifications));
    when(
      () => repo.markAsRead('n1'),
    ).thenAnswer((_) async => left(ServerFailure('تعذّر التحديث')));

    await cubit.getNotifications();
    await cubit.markAsRead('n1');

    expect(cubit.state, isA<NotificationsMarkError>());
    expect((cubit.state as NotificationsMarkError).message, 'تعذّر التحديث');
  });

  test('markAllAsRead marks every notification read', () async {
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => right(_notifications));
    when(() => repo.markAllAsRead()).thenAnswer((_) async => right(null));

    await cubit.getNotifications();
    await cubit.markAllAsRead();

    final state = cubit.state as NotificationsLoaded;
    expect(state.notifications.every((n) => n.isRead), isTrue);
  });

  test('markAllAsRead does nothing when everything is already read', () async {
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => right([_notifications[1]]));

    await cubit.getNotifications();
    await cubit.markAllAsRead();

    verifyNever(() => repo.markAllAsRead());
  });
}

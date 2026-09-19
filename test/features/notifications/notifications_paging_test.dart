import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_model.dart';
import 'package:dental_lab_app/features/notifications/data/models/notification_page_model.dart';
import 'package:dental_lab_app/features/notifications/data/repos/notifications_repo.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_cubit.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsRepo extends Mock implements NotificationsRepo {}

NotificationModel _note(String id) => NotificationModel(id: id, title: id);

void main() {
  late _MockNotificationsRepo repo;
  late NotificationsCubit cubit;

  setUp(() {
    repo = _MockNotificationsRepo();
    cubit = NotificationsCubit(repo);
  });

  tearDown(() => cubit.close());

  void stubPage(int page, NotificationPageModel result) {
    when(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: page,
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => right(result));
  }

  test('the paged endpoint is preferred over the flat one', () async {
    stubPage(
      1,
      NotificationPageModel(items: [_note('n1')], page: 1, totalPages: 2),
    );

    await cubit.getNotifications();

    expect(cubit.state, isA<NotificationsLoaded>());
    expect((cubit.state as NotificationsLoaded).hasMore, isTrue);
    // The flat endpoint is the fallback, so it must not be hit when paging
    // worked — two reads per open would double the screen's cost.
    verifyNever(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    );
  });

  test('a failed page falls back to the flat list, not to an error', () async {
    when(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('no schema')));
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => right([_note('n1')]));

    await cubit.getNotifications();

    final state = cubit.state;
    expect(state, isA<NotificationsLoaded>());
    expect((state as NotificationsLoaded).notifications, hasLength(1));
    // A flat list has no next page — offering one would spin forever.
    expect(state.hasMore, isFalse);
  });

  test('both failing is the only path to an error state', () async {
    when(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('no schema')));
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => left(ServerFailure('انقطع الاتصال')));

    await cubit.getNotifications();

    expect(cubit.state, isA<NotificationsError>());
    expect((cubit.state as NotificationsError).message, 'انقطع الاتصال');
  });

  test('loadMore appends rather than replacing', () async {
    stubPage(
      1,
      NotificationPageModel(items: [_note('n1')], page: 1, totalPages: 2),
    );
    stubPage(
      2,
      NotificationPageModel(items: [_note('n2')], page: 2, totalPages: 2),
    );

    await cubit.getNotifications();
    await cubit.loadMore();

    final state = cubit.state as NotificationsLoaded;
    expect(
      state.notifications.map((n) => n.id),
      ['n1', 'n2'],
    );
    // The new page's own figures are kept, so hasMore reflects where the list
    // actually is rather than where it started.
    expect(state.hasMore, isFalse);
  });

  test('loadMore is a no-op on the last page', () async {
    stubPage(
      1,
      NotificationPageModel(items: [_note('n1')], page: 1, totalPages: 1),
    );

    await cubit.getNotifications();
    await cubit.loadMore();

    verifyNever(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: 2,
        pageSize: any(named: 'pageSize'),
      ),
    );
  });

  test('loadMore is a no-op after the flat fallback', () async {
    when(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('no schema')));
    when(
      () => repo.getNotifications(unreadOnly: any(named: 'unreadOnly')),
    ).thenAnswer((_) async => right([_note('n1')]));

    await cubit.getNotifications();
    clearInteractions(repo);
    await cubit.loadMore();

    // The scroll listener fires constantly at the bottom of a short list; a
    // fallback list that kept re-requesting page 2 would hammer the server.
    verifyNever(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: any(named: 'page'),
        pageSize: any(named: 'pageSize'),
      ),
    );
  });

  test('a failed next page keeps the pages already shown', () async {
    stubPage(
      1,
      NotificationPageModel(items: [_note('n1')], page: 1, totalPages: 3),
    );
    when(
      () => repo.getPage(
        unreadOnly: any(named: 'unreadOnly'),
        page: 2,
        pageSize: any(named: 'pageSize'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('انقطع الاتصال')));

    await cubit.getNotifications();
    await cubit.loadMore();

    final state = cubit.state;
    expect(state, isA<NotificationsLoaded>());
    expect((state as NotificationsLoaded).notifications, hasLength(1));
    expect(state.isLoadingMore, isFalse);
    // Still offered, so the user can try again.
    expect(state.hasMore, isTrue);
  });
}

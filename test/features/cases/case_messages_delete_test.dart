import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCasesRepo extends Mock implements CasesRepo {}

CaseMessageModel _message(String id, {String senderId = 'u1'}) =>
    CaseMessageModel(id: id, caseId: 'c1', senderId: senderId, message: id);

void main() {
  late _MockCasesRepo repo;
  late CaseMessagesCubit cubit;

  setUp(() async {
    repo = _MockCasesRepo();
    when(() => repo.getMessages(any())).thenAnswer(
      (_) async => Right<Failure, List<CaseMessageModel>>([
        _message('m1'),
        _message('m2', senderId: 'u2'),
      ]),
    );
    cubit = CaseMessagesCubit(repo);
    // Establishes the case id the delete call is scoped to.
    await cubit.getMessages('c1');
  });

  tearDown(() => cubit.close());

  test('drops the deleted message from the loaded list', () async {
    when(
      () => repo.deleteMessage(
        id: any(named: 'id'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((_) async => right(null));

    await cubit.deleteMessage('m1');

    final state = cubit.state as CaseMessagesLoaded;
    expect(state.messages.map((m) => m.id), ['m2']);
    verify(() => repo.deleteMessage(id: 'c1', messageId: 'm1')).called(1);
  });

  test('keeps the list intact when the API rejects the delete', () async {
    when(
      () => repo.deleteMessage(
        id: any(named: 'id'),
        messageId: any(named: 'messageId'),
      ),
    ).thenAnswer((_) async => left(ServerFailure('غير مسموح')));

    // The failure is reported as a transient state, then the untouched list is
    // re-emitted — so the assertion has to watch the stream, not just the
    // settled state.
    final expectation = expectLater(
      cubit.stream,
      emitsInOrder([
        isA<CaseMessagesActionError>().having(
          (s) => s.message,
          'message',
          'غير مسموح',
        ),
        isA<CaseMessagesLoaded>(),
      ]),
    );

    await cubit.deleteMessage('m1');
    await expectation;

    final state = cubit.state as CaseMessagesLoaded;
    expect(state.messages.map((m) => m.id), ['m1', 'm2']);
  });
}

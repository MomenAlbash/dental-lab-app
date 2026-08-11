import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CaseMessagesCubit extends Cubit<CaseMessagesState> {
  CaseMessagesCubit(this._casesRepo) : super(const CaseMessagesInitial());

  final CasesRepo _casesRepo;

  late String _caseId;

  Future<void> getMessages(String caseId) async {
    _caseId = caseId;
    emit(const CaseMessagesLoading());

    final result = await _casesRepo.getMessages(caseId);

    result.fold(
      (failure) => emit(CaseMessagesError(failure.errorMessage)),
      (messages) => emit(CaseMessagesLoaded(messages)),
    );
  }

  Future<void> sendMessage({String? message, String? filePath}) async {
    final current = state;
    final messages = current is CaseMessagesLoaded
        ? current.messages
        : const <CaseMessageModel>[];
    emit(CaseMessagesLoaded(messages, isSending: true));

    final result = await _casesRepo.sendMessage(
      id: _caseId,
      message: message,
      filePath: filePath,
    );

    result.fold((failure) {
      emit(CaseMessagesActionError(failure.errorMessage));
      emit(CaseMessagesLoaded(messages));
    }, (sent) => emit(CaseMessagesLoaded([...messages, sent])));
  }

  /// Deletes one message. The API only permits this for an admin or the
  /// sender, so a rejection here is surfaced as a toast and the list is left
  /// untouched.
  Future<void> deleteMessage(String messageId) async {
    final current = state;
    final messages = current is CaseMessagesLoaded
        ? current.messages
        : const <CaseMessageModel>[];

    final result = await _casesRepo.deleteMessage(
      id: _caseId,
      messageId: messageId,
    );

    result.fold(
      (failure) {
        emit(CaseMessagesActionError(failure.errorMessage));
        emit(CaseMessagesLoaded(messages));
      },
      (_) {
        emit(const CaseMessageDeleted());
        emit(
          CaseMessagesLoaded(messages.where((m) => m.id != messageId).toList()),
        );
      },
    );
  }
}

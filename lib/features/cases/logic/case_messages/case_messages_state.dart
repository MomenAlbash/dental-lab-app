import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';

sealed class CaseMessagesState {
  const CaseMessagesState();
}

class CaseMessagesInitial extends CaseMessagesState {
  const CaseMessagesInitial();
}

class CaseMessagesLoading extends CaseMessagesState {
  const CaseMessagesLoading();
}

class CaseMessagesLoaded extends CaseMessagesState {
  const CaseMessagesLoaded(this.messages, {this.isSending = false});

  final List<CaseMessageModel> messages;

  /// True while a message is being uploaded/sent.
  final bool isSending;
}

class CaseMessagesError extends CaseMessagesState {
  const CaseMessagesError(this.message);
  final String message;
}

/// Transient failure of a send or delete — surfaced as a toast.
class CaseMessagesActionError extends CaseMessagesState {
  const CaseMessagesActionError(this.message);
  final String message;
}

/// Transient success of a delete — surfaced as a toast.
class CaseMessageDeleted extends CaseMessagesState {
  const CaseMessageDeleted();
}

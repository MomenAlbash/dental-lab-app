import 'package:dental_lab_app/features/scanner_sessions/data/models/digital_scan_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_message_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/repos/scanner_sessions_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class SessionMessagesState {
  const SessionMessagesState();
}

class SessionMessagesLoading extends SessionMessagesState {
  const SessionMessagesLoading();
}

class SessionMessagesError extends SessionMessagesState {
  const SessionMessagesError(this.message);
  final String message;
}

class SessionMessagesLoaded extends SessionMessagesState {
  const SessionMessagesLoaded(this.messages, {this.isSending = false});

  final List<ScannerSessionMessageModel> messages;

  /// A send in flight. The composer stays enabled — a thread that locks on
  /// every send feels broken on a slow connection — but the button does not
  /// fire twice.
  final bool isSending;

  SessionMessagesLoaded copyWith({bool? isSending}) =>
      SessionMessagesLoaded(messages, isSending: isSending ?? this.isSending);
}

class SessionMessagesActionError extends SessionMessagesState {
  const SessionMessagesActionError(this.message);
  final String message;
}

class SessionMessagesUploaded extends SessionMessagesState {
  const SessionMessagesUploaded(this.scan);
  final DigitalScanModel scan;
}

/// The thread between the lab and the doctor about one scanner appointment.
///
/// Kept on the session rather than on a case because at booking time there is
/// usually no case yet — the case is what the session produces.
class SessionMessagesCubit extends Cubit<SessionMessagesState> {
  SessionMessagesCubit(this._repo) : super(const SessionMessagesLoading());

  final ScannerSessionsRepo _repo;

  late String _sessionId;

  /// Loads the thread and clears the other side's unread marks in one pass.
  ///
  /// Opening the thread *is* reading it, so the receipt is not a separate
  /// button — and the refreshed list the server answers with is what gets
  /// shown, rather than the pre-read copy with locally flipped flags.
  Future<void> load(String sessionId) async {
    _sessionId = sessionId;
    emit(const SessionMessagesLoading());

    final result = await _repo.markRead(sessionId);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        // Marking read is a courtesy; failing it must not hide the thread.
        // Fall back to a plain read so the user still sees the conversation.
        final plain = await _repo.getMessages(sessionId);
        if (isClosed) return;

        plain.fold(
          (_) => emit(SessionMessagesError(failure.errorMessage)),
          (messages) => emit(SessionMessagesLoaded(messages)),
        );
      },
      (messages) async => emit(SessionMessagesLoaded(messages)),
    );
  }

  Future<void> send(String message) async {
    final text = message.trim();
    if (text.isEmpty) return;

    final current = state;
    if (current is SessionMessagesLoaded) {
      if (current.isSending) return;
      emit(current.copyWith(isSending: true));
    }

    final result = await _repo.sendMessage(
      sessionId: _sessionId,
      message: text,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(SessionMessagesActionError(failure.errorMessage));
        if (current is SessionMessagesLoaded) {
          emit(current.copyWith(isSending: false));
        }
      },
      // Reloaded rather than appended: the server stamps the time, and a
      // locally appended message would carry the phone's clock into a record
      // both sides read.
      (_) async => load(_sessionId),
    );
  }

  /// Uploads one scan taken during the session.
  ///
  /// Does not reload the thread — a scan is not a message, and the two lists
  /// are separate on the server too.
  Future<void> uploadScan({
    required String filePath,
    DigitalScanRole? role,
    String? notes,
    String? clientUploadKey,
  }) async {
    final current = state;

    final result = await _repo.uploadScan(
      sessionId: _sessionId,
      filePath: filePath,
      role: role,
      notes: notes,
      clientUploadKey: clientUploadKey,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(SessionMessagesActionError(failure.errorMessage));
        if (current is SessionMessagesLoaded) emit(current);
      },
      (scan) {
        emit(SessionMessagesUploaded(scan));
        if (current is SessionMessagesLoaded) emit(current);
      },
    );
  }
}

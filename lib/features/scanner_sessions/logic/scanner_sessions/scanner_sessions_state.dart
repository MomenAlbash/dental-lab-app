import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';

sealed class ScannerSessionsState {
  const ScannerSessionsState();
}

class ScannerSessionsInitial extends ScannerSessionsState {
  const ScannerSessionsInitial();
}

class ScannerSessionsLoading extends ScannerSessionsState {
  const ScannerSessionsLoading();
}

class ScannerSessionsLoaded extends ScannerSessionsState {
  const ScannerSessionsLoaded(this.sessions, {this.isBusy = false});

  final List<ScannerSessionModel> sessions;

  /// A write is in flight. Actions disable rather than the list disappearing —
  /// two dispatchers assigning the same session at once is the failure this
  /// prevents.
  final bool isBusy;

  /// Sessions nobody is coming to unless someone acts: unassigned, or the
  /// assignee declined. This is the dispatcher's actual work queue.
  List<ScannerSessionModel> get needingAttention =>
      sessions.where((s) => s.needsAttention).toList();

  ScannerSessionsLoaded copyWith({
    List<ScannerSessionModel>? sessions,
    bool? isBusy,
  }) => ScannerSessionsLoaded(
    sessions ?? this.sessions,
    isBusy: isBusy ?? this.isBusy,
  );
}

class ScannerSessionsError extends ScannerSessionsState {
  const ScannerSessionsError(this.message);

  final String message;
}

class ScannerSessionActionSuccess extends ScannerSessionsState {
  const ScannerSessionActionSuccess(this.message);

  final String message;
}

class ScannerSessionActionError extends ScannerSessionsState {
  const ScannerSessionActionError(this.message);

  final String message;
}

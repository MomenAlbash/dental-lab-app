import 'dart:async';

import 'package:dental_lab_app/features/excel_import/data/models/import_session_model.dart';
import 'package:dental_lab_app/features/excel_import/data/repos/excel_import_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class ExcelImportState {
  const ExcelImportState();
}

class ExcelImportLoading extends ExcelImportState {
  const ExcelImportLoading();
}

class ExcelImportError extends ExcelImportState {
  const ExcelImportError(this.message);
  final String message;
}

class ExcelImportLoaded extends ExcelImportState {
  const ExcelImportLoaded({
    this.sessions = const [],
    this.isUploading = false,
  });

  /// Running and recent runs, newest first.
  final List<ImportSessionModel> sessions;

  /// A file on its way up. Separate from a session being *processed*: the
  /// upload is the one part the user is waiting on directly, and the run that
  /// follows happens whether they stay on the screen or not.
  final bool isUploading;

  /// Whether anything is still being worked through — what decides whether to
  /// keep polling.
  bool get hasRunning => sessions.any((session) => session.isRunning);

  ExcelImportLoaded copyWith({
    List<ImportSessionModel>? sessions,
    bool? isUploading,
  }) => ExcelImportLoaded(
    sessions: sessions ?? this.sessions,
    isUploading: isUploading ?? this.isUploading,
  );
}

class ExcelImportTemplateReady extends ExcelImportState {
  const ExcelImportTemplateReady(this.entityType, this.bytes);
  final ImportEntityType entityType;
  final List<int> bytes;
}

class ExcelImportActionError extends ExcelImportState {
  const ExcelImportActionError(this.message);
  final String message;
}

/// Bulk import from a spreadsheet.
///
/// The server processes a file in the background, so this polls rather than
/// awaiting — and **only while something is actually running**. A timer that
/// kept firing over a finished list would be a request every few seconds for
/// as long as the screen stayed open.
class ExcelImportCubit extends Cubit<ExcelImportState> {
  ExcelImportCubit(this._repo) : super(const ExcelImportLoading());

  final ExcelImportRepo _repo;

  Timer? _poll;

  /// Slow enough not to hammer the server, fast enough that a short file does
  /// not look stuck.
  static const _pollInterval = Duration(seconds: 3);

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }

  Future<void> load() async {
    emit(const ExcelImportLoading());

    final result = await _repo.getSessions();
    if (isClosed) return;

    result.fold(
      (failure) => emit(ExcelImportError(failure.errorMessage)),
      (sessions) {
        emit(ExcelImportLoaded(sessions: _sorted(sessions)));
        _syncPolling();
      },
    );
  }

  /// Refetches without the loading state, so a poll does not blank the list
  /// the user is reading.
  Future<void> _refresh() async {
    final current = state;
    if (current is! ExcelImportLoaded) return;

    final result = await _repo.getSessions();
    if (isClosed) return;

    result.fold(
      // A failed poll is silent: the run is the server's, not this screen's,
      // and a toast every three seconds over a flaky connection is worse than
      // a list that updates late.
      (_) {},
      (sessions) {
        emit(current.copyWith(sessions: _sorted(sessions)));
        _syncPolling();
      },
    );
  }

  /// Starts or stops the timer to match whether anything is running.
  void _syncPolling() {
    final current = state;
    final shouldPoll = current is ExcelImportLoaded && current.hasRunning;

    if (!shouldPoll) {
      _poll?.cancel();
      _poll = null;
      return;
    }

    _poll ??= Timer.periodic(_pollInterval, (_) => _refresh());
  }

  /// Fetches the blank spreadsheet for [entityType].
  Future<void> downloadTemplate(ImportEntityType entityType) async {
    final current = state;

    final result = await _repo.downloadTemplate(entityType);
    if (isClosed) return;

    result.fold(
      (failure) {
        // The one place a wrong `ImportEntityType.wireValue` surfaces, and it
        // surfaces as the server's own message rather than as silence.
        emit(ExcelImportActionError(failure.errorMessage));
        if (current is ExcelImportLoaded) emit(current);
      },
      (bytes) {
        emit(ExcelImportTemplateReady(entityType, bytes));
        if (current is ExcelImportLoaded) emit(current);
      },
    );
  }

  /// Uploads a filled-in file and starts polling its run.
  Future<void> upload({
    required ImportEntityType entityType,
    required String filePath,
  }) async {
    final current = state;
    if (current is ExcelImportLoaded) {
      if (current.isUploading) return;
      emit(current.copyWith(isUploading: true));
    }

    final result = await _repo.upload(
      entityType: entityType,
      filePath: filePath,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ExcelImportActionError(failure.errorMessage));
        if (current is ExcelImportLoaded) {
          emit(current.copyWith(isUploading: false));
        }
      },
      // Reloaded rather than prepending the answer: the list is the server's
      // view of every run, and splicing one in would put this client's copy
      // beside the server's own.
      (_) async => load(),
    );
  }

  /// Newest first — a run started a minute ago is what somebody opening this
  /// screen came to look at.
  static List<ImportSessionModel> _sorted(List<ImportSessionModel> sessions) {
    return [...sessions]..sort((a, b) {
      final aAt = a.startedAt;
      final bAt = b.startedAt;
      if (aAt == null && bAt == null) return 0;
      // A run with no start time goes last rather than to the top.
      if (aAt == null) return 1;
      if (bAt == null) return -1;
      return bAt.compareTo(aAt);
    });
  }
}

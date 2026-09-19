import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_enums.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_filters_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/repos/scanner_sessions_repo.dart';
import 'package:dental_lab_app/features/scanner_sessions/logic/scanner_sessions/scanner_sessions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the scanner-session dispatch board.
class ScannerSessionsCubit extends Cubit<ScannerSessionsState> {
  ScannerSessionsCubit(this._repo) : super(const ScannerSessionsInitial());

  final ScannerSessionsRepo _repo;

  ScannerSessionFiltersModel _filters = ScannerSessionFiltersModel.empty;

  ScannerSessionFiltersModel get filters => _filters;

  /// Kept so a failed write can put the board back rather than replacing a
  /// working list with an error page.
  List<ScannerSessionModel> _lastLoaded = const [];

  Future<void> getSessions() async {
    emit(const ScannerSessionsLoading());

    final result = await _repo.getSessions(filters: _filters);
    if (isClosed) return;

    result.fold((failure) => emit(ScannerSessionsError(failure.errorMessage)), (
      sessions,
    ) {
      _lastLoaded = _sorted(sessions);
      emit(ScannerSessionsLoaded(_lastLoaded));
    });
  }

  Future<void> applyFilters(ScannerSessionFiltersModel filters) async {
    if (filters == _filters) return;
    _filters = filters;
    await getSessions();
  }

  Future<void> clearFilters() => applyFilters(ScannerSessionFiltersModel.empty);

  /// Hands the session to [representativeUserId]. A null id does not clear
  /// the assignment — the server picks one itself (zone first, then whoever
  /// is free and not vetoed), so the success message says "reassigned",
  /// never "cancelled".
  ///
  /// Reassignment after a refusal is the normal path, not an exception: the
  /// first representative may decline, and the second, and each time the
  /// dispatcher sends the next one.
  Future<void> assignRepresentative({
    required String id,
    String? representativeUserId,
    String? note,
  }) => _runAction(
    successMessage: representativeUserId == null
        ? 'تم إسناد المندوب تلقائياً'
        : 'تم إسناد المندوب',
    action: () => _repo.assignRepresentative(
      id: id,
      representativeUserId: representativeUserId,
      note: note,
    ),
  );

  Future<void> setStatus({
    required String id,
    required ScannerSessionStatus status,
    String? note,
  }) => _runAction(
    successMessage: 'تم تحديث الجلسة إلى: ${status.label}',
    action: () => _repo.setStatus(id: id, status: status, note: note),
  );

  /// Runs a write, then reloads the board.
  ///
  /// Every action returns the updated session, but the board is refetched
  /// rather than patched in place: assigning a representative can change the
  /// session's status too, and a locally patched row would disagree with the
  /// server about what just happened.
  Future<void> _runAction({
    required String successMessage,
    required Future<Either<Failure, ScannerSessionModel>> Function() action,
  }) async {
    final current = state;
    if (current is ScannerSessionsLoaded) {
      emit(current.copyWith(isBusy: true));
    }

    final result = await action();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ScannerSessionActionError(failure.errorMessage));
        // The board is still valid — put it back so the error is a toast over
        // the queue rather than a screen replacing it.
        emit(ScannerSessionsLoaded(_lastLoaded));
      },
      (_) async {
        emit(ScannerSessionActionSuccess(successMessage));
        await getSessions();
      },
    );
  }

  /// The sessions needing a dispatcher first, then by scheduled time. A board
  /// sorted purely by clock buries the refusal that needs answering today
  /// under next week's bookings.
  static List<ScannerSessionModel> _sorted(List<ScannerSessionModel> sessions) {
    final sorted = [...sessions];
    sorted.sort((a, b) {
      if (a.needsAttention != b.needsAttention) {
        return a.needsAttention ? -1 : 1;
      }
      final left = a.scheduledAt;
      final right = b.scheduledAt;
      if (left == null && right == null) return 0;
      if (left == null) return 1;
      if (right == null) return -1;
      return left.compareTo(right);
    });
    return sorted;
  }
}

import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_exception_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/repos/scanner_availability_repo.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_exceptions/scanner_exceptions_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScannerExceptionsCubit extends Cubit<ScannerExceptionsState> {
  ScannerExceptionsCubit(this._repo) : super(const ScannerExceptionsInitial());

  final ScannerAvailabilityRepo _repo;

  /// The exceptions endpoint is date-ranged, so the cubit holds the window it
  /// last loaded — a save or a delete has to refetch the same one rather than
  /// silently jumping back to the default.
  DateTime? _from;
  DateTime? _to;

  DateTime get from => _from ?? _defaultFrom;
  DateTime get to => _to ?? _defaultTo;

  /// From today: past closures are history, and the lab is scheduling ahead.
  static DateTime get _defaultFrom {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Three months out — far enough to cover the holidays a lab plans around,
  /// short enough to stay one quick request.
  static DateTime get _defaultTo {
    final from = _defaultFrom;
    return DateTime(from.year, from.month + 3, from.day);
  }

  Future<void> getExceptions({DateTime? from, DateTime? to}) async {
    _from = from ?? _from ?? _defaultFrom;
    _to = to ?? _to ?? _defaultTo;

    emit(const ScannerExceptionsLoading());

    final result = await _repo.getExceptions(from: _from!, to: _to!);

    result.fold(
      (failure) => emit(ScannerExceptionsError(failure.errorMessage)),
      (exceptions) => emit(ScannerExceptionsLoaded(_sorted(exceptions))),
    );
  }

  /// Soonest first — the next closure is the one that matters.
  List<ScannerAvailabilityExceptionModel> _sorted(
    List<ScannerAvailabilityExceptionModel> exceptions,
  ) {
    final sorted = [...exceptions];
    sorted.sort((a, b) {
      final aDate = a.date;
      final bDate = b.date;
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });
    return sorted;
  }

  Future<void> saveException(
    SaveScannerAvailabilityExceptionRequestModel body,
  ) async {
    final result = await _repo.saveException(body);

    await result.fold(
      (failure) async => emit(ScannerExceptionSaveError(failure.errorMessage)),
      (_) async {
        emit(const ScannerExceptionSaved());
        await getExceptions();
      },
    );
  }

  Future<void> deleteException(String id) async {
    final result = await _repo.deleteException(id);

    await result.fold(
      (failure) async =>
          emit(ScannerExceptionDeleteError(failure.errorMessage)),
      (_) async {
        emit(const ScannerExceptionDeleted());
        await getExceptions();
      },
    );
  }
}

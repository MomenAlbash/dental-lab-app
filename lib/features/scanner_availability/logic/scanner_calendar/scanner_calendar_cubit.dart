import 'package:dental_lab_app/features/scanner_availability/data/repos/scanner_availability_repo.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_calendar/scanner_calendar_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives the read-only preview of what the rules and exceptions actually
/// produce — the same days and slots the doctor is offered.
class ScannerCalendarCubit extends Cubit<ScannerCalendarState> {
  ScannerCalendarCubit(this._repo) : super(const ScannerCalendarInitial());

  final ScannerAvailabilityRepo _repo;

  /// How many days the preview covers. Two weeks shows the weekly pattern
  /// repeating, which is what makes a wrong rule obvious.
  static const int windowDays = 14;

  DateTime _from = _today;

  DateTime get from => _from;
  DateTime get to => _from.add(const Duration(days: windowDays - 1));

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> getCalendar() async {
    emit(const ScannerCalendarLoading());

    final result = await _repo.getCalendar(from: _from, to: to);

    result.fold(
      (failure) => emit(ScannerCalendarError(failure.errorMessage)),
      (days) => emit(ScannerCalendarLoaded(days)),
    );
  }

  Future<void> nextWindow() async {
    _from = _from.add(const Duration(days: windowDays));
    await getCalendar();
  }

  /// Never steps before today — the calendar is for scheduling, and past
  /// availability cannot be acted on.
  Future<void> previousWindow() async {
    final previous = _from.subtract(const Duration(days: windowDays));
    _from = previous.isBefore(_today) ? _today : previous;
    await getCalendar();
  }

  bool get canGoBack => _from.isAfter(_today);
}

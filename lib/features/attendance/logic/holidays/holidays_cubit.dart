import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class HolidaysState {
  const HolidaysState();
}

class HolidaysInitial extends HolidaysState {
  const HolidaysInitial();
}

class HolidaysLoading extends HolidaysState {
  const HolidaysLoading();
}

class HolidaysError extends HolidaysState {
  const HolidaysError(this.message);
  final String message;
}

class HolidaysLoaded extends HolidaysState {
  const HolidaysLoaded(this.holidays, {this.isBusy = false});

  final List<HolidayModel> holidays;
  final bool isBusy;

  HolidaysLoaded copyWith({bool? isBusy}) =>
      HolidaysLoaded(holidays, isBusy: isBusy ?? this.isBusy);
}

class HolidaysActionSuccess extends HolidaysState {
  const HolidaysActionSuccess(this.message);
  final String message;
}

class HolidaysActionError extends HolidaysState {
  const HolidaysActionError(this.message);
  final String message;
}

/// The days the laboratory — or some of it — does not work.
///
/// Adding or removing one re-judges every attendance day it covers, which is
/// why both writes reload rather than editing the list in place.
class HolidaysCubit extends Cubit<HolidaysState> {
  HolidaysCubit(this._repo) : super(const HolidaysInitial());

  final AttendanceRepo _repo;

  DateTime? _from;
  DateTime? _to;

  Future<void> load({DateTime? from, DateTime? to, bool clearWindow = false}) async {
    if (clearWindow) {
      _from = null;
      _to = null;
    } else {
      _from = from ?? _from;
      _to = to ?? _to;
    }

    emit(const HolidaysLoading());

    final result = await _repo.getHolidays(from: _from, to: _to);
    if (isClosed) return;

    result.fold(
      (failure) => emit(HolidaysError(failure.errorMessage)),
      (holidays) => emit(HolidaysLoaded(holidays)),
    );
  }

  Future<void> create(SaveHolidayRequestModel body) =>
      _write('تمت إضافة العطلة', () => _repo.createHoliday(body));

  Future<void> delete(String id) =>
      _write('تم حذف العطلة', () => _repo.deleteHoliday(id));

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is HolidaysLoaded) emit(current.copyWith(isBusy: true));

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(HolidaysActionError(failure.errorMessage));
        if (current is HolidaysLoaded) emit(current);
      },
      (_) async {
        emit(HolidaysActionSuccess(successMessage));
        await load();
      },
    );
  }
}

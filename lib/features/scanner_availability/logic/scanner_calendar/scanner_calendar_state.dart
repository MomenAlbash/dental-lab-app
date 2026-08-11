import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_day_model.dart';

sealed class ScannerCalendarState {
  const ScannerCalendarState();
}

class ScannerCalendarInitial extends ScannerCalendarState {
  const ScannerCalendarInitial();
}

class ScannerCalendarLoading extends ScannerCalendarState {
  const ScannerCalendarLoading();
}

class ScannerCalendarLoaded extends ScannerCalendarState {
  const ScannerCalendarLoaded(this.days);
  final List<ScannerDayModel> days;
}

class ScannerCalendarError extends ScannerCalendarState {
  const ScannerCalendarError(this.message);
  final String message;
}

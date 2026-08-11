import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';

sealed class ScannerExceptionsState {
  const ScannerExceptionsState();
}

class ScannerExceptionsInitial extends ScannerExceptionsState {
  const ScannerExceptionsInitial();
}

class ScannerExceptionsLoading extends ScannerExceptionsState {
  const ScannerExceptionsLoading();
}

class ScannerExceptionsLoaded extends ScannerExceptionsState {
  const ScannerExceptionsLoaded(this.exceptions);
  final List<ScannerAvailabilityExceptionModel> exceptions;
}

class ScannerExceptionsError extends ScannerExceptionsState {
  const ScannerExceptionsError(this.message);
  final String message;
}

class ScannerExceptionSaved extends ScannerExceptionsState {
  const ScannerExceptionSaved();
}

class ScannerExceptionSaveError extends ScannerExceptionsState {
  const ScannerExceptionSaveError(this.message);
  final String message;
}

class ScannerExceptionDeleted extends ScannerExceptionsState {
  const ScannerExceptionDeleted();
}

class ScannerExceptionDeleteError extends ScannerExceptionsState {
  const ScannerExceptionDeleteError(this.message);
  final String message;
}

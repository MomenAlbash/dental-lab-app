import 'package:dental_lab_app/features/store_reports/data/models/monthly_feasibility_model.dart';

sealed class FeasibilityState {
  const FeasibilityState();
}

class FeasibilityLoading extends FeasibilityState {
  const FeasibilityLoading();
}

class FeasibilityLoaded extends FeasibilityState {
  const FeasibilityLoaded(this.feasibility, {required this.months});
  final MonthlyFeasibilityModel feasibility;

  /// The window this was loaded with, so the screen's own selector stays in
  /// sync after a reload.
  final int months;
}

class FeasibilityError extends FeasibilityState {
  const FeasibilityError(this.message);
  final String message;
}

import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';

sealed class PhotographyVisitDetailState {
  const PhotographyVisitDetailState();
}

class PhotographyVisitDetailLoading extends PhotographyVisitDetailState {
  const PhotographyVisitDetailLoading();
}

class PhotographyVisitDetailError extends PhotographyVisitDetailState {
  const PhotographyVisitDetailError(this.message);
  final String message;
}

/// The visit, plus what its action sheets offer: the technicians it can be
/// assigned to and the currencies a price can be in.
class PhotographyVisitDetailLoaded extends PhotographyVisitDetailState {
  const PhotographyVisitDetailLoaded({
    required this.visit,
    this.employees = const [],
    this.currencies = const [],
    this.isBusy = false,
  });

  final PhotographyVisitModel visit;
  final List<EmployeeModel> employees;
  final List<CurrencyModel> currencies;

  /// An action is in flight; every button waits.
  final bool isBusy;
}

/// One-shot outcomes, shown as a toast and never built.
class PhotographyVisitActionSuccess extends PhotographyVisitDetailState {
  const PhotographyVisitActionSuccess(this.message);
  final String message;
}

class PhotographyVisitActionError extends PhotographyVisitDetailState {
  const PhotographyVisitActionError(this.message);
  final String message;
}

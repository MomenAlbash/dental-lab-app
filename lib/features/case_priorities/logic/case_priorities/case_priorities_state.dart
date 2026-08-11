import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';

sealed class CasePrioritiesState {
  const CasePrioritiesState();
}

class CasePrioritiesInitial extends CasePrioritiesState {
  const CasePrioritiesInitial();
}

class CasePrioritiesLoading extends CasePrioritiesState {
  const CasePrioritiesLoading();
}

class CasePrioritiesLoaded extends CasePrioritiesState {
  const CasePrioritiesLoaded(this.priorities);
  final List<CasePriorityModel> priorities;
}

class CasePrioritiesError extends CasePrioritiesState {
  const CasePrioritiesError(this.message);
  final String message;
}

class CasePriorityDeleted extends CasePrioritiesState {
  const CasePriorityDeleted();
}

class CasePriorityDeleteError extends CasePrioritiesState {
  const CasePriorityDeleteError(this.message);
  final String message;
}

class CasePrioritiesSeeded extends CasePrioritiesState {
  const CasePrioritiesSeeded();
}

class CasePrioritiesSeedError extends CasePrioritiesState {
  const CasePrioritiesSeedError(this.message);
  final String message;
}

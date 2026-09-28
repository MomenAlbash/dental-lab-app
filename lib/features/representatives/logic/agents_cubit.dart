import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class AgentsState {
  const AgentsState();
}

class AgentsLoading extends AgentsState {
  const AgentsLoading();
}

class AgentsLoaded extends AgentsState {
  const AgentsLoaded(this.agents);
  final List<EmployeeModel> agents;
}

class AgentsError extends AgentsState {
  const AgentsError(this.message);
  final String message;
}

/// The agents (وكلاء) — employees flagged `isAgent`, who head the
/// representatives and receive the cash they collect.
class AgentsCubit extends Cubit<AgentsState> {
  AgentsCubit(this._repo) : super(const AgentsLoading());

  final EmployeesRepo _repo;

  Future<void> getAgents() async {
    emit(const AgentsLoading());
    final result = await _repo.getAgents();
    if (isClosed) return;
    result.fold(
      (failure) => emit(AgentsError(failure.errorMessage)),
      (agents) => emit(AgentsLoaded(agents)),
    );
  }
}

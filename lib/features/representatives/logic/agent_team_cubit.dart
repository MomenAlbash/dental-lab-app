import 'package:dental_lab_app/features/representatives/data/models/representative_agent_model.dart';
import 'package:dental_lab_app/features/representatives/data/repos/representative_agents_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class AgentTeamState {
  const AgentTeamState();
}

class AgentTeamLoading extends AgentTeamState {
  const AgentTeamLoading();
}

class AgentTeamLoaded extends AgentTeamState {
  const AgentTeamLoaded(this.team);
  final List<RepresentativeAgentModel> team;
}

class AgentTeamError extends AgentTeamState {
  const AgentTeamError(this.message);
  final String message;
}

/// The representatives currently reporting to one agent.
class AgentTeamCubit extends Cubit<AgentTeamState> {
  AgentTeamCubit(this._repo) : super(const AgentTeamLoading());

  final RepresentativeAgentsRepo _repo;

  /// [agentUserId] is the agent's login account — the team endpoint keys on
  /// users, not employee records. An agent without one has no team to show.
  Future<void> load(String? agentUserId) async {
    if (agentUserId == null || agentUserId.isEmpty) {
      emit(const AgentTeamError('لا يملك هذا الوكيل حساب مستخدم'));
      return;
    }
    emit(const AgentTeamLoading());
    final result = await _repo.getAgentTeam(agentUserId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AgentTeamError(failure.errorMessage)),
      (team) => emit(AgentTeamLoaded(team)),
    );
  }
}

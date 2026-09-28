import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/representatives/data/models/representative_agent_model.dart';
import 'package:dental_lab_app/features/representatives/data/repos/representative_agents_repo.dart';
import 'package:dental_lab_app/features/representatives/logic/agent_team_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements RepresentativeAgentsRepo {}

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  test('loads the team of the agent user', () async {
    when(() => repo.getAgentTeam('u1')).thenAnswer(
      (_) async => right([
        RepresentativeAgentModel.fromJson(const {
          'representativeUserId': 'r1',
          'agentUserId': 'u1',
        }),
      ]),
    );
    final cubit = AgentTeamCubit(repo);
    await cubit.load('u1');
    expect(
      cubit.state,
      isA<AgentTeamLoaded>().having(
        (s) => s.team.single.representativeUserId,
        'representativeUserId',
        'r1',
      ),
    );
  });

  test('an agent without a user account errors without a call', () async {
    final cubit = AgentTeamCubit(repo);
    await cubit.load(null);
    expect(cubit.state, isA<AgentTeamError>());
    verifyNever(() => repo.getAgentTeam(any()));
  });

  test('surfaces the failure message', () async {
    when(
      () => repo.getAgentTeam('u1'),
    ).thenAnswer((_) async => left(ServerFailure('boom')));
    final cubit = AgentTeamCubit(repo);
    await cubit.load('u1');
    expect(
      cubit.state,
      isA<AgentTeamError>().having((s) => s.message, 'message', 'boom'),
    );
  });
}

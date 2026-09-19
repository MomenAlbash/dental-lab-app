import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/features/representatives/data/models/representative_agent_model.dart';
import 'package:dio/dio.dart';

/// Which agent each representative reports to, as a dated history.
class RepresentativeAgentsRepo {
  RepresentativeAgentsRepo();

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  Future<Either<Failure, T>> _guard<T>(
    String what,
    Future<T> Function() request,
  ) async {
    try {
      return right(await request());
    } on DioException catch (e) {
      log('DioException while $what: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while $what: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  List<RepresentativeAgentModel> _decode(dynamic data) {
    if (data is! List) return const [];
    return [
      for (final entry in data)
        if (entry is Map<String, dynamic>)
          RepresentativeAgentModel.fromJson(entry),
    ];
  }

  /// Who reports to this agent **now** — open spells only.
  Future<Either<Failure, List<RepresentativeAgentModel>>> getAgentTeam(
    String agentUserId,
  ) => _guard('fetching an agent\'s representatives', () async {
    final data = await Api().get(
      url: 'representative-agents/agent/$agentUserId',
      token: _token,
    );
    return _decode(data);
  });

  /// Every agent this representative has ever reported to, in order — the
  /// history the screen edits as a list with one highlighted active row.
  Future<Either<Failure, List<RepresentativeAgentModel>>> getHistory(
    String representativeUserId,
  ) => _guard('fetching a representative\'s agent history', () async {
    final data = await Api().get(
      url: 'representative-agents/representative/$representativeUserId',
      token: _token,
    );
    return _decode(data);
  });

  Future<Either<Failure, RepresentativeAgentModel?>> getActiveAgent(
    String representativeUserId,
  ) => _guard('fetching a representative\'s current agent', () async {
    final data = await Api().get(
      url: 'representative-agents/representative/$representativeUserId/active',
      token: _token,
    );
    // A representative reporting to nobody is an ordinary answer.
    if (data is! Map<String, dynamic>) return null;
    return RepresentativeAgentModel.fromJson(data);
  });

  /// Opens a new spell — closing whatever one is currently active.
  Future<Either<Failure, RepresentativeAgentModel>> assign(
    AssignRepresentativeAgentRequestModel body,
  ) => _guard('assigning a representative agent', () async {
    final response = await Api().post(
      url: 'representative-agents',
      body: body.toJson(),
      token: _token,
    );
    return RepresentativeAgentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  });
}

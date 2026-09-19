import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/features/assistant/data/models/assistant_models.dart';
import 'package:dio/dio.dart';

/// The rule-based assistant — no external AI service behind any of it.
///
/// Two of these four calls are deliberately different in kind: the capability
/// catalogue and the smart items are ordinary reads, while `ask` is sent an
/// **intent id the client already resolved** rather than the sentence the user
/// typed. That is the assistant's privacy claim, and `suggest` is the single
/// exception — looking up a doctor by a fragment of their name cannot be done
/// without sending the fragment.
class AssistantRepo {
  AssistantRepo();

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

  List<T> _decodeList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return const [];
    return [
      for (final entry in data)
        if (entry is Map<String, dynamic>) fromJson(entry),
    ];
  }

  /// What this caller may ask about — already narrowed server-side to their
  /// own permissions, so nothing offered here can come back refused.
  Future<Either<Failure, List<AssistantCapabilityModel>>> getCapabilities() =>
      _guard('fetching assistant capabilities', () async {
        final data = await Api().get(
          url: 'Assistant/capabilities',
          token: _token,
        );
        return _decodeList(data, AssistantCapabilityModel.fromJson);
      });

  /// Answers one capability.
  ///
  /// [query] is sent **only** for capabilities whose `acceptsQuery` is true;
  /// for everything else the typed text never leaves the device.
  Future<Either<Failure, AssistantAnswerModel>> ask({
    required String intentId,
    String? query,
    int? count,
  }) => _guard('asking the assistant', () async {
    final response = await Api().post(
      url: 'Assistant/ask',
      body: {'intentId': intentId, 'query': ?query, 'count': ?count},
      token: _token,
    );
    return AssistantAnswerModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  });

  /// Cases and doctors matching a typed fragment.
  Future<Either<Failure, List<AssistantSuggestionModel>>> suggest(
    String query,
  ) => _guard('fetching assistant suggestions', () async {
    final data = await Api().get(
      url: 'Assistant/suggest?q=${Uri.encodeQueryComponent(query)}',
      token: _token,
    );
    return _decodeList(data, AssistantSuggestionModel.fromJson);
  });

  /// Operational recommendations — what the lab should look at right now.
  Future<Either<Failure, List<SmartAssistantItemModel>>> getSmartItems({
    int? count,
  }) => _guard('fetching smart assistant items', () async {
    final data = await Api().get(
      url: 'Assistant/smart-items${count == null ? '' : '?count=$count'}',
      token: _token,
    );
    return _decodeList(data, SmartAssistantItemModel.fromJson);
  });
}

import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/features/deletion/data/models/deletion_plan_model.dart';
import 'package:dio/dio.dart';

/// The generic delete mechanism.
///
/// One flow for every entity type, so a screen does not have to know which
/// blockers its own kind of row can have — it asks for the plan and renders
/// what comes back. `entityType` is a server-owned key (the same one a
/// blocker step names), which is why it is a plain string here rather than an
/// enum this client would have to keep in step with the backend.
class DeletionRepo {
  DeletionRepo();

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  /// What would have to happen before this row can go.
  Future<Either<Failure, DeletionPlanModel>> getPlan({
    required String entityType,
    required String id,
  }) async {
    try {
      log('Fetching deletion plan for $entityType/$id');

      final data = await Api().get(
        url: 'Deletion/$entityType/$id/plan',
        token: _token,
      );
      if (data is! Map<String, dynamic>) {
        return right(const DeletionPlanModel());
      }

      return right(DeletionPlanModel.fromJson(data));
    } on DioException catch (e) {
      log('DioException while fetching a deletion plan: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching a deletion plan: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Deletes through the generic mechanism.
  ///
  /// Still refused by the server when a blocker stands — the plan is guidance
  /// for the UI, never the authority. That is also why a failure's message is
  /// shown as it comes back.
  Future<Either<Failure, void>> delete({
    required String entityType,
    required String id,
  }) async {
    try {
      log('Deleting $entityType/$id through the generic mechanism');

      await Api().delete(url: 'Deletion/$entityType/$id', token: _token);
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting an entity: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting an entity: $e');
      return left(ServerFailure.fromException(e));
    }
  }
}

import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/photography_api.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dio/dio.dart';

/// Standalone photography visits: requested for a doctor, optionally
/// scheduled, then completed (which bills the doctor) or cancelled.
class PhotographyVisitsRepo {
  PhotographyVisitsRepo(this._apiService);

  final ApiService _apiService;

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

  Future<Either<Failure, List<PhotographyVisitModel>>> getVisits({
    String? doctorId,
    PhotographyVisitStatus? status,
  }) => _guard(
    'fetching photography visits',
    () => _apiService.getPhotographyVisits(
      doctorId: doctorId,
      status: status,
      token: _token,
    ),
  );

  Future<Either<Failure, PhotographyVisitModel>> getVisit(String id) => _guard(
    'fetching a photography visit',
    () => _apiService.getPhotographyVisit(id: id, token: _token),
  );

  Future<Either<Failure, PhotographyVisitModel>> create(
    CreatePhotographyVisitRequestModel body,
  ) => _guard(
    'creating a photography visit',
    () => _apiService.createPhotographyVisit(body: body, token: _token),
  );

  Future<Either<Failure, PhotographyVisitModel>> schedule(
    String id,
    SchedulePhotographyVisitRequestModel body,
  ) => _guard(
    'scheduling a photography visit',
    () =>
        _apiService.schedulePhotographyVisit(id: id, body: body, token: _token),
  );

  Future<Either<Failure, PhotographyVisitModel>> complete(
    String id,
    CompletePhotographyVisitRequestModel body,
  ) => _guard(
    'completing a photography visit',
    () =>
        _apiService.completePhotographyVisit(id: id, body: body, token: _token),
  );

  Future<Either<Failure, PhotographyVisitModel>> cancel(
    String id, {
    String? note,
  }) => _guard(
    'cancelling a photography visit',
    () => _apiService.cancelPhotographyVisit(id: id, note: note, token: _token),
  );

  Future<Either<Failure, PhotographyVisitModel>> uploadPhotos(
    String id,
    List<String> filePaths,
  ) => _guard(
    'uploading photography visit photos',
    () => _apiService.uploadPhotographyVisitPhotos(
      id: id,
      filePaths: filePaths,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> deletePhoto(String id, String photoId) =>
      _guard(
        'deleting a photography visit photo',
        () => _apiService.deletePhotographyVisitPhoto(
          id: id,
          photoId: photoId,
          token: _token,
        ),
      );
}

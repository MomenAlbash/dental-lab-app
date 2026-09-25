import 'dart:developer';

import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/photography_visits/data/models/photography_visit_models.dart';
import 'package:dio/dio.dart';

/// Standalone photography visits transport (`api/clinic/photography-visits`),
/// beside the other per-module extensions on [ApiService].
///
/// Not the older case-bound `photography-sessions` — a different feature under
/// a different name, and deliberately kept apart.
extension PhotographyApi on ApiService {
  PhotographyVisitModel _visit(Response response) =>
      PhotographyVisitModel.fromJson(response.data as Map<String, dynamic>);

  /// `GET /photography-visits` — every filter optional.
  Future<List<PhotographyVisitModel>> getPhotographyVisits({
    String? doctorId,
    PhotographyVisitStatus? status,
    DateTime? from,
    DateTime? to,
    String? token,
  }) async {
    log('Fetching photography visits');

    final query = [
      if (doctorId != null) 'doctorId=$doctorId',
      if (status != null) 'status=${status.value}',
      if (from != null) 'from=${ApiTime.formatDate(from)}',
      if (to != null) 'to=${ApiTime.formatDate(to)}',
    ].join('&');

    final data = await Api().get(
      url: 'photography-visits${query.isEmpty ? '' : '?$query'}',
      token: token,
    );
    if (data is! List) return const [];
    return [
      for (final entry in data)
        if (entry is Map<String, dynamic>)
          PhotographyVisitModel.fromJson(entry),
    ];
  }

  /// `GET /photography-visits/{id}`
  Future<PhotographyVisitModel> getPhotographyVisit({
    required String id,
    String? token,
  }) async {
    log('Fetching photography visit: $id');

    final data = await Api().get(url: 'photography-visits/$id', token: token);
    return PhotographyVisitModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /photography-visits`
  Future<PhotographyVisitModel> createPhotographyVisit({
    required CreatePhotographyVisitRequestModel body,
    String? token,
  }) async {
    log('Creating photography visit');

    return _visit(
      await Api().post(
        url: 'photography-visits',
        body: body.toJson(),
        token: token,
      ),
    );
  }

  /// `PUT /photography-visits/{id}/schedule`
  Future<PhotographyVisitModel> schedulePhotographyVisit({
    required String id,
    required SchedulePhotographyVisitRequestModel body,
    String? token,
  }) async {
    log('Scheduling photography visit: $id');

    return _visit(
      await Api().put(
        url: 'photography-visits/$id/schedule',
        body: body.toJson(),
        token: token,
      ),
    );
  }

  /// `PUT /photography-visits/{id}/complete` — also bills the doctor.
  Future<PhotographyVisitModel> completePhotographyVisit({
    required String id,
    required CompletePhotographyVisitRequestModel body,
    String? token,
  }) async {
    log('Completing photography visit: $id');

    return _visit(
      await Api().put(
        url: 'photography-visits/$id/complete',
        body: body.toJson(),
        token: token,
      ),
    );
  }

  /// `PUT /photography-visits/{id}/cancel`
  Future<PhotographyVisitModel> cancelPhotographyVisit({
    required String id,
    String? note,
    String? token,
  }) async {
    log('Cancelling photography visit: $id');

    return _visit(
      await Api().put(
        url: 'photography-visits/$id/cancel',
        body: {'note': note},
        token: token,
      ),
    );
  }

  /// `POST /photography-visits/{id}/photos` — multipart, `files` repeated.
  Future<PhotographyVisitModel> uploadPhotographyVisitPhotos({
    required String id,
    required List<String> filePaths,
    String? notes,
    String? token,
  }) async {
    log('Uploading ${filePaths.length} photos to visit: $id');

    final form = FormData();
    for (final path in filePaths) {
      form.files.add(MapEntry('files', await MultipartFile.fromFile(path)));
    }
    if (notes != null && notes.isNotEmpty) {
      form.fields.add(MapEntry('notes', notes));
    }

    return _visit(
      await Api().post(
        url: 'photography-visits/$id/photos',
        body: form,
        isFormData: true,
        token: token,
      ),
    );
  }

  /// `DELETE /photography-visits/{id}/photos/{photoId}`
  Future<void> deletePhotographyVisitPhoto({
    required String id,
    required String photoId,
    String? token,
  }) async {
    log('Deleting photo $photoId from visit: $id');

    await Api().delete(
      url: 'photography-visits/$id/photos/$photoId',
      token: token,
    );
  }
}

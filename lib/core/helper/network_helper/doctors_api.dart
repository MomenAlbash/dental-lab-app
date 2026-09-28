import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/doctors/data/models/approve_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/create_doctor_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_price_tier_spell_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/exclusion_reason_request_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/update_doctor_request_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_model.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dio/dio.dart';

/// The `doctors` endpoints — split out of
/// [ApiService], reached through the same instance.
extension DoctorsApi on ApiService {
  // --------------------------------------------------------------- doctors ---

  /// `GET /Doctors?search=` — matched on the server, across every doctor.
  ///
  /// Kept apart from [getDoctors] on purpose: that one caches the whole list
  /// for offline use, and a search result must not overwrite it.
  Future<List<DoctorModel>> searchDoctors({
    required String query,
    String? token,
  }) async {
    log('Searching doctors');

    final responseData = await Api().get(
      url: 'Doctors?search=${Uri.encodeQueryComponent(query)}',
      token: token,
    );

    return [
      for (final row in responseData as List<dynamic>? ?? const [])
        if (row is Map<String, dynamic>) DoctorModel.fromJson(row),
    ];
  }

  Future<List<DoctorModel>> getDoctors({String? token}) async {
    log('Fetching doctors');

    final responseData = await Api().get(url: 'Doctors', token: token);

    log('Doctors response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedDoctorsList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => DoctorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DoctorModel> getDoctorById({required String id, String? token}) async {
    log('Fetching doctor by id: $id');

    final responseData = await Api().get(url: 'Doctors/$id', token: token);

    log('Doctor by id response data: ${logSafe(responseData)}');

    return DoctorModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<DoctorModel> createDoctor({
    required CreateDoctorRequestModel createDoctorRequestBody,
    String? token,
  }) async {
    final body = createDoctorRequestBody.toJson();

    log('Sending Create Doctor request with: ${logSafe(body)}');

    final response = await Api().post(url: 'Doctors', body: body, token: token);

    log('Create Doctor response data: ${logSafe(response.data)}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DoctorModel> updateDoctor({
    required String id,
    required UpdateDoctorRequestModel updateDoctorRequestBody,
    String? token,
  }) async {
    final body = updateDoctorRequestBody.toJson();

    log('Sending Update Doctor request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Doctors/$id',
      body: body,
      token: token,
    );

    log('Update Doctor response data: ${logSafe(response.data)}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Doctors/{id}/approve` — accepts a self-registered doctor,
  /// optionally linking them to a clinic in the same call.
  Future<DoctorModel> approveDoctor({
    required String id,
    required ApproveDoctorRequestModel approveDoctorRequestBody,
    String? token,
  }) async {
    final body = approveDoctorRequestBody.toJson();

    log('Sending Approve Doctor request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'Doctors/$id/approve',
      body: body,
      token: token,
    );

    log('Approve Doctor response data: ${logSafe(response.data)}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `POST /Doctors/{id}/reject` — turns a registration down. The API requires
  /// a reason, which is shown back on the doctor's page.
  Future<DoctorModel> rejectDoctor({
    required String id,
    required RejectDoctorRequestModel rejectDoctorRequestBody,
    String? token,
  }) async {
    final body = rejectDoctorRequestBody.toJson();

    log('Sending Reject Doctor request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'Doctors/$id/reject',
      body: body,
      token: token,
    );

    log('Reject Doctor response data: ${logSafe(response.data)}');

    return DoctorModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteDoctor({required String id, String? token}) async {
    log('Deleting doctor: $id');

    final response = await Api().delete(url: 'Doctors/$id', token: token);

    log('Delete Doctor response data: ${logSafe(response.data)}');
  }

  Future<DoctorAttachmentFileModel> uploadDoctorFile({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading file for doctor: $id');

    final formData = FormData.fromMap({
      'Id': id,
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'Doctors/$id/files',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Upload Doctor file response data: ${logSafe(response.data)}');

    return DoctorAttachmentFileModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteDoctorFile({
    required String id,
    required String fileId,
    String? token,
  }) async {
    log('Deleting file $fileId for doctor: $id');

    final response = await Api().delete(
      url: 'Doctors/$id/files/$fileId',
      token: token,
    );

    log('Delete Doctor file response data: ${logSafe(response.data)}');
  }

  /// `GET /doctors/{doctorId}/zone` — the territory this doctor falls under.
  ///
  /// Resolved server-side from their area, or from a manual pin where one was
  /// set: which of the two it came from is not something the client can work
  /// out from the doctor's own record, and the answer decides which
  /// representatives may take their scanner sessions.
  ///
  /// Null when the doctor sits in no zone at all — an ordinary state for a
  /// doctor whose area has not been mapped yet, not an error.
  Future<ZoneModel?> getDoctorZone({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching zone for doctor: $doctorId');

    final data = await Api().get(url: 'doctors/$doctorId/zone', token: token);
    if (data is! Map<String, dynamic>) return null;

    return ZoneModel.fromJson(data);
  }

  /// `GET /doctors/{doctorId}/excluded-representatives` — representatives
  /// vetoed from this doctor's own scanner sessions, regardless of zone.
  Future<List<ZoneRepresentativeModel>> getExcludedRepresentatives({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching excluded representatives for doctor: $doctorId');

    final responseData = await Api().get(
      url: 'doctors/$doctorId/excluded-representatives',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => ZoneRepresentativeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `PUT /doctors/{doctorId}/excluded-representatives/{userId}` —
  /// representative [userId] is never candidated for this doctor again.
  Future<void> excludeRepresentative({
    required String doctorId,
    required String userId,
    required ExclusionReasonRequestModel body,
    String? token,
  }) async {
    log(
      'Excluding representative $userId for doctor $doctorId: ${body.toJson()}',
    );

    await Api().put(
      url: 'doctors/$doctorId/excluded-representatives/$userId',
      body: body.toJson(),
      token: token,
    );
  }

  /// `DELETE /doctors/{doctorId}/excluded-representatives/{userId}`.
  Future<void> removeExcludedRepresentative({
    required String doctorId,
    required String userId,
    String? token,
  }) async {
    log('Removing exclusion of $userId for doctor $doctorId');

    await Api().delete(
      url: 'doctors/$doctorId/excluded-representatives/$userId',
      token: token,
    );
  }

  /// `GET /Doctors/{id}/price-tier-history` — every stretch of time the
  /// doctor spent on a price tier, oldest and newest alike.
  Future<List<DoctorPriceTierSpellModel>> getDoctorPriceTierHistory({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching price-tier history for doctor: $doctorId');

    final responseData = await Api().get(
      url: 'Doctors/$doctorId/price-tier-history',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) => DoctorPriceTierSpellModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }


}

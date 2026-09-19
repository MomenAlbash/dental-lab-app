import 'dart:developer';

import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/currencies/data/models/currency_assignment_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_lookup_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/footer_contact_model.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_lookup_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/digital_scan_model.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/models/scanner_session_message_model.dart';
import 'package:dio/dio.dart';

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

/// Pickers, laboratory settings, and the scanner-session thread.
///
/// A third extension beside [AttendanceApi] and [PeopleApi], for the same
/// reason those exist: these belong to the screens that call them, and folding
/// them into the one service file that already carries every other feature
/// would not make them easier to find.
extension LookupApi on ApiService {
  // ---- Pickers -----------------------------------------------------------
  //
  // Deliberately separate from the full list endpoints. A picker needs a name
  // and something to tell namesakes apart; paging down balances, zones and
  // case counts to fill a dropdown is what makes a form slow to open.

  /// `GET /Doctors/lookup` — doctors as a picker sees them.
  Future<List<DoctorLookupModel>> getDoctorsLookup({
    String? search,
    String? token,
  }) async {
    log('Fetching doctor lookup');

    final query = (search == null || search.isEmpty)
        ? ''
        : '?search=${Uri.encodeQueryComponent(search)}';
    final data = await Api().get(url: 'Doctors/lookup$query', token: token);

    return _decodeList(data, DoctorLookupModel.fromJson);
  }

  /// `GET /Doctors/next-number` — the number the next doctor will get.
  ///
  /// Read from the server rather than counted locally: the lab numbers
  /// doctors in one sequence, and two people on the form at once must not be
  /// shown the same number.
  Future<int> getNextDoctorNumber({String? token}) async {
    log('Fetching the next doctor number');

    final data = await Api().get(url: 'Doctors/next-number', token: token);
    return (data as num?)?.toInt() ?? 0;
  }

  /// `GET /Patients/{id}/lookup` — just enough of a patient to confirm the
  /// right one was picked.
  Future<PatientLookupModel> getPatientLookup({
    required String id,
    String? token,
  }) async {
    log('Fetching patient lookup: $id');

    final data = await Api().get(url: 'Patients/$id/lookup', token: token);
    return PatientLookupModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /RestorationTypes/{id}/copy` — clones a restoration type, its
  /// prices, its durations and its whole route into another laboratory.
  ///
  /// Answers with the **new** type, not the source: a lab that has just cloned
  /// a catalogue entry wants to open the copy and price it, and handing back
  /// the original is how an edit lands in the wrong laboratory.
  Future<RestorationTypeModel> copyRestorationType({
    required String id,
    required String targetLaboratoryId,
    String? token,
  }) async {
    log('Copying restoration type $id to laboratory $targetLaboratoryId');

    final response = await Api().post(
      url: 'RestorationTypes/$id/copy',
      body: {'targetLaboratoryId': targetLaboratoryId},
      token: token,
    );

    return RestorationTypeModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---- Scanner-session thread -------------------------------------------

  /// `GET /scanner-sessions/{id}/messages` — the thread about one appointment.
  Future<List<ScannerSessionMessageModel>> getScannerSessionMessages({
    required String sessionId,
    String? token,
  }) async {
    log('Fetching messages of scanner session: $sessionId');

    final data = await Api().get(
      url: 'scanner-sessions/$sessionId/messages',
      token: token,
    );
    return _decodeList(data, ScannerSessionMessageModel.fromJson);
  }

  /// `POST /scanner-sessions/{id}/messages` — answers with the stored message,
  /// so the thread shows the server's timestamp rather than the phone's.
  Future<ScannerSessionMessageModel> sendScannerSessionMessage({
    required String sessionId,
    required String message,
    String? token,
  }) async {
    log('Sending a message on scanner session: $sessionId');

    final response = await Api().post(
      url: 'scanner-sessions/$sessionId/messages',
      body: {'message': message},
      token: token,
    );

    return ScannerSessionMessageModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /scanner-sessions/{id}/messages/read` — marks the other side's
  /// messages read and answers with the refreshed thread.
  Future<List<ScannerSessionMessageModel>> markScannerSessionMessagesRead({
    required String sessionId,
    String? token,
  }) async {
    log('Marking scanner session messages read: $sessionId');

    final response = await Api().put(
      url: 'scanner-sessions/$sessionId/messages/read',
      body: const <String, dynamic>{},
      token: token,
    );
    return _decodeList(response.data, ScannerSessionMessageModel.fromJson);
  }

  /// `POST /scanner-sessions/{id}/scans` — uploads one scan file taken during
  /// the session.
  ///
  /// [role] says which arch or bite it is. Asked at upload rather than left
  /// blank because a folder of `scan_001.stl` is unusable at the bench.
  ///
  /// [clientUploadKey] is the caller's own idempotency key: a retry after a
  /// dropped connection carries the same key and the server stores one file
  /// instead of two, which matters when the file is tens of megabytes on a
  /// phone connection.
  Future<DigitalScanModel> uploadScannerSessionScan({
    required String sessionId,
    required String filePath,
    DigitalScanRole? role,
    String? notes,
    String? clientUploadKey,
    String? token,
  }) async {
    log('Uploading a scan to scanner session: $sessionId');

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
      if (role != null) 'role': role.value,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'clientUploadKey': ?clientUploadKey,
    });

    final response = await Api().post(
      url: 'scanner-sessions/$sessionId/scans',
      body: form,
      token: token,
      isFormData: true,
    );

    return DigitalScanModel.fromJson(response.data as Map<String, dynamic>);
  }

  // ---- Laboratory settings ----------------------------------------------

  /// `PUT /Laboratories/{id}/footer-contacts` — the contact lines printed at
  /// the foot of reports and invoices.
  ///
  /// The list **replaces** what the lab had: a row left out is deleted, which
  /// is what makes reordering and removing possible in one save.
  Future<void> setLaboratoryFooterContacts({
    required String id,
    required List<SaveFooterContactModel> contacts,
    String? token,
  }) async {
    log('Setting ${contacts.length} footer contacts on laboratory: $id');

    await Api().put(
      url: 'Laboratories/$id/footer-contacts',
      body: {'contacts': [for (final c in contacts) c.toJson()]},
      token: token,
    );
  }

  /// `POST /Laboratories/{id}/logo`
  Future<void> uploadLaboratoryLogo({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading logo for laboratory: $id');

    await Api().post(
      url: 'Laboratories/$id/logo',
      body: FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      }),
      token: token,
      isFormData: true,
    );
  }

  /// `DELETE /Laboratories/{id}/logo` — back to no logo at all, which is not
  /// the same as uploading a blank one: reports lay out differently with no
  /// logo than with an empty box where one should be.
  Future<void> deleteLaboratoryLogo({
    required String id,
    String? token,
  }) async {
    log('Deleting logo of laboratory: $id');

    await Api().delete(url: 'Laboratories/$id/logo', token: token);
  }

  // ---- Currency assignment ----------------------------------------------
  //
  // Which currencies are actually traded in, as opposed to the catalogue of
  // every currency that exists. Quoting a doctor in a currency their clinic
  // does not settle in is a pricing error that only surfaces at invoice time.

  /// `GET /Currencies/laboratory`
  Future<CurrencyAssignmentModel> getLaboratoryCurrencies({
    String? token,
  }) async {
    log('Fetching laboratory currencies');

    final data = await Api().get(url: 'Currencies/laboratory', token: token);
    return CurrencyAssignmentModel.fromJson(data as Map<String, dynamic>);
  }

  /// `PUT /Currencies/laboratory` — replaces the lab's set.
  Future<CurrencyAssignmentModel> setLaboratoryCurrencies({
    required SetLaboratoryCurrenciesRequestModel body,
    String? token,
  }) async {
    log('Setting ${body.currencyIds.length} laboratory currencies');

    final response = await Api().put(
      url: 'Currencies/laboratory',
      body: body.toJson(),
      token: token,
    );

    return CurrencyAssignmentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `GET /Currencies/clinic/{clinicId}` — the clinic's own narrowed set, or
  /// the laboratory's shown through with `isInherited` set.
  Future<CurrencyAssignmentModel> getClinicCurrencies({
    required String clinicId,
    String? token,
  }) async {
    log('Fetching currencies of clinic: $clinicId');

    final data = await Api().get(
      url: 'Currencies/clinic/$clinicId',
      token: token,
    );
    return CurrencyAssignmentModel.fromJson(data as Map<String, dynamic>);
  }

  /// `PUT /Currencies/clinic/{clinicId}` — narrows the clinic to a subset of
  /// the lab's currencies. An empty list clears the override and returns the
  /// clinic to inheriting.
  Future<CurrencyAssignmentModel> setClinicCurrencies({
    required String clinicId,
    required SetClinicCurrenciesRequestModel body,
    String? token,
  }) async {
    log('Setting ${body.currencyIds.length} currencies on clinic: $clinicId');

    final response = await Api().put(
      url: 'Currencies/clinic/$clinicId',
      body: body.toJson(),
      token: token,
    );

    return CurrencyAssignmentModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

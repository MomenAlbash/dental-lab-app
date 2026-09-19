import 'dart:developer';

import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/employee_activity/data/models/employee_activity_model.dart';
import 'package:dental_lab_app/features/scan_storage/data/models/scan_storage_model.dart';
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

/// Scan storage and the team-activity report.
///
/// A fourth extension beside [AttendanceApi], [PeopleApi] and [LookupApi], for
/// the same reason those exist: these belong to the screens that call them,
/// and folding them into the one service file that already carries every other
/// feature would not make them easier to find.
extension ActivityApi on ApiService {
  // ---- Scan storage ------------------------------------------------------

  /// `GET /ScanStorage` — what the laboratory is holding, against its budget.
  Future<ScanStorageModel> getScanStorage({String? token}) async {
    log('Fetching scan storage');

    final data = await Api().get(url: 'ScanStorage', token: token);
    return ScanStorageModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /ScanStorage/run` — runs the retention sweep now.
  ///
  /// Deletes only what the lab's own rules allow — age, and whether the case
  /// is closed. A lab that is over budget with nothing eligible gets a run
  /// that frees nothing, which is why the result says `stillOverBudget`
  /// rather than just a count.
  Future<ScanRetentionRunResultModel> runScanRetention({String? token}) async {
    log('Running the scan retention sweep');

    final response = await Api().post(
      url: 'ScanStorage/run',
      body: const <String, dynamic>{},
      token: token,
    );

    return ScanRetentionRunResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `POST /ScanStorage/scans/{id}/remove-file` — deletes one file's bytes.
  ///
  /// The row stays: a case filed two years ago still says what was scanned,
  /// instead of showing an empty attachment list that reads like the scan was
  /// never taken.
  Future<ScanRetentionRunResultModel> removeScanFile({
    required String id,
    String? token,
  }) async {
    log('Removing the file of scan: $id');

    final response = await Api().post(
      url: 'ScanStorage/scans/$id/remove-file',
      body: const <String, dynamic>{},
      token: token,
    );

    return ScanRetentionRunResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `GET /ScanStorage/nas-archive/pending` — scans waiting to be copied to
  /// the laboratory's own NAS.
  Future<List<PendingNasArchiveModel>> getPendingNasArchive({
    String? token,
  }) async {
    log('Fetching scans pending NAS archive');

    final data = await Api().get(
      url: 'ScanStorage/nas-archive/pending',
      token: token,
    );
    return _decodeList(data, PendingNasArchiveModel.fromJson);
  }

  /// `POST /ScanStorage/nas-archive/confirm` — tells the server the copies are
  /// safely on the NAS, at which point it frees the bytes.
  ///
  /// **Sent only after the copy is verified.** The two-step flow exists so a
  /// failed copy costs nothing; confirming first and copying afterwards would
  /// lose a scan every time the copy failed.
  Future<ScanRetentionRunResultModel> confirmNasArchive({
    required ConfirmNasArchiveRequestModel body,
    String? token,
  }) async {
    log('Confirming ${body.items.length} NAS archives');

    final response = await Api().post(
      url: 'ScanStorage/nas-archive/confirm',
      body: body.toJson(),
      token: token,
    );

    return ScanRetentionRunResultModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---- Team activity -----------------------------------------------------
  //
  // Reads history. It does not add a new clock — the per-stage work timers are
  // deliberately off — so these answer "how much moved through whom", never
  // "how long did it take".

  /// `GET /EmployeeActivity/summary` — the whole team over a period.
  Future<EmployeeActivitySummaryModel> getActivitySummary({
    EmployeeActivityFiltersModel filters = EmployeeActivityFiltersModel.empty,
    String? token,
  }) async {
    log('Fetching the team activity summary');

    final data = await Api().get(
      url: 'EmployeeActivity/summary${filters.toQuery()}',
      token: token,
    );
    return EmployeeActivitySummaryModel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /EmployeeActivity/daily` — one row per employee per day.
  Future<List<EmployeeActivityDailyModel>> getActivityDaily({
    EmployeeActivityFiltersModel filters = EmployeeActivityFiltersModel.empty,
    String? token,
  }) async {
    log('Fetching daily employee activity');

    final data = await Api().get(
      url: 'EmployeeActivity/daily${filters.toQuery()}',
      token: token,
    );
    return _decodeList(data, EmployeeActivityDailyModel.fromJson);
  }

  /// `GET /EmployeeActivity/timeline` — the individual events, paged.
  Future<ActivityTimelineModel> getActivityTimeline({
    EmployeeActivityFiltersModel filters = EmployeeActivityFiltersModel.empty,
    String? token,
  }) async {
    log('Fetching the activity timeline (page ${filters.page})');

    final data = await Api().get(
      url: 'EmployeeActivity/timeline${filters.toQuery()}',
      token: token,
    );
    return ActivityTimelineModel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /EmployeeActivity/export` — the same report as a spreadsheet.
  ///
  /// Answers with the file's bytes; the caller saves or shares them.
  ///
  /// Goes through `Api.dio` directly rather than [Api.get], which only ever
  /// decodes JSON — the same reason [ApiService.exportCasesCsv] does.
  Future<List<int>> exportActivity({
    EmployeeActivityFiltersModel filters = EmployeeActivityFiltersModel.empty,
    String? token,
  }) async {
    log('Exporting the team activity report');

    final response = await Api.dio.get<List<int>>(
      'EmployeeActivity/export${filters.toQuery()}',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }
}

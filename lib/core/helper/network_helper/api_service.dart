import 'dart:developer';


import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/doctor_priority_quota_model.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/save_case_priority_request_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/route_problem_model.dart';
import 'package:dental_lab_app/features/case_stages/data/models/save_case_stage_request_models.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/data/models/cases_page_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/deliver_directly_models.dart';
import 'package:dental_lab_app/features/cases/data/models/send_back_models.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/users/data/models/create_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/update_user_request_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dio/dio.dart';
/// Decodes a JSON array response into models, tolerating a `null` body —
/// shared by [ApiService] and the per-feature extensions on it.
List<T> decodeJsonList<T>(
  dynamic data,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (data is! List) return const [];
  return data
      .whereType<Map<String, dynamic>>()
      .map(fromJson)
      .toList(growable: false);
}

class ApiService {
  // ----------------------------------------------------------------- users ---

  Future<List<UserModel>> getUsers({
    String? laboratoryId,
    String? doctorId,
    String? employeeId,
    List<int>? types,
    String? token,
  }) async {
    log('Fetching users');

    final query = <String>[];
    if (laboratoryId != null && laboratoryId.isNotEmpty) {
      query.add('laboratoryId=${Uri.encodeQueryComponent(laboratoryId)}');
    }
    if (doctorId != null && doctorId.isNotEmpty) {
      query.add('doctorId=${Uri.encodeQueryComponent(doctorId)}');
    }
    if (employeeId != null && employeeId.isNotEmpty) {
      query.add('employeeId=${Uri.encodeQueryComponent(employeeId)}');
    }
    // Repeated key — how the endpoint declares its array parameters.
    for (final type in types ?? const <int>[]) {
      query.add('types=$type');
    }

    final responseData = await Api().get(
      url: query.isEmpty ? 'Users' : 'Users?${query.join('&')}',
      token: token,
    );

    log('Users response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedUsersList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> getUserById({required String id, String? token}) async {
    log('Fetching user by id: $id');

    final responseData = await Api().get(url: 'Users/$id', token: token);

    log('User by id response data: ${logSafe(responseData)}');

    return UserModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<UserModel> createUser({
    required CreateUserRequestModel createUserRequestBody,
    String? token,
  }) async {
    final body = createUserRequestBody.toJson();

    log('Sending Create User request with: ${logSafe(body)}');

    final response = await Api().post(url: 'Users', body: body, token: token);

    log('Create User response data: ${logSafe(response.data)}');

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserModel> updateUser({
    required String id,
    required UpdateUserRequestModel updateUserRequestBody,
    String? token,
  }) async {
    final body = updateUserRequestBody.toJson();

    log('Sending Update User request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'Users/$id',
      body: body,
      token: token,
    );

    log('Update User response data: ${logSafe(response.data)}');

    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteUser({required String id, String? token}) async {
    log('Deleting user: $id');

    final response = await Api().delete(url: 'Users/$id', token: token);

    log('Delete User response data: ${logSafe(response.data)}');
  }

  Future<void> activateUser({required String id, String? token}) async {
    log('Activating user: $id');

    final response = await Api().post(
      url: 'Users/$id/activate',
      body: const <String, dynamic>{},
      token: token,
    );

    log('Activate User response data: ${logSafe(response.data)}');
  }

  Future<void> deactivateUser({required String id, String? token}) async {
    log('Deactivating user: $id');

    final response = await Api().post(
      url: 'Users/$id/deactivate',
      body: const <String, dynamic>{},
      token: token,
    );

    log('Deactivate User response data: ${logSafe(response.data)}');
  }

  Future<void> resetUserPassword({
    required String id,
    required String newPassword,
    String? token,
  }) async {
    log('Resetting password for user: $id');

    final response = await Api().post(
      url: 'Users/$id/reset-password',
      body: {'newPassword': newPassword},
      token: token,
    );

    // Never the body: it may carry the new password.
    log('Reset User password answered ${response.statusCode}');
  }

  // ------------------------------------------------------- case priorities ---

  /// [includeInactive] is what the management screen uses — everywhere inside
  /// cases reads the active set, so a retired priority is never offered.
  Future<List<CasePriorityModel>> getCasePriorities({
    bool includeInactive = false,
    String? token,
  }) async {
    log('Fetching case priorities (includeInactive: $includeInactive)');

    final responseData = await Api().get(
      url: 'case-priorities?includeInactive=$includeInactive',
      token: token,
    );

    log('Case priorities response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: includeInactive
          ? CacheKeys.cachedAllCasePrioritiesList
          : CacheKeys.cachedCasePrioritiesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => CasePriorityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CasePriorityModel> createCasePriority({
    required SaveCasePriorityRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Create CasePriority request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'case-priorities',
      body: body,
      token: token,
    );

    log('Create CasePriority response data: ${logSafe(response.data)}');

    return CasePriorityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CasePriorityModel> updateCasePriority({
    required String id,
    required SaveCasePriorityRequestModel saveRequestBody,
    String? token,
  }) async {
    final body = saveRequestBody.toJson();

    log('Sending Update CasePriority request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'case-priorities/$id',
      body: body,
      token: token,
    );

    log('Update CasePriority response data: ${logSafe(response.data)}');

    return CasePriorityModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCasePriority({required String id, String? token}) async {
    log('Deleting case priority: $id');

    final response = await Api().delete(
      url: 'case-priorities/$id',
      token: token,
    );

    log('Delete CasePriority response data: ${logSafe(response.data)}');
  }

  /// Creates the lab's starting set of priorities. Only meaningful while the
  /// list is still empty — the API owns what "defaults" means.
  Future<List<CasePriorityModel>> seedDefaultCasePriorities({
    String? token,
  }) async {
    log('Seeding default case priorities');

    final response = await Api().post(
      url: 'case-priorities/seed-defaults',
      body: const <String, dynamic>{},
      token: token,
    );

    log('Seed CasePriorities response data: ${logSafe(response.data)}');

    return (response.data as List<dynamic>)
        .map((e) => CasePriorityModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------------------------------------------------- priority quotas ---
  //
  // A doctor's own free allowance per priority, overriding the laboratory's
  // default. **One doctor and one priority per call** — there is no bulk
  // endpoint, so handing an allowance to a whole city costs one request per
  // doctor.
  // ---------------------------------------------------------------------

  /// `GET /doctors/{doctorId}/priority-quota`
  Future<DoctorPriorityQuotaModel> getDoctorPriorityQuota({
    required String doctorId,
    String? token,
  }) async {
    log('Fetching priority quota for doctor: $doctorId');

    final data = await Api().get(
      url: 'doctors/$doctorId/priority-quota',
      token: token,
    );

    return DoctorPriorityQuotaModel.fromJson(data as Map<String, dynamic>);
  }

  /// `POST /doctors/{doctorId}/priority-quota/{priorityId}/increase`
  ///
  /// Bumps one doctor's allowance at one level — permanently or for this
  /// period only, free or against an invoice. See
  /// [IncreasePriorityAllowanceRequestModel] for why those are two separate
  /// choices rather than one.
  Future<DoctorPriorityQuotaModel> increaseDoctorPriorityAllowance({
    required String doctorId,
    required String priorityId,
    required IncreasePriorityAllowanceRequestModel body,
    String? token,
  }) async {
    log('Increasing priority $priorityId for doctor $doctorId');

    final response = await Api().post(
      url: 'doctors/$doctorId/priority-quota/$priorityId/increase',
      body: body.toJson(),
      token: token,
    );

    return DoctorPriorityQuotaModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `GET /case-priorities/overview` — every doctor's standing, one query.
  Future<PriorityOverviewModel> getPriorityOverview({
    String? search,
    String? token,
  }) async {
    log('Fetching priority overview');

    final query = search == null || search.isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search)}';

    final data = await Api().get(
      url: 'case-priorities/overview$query',
      token: token,
    );

    return PriorityOverviewModel.fromJson(
      data as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /case-priorities/{id}/allowances` — only the doctors with an
  /// override at this level. The absence of a row means standard terms.
  Future<List<PriorityAllowanceModel>> getPriorityAllowances({
    required String priorityId,
    String? token,
  }) async {
    log('Fetching allowances for priority: $priorityId');

    final data = await Api().get(
      url: 'case-priorities/$priorityId/allowances',
      token: token,
    );

    return _decodeList(data, PriorityAllowanceModel.fromJson);
  }

  /// `PUT /case-priorities/{id}/allowances` — writes one level's terms onto a
  /// set of doctors. Not a replace: doctors not listed keep what they had.
  Future<List<PriorityAllowanceModel>> setPriorityAllowances({
    required String priorityId,
    required BulkSetPriorityAllowanceRequestModel body,
    String? token,
  }) async {
    log('Setting allowances for priority $priorityId');

    final response = await Api().put(
      url: 'case-priorities/$priorityId/allowances',
      body: body.toJson(),
      token: token,
    );

    return _decodeList(response.data, PriorityAllowanceModel.fromJson);
  }

  /// `PUT /doctors/{doctorId}/priority-quota`
  Future<DoctorPriorityQuotaModel> setDoctorPriorityAllowance({
    required String doctorId,
    required SetPriorityAllowanceRequestModel body,
    String? token,
  }) async {
    log('Setting priority allowance for $doctorId: ${body.toJson()}');

    final response = await Api().put(
      url: 'doctors/$doctorId/priority-quota',
      body: body.toJson(),
      token: token,
    );

    return DoctorPriorityQuotaModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ----------------------------------------------------------------- cases ---

  /// [stageIds] narrows to the lab's own workflow stages and is **repeatable**
  /// — which is why the query is built as an ordered list of entries rather
  /// than a map: a map cannot hold `StageIds` twice.
  ///
  /// The date window filters on *reception*, not the due date; the API's old
  /// `DueDateFrom`/`DueDateTo` params are gone and were silently ignored.
  /// The `ClinicCaseFilter` query params shared by `GET /Cases` and
  /// `GET /Reports/cases` — the CSV export takes the same filter shape, so
  /// building it once keeps the two from silently drifting apart.
  static List<MapEntry<String, String>> _caseFilterParams({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    int? phaseTab,
    String? slaParam,
  }) {
    final params = <MapEntry<String, String>>[];
    void add(String key, String? value) {
      if (value != null && value.isNotEmpty) {
        params.add(MapEntry(key, value));
      }
    }

    add('Search', search);
    add('DoctorId', doctorId);
    add('ClinicId', clinicId);
    add('PatientId', patientId);
    add('PriorityId', priorityId);
    add('ReceivedFrom', receivedFrom);
    add('ReceivedTo', receivedTo);
    // A field of its own, not folded into `Phase`/`Phases`: those two already
    // carry older meanings the server still honours for callers that never
    // send a tab, and layering a third meaning onto them would need a document
    // to disambiguate which of them a given request meant.
    add('PhaseTab', phaseTab?.toString());
    // Exactly one of IsLate/DueToday/NoExpectedCompletion, and only when the
    // segment is on: the three exclude one another server-side.
    add(slaParam ?? '', slaParam == null ? null : 'true');
    for (final stageId in stageIds ?? const <String>[]) {
      add('StageIds', stageId);
    }
    for (final stageId in restorationStageIds ?? const <String>[]) {
      add('RestorationStageIds', stageId);
    }
    // Specific restorations handed to this login by a temporary override —
    // restoration ids, not stage ids, so they match only that one piece.
    for (final restorationId in overriddenRestorationIds ?? const <String>[]) {
      add('OverriddenCaseRestorationIds', restorationId);
    }
    // "My tasks" means any one of the three matches, not all of them: the
    // server ANDs the stage lists unless told otherwise.
    if (matchAnyAssignedStage) add('MatchAnyAssignedStage', 'true');
    // Repeated key, not a comma-joined list — that is how the endpoint
    // declares its array parameters. Sending none leaves the case list scoped
    // to the `X-Laboratory-Id` header, which is the ordinary single-lab view;
    // the server pins a user without `Branches` to that header regardless.
    for (final laboratoryId in laboratoryIds ?? const <String>[]) {
      add('LaboratoryIds', laboratoryId);
    }

    return params;
  }

  /// [stageIds] narrows to the lab's own workflow stages and is **repeatable**
  /// — which is why the query is built as an ordered list of entries rather
  /// than a map: a map cannot hold `StageIds` twice.
  ///
  /// The date window filters on *reception*, not the due date; the API's old
  /// `DueDateFrom`/`DueDateTo` params are gone and were silently ignored.
  ///
  /// The first 200 rows only — for pickers that search rather than scroll.
  /// The cases list pages through [getCasesPage] instead.
  Future<List<CaseListItemModel>> getCases({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    int? phaseTab,
    String? slaParam,
    String? token,
  }) async {
    final page = await getCasesPage(
      search: search,
      doctorId: doctorId,
      clinicId: clinicId,
      patientId: patientId,
      priorityId: priorityId,
      stageIds: stageIds,
      restorationStageIds: restorationStageIds,
      overriddenRestorationIds: overriddenRestorationIds,
      matchAnyAssignedStage: matchAnyAssignedStage,
      laboratoryIds: laboratoryIds,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
      phaseTab: phaseTab,
      slaParam: slaParam,
      pageSize: 200,
      token: token,
    );
    return page.items;
  }

  /// `GET /Cases` — one page of the list, with the total behind it.
  Future<CasesPageModel> getCasesPage({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    int? phaseTab,
    String? slaParam,
    String? token,
    int page = 1,
    int pageSize = 30,
  }) async {
    log('Fetching cases page $page');

    final params = <MapEntry<String, String>>[
      MapEntry('Page', '$page'),
      MapEntry('PageSize', '$pageSize'),
      ..._caseFilterParams(
        search: search,
        doctorId: doctorId,
        clinicId: clinicId,
        patientId: patientId,
        priorityId: priorityId,
        stageIds: stageIds,
        restorationStageIds: restorationStageIds,
        overriddenRestorationIds: overriddenRestorationIds,
        matchAnyAssignedStage: matchAnyAssignedStage,
        laboratoryIds: laboratoryIds,
        receivedFrom: receivedFrom,
        receivedTo: receivedTo,
        phaseTab: phaseTab,
        slaParam: slaParam,
      ),
    ];

    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(url: 'Cases?$query', token: token);

    log('Cases response data: ${logSafe(responseData)}');

    // The endpoint returns a paged result: { items: [...], ... }.
    final items = responseData is Map<String, dynamic>
        ? (responseData['items'] as List<dynamic>? ?? const [])
        : (responseData as List<dynamic>);

    // Only the first page is cached: it is what the offline fallback shows,
    // and a later page cached alone would pass for the whole list.
    final isUnfiltered =
        page == 1 &&
        search == null &&
        doctorId == null &&
        clinicId == null &&
        patientId == null &&
        priorityId == null &&
        (stageIds == null || stageIds.isEmpty) &&
        (restorationStageIds == null || restorationStageIds.isEmpty) &&
        (overriddenRestorationIds == null ||
            overriddenRestorationIds.isEmpty) &&
        !matchAnyAssignedStage &&
        receivedFrom == null &&
        receivedTo == null &&
        // A tab or an SLA segment narrows the list exactly as a filter does;
        // caching a narrowed page as "the case list" would hand the offline
        // fallback a slice and call it everything.
        phaseTab == null &&
        slaParam == null;
    if (isUnfiltered) {
      await CacheHelper.saveJson(key: CacheKeys.cachedCasesList, value: items);
    }

    return CasesPageModel.fromJson(responseData);
  }

  /// `GET /Cases/phase-counts` — how many cases sit behind each lifecycle tab.
  ///
  /// Takes the same filters the list is showing **except** the tab itself:
  /// counting is what this exists to do instead of applying it, so a tab bar
  /// built from it shows the size of every tab, not just the open one.
  Future<CasePhaseCountsModel> getCasePhaseCounts({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    String? slaParam,
    String? token,
  }) async {
    log('Fetching case phase counts');

    final params = _caseFilterParams(
      search: search,
      doctorId: doctorId,
      clinicId: clinicId,
      patientId: patientId,
      priorityId: priorityId,
      stageIds: stageIds,
      restorationStageIds: restorationStageIds,
      overriddenRestorationIds: overriddenRestorationIds,
      matchAnyAssignedStage: matchAnyAssignedStage,
      laboratoryIds: laboratoryIds,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
      slaParam: slaParam,
    );
    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(
      url: 'Cases/phase-counts${query.isEmpty ? '' : '?$query'}',
      token: token,
    );

    return CasePhaseCountsModel.fromJson(
      responseData as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /Cases/sla-counts` — the three date badges, under the same filters
  /// the list is showing except the SLA segment itself and the phase tab.
  Future<CaseSlaCountsModel> getCaseSlaCounts({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? restorationStageIds,
    List<String>? overriddenRestorationIds,
    bool matchAnyAssignedStage = false,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    String? token,
  }) async {
    log('Fetching case SLA counts');

    final params = _caseFilterParams(
      search: search,
      doctorId: doctorId,
      clinicId: clinicId,
      patientId: patientId,
      priorityId: priorityId,
      stageIds: stageIds,
      restorationStageIds: restorationStageIds,
      overriddenRestorationIds: overriddenRestorationIds,
      matchAnyAssignedStage: matchAnyAssignedStage,
      laboratoryIds: laboratoryIds,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
    );
    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final responseData = await Api().get(
      url: 'Cases/sla-counts${query.isEmpty ? '' : '?$query'}',
      token: token,
    );

    return CaseSlaCountsModel.fromJson(
      responseData as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /Cases/my-workflow-assignments` — the stages this login may act on.
  ///
  /// Server-resolved: it is the union of being named personally and belonging
  /// to a department the stage lists, through the employee's *active*
  /// membership spell — none of which the client holds.
  Future<MyWorkflowAssignmentsModel> getMyWorkflowAssignments({
    String? token,
  }) async {
    log('Fetching my workflow assignments');

    final responseData = await Api().get(
      url: 'Cases/my-workflow-assignments',
      token: token,
    );

    return MyWorkflowAssignmentsModel.fromJson(
      responseData as Map<String, dynamic>? ?? const {},
    );
  }

  /// `GET /Reports/cases` — the case list as a CSV file, filtered the same
  /// way `GET /Cases` is. Raw bytes: goes through [Api.dio] directly, the
  /// same as [downloadInvoicePdf], since [Api.get] only ever decodes JSON.
  Future<List<int>> exportCasesCsv({
    String? search,
    String? doctorId,
    String? clinicId,
    String? patientId,
    String? priorityId,
    List<String>? stageIds,
    List<String>? laboratoryIds,
    String? receivedFrom,
    String? receivedTo,
    String? token,
  }) async {
    log('Exporting cases CSV');

    final params = _caseFilterParams(
      search: search,
      doctorId: doctorId,
      clinicId: clinicId,
      patientId: patientId,
      priorityId: priorityId,
      stageIds: stageIds,
      laboratoryIds: laboratoryIds,
      receivedFrom: receivedFrom,
      receivedTo: receivedTo,
    );
    final query = params
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final response = await Api.dio.get<List<int>>(
      'Reports/cases${query.isEmpty ? '' : '?$query'}',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }

  /// `GET /Reports/cases/{id}/pdf` — raw bytes, same pattern as
  /// [downloadInvoicePdf].
  Future<List<int>> downloadCasePdf({required String id, String? token}) async {
    log('Downloading case PDF: $id');

    final response = await Api.dio.get<List<int>>(
      'Reports/cases/$id/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }

  // ------------------------------------------------------ case workflow ---

  /// The laboratory's case-stage catalogue — what replaced the old fixed
  /// `CaseStatus` enum.
  Future<List<CaseStageModel>> getCaseStages({String? token}) async {
    log('Fetching case stages');

    final responseData = await Api().get(url: 'case-statuses', token: token);

    log('Case stages response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedCaseStagesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => CaseStageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CaseDetailModel> getCaseById({
    required String id,
    String? token,
  }) async {
    log('Fetching case by id: $id');

    final responseData = await Api().get(url: 'Cases/$id', token: token);

    log('Case by id response data: ${logSafe(responseData)}');

    return CaseDetailModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Cases/expected-completion-preview` — what the draft would promise.
  ///
  /// Computed by the same code that will date the case at creation, including
  /// the fallback to a slower priority level when the chosen one has no
  /// duration configured — a rule the client cannot see from the catalogue, so
  /// a figure worked out here would quietly disagree with the case once filed.
  ///
  /// Null means no restoration type on the draft has any duration at all:
  /// nothing to promise, not a blank to fill in.
  Future<DateTime?> getExpectedCompletionPreview({
    String? priorityId,
    List<String> restorationTypeIds = const [],
    String? token,
  }) async {
    log(
      'Previewing expected completion for ${restorationTypeIds.length} types',
    );

    final params = <String>[
      if (priorityId != null && priorityId.isNotEmpty)
        'priorityId=${Uri.encodeQueryComponent(priorityId)}',
      for (final id in restorationTypeIds)
        'restorationTypeIds=${Uri.encodeQueryComponent(id)}',
    ];

    final responseData = await Api().get(
      url:
          'Cases/expected-completion-preview${params.isEmpty ? '' : '?${params.join('&')}'}',
      token: token,
    );

    final map = responseData as Map<String, dynamic>?;
    return DateTime.tryParse(map?['expectedCompletionAt'] as String? ?? '');
  }

  /// `GET /Cases/{id}/flow` — the whole lifecycle, assembled by the server.
  ///
  /// The six fixed checkpoints, and nested under `InProduction` the case's own
  /// stages, every restoration's own route, and the stages that wait for all
  /// of them — each node already carrying whether it is done, current, pending
  /// or skipped. Nothing here is recomputed on the client: the plan a case
  /// travels is frozen when the case is created, so walking the restoration
  /// type's live catalogue instead would draw the wrong board for any case in
  /// flight when a lab edits a route.
  Future<CaseFlowModel> getCaseFlow({required String id, String? token}) async {
    log('Fetching flow for case: $id');

    final responseData = await Api().get(url: 'Cases/$id/flow', token: token);

    return CaseFlowModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Cases/by-number/{caseNumber}` — resolves a scanned case barcode.
  Future<CaseDetailModel> getCaseByNumber({
    required String caseNumber,
    String? token,
  }) async {
    log('Fetching case by number: $caseNumber');

    final responseData = await Api().get(
      url: 'Cases/by-number/${Uri.encodeComponent(caseNumber)}',
      token: token,
    );

    return CaseDetailModel.fromJson(responseData as Map<String, dynamic>);
  }

  /// `GET /Cases/restorations/by-number/{restorationNumber}` — resolves a
  /// scanned restoration barcode. Answers with the whole case, plus which
  /// restoration on it was scanned.
  Future<ScannedRestorationModel> getRestorationByNumber({
    required String restorationNumber,
    String? token,
  }) async {
    log('Fetching restoration by number: $restorationNumber');

    final responseData = await Api().get(
      url:
          'Cases/restorations/by-number/'
          '${Uri.encodeComponent(restorationNumber)}',
      token: token,
    );

    return ScannedRestorationModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  /// `GET /Cases/{id}/print-ticket` — the thermal ticket's data, including the
  /// `qrPayload` the case's own barcode encodes.
  Future<CasePrintTicketModel> getCasePrintTicket({
    required String id,
    String? token,
  }) async {
    log('Fetching print ticket for case: $id');

    final responseData = await Api().get(
      url: 'Cases/$id/print-ticket',
      token: token,
    );

    return CasePrintTicketModel.fromJson(responseData as Map<String, dynamic>);
  }

  Future<CaseDetailModel> createCase({
    required CreateCaseRequestModel createCaseRequestBody,
    String? token,
  }) async {
    final body = createCaseRequestBody.toJson();

    log('Sending Create Case request with: ${logSafe(body)}');

    final response = await Api().post(url: 'Cases', body: body, token: token);

    log('Create Case response data: ${logSafe(response.data)}');

    return CaseDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCase({required String id, String? token}) async {
    log('Deleting case: $id');

    final response = await Api().delete(url: 'Cases/$id', token: token);

    log('Delete Case response data: ${logSafe(response.data)}');
  }

  Future<void> setRestorationStage({
    required String caseId,
    required String restorationId,
    required String stageId,
    String? note,
    SendBackReason reason = const SendBackReason(),
    String? token,
  }) async {
    log('Setting stage $stageId for restoration $restorationId (case $caseId)');

    final response = await Api().put(
      url: 'Cases/$caseId/restorations/$restorationId/stage',
      // The reason only matters on a send-back; a forward move sends none.
      body: {'stageId': stageId, 'note': note, ...reason.toJson()},
      token: token,
    );

    log('Set Restoration stage response data: ${logSafe(response.data)}');
  }

  /// Moves the case to another of the lab's workflow stages.
  ///
  /// [caseStatusId] is the id of a stage, not an enum member. The target must
  /// be reachable by an edge from where the case is — the server enforces
  /// that, and it also refuses any hand-move across production for everyone,
  /// admins included.
  ///
  /// Returns nothing: the response shape is not contracted, and the caller
  /// refetches the case anyway.
  Future<void> moveCaseStage({
    required String id,
    required String caseStatusId,
    String? note,
    String? rejectionReason,
    String? token,
  }) async {
    log('Moving case $id to stage $caseStatusId');

    final response = await Api().put(
      url: 'Cases/$id/status',
      body: {
        'caseStatusId': caseStatusId,
        'note': note,
        'rejectionReason': rejectionReason,
      },
      token: token,
    );

    log('Move case stage response data: ${logSafe(response.data)}');
  }

  /// `PUT /Cases/{id}/restorations/{restorationId}/stage/reject`
  ///
  /// Declines a proposed move: the piece stays exactly where it is, and the
  /// refusal — with the stage that was attempted — is written to its history,
  /// so the timeline shows what was asked for as well as what happened.
  Future<void> rejectRestorationStage({
    required String caseId,
    required String restorationId,
    required String attemptedStageId,
    required String reason,
    String? token,
  }) async {
    log('Rejecting stage $attemptedStageId for restoration $restorationId');

    await Api().put(
      url: 'Cases/$caseId/restorations/$restorationId/stage/reject',
      body: {'attemptedStageId': attemptedStageId, 'reason': reason},
      token: token,
    );
  }

  /// `GET /Cases/{id}/restorations/{restorationId}/forward-targets`
  ///
  /// Where a piece may be sent **next**. Server-driven for the same reason the
  /// rework list is: the next step is the stage's declared `nextStageId`, or
  /// the following position in the frozen plan's order — and with parallel
  /// steps there can be more than one. A client walking the type's live route
  /// gets both of those wrong the moment a lab edits the route mid-case.
  Future<List<CaseWorkflowStageModel>> getForwardTargets({
    required String caseId,
    required String restorationId,
    String? token,
  }) async {
    log('Fetching forward targets for restoration $restorationId');

    final data = await Api().get(
      url: 'Cases/$caseId/restorations/$restorationId/forward-targets',
      token: token,
    );

    return _decodeList(data, CaseWorkflowStageModel.fromJson);
  }

  // ---- CasePhase checkpoints -------------------------------------------

  /// `GET /Cases/{id}/restorations/{restorationId}/rework-targets`
  ///
  /// Where a rejected piece may be sent back to. Server-driven: it is the
  /// stage's declared `sendBackToStageId`, or every earlier stage when none
  /// was declared, and the rules behind that are the server's.
  Future<List<CaseWorkflowStageModel>> getReworkTargets({
    required String caseId,
    required String restorationId,
    String? token,
  }) async {
    log('Fetching rework targets for restoration $restorationId');

    final data = await Api().get(
      url: 'Cases/$caseId/restorations/$restorationId/rework-targets',
      token: token,
    );

    return _decodeList(data, CaseWorkflowStageModel.fromJson);
  }
  //
  // The fixed six-value lifecycle (New → Received → InProduction →
  // QualityCheck → Ready → Delivered) is not lab-drawn and is not moved by
  // picking a stage: each step past it is its own action. A case sitting in
  // `New` has no stage moves on offer at all — recording the material is what
  // opens its workflow, which is why the pre-production stages looked stuck.

  /// `PUT /Cases/{id}/material-received`
  Future<void> receiveCaseMaterial({
    required String id,
    String? note,
    String? token,
  }) async {
    log('Recording material received for case $id');

    await Api().put(
      url: 'Cases/$id/material-received',
      body: {'note': note},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/material-received/undo`
  ///
  /// Takes the case back to `New`. The escape hatch for the front desk
  /// recording an arrival against the wrong case — which happens, and which
  /// without this leaves the case in a phase nothing can walk back.
  Future<void> undoCaseMaterialReceived({
    required String id,
    String? token,
  }) async {
    log('Undoing material received for case $id');

    await Api().put(
      url: 'Cases/$id/material-received/undo',
      body: const <String, dynamic>{},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/quality-check/pass`
  Future<void> passCaseQualityCheck({
    required String id,
    String? note,
    String? token,
  }) async {
    log('Passing quality check for case $id');

    await Api().put(
      url: 'Cases/$id/quality-check/pass',
      body: {'note': note},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/trying/approve`
  Future<void> approveCaseTrying({
    required String id,
    String? note,
    String? token,
  }) async {
    log('Approving trying for case $id');

    await Api().put(
      url: 'Cases/$id/trying/approve',
      body: {'note': note},
      token: token,
    );
  }

  /// `PUT /Cases/deliver-directly` — "تم التسليم" for many cases at once.
  ///
  /// Each case is walked through every remaining step of its route on its
  /// own; one refusing does not stop the others, so the answer is a row per
  /// case rather than one success or failure.
  Future<List<DeliverDirectlyResultModel>> deliverCasesDirectly({
    required List<String> caseIds,
    String? note,
    String? token,
  }) async {
    log('Delivering ${caseIds.length} cases directly');

    final response = await Api().put(
      url: 'Cases/deliver-directly',
      body: {'caseIds': caseIds, 'note': note},
      token: token,
    );
    final data = response.data;
    if (data is! List) return const [];
    return [
      for (final row in data)
        if (row is Map<String, dynamic>)
          DeliverDirectlyResultModel.fromJson(row),
    ];
  }

  /// `PUT /Cases/{id}/deliver-directly` — the single-case twin, which also
  /// records how the work leaves the lab.
  ///
  /// Returns nothing: the caller refetches the case anyway.
  Future<void> deliverCaseDirectly({
    required String id,
    String? note,
    CollectionMethod collectionMethod = CollectionMethod.none,
    String? token,
  }) async {
    log('Delivering case $id directly');

    await Api().put(
      url: 'Cases/$id/deliver-directly',
      body: {'note': note, 'collectionMethod': collectionMethod.value},
      token: token,
    );
  }

  /// `PUT /Cases/{id}/trying/reject`
  ///
  /// The other half of trying: the doctor refused the fit. Each flagged piece
  /// names the stage it goes back to and may carry its own note, and the case
  /// itself drops back into production — so this is one request, not a reject
  /// per restoration followed by a case move.
  Future<void> rejectCaseTrying({
    required String id,
    required List<TryingRejectLine> restorations,
    String? note,
    String? token,
  }) async {
    log('Rejecting trying for case $id (${restorations.length} restorations)');

    await Api().put(
      url: 'Cases/$id/trying/reject',
      body: {
        'note': note,
        'restorations': [
          for (final restoration in restorations) restoration.toJson(),
        ],
      },
      token: token,
    );
  }

  /// `PUT /Cases/{id}/delay-reason`
  Future<void> setCaseDelayReason({
    required String id,
    required String reason,
    String? note,
    String? token,
  }) async {
    log('Recording a delay reason for case $id');

    await Api().put(
      url: 'Cases/$id/delay-reason',
      body: {'reason': reason, 'note': note},
      token: token,
    );
  }

  Future<CaseFileModel> uploadCaseFile({
    required String id,
    required String filePath,
    String? token,
  }) async {
    log('Uploading file for case: $id');

    final formData = FormData.fromMap({
      'Id': id,
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'Cases/$id/files',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Upload Case file response data: ${logSafe(response.data)}');

    return CaseFileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CaseMessageModel>> getCaseMessages({
    required String id,
    String? token,
  }) async {
    log('Fetching messages for case: $id');

    final responseData = await Api().get(
      url: 'Cases/$id/messages',
      token: token,
    );

    log('Case messages response data: ${logSafe(responseData)}');

    return (responseData as List<dynamic>)
        .map((e) => CaseMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CaseMessageModel> sendCaseMessage({
    required String id,
    String? message,
    String? replyToMessageId,
    String? filePath,
    String? token,
  }) async {
    log('Sending message for case: $id');

    final formData = FormData.fromMap({
      'Message': ?message,
      'ReplyToMessageId': ?replyToMessageId,
      if (filePath != null) 'File': await MultipartFile.fromFile(filePath),
    });

    final response = await Api().post(
      url: 'Cases/$id/messages',
      body: formData,
      isFormData: true,
      token: token,
    );

    log('Send Case message response data: ${logSafe(response.data)}');

    return CaseMessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /Cases/{id}/messages/{messageId}` — the API allows this for an
  /// admin or the message's own sender, and rejects anyone else.
  Future<void> deleteCaseMessage({
    required String id,
    required String messageId,
    String? token,
  }) async {
    log('Deleting message $messageId for case: $id');

    final response = await Api().delete(
      url: 'Cases/$id/messages/$messageId',
      token: token,
    );

    log('Delete Case message response data: ${logSafe(response.data)}');
  }

  Future<void> deleteCaseFile({
    required String id,
    required String fileId,
    String? token,
  }) async {
    log('Deleting file $fileId for case: $id');

    final response = await Api().delete(
      url: 'Cases/$id/files/$fileId',
      token: token,
    );

    log('Delete Case file response data: ${logSafe(response.data)}');
  }

  // ---------------------------------------------------------------------
  // Case workflow editing (MOBILE-SPEC §15.5b)
  // ---------------------------------------------------------------------

  /// `POST /case-statuses`
  Future<CaseStageModel> createCaseStage({
    required SaveCaseStageRequestModel body,
    String? token,
  }) async {
    log('Creating case stage: ${body.toJson()}');

    final response = await Api().post(
      url: 'case-statuses',
      body: body.toJson(),
      token: token,
    );

    return CaseStageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `PUT /case-statuses/{id}`
  Future<CaseStageModel> updateCaseStage({
    required String id,
    required SaveCaseStageRequestModel body,
    String? token,
  }) async {
    log('Updating case stage $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'case-statuses/$id',
      body: body.toJson(),
      token: token,
    );

    return CaseStageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `DELETE /case-statuses/{id}`
  Future<void> deleteCaseStage({required String id, String? token}) async {
    log('Deleting case stage: $id');

    await Api().delete(url: 'case-statuses/$id', token: token);
  }

  /// `GET /case-statuses/optional` — the stages a case may skip.
  ///
  /// Narrowed by [intake] where given: a route carries a traditional head and
  /// a digital head, and the optional steps of one are not offered on the
  /// other.
  Future<List<CaseStageModel>> getOptionalCaseStages({
    int? intake,
    String? token,
  }) async {
    log('Fetching optional case stages');

    final responseData = await Api().get(
      url: 'case-statuses/optional${intake == null ? '' : '?intake=$intake'}',
      token: token,
    );

    return _decodeList(responseData, CaseStageModel.fromJson);
  }

  /// `PUT /case-statuses/{id}/assignments` — who staffs this stage.
  ///
  /// A separate, smaller request than the full save on purpose: staffing is
  /// edited constantly and by different people than the ones who draw the
  /// workflow, and pushing it through the whole-status body would make every
  /// roster change a chance to clobber the rules.
  ///
  /// Each list **replaces** its set when present; passing null leaves that
  /// side alone. [userIds] are logins, not employee ids.
  Future<CaseStageModel> setCaseStageAssignments({
    required String id,
    List<String>? departmentIds,
    List<String>? userIds,
    String? token,
  }) async {
    log('Setting assignments for case status: $id');

    final response = await Api().put(
      url: 'case-statuses/$id/assignments',
      body: {'departmentIds': departmentIds, 'userIds': userIds},
      token: token,
    );

    return CaseStageModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /case-statuses/validate` — the defects that make a case silently
  /// stop, computed server-side against the drawn flow.
  Future<List<RouteProblemModel>> validateCaseStatuses({String? token}) async {
    log('Validating case-status workflow');

    final responseData = await Api().get(
      url: 'case-statuses/validate',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map((e) => RouteProblemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /case-statuses/seed-defaults` — idempotent starter workflow.
  Future<void> seedDefaultCaseStages({String? token}) async {
    log('Seeding default case stages');

    await Api().post(
      url: 'case-statuses/seed-defaults',
      body: const {},
      token: token,
    );
  }

  /// Decodes a JSON array response into models, tolerating a `null` body.
  List<T> _decodeList<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: false);
  }
  // ---------------------------------------------------------------------
  // Case ticket templates (`/CaseTicketTemplates`) — the thermal-ticket
  // layout library, gated by `Branches` same as every other per-laboratory
  // settings screen (order-form template, footer contacts, logo).
  // ---------------------------------------------------------------------

  Future<List<CaseTicketTemplateListItemModel>> getCaseTicketTemplates({
    String? laboratoryId,
    String? token,
  }) async {
    log('Fetching case ticket templates (laboratoryId: $laboratoryId)');

    final responseData = await Api().get(
      url: laboratoryId == null
          ? 'CaseTicketTemplates'
          : 'CaseTicketTemplates?laboratoryId=$laboratoryId',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) => CaseTicketTemplateListItemModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<CaseTicketTemplateModel> getCaseTicketTemplateById({
    required String id,
    String? token,
  }) async {
    log('Fetching case ticket template: $id');

    final responseData = await Api().get(
      url: 'CaseTicketTemplates/$id',
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      responseData as Map<String, dynamic>,
    );
  }

  Future<CaseTicketTemplateModel> createCaseTicketTemplate({
    required CreateCaseTicketTemplateRequestModel body,
    String? laboratoryId,
    String? token,
  }) async {
    log('Creating case ticket template: ${body.toJson()}');

    final response = await Api().post(
      url: laboratoryId == null
          ? 'CaseTicketTemplates'
          : 'CaseTicketTemplates?laboratoryId=$laboratoryId',
      body: body.toJson(),
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CaseTicketTemplateModel> updateCaseTicketTemplate({
    required String id,
    required UpdateCaseTicketTemplateRequestModel body,
    String? token,
  }) async {
    log('Updating case ticket template $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'CaseTicketTemplates/$id',
      body: body.toJson(),
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> deleteCaseTicketTemplate({
    required String id,
    String? token,
  }) async {
    log('Deleting case ticket template: $id');

    await Api().delete(url: 'CaseTicketTemplates/$id', token: token);
  }

  Future<CaseTicketTemplateModel> setDefaultCaseTicketTemplate({
    required String id,
    String? token,
  }) async {
    log('Setting default case ticket template: $id');

    final response = await Api().post(
      url: 'CaseTicketTemplates/$id/set-default',
      body: const <String, dynamic>{},
      token: token,
    );

    return CaseTicketTemplateModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

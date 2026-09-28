import 'dart:developer';

import 'package:dental_lab_app/core/helper/debug_log.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/save_workflow_stage_request_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/create_restoration_type_request_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/doctor_restoration_type_lookup_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/update_restoration_type_request_model.dart';

/// The `restoration types` endpoints — split out of
/// [ApiService], reached through the same instance.
extension RestorationTypesApi on ApiService {
  // ----------------------------------------------------- restoration types ---

  Future<List<RestorationTypeModel>> getRestorationTypes({
    String? token,
  }) async {
    log('Fetching restoration types');

    final responseData = await Api().get(url: 'RestorationTypes', token: token);

    log('Restoration types response data: ${logSafe(responseData)}');

    await CacheHelper.saveJson(
      key: CacheKeys.cachedRestorationTypesList,
      value: responseData,
    );

    return (responseData as List<dynamic>)
        .map((e) => RestorationTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /RestorationTypes/lookup?doctorId=&intake=` — the catalog priced
  /// for one doctor (their tier/negotiated/list rate). This is what a
  /// case-creation form must quote from, not the plain list above — quoting
  /// a different total than the invoice charges is the one pricing bug a
  /// lab never forgives.
  ///
  /// [intake] is the `RouteStageAppliesTo` value (2 = traditional, 3 =
  /// digital), not `ImpressionMethod`'s own (1/2) — the caller converts.
  Future<List<DoctorRestorationTypeLookupModel>> getRestorationTypesLookup({
    String? doctorId,
    int? intake,
    String? token,
  }) async {
    log('Fetching doctor-priced restoration types: doctorId=$doctorId');

    final params = <String>[];
    if (doctorId != null && doctorId.isNotEmpty) {
      params.add('doctorId=${Uri.encodeQueryComponent(doctorId)}');
    }
    if (intake != null) params.add('intake=$intake');
    final query = params.isEmpty ? '' : '?${params.join('&')}';

    final responseData = await Api().get(
      url: 'RestorationTypes/lookup$query',
      token: token,
    );

    return (responseData as List<dynamic>)
        .map(
          (e) => DoctorRestorationTypeLookupModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<RestorationTypeModel> createRestorationType({
    required CreateRestorationTypeRequestModel createRequestBody,
    String? token,
  }) async {
    final body = createRequestBody.toJson();

    log('Sending Create RestorationType request with: ${logSafe(body)}');

    final response = await Api().post(
      url: 'RestorationTypes',
      body: body,
      token: token,
    );

    log('Create RestorationType response data: ${logSafe(response.data)}');

    return RestorationTypeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<RestorationTypeModel> updateRestorationType({
    required String id,
    required UpdateRestorationTypeRequestModel updateRequestBody,
    String? token,
  }) async {
    final body = updateRequestBody.toJson();

    log('Sending Update RestorationType request with: ${logSafe(body)}');

    final response = await Api().put(
      url: 'RestorationTypes/$id',
      body: body,
      token: token,
    );

    log('Update RestorationType response data: ${logSafe(response.data)}');

    return RestorationTypeModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteRestorationType({
    required String id,
    String? token,
  }) async {
    log('Deleting restoration type: $id');

    final response = await Api().delete(
      url: 'RestorationTypes/$id',
      token: token,
    );

    log('Delete RestorationType response data: ${logSafe(response.data)}');
  }


  // ---------------------------------------------------------------------
  // Restoration route stages (`/restoration-type-stages`). Renamed server-side
  // from `/CaseWorkflowStages`, which now 404s — the old path is what made the
  // restoration-route screen fail to open at all.
  //
  // A different catalogue from `/case-statuses`: these are the manufacturing
  // stages of one restoration *type's* route, and they carry the concern only
  // production has — a checkpoint that may reject. `appliesTo` is the one
  // gate left that decides whether a stage is cut onto a given case at all;
  // per-priority durations moved to the restoration type itself.
  // ---------------------------------------------------------------------

  /// `GET /restoration-type-stages`
  Future<List<CaseWorkflowStageModel>> getWorkflowStages({
    String? restorationTypeId,
    String? token,
  }) async {
    log('Fetching workflow stages for type: $restorationTypeId');

    final query = restorationTypeId == null || restorationTypeId.isEmpty
        ? ''
        : '?restorationTypeId=${Uri.encodeQueryComponent(restorationTypeId)}';

    final data = await Api().get(
      url: 'restoration-type-stages$query',
      token: token,
    );

    return decodeJsonList(data, CaseWorkflowStageModel.fromJson);
  }

  /// `GET /restoration-type-stages/next` — the step that follows
  /// [currentStageId] on this type's route.
  ///
  /// A **list**, not one stage: stages sharing an `order` run in parallel, so
  /// the next step can hold several. The server resolves it the same way the
  /// stage-move endpoint does (honouring any `nextStageId` override), which is
  /// why the move must be aimed with this rather than with arithmetic on
  /// `order` — the client would disagree with the server the moment a lab
  /// declares a forward override.
  ///
  /// An empty list means the restoration is at the end of its route.
  Future<List<CaseWorkflowStageModel>> getNextRestorationStages({
    required String restorationTypeId,
    String? currentStageId,
    ImpressionMethod? intake,
    String? token,
  }) async {
    log('Fetching next stage after $currentStageId on type $restorationTypeId');

    final params = <String>[
      'restorationTypeId=${Uri.encodeQueryComponent(restorationTypeId)}',
      if (currentStageId != null && currentStageId.isNotEmpty)
        'currentStageId=${Uri.encodeQueryComponent(currentStageId)}',
      // The route carries a traditional head and a digital head; without the
      // intake the server cannot tell which one this case is running.
      if (intake != null)
        'intake=${intake == ImpressionMethod.digital ? RouteStageAppliesTo.digitalOnly.value : RouteStageAppliesTo.traditionalOnly.value}',
    ];

    final data = await Api().get(
      url: 'restoration-type-stages/next?${params.join('&')}',
      token: token,
    );

    return decodeJsonList(data, CaseWorkflowStageModel.fromJson);
  }

  /// `POST /restoration-type-stages`
  Future<CaseWorkflowStageModel> createWorkflowStage({
    required CreateWorkflowStageRequestModel body,
    String? token,
  }) async {
    log('Creating workflow stage: ${body.toJson()}');

    final response = await Api().post(
      url: 'restoration-type-stages',
      body: body.toJson(),
      token: token,
    );

    return CaseWorkflowStageModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /restoration-type-stages/{id}`
  Future<CaseWorkflowStageModel> updateWorkflowStage({
    required String id,
    required UpdateWorkflowStageRequestModel body,
    String? token,
  }) async {
    log('Updating workflow stage $id: ${body.toJson()}');

    final response = await Api().put(
      url: 'restoration-type-stages/$id',
      body: body.toJson(),
      token: token,
    );

    return CaseWorkflowStageModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `GET /routing/routes/{restorationTypeId}` — the route's stages and the
  /// server's own live verdict on whether it runs.
  Future<RouteDefinitionModel> getRouteDefinition({
    required String restorationTypeId,
    String? token,
  }) async {
    log('Fetching route definition for $restorationTypeId');

    final data = await Api().get(
      url: 'routing/routes/$restorationTypeId',
      token: token,
    );

    return RouteDefinitionModel.fromJson(data as Map<String, dynamic>);
  }

  /// `DELETE /restoration-type-stages/{id}`
  Future<void> deleteWorkflowStage({required String id, String? token}) async {
    log('Deleting workflow stage: $id');

    await Api().delete(url: 'restoration-type-stages/$id', token: token);
  }


}

import 'dart:developer';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cacheable_fetch.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/models/route_definition_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_message_model.dart';
import 'package:dental_lab_app/features/cases/data/models/create_case_request_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/deliver_directly_models.dart';
import 'package:dental_lab_app/features/cases/data/models/send_back_models.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class CasesRepo {
  final ApiService _apiService;
  CasesRepo(this._apiService);

  String? get _token => CacheHelper.getData(key: CacheKeys.token) as String?;

  String? _isoDate(DateTime? date) => date?.toIso8601String();

  /// Narrows the rows we ended up with by the filters the query could not
  /// carry.
  ///
  /// Two reasons a filter lands here. The stage filter is re-applied because
  /// the cache-fallback path runs no query at all, and because a server that
  /// ignores an unrecognised param answers with the full list — which reads
  /// as "the filter does nothing". The city filter is here because
  /// `GET /Cases` has no city parameter at all: it can only narrow what
  /// already arrived, so it filters the page rather than the table.
  List<CaseListItemModel> _narrow(
    List<CaseListItemModel> cases,
    CaseFiltersModel filters,
  ) {
    var rows = cases;
    if (filters.stageIds.isNotEmpty) {
      rows = rows
          .where((c) => filters.stageIds.contains(c.stage.stageId))
          .toList();
    }
    if (filters.cityIds.isNotEmpty) {
      rows = rows.where((c) {
        final cityId = c.clinic?.cityId;
        return cityId != null && filters.cityIds.contains(cityId);
      }).toList();
    }
    return rows;
  }

  Future<Either<Failure, List<CaseListItemModel>>> getCases({
    String? search,
    CaseFiltersModel filters = CaseFiltersModel.empty,
  }) async {
    try {
      final cases = await _apiService.getCases(
        search: search,
        doctorId: filters.doctorId,
        clinicId: filters.clinicId,
        patientId: filters.patientId,
        priorityId: filters.priorityId,
        stageIds: filters.stageIds.toList(),
        restorationStageIds: filters.restorationStageIds.toList(),
        overriddenRestorationIds: filters.overriddenRestorationIds.toList(),
        matchAnyAssignedStage: filters.matchAnyAssignedStage,
        laboratoryIds: filters.laboratoryIds.toList(),
        receivedFrom: _isoDate(filters.receivedFrom),
        receivedTo: _isoDate(filters.receivedTo),
        phaseTab: filters.phaseTab.value,
        slaParam: filters.sla.param,
        token: _token,
      );

      log('Fetched ${cases.length} cases');
      return right(_narrow(cases, filters));
    } on DioException catch (e) {
      log('DioException while fetching cases: ${e.message}');
      final cached = fallbackToCache(
        cacheKey: CacheKeys.cachedCasesList,
        fromJson: CaseListItemModel.fromJson,
        onFailure: () => ServerFailure.fromDioException(e),
      );
      return cached.map((cases) => _narrow(cases, filters));
    } catch (e) {
      log('General Exception while fetching cases: ${e.toString()}');
      final cached = fallbackToCache(
        cacheKey: CacheKeys.cachedCasesList,
        fromJson: CaseListItemModel.fromJson,
        onFailure: () => ServerFailure.fromException(e),
      );
      return cached.map((cases) => _narrow(cases, filters));
    }
  }

  /// How many cases stand behind each lifecycle tab, under the filters the
  /// list is showing — the tab bar's badges.
  Future<Either<Failure, CasePhaseCountsModel>> getPhaseCounts({
    String? search,
    CaseFiltersModel filters = CaseFiltersModel.empty,
  }) => _guardPhase(
    'fetching case phase counts',
    () => _apiService.getCasePhaseCounts(
      search: search,
      doctorId: filters.doctorId,
      clinicId: filters.clinicId,
      patientId: filters.patientId,
      priorityId: filters.priorityId,
      stageIds: filters.stageIds.toList(),
      restorationStageIds: filters.restorationStageIds.toList(),
      overriddenRestorationIds: filters.overriddenRestorationIds.toList(),
      matchAnyAssignedStage: filters.matchAnyAssignedStage,
      laboratoryIds: filters.laboratoryIds.toList(),
      receivedFrom: _isoDate(filters.receivedFrom),
      receivedTo: _isoDate(filters.receivedTo),
      slaParam: filters.sla.param,
      token: _token,
    ),
  );

  /// The three date badges (late / due today / no promised date).
  Future<Either<Failure, CaseSlaCountsModel>> getSlaCounts({
    String? search,
    CaseFiltersModel filters = CaseFiltersModel.empty,
  }) => _guardPhase(
    'fetching case SLA counts',
    () => _apiService.getCaseSlaCounts(
      search: search,
      doctorId: filters.doctorId,
      clinicId: filters.clinicId,
      patientId: filters.patientId,
      priorityId: filters.priorityId,
      stageIds: filters.stageIds.toList(),
      restorationStageIds: filters.restorationStageIds.toList(),
      overriddenRestorationIds: filters.overriddenRestorationIds.toList(),
      matchAnyAssignedStage: filters.matchAnyAssignedStage,
      laboratoryIds: filters.laboratoryIds.toList(),
      receivedFrom: _isoDate(filters.receivedFrom),
      receivedTo: _isoDate(filters.receivedTo),
      token: _token,
    ),
  );

  /// The stages the signed-in user may act on — the "my tasks" queue's filter.
  Future<Either<Failure, MyWorkflowAssignmentsModel>>
  getMyWorkflowAssignments() => _guardPhase(
    'fetching my workflow assignments',
    () => _apiService.getMyWorkflowAssignments(token: _token),
  );

  /// Saves the filtered case list as a CSV file and returns its local path.
  /// Same filter shape as [getCases] — the export matches what the list
  /// screen is actually showing, not a separate unfiltered dump.
  Future<Either<Failure, String>> exportCasesCsv({
    String? search,
    CaseFiltersModel filters = CaseFiltersModel.empty,
  }) async {
    try {
      final bytes = await _apiService.exportCasesCsv(
        search: search,
        doctorId: filters.doctorId,
        clinicId: filters.clinicId,
        patientId: filters.patientId,
        priorityId: filters.priorityId,
        stageIds: filters.stageIds.toList(),
        laboratoryIds: filters.laboratoryIds.toList(),
        receivedFrom: _isoDate(filters.receivedFrom),
        receivedTo: _isoDate(filters.receivedTo),
        token: _token,
      );

      final dir = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${dir.path}/cases-$stamp.csv');
      await file.writeAsBytes(bytes, flush: true);

      log('Saved cases CSV to ${file.path}');
      return right(file.path);
    } on DioException catch (e) {
      log('DioException while exporting cases CSV: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while exporting cases CSV: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, String>> downloadCasePdf({
    required String id,
    required String caseNumber,
  }) async {
    try {
      final bytes = await _apiService.downloadCasePdf(id: id, token: _token);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/case-$caseNumber.pdf');
      await file.writeAsBytes(bytes, flush: true);

      log('Saved case PDF to ${file.path}');
      return right(file.path);
    } on DioException catch (e) {
      log('DioException while downloading case PDF: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while downloading case PDF: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseDetailModel>> getCaseById(String id) async {
    try {
      final caseDetail = await _apiService.getCaseById(id: id, token: _token);

      log('Fetched case: ${caseDetail.caseNumber}');
      return right(caseDetail);
    } on DioException catch (e) {
      log('DioException while fetching case: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching case: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Resolves a scanned case barcode to the case it names.
  Future<Either<Failure, CaseDetailModel>> getCaseByNumber(
    String caseNumber,
  ) async {
    try {
      final caseDetail = await _apiService.getCaseByNumber(
        caseNumber: caseNumber,
        token: _token,
      );

      log('Scanned case: ${caseDetail.caseNumber}');
      return right(caseDetail);
    } on DioException catch (e) {
      log('DioException while resolving a case barcode: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while resolving a case barcode: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Resolves a scanned restoration barcode — the piece in the technician's
  /// hand — to its restoration and the case carrying it.
  Future<Either<Failure, ScannedRestorationModel>> getRestorationByNumber(
    String restorationNumber,
  ) async {
    try {
      final scanned = await _apiService.getRestorationByNumber(
        restorationNumber: restorationNumber,
        token: _token,
      );

      log('Scanned restoration: ${scanned.restorationNumber}');
      return right(scanned);
    } on DioException catch (e) {
      log('DioException while resolving a restoration barcode: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while resolving a restoration barcode: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// The case's printable ticket, which carries the barcode payload the lab's
  /// printer encodes.
  Future<Either<Failure, CasePrintTicketModel>> getCasePrintTicket(
    String id,
  ) async {
    try {
      final ticket = await _apiService.getCasePrintTicket(
        id: id,
        token: _token,
      );

      log('Fetched print ticket for case: ${ticket.caseNumber}');
      return right(ticket);
    } on DioException catch (e) {
      log('DioException while fetching a print ticket: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching a print ticket: $e');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Where a rejected piece may go back to — fetched, never computed: the
  /// declared rework target and the "every earlier stage" fallback are both
  /// the server's to decide.
  Future<Either<Failure, List<CaseWorkflowStageModel>>> getReworkTargets({
    required String caseId,
    required String restorationId,
  }) => _guardPhase(
    'fetching rework targets',
    () => _apiService.getReworkTargets(
      caseId: caseId,
      restorationId: restorationId,
      token: _token,
    ),
  );

  /// Where a piece may be sent next — fetched for the same reason the rework
  /// list is: the frozen plan's order, the declared `nextStageId` and parallel
  /// steps are all the server's to resolve.
  Future<Either<Failure, List<CaseWorkflowStageModel>>> getForwardTargets({
    required String caseId,
    required String restorationId,
  }) => _guardPhase(
    'fetching forward targets',
    () => _apiService.getForwardTargets(
      caseId: caseId,
      restorationId: restorationId,
      token: _token,
    ),
  );

  /// Declines a proposed move: the piece stays put and the refusal is
  /// recorded, which is a different act from sending it back for rework.
  Future<Either<Failure, void>> rejectRestorationStage({
    required String caseId,
    required String restorationId,
    required String attemptedStageId,
    required String reason,
  }) => _guardPhase(
    'rejecting a restoration stage move',
    () => _apiService.rejectRestorationStage(
      caseId: caseId,
      restorationId: restorationId,
      attemptedStageId: attemptedStageId,
      reason: reason,
      token: _token,
    ),
  );

  /// What the draft being entered would be promised, asked of the server
  /// rather than worked out here: the priority fallback that decides it is not
  /// visible in the restoration-type catalogue the client holds.
  Future<Either<Failure, DateTime?>> getExpectedCompletionPreview({
    String? priorityId,
    List<String> restorationTypeIds = const [],
  }) => _guardPhase(
    'previewing the expected completion date',
    () => _apiService.getExpectedCompletionPreview(
      priorityId: priorityId,
      restorationTypeIds: restorationTypeIds,
      token: _token,
    ),
  );

  /// The case's whole lifecycle, assembled server-side.
  Future<Either<Failure, CaseFlowModel>> getCaseFlow(String id) => _guardPhase(
    'fetching the case flow',
    () => _apiService.getCaseFlow(id: id, token: _token),
  );

  /// The step that follows [currentStageId] on a restoration type's route.
  ///
  /// A list, because stages sharing an `order` run in parallel; empty means
  /// the restoration has reached the end of its route.
  Future<Either<Failure, List<CaseWorkflowStageModel>>>
  getNextRestorationStages({
    required String restorationTypeId,
    String? currentStageId,
    ImpressionMethod? intake,
  }) => _guardPhase(
    'fetching the next restoration stage',
    () => _apiService.getNextRestorationStages(
      restorationTypeId: restorationTypeId,
      currentStageId: currentStageId,
      intake: intake,
      token: _token,
    ),
  );

  /// The whole route of a restoration type.
  ///
  /// Used to put a name on a stage the case response only identified by id —
  /// the API omits a restoration's expanded `currentStage` for non-admin
  /// employees, and a technician cannot act on a stage the screen will not
  /// name.
  Future<Either<Failure, List<CaseWorkflowStageModel>>> getRestorationRoute({
    required String restorationTypeId,
  }) => _guardPhase(
    'fetching the restoration route',
    () => _apiService.getWorkflowStages(
      restorationTypeId: restorationTypeId,
      token: _token,
    ),
  );

  /// The fixed lifecycle checkpoints. Each is its own action, not a stage
  /// move: a case in `New` has no stage transitions on offer until its
  /// material is recorded, which is what opens its workflow.
  Future<Either<Failure, void>> receiveMaterial({
    required String id,
    String? note,
  }) => _guardPhase(
    'recording material received',
    () => _apiService.receiveCaseMaterial(id: id, note: note, token: _token),
  );

  Future<Either<Failure, void>> passQualityCheck({
    required String id,
    String? note,
  }) => _guardPhase(
    'passing the quality check',
    () => _apiService.passCaseQualityCheck(id: id, note: note, token: _token),
  );

  /// Takes a wrongly-recorded arrival back to `New`.
  Future<Either<Failure, void>> undoMaterialReceived({required String id}) =>
      _guardPhase(
        'undoing material received',
        () => _apiService.undoCaseMaterialReceived(id: id, token: _token),
      );

  Future<Either<Failure, void>> approveTrying({
    required String id,
    String? note,
  }) => _guardPhase(
    'approving the trying',
    () => _apiService.approveCaseTrying(id: id, note: note, token: _token),
  );

  /// The doctor refused the fit: each flagged piece names the stage it goes
  /// back to, and the case itself drops back into production — one request,
  /// because the server writes it as one decision.
  Future<Either<Failure, void>> rejectTrying({
    required String id,
    required List<TryingRejectLine> restorations,
    String? note,
  }) => _guardPhase(
    'rejecting the trying',
    () => _apiService.rejectCaseTrying(
      id: id,
      restorations: restorations,
      note: note,
      token: _token,
    ),
  );

  /// Walks many cases to delivered in one call — one result per case.
  Future<Either<Failure, List<DeliverDirectlyResultModel>>> deliverDirectly({
    required List<String> caseIds,
    String? note,
  }) => _guardPhase(
    'delivering cases directly',
    () => _apiService.deliverCasesDirectly(
      caseIds: caseIds,
      note: note,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> deliverCaseDirectly({
    required String id,
    String? note,
    CollectionMethod collectionMethod = CollectionMethod.none,
  }) => _guardPhase(
    'delivering a case directly',
    () => _apiService.deliverCaseDirectly(
      id: id,
      note: note,
      collectionMethod: collectionMethod,
      token: _token,
    ),
  );

  Future<Either<Failure, void>> setDelayReason({
    required String id,
    required String reason,
    String? note,
  }) => _guardPhase(
    'recording a delay reason',
    () => _apiService.setCaseDelayReason(
      id: id,
      reason: reason,
      note: note,
      token: _token,
    ),
  );

  Future<Either<Failure, T>> _guardPhase<T>(
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

  Future<Either<Failure, CaseDetailModel>> createCase(
    CreateCaseRequestModel createCaseRequestBody,
  ) async {
    try {
      final caseDetail = await _apiService.createCase(
        createCaseRequestBody: createCaseRequestBody,
        token: _token,
      );

      log('Created case: ${caseDetail.caseNumber}');
      return right(caseDetail);
    } on DioException catch (e) {
      log('DioException while creating case: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while creating case: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteCase(String id) async {
    try {
      await _apiService.deleteCase(id: id, token: _token);

      log('Deleted case: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting case: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Sets the stage of one restoration within the case — stages are scoped
  /// to a restoration (and, through it, to its restoration type), not to the
  /// case as a whole.
  Future<Either<Failure, void>> setRestorationStage({
    required String caseId,
    required String restorationId,
    required String stageId,
    String? note,
    SendBackReason reason = const SendBackReason(),
  }) async {
    try {
      await _apiService.setRestorationStage(
        caseId: caseId,
        restorationId: restorationId,
        stageId: stageId,
        note: note,
        reason: reason,
        token: _token,
      );

      log('Set stage for restoration $restorationId (case $caseId)');
      return right(null);
    } on DioException catch (e) {
      log('DioException while setting restoration stage: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while setting restoration stage: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  /// Moves the case along its own workflow — distinct from a restoration's
  /// route, which is drawn per restoration type.
  ///
  /// [toStageId] is the id of one of the lab's stages. Which ones are legal
  /// from here comes from the stage catalogue's transitions; the server has
  /// the final say and refuses anything else.
  Future<Either<Failure, void>> moveCaseStage({
    required String id,
    required String toStageId,
    String? note,
    String? rejectionReason,
  }) async {
    try {
      await _apiService.moveCaseStage(
        id: id,
        caseStatusId: toStageId,
        note: note,
        rejectionReason: rejectionReason,
        token: _token,
      );

      log('Moved case $id to stage $toStageId');
      return right(null);
    } on DioException catch (e) {
      log('DioException while moving case stage: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while moving case stage: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseFileModel>> uploadFile({
    required String id,
    required String filePath,
  }) async {
    try {
      final file = await _apiService.uploadCaseFile(
        id: id,
        filePath: filePath,
        token: _token,
      );

      log('Uploaded file for case: $id');
      return right(file);
    } on DioException catch (e) {
      log('DioException while uploading case file: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while uploading case file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, List<CaseMessageModel>>> getMessages(String id) async {
    try {
      final messages = await _apiService.getCaseMessages(id: id, token: _token);

      log('Fetched ${messages.length} messages for case: $id');
      return right(messages);
    } on DioException catch (e) {
      log('DioException while fetching case messages: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while fetching case messages: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, CaseMessageModel>> sendMessage({
    required String id,
    String? message,
    String? replyToMessageId,
    String? filePath,
  }) async {
    try {
      final sent = await _apiService.sendCaseMessage(
        id: id,
        message: message,
        replyToMessageId: replyToMessageId,
        filePath: filePath,
        token: _token,
      );

      log('Sent message for case: $id');
      return right(sent);
    } on DioException catch (e) {
      log('DioException while sending case message: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while sending case message: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteMessage({
    required String id,
    required String messageId,
  }) async {
    try {
      await _apiService.deleteCaseMessage(
        id: id,
        messageId: messageId,
        token: _token,
      );

      log('Deleted message $messageId for case: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case message: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting case message: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  Future<Either<Failure, void>> deleteFile({
    required String id,
    required String fileId,
  }) async {
    try {
      await _apiService.deleteCaseFile(id: id, fileId: fileId, token: _token);

      log('Deleted file $fileId for case: $id');
      return right(null);
    } on DioException catch (e) {
      log('DioException while deleting case file: ${e.message}');
      return left(ServerFailure.fromDioException(e));
    } catch (e) {
      log('General Exception while deleting case file: ${e.toString()}');
      return left(ServerFailure.fromException(e));
    }
  }

  // ---- Restoration stage actions (MOBILE-SPEC §17.5) ----

  /// Maps whatever [request] throws onto a [Failure]. The stage actions are
  /// five near-identical calls; without this each would carry the same nine
  /// lines of catch blocks.
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

  /// The whole production route of a restoration type — every stage, plus
  /// whatever the server finds wrong with the drawing.
  ///
  /// Replaces the old `/routing/preview` + `/routing/options` pair, which was
  /// deleted server-side along with the graph engine. There is no "preview
  /// under these answers" call any more: the route is returned whole, and the
  /// caller filters it by intake and by which optional stages the case took.
  Future<Either<Failure, RouteDefinitionModel>> getRouteDefinition(
    String restorationTypeId,
  ) => _guard(
    'fetching the restoration route',
    () => _apiService.getRouteDefinition(
      restorationTypeId: restorationTypeId,
      token: _token,
    ),
  );
}

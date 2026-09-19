import 'dart:developer';

import 'package:dental_lab_app/core/helper/network_helper/api.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:dental_lab_app/features/excel_import/data/models/import_session_model.dart';
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

/// The laboratory's own custom questions, and the answers people give them.
///
/// A fifth extension beside [AttendanceApi], [PeopleApi], [LookupApi] and
/// [ActivityApi], for the same reason those exist.
extension QuestionsApi on ApiService {
  // ---- The questions themselves -----------------------------------------

  /// `GET /DetailsQuestions`
  ///
  /// [personType] narrows to one audience — what an answer form wants, since
  /// a doctor should never be shown the questions written for employees.
  Future<List<DetailsQuestionModel>> getDetailsQuestions({
    QuestionPersonType? personType,
    String? token,
  }) async {
    log('Fetching details questions');

    final query = personType == null
        ? ''
        : '?personType=${personType.value}';
    final data = await Api().get(url: 'DetailsQuestions$query', token: token);

    return _decodeList(data, DetailsQuestionModel.fromJson);
  }

  /// `POST /DetailsQuestions`
  Future<DetailsQuestionModel> createDetailsQuestion({
    required CreateDetailsQuestionRequestModel body,
    String? token,
  }) async {
    log('Creating a details question');

    final response = await Api().post(
      url: 'DetailsQuestions',
      body: body.toJson(),
      token: token,
    );

    return DetailsQuestionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `PUT /DetailsQuestions/{id}`
  Future<DetailsQuestionModel> updateDetailsQuestion({
    required String id,
    required UpdateDetailsQuestionRequestModel body,
    String? token,
  }) async {
    log('Updating details question: $id');

    final response = await Api().put(
      url: 'DetailsQuestions/$id',
      body: body.toJson(),
      token: token,
    );

    return DetailsQuestionModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// `DELETE /DetailsQuestions/{id}`
  ///
  /// Refused by the server once somebody has answered — deleting would orphan
  /// their answer. Deactivating is the answer there: the question leaves the
  /// forms and the answers already filed still read.
  Future<void> deleteDetailsQuestion({
    required String id,
    String? token,
  }) async {
    log('Deleting details question: $id');

    await Api().delete(url: 'DetailsQuestions/$id', token: token);
  }

  // ---- One person's answers ---------------------------------------------

  /// `GET /Doctors/{id}/answers` or `GET /Employees/{id}/answers`.
  ///
  /// One method for both, keyed off [isDoctor], because the two endpoints are
  /// the same shape on both sides — writing them twice is how they drift.
  Future<List<PersonAnswerModel>> getPersonAnswers({
    required String personId,
    required bool isDoctor,
    String? token,
  }) async {
    log('Fetching answers for ${isDoctor ? 'doctor' : 'employee'}: $personId');

    final data = await Api().get(
      url: '${isDoctor ? 'Doctors' : 'Employees'}/$personId/answers',
      token: token,
    );
    return _decodeList(data, PersonAnswerModel.fromJson);
  }

  /// `PUT /{Doctors|Employees}/{id}/answers`
  ///
  /// **Replaces** the person's answers: a question left out is cleared, which
  /// is why the caller sends every question it rendered rather than only the
  /// ones that were edited.
  Future<void> savePersonAnswers({
    required String personId,
    required bool isDoctor,
    required SaveAnswersRequestModel body,
    String? token,
  }) async {
    log('Saving ${body.answers.length} answers for $personId');

    await Api().put(
      url: '${isDoctor ? 'Doctors' : 'Employees'}/$personId/answers',
      body: body.toJson(),
      token: token,
    );
  }

  /// `POST /{Doctors|Employees}/{id}/answers/{questionId}/file`
  ///
  /// A file answer's own endpoint. It never goes through
  /// [savePersonAnswers] — putting a filename in `value` would store the name
  /// as if it were the answer.
  ///
  /// Both ids are repeated in the body as well as the path: that is how this
  /// API's binder is written, and sending only one of the two is a 400 that
  /// reads like a file problem.
  Future<void> uploadAnswerFile({
    required String personId,
    required String questionId,
    required bool isDoctor,
    required String filePath,
    String? token,
  }) async {
    log('Uploading a file answer for question: $questionId');

    await Api().post(
      url:
          '${isDoctor ? 'Doctors' : 'Employees'}/$personId/answers/'
          '$questionId/file',
      body: FormData.fromMap({
        'Id': personId,
        'QuestionId': questionId,
        'file': await MultipartFile.fromFile(filePath),
      }),
      token: token,
      isFormData: true,
    );
  }
}

/// Bulk import from a spreadsheet.
///
/// Sits beside [QuestionsApi] rather than in its own file because it is four
/// endpoints; a file per handful of methods is how the helper folder stops
/// being navigable.
extension ImportApi on ApiService {
  /// `GET /Import/{entityType}/template` — the blank spreadsheet to fill in.
  ///
  /// Answers with the file's bytes. Goes through `Api.dio` directly rather
  /// than [Api.get], which only ever decodes JSON.
  Future<List<int>> downloadImportTemplate({
    required ImportEntityType entityType,
    String? token,
  }) async {
    log('Downloading the ${entityType.wireValue} import template');

    final response = await Api.dio.get<List<int>>(
      'Import/${entityType.wireValue}/template',
      options: Options(
        responseType: ResponseType.bytes,
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    );

    return response.data ?? const [];
  }

  /// `POST /Import/{entityType}/upload`
  ///
  /// Answers with the session, **not** with the finished result: the server
  /// works through the file in the background, so the caller polls
  /// [getImportSession] until it completes.
  Future<ImportSessionModel> uploadImportFile({
    required ImportEntityType entityType,
    required String filePath,
    String? token,
  }) async {
    log('Uploading a ${entityType.wireValue} import file');

    final response = await Api().post(
      url: 'Import/${entityType.wireValue}/upload',
      body: FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      }),
      token: token,
      isFormData: true,
    );

    return ImportSessionModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /Import/sessions/{sessionId}` — how far along one run is.
  Future<ImportSessionModel> getImportSession({
    required String sessionId,
    String? token,
  }) async {
    log('Fetching import session: $sessionId');

    final data = await Api().get(
      url: 'Import/sessions/$sessionId',
      token: token,
    );
    return ImportSessionModel.fromJson(data as Map<String, dynamic>);
  }

  /// `GET /Import/sessions/current` — this laboratory's running and recent
  /// imports.
  Future<List<ImportSessionModel>> getImportSessions({String? token}) async {
    log('Fetching current import sessions');

    final data = await Api().get(url: 'Import/sessions/current', token: token);
    return _decodeList(data, ImportSessionModel.fromJson);
  }
}

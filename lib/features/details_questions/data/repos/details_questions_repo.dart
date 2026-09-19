import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/helper/network_helper/questions_api.dart';
import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:dio/dio.dart';

/// The laboratory's own custom questions, and the answers people give them.
///
/// Not cached offline: a form built from a stale question set would collect
/// answers against questions that no longer exist, and the save that follows
/// replaces the person's whole answer set.
class DetailsQuestionsRepo {
  DetailsQuestionsRepo(this._apiService);

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

  Future<Either<Failure, List<DetailsQuestionModel>>> getQuestions({
    QuestionPersonType? personType,
  }) => _guard(
    'fetching details questions',
    () => _apiService.getDetailsQuestions(
      personType: personType,
      token: _token,
    ),
  );

  Future<Either<Failure, DetailsQuestionModel>> createQuestion(
    CreateDetailsQuestionRequestModel body,
  ) => _guard(
    'creating a details question',
    () => _apiService.createDetailsQuestion(body: body, token: _token),
  );

  Future<Either<Failure, DetailsQuestionModel>> updateQuestion({
    required String id,
    required UpdateDetailsQuestionRequestModel body,
  }) => _guard(
    'updating a details question',
    () => _apiService.updateDetailsQuestion(id: id, body: body, token: _token),
  );

  /// Refused by the server once somebody has answered — deactivating is the
  /// answer there, since it takes the question out of the forms while the
  /// answers already filed still read.
  Future<Either<Failure, void>> deleteQuestion(String id) => _guard(
    'deleting a details question',
    () => _apiService.deleteDetailsQuestion(id: id, token: _token),
  );

  Future<Either<Failure, List<PersonAnswerModel>>> getAnswers({
    required String personId,
    required bool isDoctor,
  }) => _guard(
    'fetching a person\'s answers',
    () => _apiService.getPersonAnswers(
      personId: personId,
      isDoctor: isDoctor,
      token: _token,
    ),
  );

  /// **Replaces** the person's answers — a question left out is cleared.
  Future<Either<Failure, void>> saveAnswers({
    required String personId,
    required bool isDoctor,
    required SaveAnswersRequestModel body,
  }) => _guard(
    'saving a person\'s answers',
    () => _apiService.savePersonAnswers(
      personId: personId,
      isDoctor: isDoctor,
      body: body,
      token: _token,
    ),
  );

  /// A file answer, on its own endpoint — it never goes through
  /// [saveAnswers].
  Future<Either<Failure, void>> uploadAnswerFile({
    required String personId,
    required String questionId,
    required bool isDoctor,
    required String filePath,
  }) => _guard(
    'uploading a file answer',
    () => _apiService.uploadAnswerFile(
      personId: personId,
      questionId: questionId,
      isDoctor: isDoctor,
      filePath: filePath,
      token: _token,
    ),
  );
}

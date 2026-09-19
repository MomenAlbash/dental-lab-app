import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:dental_lab_app/features/details_questions/data/repos/details_questions_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class PersonAnswersState {
  const PersonAnswersState();
}

class PersonAnswersLoading extends PersonAnswersState {
  const PersonAnswersLoading();
}

class PersonAnswersError extends PersonAnswersState {
  const PersonAnswersError(this.message);
  final String message;
}

class PersonAnswersLoaded extends PersonAnswersState {
  const PersonAnswersLoaded({
    required this.questions,
    required this.answers,
    this.isBusy = false,
  });

  /// Every active question for this audience, sorted — **not** only the ones
  /// already answered. A form that showed only existing answers could never
  /// collect a new one.
  final List<DetailsQuestionModel> questions;

  /// What this person has answered so far, keyed by question.
  final Map<String, PersonAnswerModel> answers;

  final bool isBusy;

  /// Required questions this person has not answered.
  ///
  /// Reported rather than enforced: these questions are usually added after
  /// the people were, so half the directory is legitimately incomplete on the
  /// day one is introduced, and refusing to save would make the form unusable.
  List<DetailsQuestionModel> get missingRequired => [
    for (final question in questions)
      if (question.isRequired && !(answers[question.id]?.hasAnswer ?? false))
        question,
  ];

  PersonAnswersLoaded copyWith({bool? isBusy}) => PersonAnswersLoaded(
    questions: questions,
    answers: answers,
    isBusy: isBusy ?? this.isBusy,
  );
}

class PersonAnswersSaved extends PersonAnswersState {
  const PersonAnswersSaved();
}

class PersonAnswersActionError extends PersonAnswersState {
  const PersonAnswersActionError(this.message);
  final String message;
}

/// One person's answers to the laboratory's custom questions.
///
/// Loads the **question set** and the person's answers together, because a
/// form needs both: the questions are what it renders, the answers are what it
/// fills in. Loading only the answers would hide every question nobody has got
/// round to answering — which is most of them, the day a question is added.
class PersonAnswersCubit extends Cubit<PersonAnswersState> {
  PersonAnswersCubit(this._repo) : super(const PersonAnswersLoading());

  final DetailsQuestionsRepo _repo;

  late String _personId;
  late bool _isDoctor;

  Future<void> load({
    required String personId,
    required bool isDoctor,
  }) async {
    _personId = personId;
    _isDoctor = isDoctor;
    emit(const PersonAnswersLoading());

    final questions = await _repo.getQuestions(
      personType: isDoctor
          ? QuestionPersonType.doctor
          : QuestionPersonType.employee,
    );
    if (isClosed) return;

    await questions.fold(
      (failure) async => emit(PersonAnswersError(failure.errorMessage)),
      (list) async {
        final answers = await _repo.getAnswers(
          personId: personId,
          isDoctor: isDoctor,
        );
        if (isClosed) return;

        answers.fold(
          (failure) => emit(PersonAnswersError(failure.errorMessage)),
          (given) => emit(
            PersonAnswersLoaded(
              // Inactive questions are dropped from the form but their answers
              // stay readable on the record — a retired question should stop
              // being asked without erasing what people already said.
              questions: [
                for (final question in list)
                  if (question.isActive) question,
              ]..sort(compareQuestions),
              answers: {
                for (final answer in given) answer.questionId: answer,
              },
            ),
          ),
        );
      },
    );
  }

  /// Saves the typed answers.
  ///
  /// [values] must carry **every non-file question the form rendered**, not
  /// only the edited ones: the endpoint replaces the person's answer set, so a
  /// question left out is cleared.
  Future<void> save(Map<String, String?> values) async {
    final current = state;
    if (current is PersonAnswersLoaded) emit(current.copyWith(isBusy: true));

    final result = await _repo.saveAnswers(
      personId: _personId,
      isDoctor: _isDoctor,
      body: SaveAnswersRequestModel(
        answers: [
          for (final entry in values.entries)
            SaveAnswerModel(
              questionId: entry.key,
              // An empty box means "no answer", so it is sent as null rather
              // than as an answer that happens to be blank.
              value: (entry.value?.trim().isEmpty ?? true)
                  ? null
                  : entry.value!.trim(),
            ),
        ],
      ),
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(PersonAnswersActionError(failure.errorMessage));
        if (current is PersonAnswersLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (_) async {
        emit(const PersonAnswersSaved());
        await load(personId: _personId, isDoctor: _isDoctor);
      },
    );
  }

  /// Uploads a file answer, on its own endpoint.
  Future<void> uploadFile({
    required String questionId,
    required String filePath,
  }) async {
    final current = state;
    if (current is PersonAnswersLoaded) emit(current.copyWith(isBusy: true));

    final result = await _repo.uploadAnswerFile(
      personId: _personId,
      questionId: questionId,
      isDoctor: _isDoctor,
      filePath: filePath,
    );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(PersonAnswersActionError(failure.errorMessage));
        if (current is PersonAnswersLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (_) async => load(personId: _personId, isDoctor: _isDoctor),
    );
  }
}

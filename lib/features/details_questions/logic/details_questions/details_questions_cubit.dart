import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:dental_lab_app/features/details_questions/data/repos/details_questions_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class DetailsQuestionsState {
  const DetailsQuestionsState();
}

class DetailsQuestionsLoading extends DetailsQuestionsState {
  const DetailsQuestionsLoading();
}

class DetailsQuestionsError extends DetailsQuestionsState {
  const DetailsQuestionsError(this.message);
  final String message;
}

class DetailsQuestionsLoaded extends DetailsQuestionsState {
  const DetailsQuestionsLoaded({
    required this.questions,
    required this.personType,
    this.isBusy = false,
  });

  /// Already sorted the way a form should render them.
  final List<DetailsQuestionModel> questions;

  /// Which audience is being shown.
  final QuestionPersonType personType;

  final bool isBusy;

  DetailsQuestionsLoaded copyWith({bool? isBusy}) => DetailsQuestionsLoaded(
    questions: questions,
    personType: personType,
    isBusy: isBusy ?? this.isBusy,
  );
}

class DetailsQuestionsActionSuccess extends DetailsQuestionsState {
  const DetailsQuestionsActionSuccess(this.message);
  final String message;
}

class DetailsQuestionsActionError extends DetailsQuestionsState {
  const DetailsQuestionsActionError(this.message);
  final String message;
}

/// The laboratory's custom questions, one audience at a time.
///
/// Scoped to an audience rather than showing them all at once because that is
/// how they are used: a question written for employees has no business
/// appearing in a doctor's form, and a flat list invites exactly that mistake
/// when somebody edits one.
class DetailsQuestionsCubit extends Cubit<DetailsQuestionsState> {
  DetailsQuestionsCubit(this._repo) : super(const DetailsQuestionsLoading());

  final DetailsQuestionsRepo _repo;

  QuestionPersonType _personType = QuestionPersonType.employee;

  QuestionPersonType get personType => _personType;

  Future<void> load({QuestionPersonType? personType}) async {
    _personType = personType ?? _personType;
    emit(const DetailsQuestionsLoading());

    final result = await _repo.getQuestions(personType: _personType);
    if (isClosed) return;

    result.fold(
      (failure) => emit(DetailsQuestionsError(failure.errorMessage)),
      (questions) => emit(
        DetailsQuestionsLoaded(
          questions: [...questions]..sort(compareQuestions),
          personType: _personType,
        ),
      ),
    );
  }

  Future<void> create(CreateDetailsQuestionRequestModel body) =>
      _write('تمت إضافة السؤال', () => _repo.createQuestion(body));

  Future<void> update({
    required String id,
    required UpdateDetailsQuestionRequestModel body,
  }) => _write(
    'تم تعديل السؤال',
    () => _repo.updateQuestion(id: id, body: body),
  );

  /// Deletes a question.
  ///
  /// Refused locally when the server already said it cannot be deleted, with
  /// the server's own reason — there is no point making the user confirm a
  /// destructive action that is going to come back rejected.
  Future<void> delete(DetailsQuestionModel question) async {
    if (!question.canDelete) {
      final current = state;
      emit(
        DetailsQuestionsActionError(
          question.deleteMessage ??
              'لا يمكن حذف هذا السؤال — عطّله بدلاً من ذلك',
        ),
      );
      if (current is DetailsQuestionsLoaded) emit(current);
      return;
    }

    await _write('تم حذف السؤال', () => _repo.deleteQuestion(question.id));
  }

  Future<void> _write<T>(
    String successMessage,
    Future<Either<Failure, T>> Function() request,
  ) async {
    final current = state;
    if (current is DetailsQuestionsLoaded) {
      emit(current.copyWith(isBusy: true));
    }

    final result = await request();
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(DetailsQuestionsActionError(failure.errorMessage));
        if (current is DetailsQuestionsLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (_) async {
        emit(DetailsQuestionsActionSuccess(successMessage));
        await load();
      },
    );
  }
}

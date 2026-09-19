import 'package:dental_lab_app/features/details_questions/data/models/details_question_model.dart';
import 'package:flutter_test/flutter_test.dart';

DetailsQuestionModel _question({
  String id = 'q1',
  int? order,
  int type = 1,
  String? ar,
  String? en,
  bool isRequired = false,
  bool canDelete = true,
}) => DetailsQuestionModel.fromJson({
  'id': id,
  'displayOrder': order,
  'type': type,
  'questionTextAr': ar,
  'questionText': en,
  'isRequired': isRequired,
  'canDelete': canDelete,
});

void main() {
  group('QuestionPersonType', () {
    test('carries all four audiences, unlike the app\'s own UserType', () {
      // A user's own type is deliberately two values because the server
      // rejects `type: 2` there. A *question* really can target a
      // representative or an agent.
      expect(QuestionPersonType.values, hasLength(4));
      expect(
        QuestionPersonType.fromValue(2),
        QuestionPersonType.representative,
      );
      expect(QuestionPersonType.fromValue(3), QuestionPersonType.agent);
    });

    test('an unknown value degrades to null', () {
      expect(QuestionPersonType.fromValue(9), isNull);
    });
  });

  group('DetailsQuestionType', () {
    test('every wire value maps to a labelled type', () {
      for (final type in DetailsQuestionType.values) {
        expect(DetailsQuestionType.fromValue(type.value), type);
        expect(type.label, isNotEmpty);
      }
    });

    test('only the file type is a file', () {
      expect(DetailsQuestionType.fileUpload.isFile, isTrue);
      expect(DetailsQuestionType.text.isFile, isFalse);
    });
  });

  group('DetailsQuestionModel.label', () {
    test('prefers Arabic over the English text', () {
      expect(_question(ar: 'هل لديك سيارة؟', en: 'Car?').label, 'هل لديك سيارة؟');
    });

    test('falls back to English when there is no Arabic', () {
      expect(_question(en: 'Car?').label, 'Car?');
    });

    test('a question with no text at all shows a dash', () {
      expect(_question().label, '—');
    });
  });

  group('compareQuestions', () {
    test('orders by displayOrder', () {
      final questions = [
        _question(id: 'b', order: 2, en: 'B'),
        _question(id: 'a', order: 1, en: 'A'),
      ]..sort(compareQuestions);

      expect(questions.first.id, 'a');
    });

    test('an unordered question goes last, not first', () {
      // Treating null as zero would jump it to the top of a form somebody
      // arranged.
      final questions = [
        _question(id: 'none', en: 'A'),
        _question(id: 'first', order: 5, en: 'B'),
      ]..sort(compareQuestions);

      expect(questions.first.id, 'first');
      expect(questions.last.id, 'none');
    });

    test('ties fall back to the label so the order is stable', () {
      final questions = [
        _question(id: 'b', order: 1, en: 'B'),
        _question(id: 'a', order: 1, en: 'A'),
      ]..sort(compareQuestions);

      expect(questions.first.id, 'a');
    });
  });

  group('PersonAnswerModel', () {
    test('a yes/no answer reads as a boolean', () {
      final answer = PersonAnswerModel.fromJson({
        'questionId': 'q1',
        'question': {'id': 'q1', 'type': 0},
        'value': 'true',
      });

      expect(answer.boolValue, isTrue);
      expect(answer.displayValue, 'نعم');
    });

    test('"true" in a text question is not a checked box', () {
      // Every answer arrives as a string; the question's type is the only
      // thing that says how to read it.
      final answer = PersonAnswerModel.fromJson({
        'questionId': 'q1',
        'question': {'id': 'q1', 'type': 1},
        'value': 'true',
      });

      expect(answer.boolValue, isNull);
      expect(answer.displayValue, 'true');
    });

    test('Arabic yes and no are understood', () {
      final yes = PersonAnswerModel.fromJson({
        'questionId': 'q1',
        'question': {'id': 'q1', 'type': 0},
        'value': 'نعم',
      });

      expect(yes.boolValue, isTrue);
    });

    test('a file answer shows the filename, not the whole path', () {
      final answer = PersonAnswerModel.fromJson({
        'questionId': 'q1',
        'question': {'id': 'q1', 'type': 4},
        'filePath': '/media/answers/licence.pdf',
      });

      expect(answer.displayValue, 'licence.pdf');
      expect(answer.hasAnswer, isTrue);
    });

    test('an unanswered question has no answer', () {
      final answer = PersonAnswerModel.fromJson({'questionId': 'q1'});

      expect(answer.hasAnswer, isFalse);
      expect(answer.displayValue, '—');
    });

    test('a whitespace-only value is not an answer', () {
      final answer = PersonAnswerModel.fromJson({
        'questionId': 'q1',
        'value': '   ',
      });

      expect(answer.hasAnswer, isFalse);
    });

    test('the question comes embedded, so an answer renders alone', () {
      final answer = PersonAnswerModel.fromJson({
        'questionId': 'q1',
        'question': {'id': 'q1', 'questionTextAr': 'هل لديك سيارة؟'},
        'value': 'نعم',
      });

      expect(answer.question?.label, 'هل لديك سيارة؟');
    });
  });

  group('CreateDetailsQuestionRequestModel', () {
    test('carries the audience, which is fixed at creation', () {
      final json = const CreateDetailsQuestionRequestModel(
        personType: QuestionPersonType.doctor,
        questionText: 'Car?',
        type: DetailsQuestionType.yesNo,
      ).toJson();

      expect(json['personType'], 1);
      expect(json['type'], 0);
    });
  });

  group('UpdateDetailsQuestionRequestModel', () {
    test('carries no personType — answers already belong to an audience', () {
      final json = const UpdateDetailsQuestionRequestModel(
        type: DetailsQuestionType.text,
        questionText: 'Car?',
      ).toJson();

      expect(json.containsKey('personType'), isFalse);
    });
  });

  group('SaveAnswersRequestModel', () {
    test('a cleared answer is sent as null, not as an empty string', () {
      final json = const SaveAnswersRequestModel(
        answers: [SaveAnswerModel(questionId: 'q1')],
      ).toJson();

      final answers = json['answers'] as List;
      expect((answers.single as Map).containsKey('value'), isTrue);
      expect(answers.single['value'], isNull);
    });

    test('every rendered question is carried, since the save replaces', () {
      final json = const SaveAnswersRequestModel(
        answers: [
          SaveAnswerModel(questionId: 'q1', value: 'نعم'),
          SaveAnswerModel(questionId: 'q2'),
        ],
      ).toJson();

      expect(json['answers'], hasLength(2));
    });
  });
}

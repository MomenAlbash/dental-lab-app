/// Who a custom question is asked of (`UserType`, as `personType`).
///
/// A different axis from the app's own [UserType], which deliberately carries
/// only two values because the server rejects `type: 2` for a *user's* own
/// type. A question, by contrast, really can target a representative or an
/// agent — so this enum carries all four rather than reusing one that is
/// narrow for a good reason elsewhere.
enum QuestionPersonType {
  employee(0, 'الموظفون'),
  doctor(1, 'الأطباء'),
  representative(2, 'المندوبون'),
  agent(3, 'الوكلاء');

  const QuestionPersonType(this.value, this.label);

  final int value;
  final String label;

  static QuestionPersonType? fromValue(int? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// What kind of answer a question takes (`DetailsQuestionType`).
///
/// The type is what the answer form renders, and it is **not** merely
/// cosmetic: every answer goes to the server as a string in the same `value`
/// field, so the type is the only thing that says how to read `"1"` — a yes, a
/// quantity, or a piece of text that happens to be a digit.
enum DetailsQuestionType {
  yesNo(0, 'نعم/لا'),
  text(1, 'نص'),
  number(2, 'رقم'),
  date(3, 'تاريخ'),
  fileUpload(4, 'ملف');

  const DetailsQuestionType(this.value, this.label);

  final int value;
  final String label;

  /// Whether the answer is a file rather than a typed value.
  ///
  /// These do not go through the bulk answer save at all — they have their own
  /// upload endpoint, and sending one in the `answers` array would store the
  /// filename as if it were the answer.
  bool get isFile => this == DetailsQuestionType.fileUpload;

  static DetailsQuestionType? fromValue(int? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// One custom question the laboratory asks (`ClinicDetailsQuestionDto`).
class DetailsQuestionModel {
  const DetailsQuestionModel({
    required this.id,
    this.laboratoryId,
    this.laboratoryName,
    this.personType,
    this.questionText,
    this.questionTextAr,
    this.type,
    this.isRequired = false,
    this.displayOrder,
    this.isActive = true,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? laboratoryId;
  final String? laboratoryName;

  final QuestionPersonType? personType;
  final String? questionText;
  final String? questionTextAr;
  final DetailsQuestionType? type;

  final bool isRequired;

  /// Null means the lab never ordered this one. Sorting treats it as last
  /// rather than as zero — an unordered question jumping to the top of a form
  /// somebody arranged is worse than it sitting at the bottom.
  final int? displayOrder;

  final bool isActive;

  /// Whether the server will accept a delete. False once somebody has
  /// answered: deleting the question would orphan their answer.
  final bool canDelete;

  /// Why it cannot be deleted — the server's own words, shown rather than
  /// paraphrased.
  final String? deleteMessage;

  /// Arabic first, falling back to the English text.
  String get label {
    final ar = questionTextAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;

    final en = questionText?.trim();
    return (en == null || en.isEmpty) ? '—' : en;
  }

  factory DetailsQuestionModel.fromJson(Map<String, dynamic> json) {
    return DetailsQuestionModel(
      id: json['id'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String?,
      laboratoryName: json['laboratoryName'] as String?,
      personType: QuestionPersonType.fromValue(json['personType'] as int?),
      questionText: json['questionText'] as String?,
      questionTextAr: json['questionTextAr'] as String?,
      type: DetailsQuestionType.fromValue(json['type'] as int?),
      isRequired: json['isRequired'] as bool? ?? false,
      displayOrder: json['displayOrder'] as int?,
      isActive: json['isActive'] as bool? ?? true,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

/// Orders questions the way a form should render them.
///
/// Unordered questions go last rather than first — see
/// [DetailsQuestionModel.displayOrder] — and ties fall back to the label so
/// the order is at least stable between loads.
int compareQuestions(DetailsQuestionModel a, DetailsQuestionModel b) {
  final orderA = a.displayOrder;
  final orderB = b.displayOrder;

  if (orderA != orderB) {
    if (orderA == null) return 1;
    if (orderB == null) return -1;
    return orderA.compareTo(orderB);
  }
  return a.label.compareTo(b.label);
}

/// `POST /DetailsQuestions` (`ClinicCreateDetailsQuestionRequest`).
///
/// [personType] is set only here: who a question is asked of cannot be changed
/// afterwards, because the answers already filed under it belong to those
/// people — which is why the update request has no such field.
class CreateDetailsQuestionRequestModel {
  const CreateDetailsQuestionRequestModel({
    required this.personType,
    required this.questionText,
    required this.type,
    this.questionTextAr,
    this.isRequired = false,
    this.displayOrder,
  });

  final QuestionPersonType personType;
  final String questionText;
  final String? questionTextAr;
  final DetailsQuestionType type;
  final bool isRequired;
  final int? displayOrder;

  Map<String, dynamic> toJson() => {
    'personType': personType.value,
    'questionText': questionText,
    'questionTextAr': questionTextAr,
    'type': type.value,
    'isRequired': isRequired,
    'displayOrder': displayOrder,
  };
}

/// `PUT /DetailsQuestions/{id}` (`ClinicUpdateDetailsQuestionRequest`).
///
/// Carries no `personType`: the answers already filed under this question
/// belong to the people it was asked of, and moving it to another audience
/// would silently reattribute them.
class UpdateDetailsQuestionRequestModel {
  const UpdateDetailsQuestionRequestModel({
    required this.type,
    this.questionText,
    this.questionTextAr,
    this.isRequired,
    this.displayOrder,
    this.isActive,
  });

  final DetailsQuestionType type;
  final String? questionText;
  final String? questionTextAr;
  final bool? isRequired;
  final int? displayOrder;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
    'questionText': questionText,
    'questionTextAr': questionTextAr,
    'type': type.value,
    'isRequired': isRequired,
    'displayOrder': displayOrder,
    'isActive': isActive,
  };
}

/// One person's answer to one question (`ClinicPersonAnswerDto`).
///
/// The question comes embedded rather than by id alone, so a person's answers
/// render without a second fetch — and so an answer to a question that has
/// since been deactivated still shows what was asked.
class PersonAnswerModel {
  const PersonAnswerModel({
    required this.questionId,
    this.question,
    this.value,
    this.filePath,
  });

  final String questionId;
  final DetailsQuestionModel? question;

  /// Every typed answer, whatever its kind, arrives as a string. The
  /// question's [DetailsQuestionType] is the only thing that says how to read
  /// it.
  final String? value;

  /// Set instead of [value] for a file question.
  final String? filePath;

  bool get hasAnswer =>
      (value?.trim().isNotEmpty ?? false) ||
      (filePath?.trim().isNotEmpty ?? false);

  /// The stored `"true"`/`"false"` read as a yes/no, or null when the question
  /// is not one — so a bare `"true"` typed into a text question is never
  /// mistaken for a checked box.
  bool? get boolValue {
    if (question?.type != DetailsQuestionType.yesNo) return null;
    return switch (value?.trim().toLowerCase()) {
      'true' || '1' || 'yes' || 'نعم' => true,
      'false' || '0' || 'no' || 'لا' => false,
      _ => null,
    };
  }

  /// What to print for this answer, read according to its question's type.
  String get displayValue {
    if (question?.type?.isFile ?? false) {
      final path = filePath?.trim();
      return (path == null || path.isEmpty) ? '—' : path.split('/').last;
    }

    final bool_ = boolValue;
    if (bool_ != null) return bool_ ? 'نعم' : 'لا';

    final text = value?.trim();
    return (text == null || text.isEmpty) ? '—' : text;
  }

  factory PersonAnswerModel.fromJson(Map<String, dynamic> json) {
    return PersonAnswerModel(
      questionId: json['questionId'] as String? ?? '',
      question: json['question'] == null
          ? null
          : DetailsQuestionModel.fromJson(
              json['question'] as Map<String, dynamic>,
            ),
      value: json['value'] as String?,
      filePath: json['filePath'] as String?,
    );
  }
}

/// `PUT /{Doctors|Employees}/{id}/answers` (`ClinicSaveAnswersRequest`).
///
/// **The list replaces the person's answers.** A question left out is cleared,
/// which is why the form always sends every question it rendered rather than
/// only the ones the user touched.
///
/// File answers are **not** sent here — they have their own upload endpoint,
/// and putting a filename in `value` would store the name as if it were the
/// answer.
class SaveAnswersRequestModel {
  const SaveAnswersRequestModel({required this.answers});

  final List<SaveAnswerModel> answers;

  Map<String, dynamic> toJson() => {
    'answers': [for (final answer in answers) answer.toJson()],
  };
}

class SaveAnswerModel {
  const SaveAnswerModel({required this.questionId, this.value});

  final String questionId;

  /// Null clears the answer — distinct from an empty string, which the server
  /// stores as an answer that happens to be blank.
  final String? value;

  Map<String, dynamic> toJson() => {'questionId': questionId, 'value': value};
}

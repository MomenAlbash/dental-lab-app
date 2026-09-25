/// Why a piece is sent back to an earlier stage (`FailureReasonCategory`).
enum FailureReasonCategory {
  fit(1, 'عدم التطابق'),
  aesthetics(2, 'الجمالية'),
  material(3, 'المادة'),
  breakage(4, 'كسر'),
  doctorRequested(5, 'بطلب الطبيب'),
  workmanship(6, 'جودة العمل'),
  other(99, 'أخرى');

  const FailureReasonCategory(this.value, this.label);

  final int value;
  final String label;

  /// Only a breakage carries a loss: who is responsible and what it does to
  /// their pay. The server ignores `loss` on any other category.
  bool get carriesLoss => this == breakage;
}

/// What a breakage does to the responsible employee's pay (`LossPayImpact`).
enum LossPayImpact {
  recordOnly(1, 'تسجيل فقط'),
  voidStagePay(2, 'إلغاء أجر المراحل المُعادة'),
  deductAmount(3, 'خصم مبلغ');

  const LossPayImpact(this.value, this.label);

  final int value;
  final String label;

  /// Void and deduct act on somebody's pay, so they need a somebody.
  bool get needsResponsible => this != recordOnly;
}

/// `ClinicBreakageLossRequest` — the money side of a breakage.
class BreakageLossDraft {
  const BreakageLossDraft({
    this.responsibleEmployeeId,
    this.payImpact = LossPayImpact.recordOnly,
    this.deductionAmount = 0,
  });

  final String? responsibleEmployeeId;
  final LossPayImpact payImpact;

  /// Only read for [LossPayImpact.deductAmount].
  final double deductionAmount;

  /// The server's own rules, checked before sending so the button can say
  /// what is missing instead of the request failing. Null means valid.
  String? get problem {
    if (payImpact.needsResponsible && responsibleEmployeeId == null) {
      return 'حدّد المسؤول عن الكسر';
    }
    if (payImpact == LossPayImpact.deductAmount && deductionAmount <= 0) {
      return 'أدخل مبلغ الخصم';
    }
    return null;
  }

  BreakageLossDraft copyWith({
    String? responsibleEmployeeId,
    bool clearResponsible = false,
    LossPayImpact? payImpact,
    double? deductionAmount,
  }) => BreakageLossDraft(
    responsibleEmployeeId: clearResponsible
        ? null
        : (responsibleEmployeeId ?? this.responsibleEmployeeId),
    payImpact: payImpact ?? this.payImpact,
    deductionAmount: deductionAmount ?? this.deductionAmount,
  );

  Map<String, dynamic> toJson() => {
    'responsibleEmployeeId': responsibleEmployeeId,
    'payImpact': payImpact.value,
    'deductionAmount': payImpact == LossPayImpact.deductAmount
        ? deductionAmount
        : 0,
  };
}

/// Why a piece goes back, and — for a breakage — the loss. Carried by both a
/// single send-back and each line of a refused trying.
class SendBackReason {
  const SendBackReason({this.category, this.loss});

  final FailureReasonCategory? category;
  final BreakageLossDraft? loss;

  /// Null means it can be sent. A reason is optional; a breakage's loss, once
  /// chosen, has to be complete.
  String? get problem => category?.carriesLoss ?? false
      ? (loss ?? const BreakageLossDraft()).problem
      : null;

  /// The fields as the API takes them — added to a send-back's body.
  Map<String, dynamic> toJson() => {
    'failureCategory': ?category?.value,
    if (category?.carriesLoss ?? false)
      'loss': (loss ?? const BreakageLossDraft()).toJson(),
  };
}

/// One refused piece of a trying (`ClinicRejectTryingRestoration`).
class TryingRejectLine {
  const TryingRejectLine({
    required this.restorationId,
    required this.stageId,
    this.note,
    this.reason = const SendBackReason(),
  });

  final String restorationId;
  final String stageId;
  final String? note;
  final SendBackReason reason;

  Map<String, dynamic> toJson() => {
    'restorationId': restorationId,
    'stageId': stageId,
    'note': note,
    ...reason.toJson(),
  };
}

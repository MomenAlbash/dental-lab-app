/// Where a visit stands (`PhotographyVisitStatus`).
enum PhotographyVisitStatus {
  requested(1, 'مطلوبة'),
  scheduled(2, 'مجدولة'),
  completed(3, 'مكتملة'),
  cancelled(4, 'ملغاة');

  const PhotographyVisitStatus(this.value, this.label);

  final int value;
  final String label;

  /// Still open to scheduling, completing or cancelling.
  bool get isOpen => this == requested || this == scheduled;

  static PhotographyVisitStatus? fromValue(int? value) {
    for (final status in PhotographyVisitStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }
}

/// How the photos are taken (`PhotographyVisitType`).
enum PhotographyVisitType {
  labTechnicianVisitsClinic(1, 'فني المخبر يزور العيادة'),
  doctorSendsPhotosElectronically(2, 'الطبيب يرسل الصور إلكترونياً');

  const PhotographyVisitType(this.value, this.label);

  final int value;
  final String label;

  /// Only a visit to the clinic has a date and a technician to schedule.
  bool get isSchedulable => this == labTechnicianVisitsClinic;

  static PhotographyVisitType? fromValue(int? value) {
    for (final type in PhotographyVisitType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// The shade and clinical notes a visit exists to capture. Shared by the
/// visit itself and the create/complete requests, which all carry the same
/// six fields.
class PhotographyShadeNotes {
  const PhotographyShadeNotes({
    this.toothShade,
    this.shadeGuideUsed = false,
    this.translucencyNotes,
    this.gradientAndShapeNotes,
    this.smileLineNotes,
    this.gumColorNotes,
  });

  final String? toothShade;
  final bool shadeGuideUsed;
  final String? translucencyNotes;
  final String? gradientAndShapeNotes;
  final String? smileLineNotes;
  final String? gumColorNotes;

  bool get isEmpty =>
      !shadeGuideUsed &&
      [
        toothShade,
        translucencyNotes,
        gradientAndShapeNotes,
        smileLineNotes,
        gumColorNotes,
      ].every((v) => v == null || v.trim().isEmpty);

  factory PhotographyShadeNotes.fromJson(Map<String, dynamic> json) {
    return PhotographyShadeNotes(
      toothShade: json['toothShade'] as String?,
      shadeGuideUsed: json['shadeGuideUsed'] as bool? ?? false,
      translucencyNotes: json['translucencyNotes'] as String?,
      gradientAndShapeNotes: json['gradientAndShapeNotes'] as String?,
      smileLineNotes: json['smileLineNotes'] as String?,
      gumColorNotes: json['gumColorNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'toothShade': toothShade,
    'shadeGuideUsed': shadeGuideUsed,
    'translucencyNotes': translucencyNotes,
    'gradientAndShapeNotes': gradientAndShapeNotes,
    'smileLineNotes': smileLineNotes,
    'gumColorNotes': gumColorNotes,
  };
}

/// One uploaded photo (`ClinicPhotographyVisitPhotoDto`).
class PhotographyVisitPhotoModel {
  const PhotographyVisitPhotoModel({
    required this.id,
    this.fileName,
    this.filePath,
    this.uploadedByName,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String? fileName;
  final String? filePath;
  final String? uploadedByName;
  final String? notes;
  final DateTime? createdAt;

  factory PhotographyVisitPhotoModel.fromJson(Map<String, dynamic> json) {
    return PhotographyVisitPhotoModel(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
      uploadedByName: json['uploadedByName'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

/// A standalone photography visit (`ClinicPhotographyVisitDto`) — owned by a
/// doctor and deliberately tied to no case. Not the older, case-bound
/// "photography session", which lives on the case detail page.
class PhotographyVisitModel {
  const PhotographyVisitModel({
    required this.id,
    required this.doctorId,
    this.laboratoryId,
    this.doctorName,
    this.patientId,
    this.patientName,
    this.visitType = PhotographyVisitType.labTechnicianVisitsClinic,
    this.status = PhotographyVisitStatus.requested,
    this.scheduledAt,
    this.completedAt,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.notes,
    this.shade = const PhotographyShadeNotes(),
    this.price = 0,
    this.currencyId,
    this.currencyCode,
    this.invoiceId,
    this.photos = const [],
    this.createdAt,
  });

  final String id;
  final String doctorId;
  final String? laboratoryId;
  final String? doctorName;
  final String? patientId;
  final String? patientName;
  final PhotographyVisitType visitType;
  final PhotographyVisitStatus status;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? notes;
  final PhotographyShadeNotes shade;

  /// Billed to the doctor's account on completion — and, unlike shipping,
  /// shown to the doctor as is.
  final double price;
  final String? currencyId;
  final String? currencyCode;

  /// Set once completing the visit has billed it.
  final String? invoiceId;
  final List<PhotographyVisitPhotoModel> photos;
  final DateTime? createdAt;

  String get priceLabel =>
      '${price.toStringAsFixed(2)}${currencyCode == null ? '' : ' $currencyCode'}';

  factory PhotographyVisitModel.fromJson(Map<String, dynamic> json) {
    return PhotographyVisitModel(
      id: json['id'] as String? ?? '',
      doctorId: json['doctorId'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String?,
      doctorName: json['doctorName'] as String?,
      patientId: json['patientId'] as String?,
      patientName: json['patientName'] as String?,
      visitType:
          PhotographyVisitType.fromValue(json['visitType'] as int?) ??
          PhotographyVisitType.labTechnicianVisitsClinic,
      status:
          PhotographyVisitStatus.fromValue(json['status'] as int?) ??
          PhotographyVisitStatus.requested,
      scheduledAt: DateTime.tryParse(json['scheduledAt'] as String? ?? ''),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      assignedEmployeeId: json['assignedEmployeeId'] as String?,
      assignedEmployeeName: json['assignedEmployeeName'] as String?,
      notes: json['notes'] as String?,
      shade: PhotographyShadeNotes.fromJson(json),
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currencyId: json['currencyId'] as String?,
      currencyCode: json['currencyCode'] as String?,
      invoiceId: json['invoiceId'] as String?,
      photos: [
        for (final photo in json['photos'] as List<dynamic>? ?? const [])
          if (photo is Map<String, dynamic>)
            PhotographyVisitPhotoModel.fromJson(photo),
      ],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }
}

/// `ClinicCreatePhotographyVisitRequest` — staff logging a visit on a
/// doctor's behalf. There is no case id anywhere on it, by design.
class CreatePhotographyVisitRequestModel {
  const CreatePhotographyVisitRequestModel({
    required this.doctorId,
    required this.visitType,
    this.patientId,
    this.scheduledAt,
    this.price = 0,
    this.currencyId,
    this.notes,
    this.shade = const PhotographyShadeNotes(),
  });

  final String doctorId;
  final PhotographyVisitType visitType;
  final String? patientId;
  final DateTime? scheduledAt;
  final double price;
  final String? currencyId;
  final String? notes;
  final PhotographyShadeNotes shade;

  Map<String, dynamic> toJson() => {
    'doctorId': doctorId,
    'visitType': visitType.value,
    'patientId': patientId,
    'scheduledAt': scheduledAt?.toUtc().toIso8601String(),
    'price': price,
    'currencyId': currencyId,
    'notes': notes,
    ...shade.toJson(),
  };
}

/// `ClinicSchedulePhotographyVisitRequest`. A null [price] and [currencyId]
/// keep whatever was set when the visit was requested.
class SchedulePhotographyVisitRequestModel {
  const SchedulePhotographyVisitRequestModel({
    required this.scheduledAt,
    this.assignedEmployeeId,
    this.price,
    this.currencyId,
    this.note,
  });

  final DateTime scheduledAt;
  final String? assignedEmployeeId;
  final double? price;
  final String? currencyId;
  final String? note;

  Map<String, dynamic> toJson() => {
    'scheduledAt': scheduledAt.toUtc().toIso8601String(),
    'assignedEmployeeId': assignedEmployeeId,
    'price': ?price,
    'currencyId': ?currencyId,
    'note': note,
  };
}

/// `ClinicCompletePhotographyVisitRequest` — completing also bills the visit
/// to the doctor, and is where the shade notes are usually filled in.
class CompletePhotographyVisitRequestModel {
  const CompletePhotographyVisitRequestModel({
    this.shade = const PhotographyShadeNotes(),
    this.price,
    this.currencyId,
    this.note,
  });

  final PhotographyShadeNotes shade;
  final double? price;
  final String? currencyId;
  final String? note;

  Map<String, dynamic> toJson() => {
    ...shade.toJson(),
    'price': ?price,
    'currencyId': ?currencyId,
    'note': note,
  };
}

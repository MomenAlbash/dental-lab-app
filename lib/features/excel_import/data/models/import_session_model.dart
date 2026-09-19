/// What an import can bring in.
///
/// **The wire values are an assumption.** `entityType` is a free `string` path
/// parameter in the API — swagger declares no enum for it — and the endpoint
/// answers `401` before it validates the path, so the accepted values could
/// not be probed either. These are the app's own entity names, lower-cased.
///
/// The cost of a wrong one is bounded and visible: the template download comes
/// back with the server's own error, which the screen shows. It cannot corrupt
/// anything. **If the backend names them differently, this list is the single
/// place to correct.**
enum ImportEntityType {
  doctors('doctors', 'الأطباء'),
  patients('patients', 'المرضى'),
  employees('employees', 'الموظفون'),
  clinics('clinics', 'العيادات');

  const ImportEntityType(this.wireValue, this.label);

  /// What goes in the URL path.
  final String wireValue;
  final String label;

  /// Matches a value the server sent back on a past session, so history rows
  /// render with a proper label. Case-insensitive, because the path is written
  /// by hand and the server may echo it in its own casing.
  static ImportEntityType? fromWire(String? value) {
    final needle = value?.trim().toLowerCase();
    if (needle == null || needle.isEmpty) return null;

    for (final type in values) {
      if (type.wireValue == needle) return type;
    }
    return null;
  }
}

/// One row the import could not take (`ClinicImportRowErrorDto`).
class ImportRowErrorModel {
  const ImportRowErrorModel({this.rowNumber = 0, this.message});

  /// The spreadsheet row, as the server counted it — so the user can open the
  /// file and go straight to it.
  final int rowNumber;
  final String? message;

  String get displayMessage {
    final text = message?.trim();
    return (text == null || text.isEmpty) ? 'خطأ غير محدد' : text;
  }

  factory ImportRowErrorModel.fromJson(Map<String, dynamic> json) {
    return ImportRowErrorModel(
      rowNumber: json['rowNumber'] as int? ?? 0,
      message: json['message'] as String?,
    );
  }
}

/// One import run (`ClinicImportSessionDto`).
///
/// The server processes the file in the background, so a session is polled
/// rather than awaited: [processedRows] climbs against [totalRows] until
/// [isFinished].
class ImportSessionModel {
  const ImportSessionModel({
    this.sessionId,
    this.entityTypeRaw,
    this.fileName,
    this.status,
    this.totalRows = 0,
    this.processedRows = 0,
    this.successCount = 0,
    this.failureCount = 0,
    this.errors = const [],
    this.failureReason,
    this.startedAt,
    this.completedAt,
  });

  final String? sessionId;

  /// As the server spelled it. Kept raw as well as parsed, so a history row
  /// for an entity this client does not know still says what it was.
  final String? entityTypeRaw;

  final String? fileName;

  /// A free string in the API, not an enum — so it is carried through and
  /// shown rather than being matched against a guessed set. [isFinished] is
  /// decided from the row counts instead, which are typed.
  final String? status;

  final int totalRows;
  final int processedRows;
  final int successCount;
  final int failureCount;

  /// The rows that failed, with the server's reason for each.
  final List<ImportRowErrorModel> errors;

  /// Set when the whole run failed rather than individual rows — a malformed
  /// file, usually. Distinct from per-row errors: nothing was imported.
  final String? failureReason;

  final DateTime? startedAt;
  final DateTime? completedAt;

  ImportEntityType? get entityType => ImportEntityType.fromWire(entityTypeRaw);

  String get entityLabel => entityType?.label ?? (entityTypeRaw ?? '—');

  String get displayFileName {
    final name = fileName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  /// Whether the server is done with this run.
  ///
  /// Read from [completedAt] rather than from [status], which is an untyped
  /// string this client must not pretend to understand. A run with a
  /// completion time is over, whatever it is called.
  bool get isFinished => completedAt != null;

  /// Whether the whole run failed, as opposed to some of its rows.
  bool get didFail => (failureReason?.trim().isNotEmpty ?? false);

  /// `0.0`–`1.0`.
  ///
  /// A run whose total is not known yet reports zero rather than dividing by
  /// it — an indeterminate bar is honest there, a full one is not.
  double get progress {
    if (totalRows <= 0) return 0;
    return (processedRows / totalRows).clamp(0.0, 1.0);
  }

  /// True while the server is still working through the file.
  bool get isRunning => !isFinished && !didFail;

  factory ImportSessionModel.fromJson(Map<String, dynamic> json) {
    return ImportSessionModel(
      sessionId: json['sessionId'] as String?,
      entityTypeRaw: json['entityType'] as String?,
      fileName: json['fileName'] as String?,
      status: json['status'] as String?,
      totalRows: json['totalRows'] as int? ?? 0,
      processedRows: json['processedRows'] as int? ?? 0,
      successCount: json['successCount'] as int? ?? 0,
      failureCount: json['failureCount'] as int? ?? 0,
      errors: [
        for (final entry in json['errors'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>) ImportRowErrorModel.fromJson(entry),
      ],
      failureReason: json['failureReason'] as String?,
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? ''),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}

/// Where a scan came from (`DigitalScanSource`).
enum DigitalScanSource {
  doctor(1, 'من الطبيب'),
  labScannerSession(2, 'جلسة سكنر بالمخبر');

  const DigitalScanSource(this.value, this.label);

  final int value;
  final String label;

  static DigitalScanSource? fromValue(int? value) {
    for (final source in values) {
      if (source.value == value) return source;
    }
    return null;
  }
}

/// Which arch or bite a scan file captures (`DigitalScanRole`).
///
/// Asked at upload because a folder of `scan_001.stl` is unusable at the
/// bench: the technician needs to know which one is the upper before opening
/// any of them.
enum DigitalScanRole {
  unspecified(1, 'غير محدد'),
  upper(2, 'الفك العلوي'),
  lower(3, 'الفك السفلي'),
  bite(4, 'الإطباق'),
  preparation(5, 'التحضير');

  const DigitalScanRole(this.value, this.label);

  final int value;
  final String label;

  static DigitalScanRole? fromValue(int? value) {
    for (final role in values) {
      if (role.value == value) return role;
    }
    return null;
  }
}

/// Whether the file itself is still on the server (`DigitalScanFileState`).
///
/// **The row outlives the file.** Retention sweeps and NAS archiving delete
/// bytes, not records — so a case filed two years ago still says what was
/// scanned and where it went, instead of showing an empty attachment list that
/// reads like the scan was never taken.
enum DigitalScanFileState {
  stored(1, 'موجود'),
  removed(2, 'محذوف');

  const DigitalScanFileState(this.value, this.label);

  final int value;
  final String label;

  static DigitalScanFileState? fromValue(int? value) {
    for (final state in values) {
      if (state.value == value) return state;
    }
    return null;
  }
}

/// Why the file went away (`DigitalScanRemovalReason`).
///
/// The distinction matters to whoever is looking for it: an archived scan can
/// be fetched off the NAS, one swept for age or budget is gone, and a manual
/// deletion is somebody's decision that can be asked about.
enum DigitalScanRemovalReason {
  retentionAge(1, 'انتهت مدة الحفظ'),
  storageBudget(2, 'امتلأت المساحة'),
  manual(3, 'حذف يدوي'),
  archivedToNas(4, 'مؤرشف على NAS');

  const DigitalScanRemovalReason(this.value, this.label);

  final int value;
  final String label;

  static DigitalScanRemovalReason? fromValue(int? value) {
    for (final reason in values) {
      if (reason.value == value) return reason;
    }
    return null;
  }
}

/// One scan file (`ClinicDigitalScanDto`).
class DigitalScanModel {
  const DigitalScanModel({
    required this.id,
    this.caseId,
    this.scannerSessionId,
    this.source,
    this.fileName,
    this.filePath,
    this.fileSizeBytes = 0,
    this.format,
    this.notes,
    this.createdAt,
    this.fileState,
    this.fileRemovedAt,
    this.removalReason,
    this.isArchivedAtLaboratory = false,
  });

  final String id;

  /// Null until the session produces a case — a scan taken at booking time
  /// belongs to the session first and is attached to the case afterwards.
  final String? caseId;
  final String? scannerSessionId;

  final DigitalScanSource? source;
  final String? fileName;
  final String? filePath;
  final int fileSizeBytes;
  final String? format;
  final String? notes;
  final DateTime? createdAt;

  final DigitalScanFileState? fileState;
  final DateTime? fileRemovedAt;
  final DigitalScanRemovalReason? removalReason;

  /// Whether a copy sits on the laboratory's own NAS. Independent of
  /// [fileState]: the server copy can be gone while the archive copy is not,
  /// which is the whole point of archiving rather than deleting.
  final bool isArchivedAtLaboratory;

  bool get isStored => fileState != DigitalScanFileState.removed;

  /// Whether the bytes can still be fetched from somewhere — the server, or
  /// the lab's NAS.
  bool get isRetrievable => isStored || isArchivedAtLaboratory;

  String get displayName {
    final name = fileName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  /// `12.4 م.ب` — sized to the unit rather than always in bytes, because a
  /// scan is tens of megabytes and a raw byte count is unreadable at that
  /// scale.
  String get sizeLabel {
    if (fileSizeBytes <= 0) return '—';

    const units = ['بايت', 'ك.ب', 'م.ب', 'غ.ب'];
    var size = fileSizeBytes.toDouble();
    var unit = 0;
    while (size >= 1024 && unit < units.length - 1) {
      size /= 1024;
      unit++;
    }
    // Bytes have no meaningful fraction; everything above does.
    final digits = unit == 0 ? 0 : 1;
    return '${size.toStringAsFixed(digits)} ${units[unit]}';
  }

  factory DigitalScanModel.fromJson(Map<String, dynamic> json) {
    return DigitalScanModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String?,
      scannerSessionId: json['scannerSessionId'] as String?,
      source: DigitalScanSource.fromValue(json['source'] as int?),
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      format: json['format'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      fileState: DigitalScanFileState.fromValue(json['fileState'] as int?),
      fileRemovedAt: DateTime.tryParse(
        json['fileRemovedAt'] as String? ?? '',
      ),
      removalReason: DigitalScanRemovalReason.fromValue(
        json['removalReason'] as int?,
      ),
      isArchivedAtLaboratory: json['isArchivedAtLaboratory'] as bool? ?? false,
    );
  }
}

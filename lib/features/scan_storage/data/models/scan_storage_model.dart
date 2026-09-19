import 'package:dental_lab_app/features/scanner_sessions/data/models/digital_scan_model.dart';

/// Renders a byte count at whatever unit makes it readable.
///
/// Shared across this feature because storage figures here span six orders of
/// magnitude — a single file is megabytes, the budget is gigabytes — and a raw
/// byte count is unreadable at either end.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 بايت';

  const units = ['بايت', 'ك.ب', 'م.ب', 'غ.ب', 'ت.ب'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  // Bytes have no meaningful fraction; everything above does.
  return '${size.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

/// One scan file still on disk, as the storage screen lists it
/// (`ClinicStoredScanDto`).
class StoredScanModel {
  const StoredScanModel({
    required this.id,
    this.caseId,
    this.caseNumber,
    this.fileName,
    this.format,
    this.fileSizeBytes = 0,
    this.uploadedAt,
    this.isEligibleForAutomaticRemoval = false,
  });

  final String id;
  final String? caseId;
  final String? caseNumber;
  final String? fileName;
  final String? format;
  final int fileSizeBytes;
  final DateTime? uploadedAt;

  /// Whether the next retention sweep would take this one.
  ///
  /// **The server decides**, against the lab's own retention rules — age, and
  /// whether the case is closed. Recomputing it here from `uploadedAt` and a
  /// day count would quietly disagree with the sweep that actually runs, and
  /// the screen would be promising deletions that never happen.
  final bool isEligibleForAutomaticRemoval;

  String get displayName {
    final name = fileName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  String get sizeLabel => formatBytes(fileSizeBytes);

  factory StoredScanModel.fromJson(Map<String, dynamic> json) {
    return StoredScanModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String?,
      caseNumber: json['caseNumber'] as String?,
      fileName: json['fileName'] as String?,
      format: json['format'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? ''),
      isEligibleForAutomaticRemoval:
          json['isEligibleForAutomaticRemoval'] as bool? ?? false,
    );
  }
}

/// A scan whose bytes are gone (`ClinicRemovedScanDto`).
///
/// The row outlives the file: a case filed two years ago still says what was
/// scanned and why it went, instead of showing an empty attachment list that
/// reads like the scan was never taken.
class RemovedScanModel {
  const RemovedScanModel({
    required this.id,
    this.caseId,
    this.caseNumber,
    this.fileName,
    this.format,
    this.fileSizeBytes = 0,
    this.uploadedAt,
    this.removedAt,
    this.removalReason,
  });

  final String id;
  final String? caseId;
  final String? caseNumber;
  final String? fileName;
  final String? format;
  final int fileSizeBytes;
  final DateTime? uploadedAt;
  final DateTime? removedAt;

  /// Why it went. The distinction matters to whoever is looking for it: an
  /// archived scan can be fetched off the NAS, one swept for age or budget is
  /// gone, and a manual deletion is somebody's decision that can be asked
  /// about.
  final DigitalScanRemovalReason? removalReason;

  String get displayName {
    final name = fileName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  String get sizeLabel => formatBytes(fileSizeBytes);

  /// Whether a copy is still retrievable from the laboratory's own NAS.
  bool get isArchived =>
      removalReason == DigitalScanRemovalReason.archivedToNas;

  factory RemovedScanModel.fromJson(Map<String, dynamic> json) {
    return RemovedScanModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String?,
      caseNumber: json['caseNumber'] as String?,
      fileName: json['fileName'] as String?,
      format: json['format'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      uploadedAt: DateTime.tryParse(json['uploadedAt'] as String? ?? ''),
      removedAt: DateTime.tryParse(json['removedAt'] as String? ?? ''),
      removalReason: DigitalScanRemovalReason.fromValue(
        json['removalReason'] as int?,
      ),
    );
  }
}

/// The laboratory's scan storage, as the server measures it
/// (`ClinicScanStorageDto`).
class ScanStorageModel {
  const ScanStorageModel({
    this.storedBytes = 0,
    this.storedCount = 0,
    this.reclaimedBytes = 0,
    this.removedCount = 0,
    this.budgetBytes = 0,
    this.usagePercent = 0,
    this.isOverBudget = false,
    this.isWarning = false,
    this.warnPercent = 0,
    this.oldestStoredAt,
    this.eligibleNowCount = 0,
    this.eligibleNowBytes = 0,
    this.overBudgetAndNothingEligible = false,
    this.retentionEnabled = false,
    this.retentionDays = 0,
    this.onlyClosedCases = false,
    this.budgetGb = 0,
    this.uploadsBytes = 0,
    this.otherUploadsBytes = 0,
    this.diskTotalBytes = 0,
    this.diskFreeBytes = 0,
    this.largestStored = const [],
    this.recentRemovals = const [],
  });

  final int storedBytes;
  final int storedCount;

  /// What past sweeps have already freed. Kept beside [storedBytes] because
  /// "we are at 80%" means something different when the sweeps have been
  /// running than when nothing has ever been deleted.
  final int reclaimedBytes;
  final int removedCount;

  final int budgetBytes;

  /// Against the budget, not the disk — the server computes it, and a client
  /// dividing the two would round differently from the sweep that decides.
  final int usagePercent;

  final bool isOverBudget;
  final bool isWarning;
  final int warnPercent;

  final DateTime? oldestStoredAt;

  /// What the next sweep would take right now.
  final int eligibleNowCount;
  final int eligibleNowBytes;

  /// **The state that needs a person.** Over budget with nothing the rules
  /// allow deleting means the sweep cannot help: either the retention window
  /// has to shorten, the budget has to grow, or files go to the NAS. Silence
  /// here is how a lab fills its disk while a green "auto-cleanup on" sits on
  /// the screen.
  final bool overBudgetAndNothingEligible;

  final bool retentionEnabled;
  final int retentionDays;

  /// When true, the sweep only prunes scans belonging to closed cases.
  final bool onlyClosedCases;

  final int budgetGb;

  /// Everything uploaded, scans included.
  final int uploadsBytes;

  /// Uploads that are **not** scans — attachments, message files. Reported
  /// separately because they are outside the retention sweep entirely, so a
  /// disk that is full of them will not be helped by running it.
  final int otherUploadsBytes;

  final int diskTotalBytes;
  final int diskFreeBytes;

  /// The biggest files still stored — where a manual deletion is worth making.
  final List<StoredScanModel> largestStored;

  final List<RemovedScanModel> recentRemovals;

  String get storedLabel => formatBytes(storedBytes);
  String get budgetLabel => formatBytes(budgetBytes);
  String get reclaimedLabel => formatBytes(reclaimedBytes);
  String get eligibleNowLabel => formatBytes(eligibleNowBytes);
  String get otherUploadsLabel => formatBytes(otherUploadsBytes);
  String get diskFreeLabel => formatBytes(diskFreeBytes);

  /// `0.0`–`1.0`, clamped, for a progress bar.
  ///
  /// Clamped because usage over budget is an ordinary state here, and a bar
  /// drawing past its own end is a rendering bug rather than a louder warning
  /// — [isOverBudget] is what says it is over.
  double get usageFraction => (usagePercent / 100).clamp(0.0, 1.0);

  /// Whether a sweep would actually free anything. A "run cleanup" button that
  /// reliably does nothing teaches people to stop trusting the screen.
  bool get hasSomethingToSweep => eligibleNowCount > 0;

  factory ScanStorageModel.fromJson(Map<String, dynamic> json) {
    return ScanStorageModel(
      storedBytes: (json['storedBytes'] as num?)?.toInt() ?? 0,
      storedCount: json['storedCount'] as int? ?? 0,
      reclaimedBytes: (json['reclaimedBytes'] as num?)?.toInt() ?? 0,
      removedCount: json['removedCount'] as int? ?? 0,
      budgetBytes: (json['budgetBytes'] as num?)?.toInt() ?? 0,
      usagePercent: json['usagePercent'] as int? ?? 0,
      isOverBudget: json['isOverBudget'] as bool? ?? false,
      isWarning: json['isWarning'] as bool? ?? false,
      warnPercent: json['warnPercent'] as int? ?? 0,
      oldestStoredAt: DateTime.tryParse(
        json['oldestStoredAt'] as String? ?? '',
      ),
      eligibleNowCount: json['eligibleNowCount'] as int? ?? 0,
      eligibleNowBytes: (json['eligibleNowBytes'] as num?)?.toInt() ?? 0,
      overBudgetAndNothingEligible:
          json['overBudgetAndNothingEligible'] as bool? ?? false,
      retentionEnabled: json['retentionEnabled'] as bool? ?? false,
      retentionDays: json['retentionDays'] as int? ?? 0,
      onlyClosedCases: json['onlyClosedCases'] as bool? ?? false,
      budgetGb: json['budgetGb'] as int? ?? 0,
      uploadsBytes: (json['uploadsBytes'] as num?)?.toInt() ?? 0,
      otherUploadsBytes: (json['otherUploadsBytes'] as num?)?.toInt() ?? 0,
      diskTotalBytes: (json['diskTotalBytes'] as num?)?.toInt() ?? 0,
      diskFreeBytes: (json['diskFreeBytes'] as num?)?.toInt() ?? 0,
      largestStored: [
        for (final entry in json['largestStored'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>) StoredScanModel.fromJson(entry),
      ],
      recentRemovals: [
        for (final entry
            in json['recentRemovals'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>) RemovedScanModel.fromJson(entry),
      ],
    );
  }
}

/// What a sweep, a manual removal or a NAS confirmation actually did
/// (`ClinicScanRetentionRunResultDto`).
class ScanRetentionRunResultModel {
  const ScanRetentionRunResultModel({
    this.removedCount = 0,
    this.reclaimedBytes = 0,
    this.missingFileCount = 0,
    this.stillOverBudget = false,
  });

  final int removedCount;
  final int reclaimedBytes;

  /// Rows whose file was already gone from disk. Not an error — it is the
  /// database and the filesystem disagreeing, usually after a restore — but it
  /// is reported because those rows freed nothing, so the numbers will not add
  /// up otherwise.
  final int missingFileCount;

  /// **Said out loud after every run.** A cleanup that finishes and leaves the
  /// lab still over budget is the case people most need to know about, and a
  /// bare "removed 12 files" reads like success.
  final bool stillOverBudget;

  String get reclaimedLabel => formatBytes(reclaimedBytes);

  factory ScanRetentionRunResultModel.fromJson(Map<String, dynamic> json) {
    return ScanRetentionRunResultModel(
      removedCount: json['removedCount'] as int? ?? 0,
      reclaimedBytes: (json['reclaimedBytes'] as num?)?.toInt() ?? 0,
      missingFileCount: json['missingFileCount'] as int? ?? 0,
      stillOverBudget: json['stillOverBudget'] as bool? ?? false,
    );
  }
}

/// A scan waiting to be copied to the laboratory's NAS
/// (`ClinicPendingNasArchiveDto`).
///
/// The flow is deliberately two-step: the lab's own tool downloads the file,
/// writes it to the NAS, and only then confirms — at which point the server
/// frees the bytes. Deleting first and copying afterwards would lose a scan
/// every time the copy failed.
class PendingNasArchiveModel {
  const PendingNasArchiveModel({
    required this.id,
    required this.caseId,
    this.caseNumber,
    this.fileName,
    this.format,
    this.fileSizeBytes = 0,
    this.contentHash,
    this.downloadPath,
  });

  final String id;
  final String caseId;
  final String? caseNumber;
  final String? fileName;
  final String? format;
  final int fileSizeBytes;

  /// What the archiving tool checks the copy against before confirming. The
  /// whole point of the two-step flow: without it, "confirmed" only means a
  /// file of the right name arrived.
  final String? contentHash;

  final String? downloadPath;

  String get displayName {
    final name = fileName?.trim();
    return (name == null || name.isEmpty) ? '—' : name;
  }

  String get sizeLabel => formatBytes(fileSizeBytes);

  factory PendingNasArchiveModel.fromJson(Map<String, dynamic> json) {
    return PendingNasArchiveModel(
      id: json['id'] as String? ?? '',
      caseId: json['caseId'] as String? ?? '',
      caseNumber: json['caseNumber'] as String?,
      fileName: json['fileName'] as String?,
      format: json['format'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      contentHash: json['contentHash'] as String?,
      downloadPath: json['downloadPath'] as String?,
    );
  }
}

/// `POST /ScanStorage/nas-archive/confirm` (`ClinicConfirmNasArchiveRequest`).
///
/// **Confirming frees the bytes**, so it is sent only once the copy is
/// verifiably on the NAS. [nasPath] records where it went — without it the
/// archive is a promise nobody can follow up on.
class ConfirmNasArchiveRequestModel {
  const ConfirmNasArchiveRequestModel({required this.items});

  final List<ConfirmNasArchiveItemModel> items;

  Map<String, dynamic> toJson() => {
    'items': [for (final item in items) item.toJson()],
  };
}

class ConfirmNasArchiveItemModel {
  const ConfirmNasArchiveItemModel({required this.scanId, this.nasPath});

  final String scanId;
  final String? nasPath;

  Map<String, dynamic> toJson() => {'scanId': scanId, 'nasPath': nasPath};
}

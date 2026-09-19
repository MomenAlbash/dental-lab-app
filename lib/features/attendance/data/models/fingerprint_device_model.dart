/// A registered fingerprint terminal (`FingerprintDeviceDto`).
///
/// The app never talks to the device itself — a desktop connector polls it and
/// posts the raw records to `Punches/bulk`. What is managed here is the
/// registry: which terminals exist, and which employee each device number
/// belongs to.
class FingerprintDeviceModel {
  const FingerprintDeviceModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.ipAddress,
    this.port = 0,
    this.commKey,
    this.lastSyncAt,
    this.enrollmentCount = 0,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? laboratoryId;
  final String? name;
  final String? ipAddress;
  final int port;

  /// The terminal's comm password. Null on devices that need none.
  final int? commKey;

  final DateTime? lastSyncAt;

  /// How many employees are mapped to a number on this device — the one figure
  /// that says whether a registered terminal is wired up to anybody yet.
  final int enrollmentCount;

  final bool canDelete;
  final String? deleteMessage;

  String get displayName => name?.trim().isNotEmpty ?? false ? name! : '—';

  String get addressLabel => '${ipAddress ?? '—'}:$port';

  /// A terminal registered but mapped to nobody records nothing — worth
  /// calling out on the row rather than leaving it to look configured.
  bool get isUnused => enrollmentCount == 0;

  factory FingerprintDeviceModel.fromJson(Map<String, dynamic> json) {
    return FingerprintDeviceModel(
      id: json['id'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      ipAddress: json['ipAddress'] as String?,
      port: json['port'] as int? ?? 0,
      commKey: json['commKey'] as int?,
      lastSyncAt: DateTime.tryParse(json['lastSyncAt'] as String? ?? ''),
      enrollmentCount: json['enrollmentCount'] as int? ?? 0,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

/// `SaveFingerprintDeviceRequest`.
class SaveFingerprintDeviceRequestModel {
  const SaveFingerprintDeviceRequestModel({
    required this.name,
    required this.ipAddress,
    this.port = 4370,
    this.commKey,
  });

  final String name;
  final String ipAddress;

  /// 4370 is the ZKTeco default, which is what these terminals almost always
  /// are — pre-filled rather than made the user look it up.
  final int port;

  final int? commKey;

  Map<String, dynamic> toJson() => {
    'name': name,
    'ipAddress': ipAddress,
    'port': port,
    'commKey': commKey,
  };
}

/// One employee's number on one device (`EmployeeFingerprintEnrollmentDto`).
class FingerprintEnrollmentModel {
  const FingerprintEnrollmentModel({
    required this.id,
    required this.fingerprintDeviceId,
    this.deviceName,
    required this.employeeId,
    this.employeeName,
    this.deviceUserId,
    this.punchCount = 0,
    this.lastPunchAt,
  });

  final String id;
  final String fingerprintDeviceId;

  /// Only filled in by the employee-first list; the device-first one already
  /// shows the device name as its own heading.
  final String? deviceName;

  final String employeeId;
  final String? employeeName;

  /// The number the terminal itself knows this person by.
  final String? deviceUserId;

  /// Punches already recorded for this employee on this device — what makes
  /// "there is history behind this row" visible *before* someone edits it.
  ///
  /// Counts punches attributed to the **employee**, not to the code: past
  /// attendance stores the resolved employee, so it survives a code change
  /// untouched.
  final int punchCount;

  final DateTime? lastPunchAt;

  factory FingerprintEnrollmentModel.fromJson(Map<String, dynamic> json) {
    return FingerprintEnrollmentModel(
      id: json['id'] as String? ?? '',
      fingerprintDeviceId: json['fingerprintDeviceId'] as String? ?? '',
      deviceName: json['deviceName'] as String?,
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      deviceUserId: json['deviceUserId'] as String?,
      punchCount: json['punchCount'] as int? ?? 0,
      lastPunchAt: DateTime.tryParse(json['lastPunchAt'] as String? ?? ''),
    );
  }
}

/// One employee and every device code they hold
/// (`EmployeeFingerprintOverviewDto`).
///
/// The management screen is employee-first because that is how the question is
/// actually asked — "what is Ahmad's number?" — and an employee with **no**
/// code has to appear too, since that is precisely the row needing attention.
class FingerprintOverviewModel {
  const FingerprintOverviewModel({
    required this.employeeId,
    this.employeeName,
    this.employeeCode,
    this.imagePath,
    this.isActive = true,
    this.enrollments = const [],
    this.totalPunchCount = 0,
    this.lastPunchAt,
  });

  final String employeeId;
  final String? employeeName;

  /// The HR staff number — unrelated to any device user id, and the two get
  /// confused constantly, which is why both are labelled on screen.
  final String? employeeCode;

  final String? imagePath;
  final bool isActive;
  final List<FingerprintEnrollmentModel> enrollments;

  /// Across every source, manual entries included — read by the delete/edit
  /// confirmation to say whether attendance is already riding on this row.
  final int totalPunchCount;

  final DateTime? lastPunchAt;

  bool get hasEnrollment => enrollments.isNotEmpty;

  factory FingerprintOverviewModel.fromJson(Map<String, dynamic> json) {
    return FingerprintOverviewModel(
      employeeId: json['employeeId'] as String? ?? '',
      employeeName: json['employeeName'] as String?,
      employeeCode: json['employeeCode'] as String?,
      imagePath: json['imagePath'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      enrollments: [
        for (final entry in json['enrollments'] as List<dynamic>? ?? const [])
          FingerprintEnrollmentModel.fromJson(entry as Map<String, dynamic>),
      ],
      totalPunchCount: json['totalPunchCount'] as int? ?? 0,
      lastPunchAt: DateTime.tryParse(json['lastPunchAt'] as String? ?? ''),
    );
  }
}

/// `EnrollEmployeeFingerprintRequest` / `UpdateEmployeeFingerprintEnrollmentRequest`
/// — the employee-first shape, where the person comes from the URL.
///
/// The employee is deliberately **not** editable: re-pointing a code at
/// somebody else would silently re-interpret every future punch with nothing on
/// screen saying whose they now are, so that stays a delete plus an add.
class SaveFingerprintEnrollmentRequestModel {
  const SaveFingerprintEnrollmentRequestModel({
    required this.deviceId,
    required this.deviceUserId,
  });

  final String deviceId;
  final String deviceUserId;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceUserId': deviceUserId,
  };
}

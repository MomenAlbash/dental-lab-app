import 'package:dental_lab_app/features/laboratories/data/models/footer_contact_model.dart';

/// A laboratory, covering both shapes the API returns.
///
/// `GET /Laboratories` and `GET /Laboratories/{id}` answer with `LaboratoryDto`
/// — contact details, the three counts, and the laboratory's settings.
/// `GET /Laboratories/own` answers with the narrower `ClinicLaboratoryDto`:
/// contact details and the message limits only, with **no counts and no
/// `isActive`**.
///
/// That is why the counts are nullable. They used to default to `0`, which
/// meant "مختبري" confidently displayed `0 users / 0 doctors / 0 cases` for
/// every laboratory — numbers the server never sent. Null now means "not
/// reported on this endpoint", and the UI hides the tiles instead of inventing
/// figures. The same goes for the settings blocks, which `/own` only partly
/// reports.
class LaboratoryModel {
  final String id;
  final String? name;
  final String? address;
  final String? phoneNumber;

  /// Where the lab's logo is stored, for the report header. Null means no
  /// logo at all, which is not the same as an empty one: reports lay out
  /// differently with no logo than with a blank box where one should be.
  final String? logoPath;

  /// The contact lines printed at the foot of reports and invoices, in the
  /// order the lab set. A list rather than one phone field because a lab
  /// prints several — reception, the duty technician, accounts — and packing
  /// them into one string is how an invoice ends up with a number nobody
  /// answers.
  final List<FooterContactModel> footerContacts;

  /// Absent from `/own`, so null there rather than a fabricated `true`.
  final bool? isActive;

  final int? userCount;
  final int? doctorCount;
  final int? caseCount;

  // ---- Case-message limits (both endpoints report these) ----

  /// Cap on attachments a single case's message thread may carry.
  final int? maxMessageAttachmentsPerCase;
  final int? maxMessageImageSizeMb;
  final int? maxMessageVideoSizeMb;
  final int? maxMessageAudioSizeMb;
  final int? maxMessageFileSizeMb;

  // ---- Workflow and scan storage (only `LaboratoryDto` reports these) ----

  /// How long before a control delivery is due the lab wants reminding.
  final int? controlDeliveryReminderHours;

  final bool? scanRetentionEnabled;
  final int? scanRetentionDays;

  /// When true, retention only prunes scans belonging to closed cases.
  final bool? scanRetentionOnlyClosedCases;

  final int? scanStorageBudgetGb;

  /// Percentage of [scanStorageBudgetGb] at which the lab is warned.
  final int? scanStorageWarnPercent;

  const LaboratoryModel({
    required this.id,
    this.name,
    this.address,
    this.phoneNumber,
    this.logoPath,
    this.footerContacts = const [],
    this.isActive,
    this.userCount,
    this.doctorCount,
    this.caseCount,
    this.maxMessageAttachmentsPerCase,
    this.maxMessageImageSizeMb,
    this.maxMessageVideoSizeMb,
    this.maxMessageAudioSizeMb,
    this.maxMessageFileSizeMb,
    this.controlDeliveryReminderHours,
    this.scanRetentionEnabled,
    this.scanRetentionDays,
    this.scanRetentionOnlyClosedCases,
    this.scanStorageBudgetGb,
    this.scanStorageWarnPercent,
  });

  /// True when this copy came from an endpoint that reports the counts — i.e.
  /// the list or the by-id detail, not `/own`.
  bool get hasCounts =>
      userCount != null || doctorCount != null || caseCount != null;

  /// True when any message limit was reported.
  bool get hasMessageLimits =>
      maxMessageAttachmentsPerCase != null ||
      maxMessageImageSizeMb != null ||
      maxMessageVideoSizeMb != null ||
      maxMessageAudioSizeMb != null ||
      maxMessageFileSizeMb != null;

  /// True when the scan-storage block was reported.
  bool get hasScanSettings =>
      scanRetentionEnabled != null ||
      scanRetentionDays != null ||
      scanRetentionOnlyClosedCases != null ||
      scanStorageBudgetGb != null ||
      scanStorageWarnPercent != null;

  factory LaboratoryModel.fromJson(Map<String, dynamic> json) {
    return LaboratoryModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      address: json['address'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      logoPath: json['logoPath'] as String?,
      footerContacts: [
        for (final entry
            in json['footerContacts'] as List<dynamic>? ?? const [])
          if (entry is Map<String, dynamic>) FooterContactModel.fromJson(entry),
      ],
      isActive: json['isActive'] as bool?,
      userCount: json['userCount'] as int?,
      doctorCount: json['doctorCount'] as int?,
      caseCount: json['caseCount'] as int?,
      maxMessageAttachmentsPerCase:
          json['maxMessageAttachmentsPerCase'] as int?,
      maxMessageImageSizeMb: json['maxMessageImageSizeMb'] as int?,
      maxMessageVideoSizeMb: json['maxMessageVideoSizeMb'] as int?,
      maxMessageAudioSizeMb: json['maxMessageAudioSizeMb'] as int?,
      maxMessageFileSizeMb: json['maxMessageFileSizeMb'] as int?,
      controlDeliveryReminderHours:
          json['controlDeliveryReminderHours'] as int?,
      scanRetentionEnabled: json['scanRetentionEnabled'] as bool?,
      scanRetentionDays: json['scanRetentionDays'] as int?,
      scanRetentionOnlyClosedCases:
          json['scanRetentionOnlyClosedCases'] as bool?,
      scanStorageBudgetGb: json['scanStorageBudgetGb'] as int?,
      scanStorageWarnPercent: json['scanStorageWarnPercent'] as int?,
    );
  }

  /// Round-trips the model for the offline list cache. Nulls are kept out so a
  /// cached `/own` copy does not come back claiming zero cases.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phoneNumber': phoneNumber,
      if (logoPath != null) 'logoPath': logoPath,
      if (footerContacts.isNotEmpty)
        'footerContacts': [
          for (final contact in footerContacts) contact.toJson(),
        ],
      if (isActive != null) 'isActive': isActive,
      if (userCount != null) 'userCount': userCount,
      if (doctorCount != null) 'doctorCount': doctorCount,
      if (caseCount != null) 'caseCount': caseCount,
      if (maxMessageAttachmentsPerCase != null)
        'maxMessageAttachmentsPerCase': maxMessageAttachmentsPerCase,
      if (maxMessageImageSizeMb != null)
        'maxMessageImageSizeMb': maxMessageImageSizeMb,
      if (maxMessageVideoSizeMb != null)
        'maxMessageVideoSizeMb': maxMessageVideoSizeMb,
      if (maxMessageAudioSizeMb != null)
        'maxMessageAudioSizeMb': maxMessageAudioSizeMb,
      if (maxMessageFileSizeMb != null)
        'maxMessageFileSizeMb': maxMessageFileSizeMb,
      if (controlDeliveryReminderHours != null)
        'controlDeliveryReminderHours': controlDeliveryReminderHours,
      if (scanRetentionEnabled != null)
        'scanRetentionEnabled': scanRetentionEnabled,
      if (scanRetentionDays != null) 'scanRetentionDays': scanRetentionDays,
      if (scanRetentionOnlyClosedCases != null)
        'scanRetentionOnlyClosedCases': scanRetentionOnlyClosedCases,
      if (scanStorageBudgetGb != null)
        'scanStorageBudgetGb': scanStorageBudgetGb,
      if (scanStorageWarnPercent != null)
        'scanStorageWarnPercent': scanStorageWarnPercent,
    };
  }
}

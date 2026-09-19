import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';

/// Gender as encoded by the API (`0` = male, `1` = female).
enum DoctorGender {
  male,
  female;

  int get apiValue => index;

  String get arabicLabel => switch (this) {
    DoctorGender.male => 'ذكر',
    DoctorGender.female => 'أنثى',
  };

  static DoctorGender? fromApi(int? value) => switch (value) {
    0 => DoctorGender.male,
    1 => DoctorGender.female,
    _ => null,
  };
}

/// Where a doctor stands in the lab's review (`DoctorApprovalStatus`, 1..3).
///
/// Doctors can now register themselves, so a record does not become usable
/// until the lab acts on it — [pending] is the state that needs a decision.
enum DoctorApprovalStatus {
  pending(1, 'قيد الانتظار'),
  approved(2, 'مقبول'),
  rejected(3, 'مرفوض');

  const DoctorApprovalStatus(this.apiValue, this.arabicLabel);

  final int apiValue;
  final String arabicLabel;

  /// Records created by the lab itself come back without the field; those are
  /// already part of the lab's own data, so they read as approved.
  static DoctorApprovalStatus fromApi(int? value) =>
      DoctorApprovalStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => DoctorApprovalStatus.approved,
      );
}

/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "firstName": "أحمد",
  "lastName": "الخطيب",
  "email": "ahmad@example.com",
  "phoneNumber": "0991234567",
  "address": "المزة، دمشق",
  "imagePath": null,
  "gender": 0,
  "dateOfBirth": "1985-04-12",
  "isActive": true,
  "cityId": "...",
  "city": { "id": "...", "name": "دمشق" },
  "clinicId": "...",
  "clinic": { "id": "...", "name": "عيادة النور" }
}
 */

class DoctorModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? address;
  final String? imagePath;
  final DoctorGender? gender;
  final String? dateOfBirth;
  final bool isActive;
  final String? cityId;
  final CityModel? city;
  final String? clinicId;
  final ClinicModel? clinic;

  /// The zone this doctor resolves to for the calling laboratory — their
  /// explicit pin if they have one, otherwise the zone covering their area.
  /// Null for a doctor with no area and no pin, or one whose area no zone
  /// covers yet. This is what decides which representatives may take their
  /// scanner sessions, and who a "قبول منطقة" pick sets during approval.
  final String? zoneId;
  final String? zoneName;
  final String? zoneNameAr;

  /// The price list this doctor is billed at. Null means the laboratory has
  /// not put them on one, which is not the same as being on a free tier —
  /// nothing prices their cases.
  final String? priceTierId;
  final String? priceTierName;

  /// When they moved onto it, so a change is visibly recent rather than
  /// looking like it was always so.
  final String? priceTierSince;

  final List<DoctorAttachmentFileModel> files;

  final DoctorApprovalStatus approvalStatus;

  /// The clinic the doctor named when registering, before the lab has linked
  /// them to a real one. Only meaningful while [isPending].
  final String? requestedClinicName;

  /// Why the lab turned the registration down — shown back on the detail page.
  final String? rejectionReason;

  DoctorModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.address,
    this.imagePath,
    this.gender,
    this.dateOfBirth,
    this.isActive = true,
    this.cityId,
    this.city,
    this.clinicId,
    this.clinic,
    this.zoneId,
    this.zoneName,
    this.zoneNameAr,
    this.priceTierId,
    this.priceTierName,
    this.priceTierSince,
    this.files = const [],
    this.approvalStatus = DoctorApprovalStatus.approved,
    this.requestedClinicName,
    this.rejectionReason,
  });

  /// Whether this doctor is waiting on the lab to approve or reject them.
  bool get isPending => approvalStatus == DoctorApprovalStatus.pending;

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

  /// Up to two leading characters of the name, used as the avatar fallback
  /// when there is no photo. Lives here so the list row and the detail header
  /// can never disagree mid-Hero-flight.
  String get initials {
    final parts = [firstName, lastName]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '؟';
    // `runes.first` rather than `part[0]`: indexing returns a UTF-16 code
    // unit, which would split a surrogate pair. No `characters` import needed
    // here, keeping the data layer free of Flutter dependencies.
    return parts
        .map((part) => String.fromCharCode(part.runes.first))
        .take(2)
        .join();
  }

  String? get cityName => city?.name;

  String? get clinicName => clinic?.name;

  String? get zoneDisplayName {
    final ar = zoneNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return zoneName?.trim();
  }

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      id: json['id'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      address: json['address'] as String?,
      imagePath: json['imagePath'] as String?,
      gender: DoctorGender.fromApi(json['gender'] as int?),
      dateOfBirth: json['dateOfBirth'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      cityId: json['cityId'] as String?,
      city: json['city'] == null
          ? null
          : CityModel.fromJson(json['city'] as Map<String, dynamic>),
      clinicId: json['clinicId'] as String?,
      clinic: json['clinic'] == null
          ? null
          : ClinicModel.fromJson(json['clinic'] as Map<String, dynamic>),
      zoneId: json['zoneId'] as String?,
      zoneName: json['zoneName'] as String?,
      zoneNameAr: json['zoneNameAr'] as String?,
      priceTierId: json['priceTierId'] as String?,
      priceTierName: json['priceTierName'] as String?,
      priceTierSince: json['priceTierSince'] as String?,
      approvalStatus: DoctorApprovalStatus.fromApi(
        json['approvalStatus'] as int?,
      ),
      requestedClinicName: json['requestedClinicName'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      files:
          (json['files'] as List<dynamic>?)
              ?.map(
                (e) => DoctorAttachmentFileModel.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }
}

/// A clinic to create while approving a doctor (`NewClinicForDoctorRequest`),
/// used when the doctor named a clinic the lab does not have yet.
class NewClinicForDoctorRequestModel {
  const NewClinicForDoctorRequestModel({
    required this.name,
    this.address,
    this.phoneNumber,
    this.email,
  });

  final String name;
  final String? address;
  final String? phoneNumber;
  final String? email;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (address != null) 'address': address,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (email != null) 'email': email,
  };
}

/// Body of `POST /Doctors/{id}/approve` (`ApproveDoctorRequest`).
///
/// Every field is optional. [clinicId] and [newClinic] are two ways of
/// answering the same question — link the doctor to a clinic the lab already
/// has, or create the one they asked for — so sending both is meaningless
/// and the constructor keeps them apart. [zoneId] and [newZoneName] are the
/// same pair one level up: assign the doctor's clinic to a zone the lab
/// already has, or create one by name. Left null, the clinic's zone (if it
/// already has one) is left untouched — a zone is not mandatory the way a
/// clinic is.
class ApproveDoctorRequestModel {
  const ApproveDoctorRequestModel({
    this.clinicId,
    this.newClinic,
    this.zoneId,
    this.newZoneName,
    this.number,
    this.note,
  }) : assert(
         clinicId == null || newClinic == null,
         'Approve with an existing clinic or a new one, not both.',
       ),
       assert(
         zoneId == null || newZoneName == null,
         'Assign an existing zone or a new one, not both.',
       );

  final String? clinicId;
  final NewClinicForDoctorRequestModel? newClinic;
  final String? zoneId;
  final String? newZoneName;
  final int? number;
  final String? note;

  Map<String, dynamic> toJson() => {
    if (clinicId != null) 'clinicId': clinicId,
    if (newClinic != null) 'newClinic': newClinic!.toJson(),
    if (zoneId != null) 'zoneId': zoneId,
    if (newZoneName != null) 'newZoneName': newZoneName,
    if (number != null) 'number': number,
    if (note != null) 'note': note,
  };
}

/// Body of `POST /Doctors/{id}/reject` (`RejectDoctorRequest`). The API
/// requires a reason of 1..1000 characters.
class RejectDoctorRequestModel {
  const RejectDoctorRequestModel({required this.reason});

  final String reason;

  Map<String, dynamic> toJson() => {'reason': reason};
}

/// One contact line printed at the foot of the lab's reports and invoices
/// (`ClinicLaboratoryFooterContactDto`).
///
/// A list rather than a single phone field on the laboratory: a lab prints
/// "الاستقبال", "الفني المناوب", "المحاسبة" and expects them in that order, and
/// packing three names and three numbers into one string is how a printed
/// invoice ends up with a phone nobody answers.
class FooterContactModel {
  const FooterContactModel({
    required this.id,
    this.name,
    this.phoneNumber,
    this.displayOrder = 0,
  });

  final String id;
  final String? name;
  final String? phoneNumber;

  /// Printed order. Explicit rather than list position, because the save
  /// endpoint takes the list and the server keeps the order it was given —
  /// the two must not be able to disagree.
  final int displayOrder;

  factory FooterContactModel.fromJson(Map<String, dynamic> json) {
    return FooterContactModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  /// For the laboratory list's offline cache only — never sent to the server,
  /// which takes [SaveFooterContactModel] instead.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'displayOrder': displayOrder,
  };
}

/// One row of `PUT /Laboratories/{id}/footer-contacts`
/// (`ClinicSaveFooterContactRequest`).
///
/// [id] null creates; an existing id edits that row in place. The **whole list
/// replaces** what the lab had — a row left out is deleted, which is what
/// makes reordering and removing possible in one save.
class SaveFooterContactModel {
  const SaveFooterContactModel({
    this.id,
    required this.name,
    required this.phoneNumber,
  });

  final String? id;
  final String name;
  final String phoneNumber;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
  };

  factory SaveFooterContactModel.fromModel(FooterContactModel contact) {
    return SaveFooterContactModel(
      id: contact.id.isEmpty ? null : contact.id,
      name: contact.name ?? '',
      phoneNumber: contact.phoneNumber ?? '',
    );
  }
}

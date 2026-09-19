/// Body of `PUT /PriceTiers/{id}/doctors` (`SetPriceTierDoctorsRequest`).
///
/// **Replaces the whole assignment.** The list sent is exactly who is billed
/// at this tier afterwards, so removing a doctor means sending the list
/// without them — and an empty list unassigns everyone.
///
/// Note what the API does *not* have: an "applies to every doctor" flag. A
/// tier that should cover the whole book is expressed by naming every doctor,
/// which is a snapshot — a doctor registered tomorrow is not in it. The UI
/// says so rather than implying the tier keeps up on its own.
class SetPriceTierDoctorsRequestModel {
  const SetPriceTierDoctorsRequestModel({required this.doctorIds});

  final List<String> doctorIds;

  Map<String, dynamic> toJson() => {'doctorIds': doctorIds};
}

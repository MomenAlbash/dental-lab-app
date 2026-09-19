/// Create/update payload for a supplier (`SaveSupplierRequest`,
/// `POST/PUT /Suppliers`). Only [name] is required.
class SaveSupplierRequestModel {
  const SaveSupplierRequestModel({
    required this.name,
    this.phone,
    this.notes,
    this.isActive = true,
  });

  final String name;
  final String? phone;
  final String? notes;
  final bool isActive;

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'notes': notes,
    'isActive': isActive,
  };
}

/// One supplier (`SupplierDto`, `GET /Suppliers`) — who a purchase is bought
/// from.
class SupplierModel {
  const SupplierModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.phone,
    this.notes,
    this.isActive = true,
    this.canDelete = true,
    this.deleteMessage,
  });

  final String id;
  final String? laboratoryId;
  final String? name;
  final String? phone;
  final String? notes;
  final bool isActive;
  final bool canDelete;
  final String? deleteMessage;

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      canDelete: json['canDelete'] as bool? ?? true,
      deleteMessage: json['deleteMessage'] as String?,
    );
  }
}

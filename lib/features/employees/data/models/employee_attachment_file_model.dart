class EmployeeAttachmentFileModel {
  final String id;
  final String? fileName;
  final String? filePath;

  EmployeeAttachmentFileModel({required this.id, this.fileName, this.filePath});

  factory EmployeeAttachmentFileModel.fromJson(Map<String, dynamic> json) {
    return EmployeeAttachmentFileModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
    );
  }
}

/*
{
  "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "fileName": "report.pdf",
  "filePath": "uploads/doctors/report.pdf"
}
 */

class DoctorAttachmentFileModel {
  final String id;
  final String? fileName;
  final String? filePath;

  DoctorAttachmentFileModel({required this.id, this.fileName, this.filePath});

  factory DoctorAttachmentFileModel.fromJson(Map<String, dynamic> json) {
    return DoctorAttachmentFileModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
    );
  }
}

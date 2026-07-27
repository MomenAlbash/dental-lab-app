class CaseFileModel {
  final String id;
  final String? fileName;
  final String? filePath;

  CaseFileModel({required this.id, this.fileName, this.filePath});

  factory CaseFileModel.fromJson(Map<String, dynamic> json) {
    return CaseFileModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String?,
      filePath: json['filePath'] as String?,
    );
  }
}

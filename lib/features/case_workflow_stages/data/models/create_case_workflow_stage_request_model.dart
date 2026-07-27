class CreateCaseWorkflowStageRequestModel {
  final String name;
  final int? order;
  final bool isFinal;

  CreateCaseWorkflowStageRequestModel({
    required this.name,
    this.order,
    this.isFinal = false,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'order': order, 'isFinal': isFinal};
  }
}

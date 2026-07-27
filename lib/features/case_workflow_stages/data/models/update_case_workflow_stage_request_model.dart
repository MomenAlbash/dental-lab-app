class UpdateCaseWorkflowStageRequestModel {
  final String? name;
  final int? order;
  final bool? isActive;
  final bool? isFinal;

  UpdateCaseWorkflowStageRequestModel({
    this.name,
    this.order,
    this.isActive,
    this.isFinal,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'order': order,
      'isActive': isActive,
      'isFinal': isFinal,
    };
  }
}

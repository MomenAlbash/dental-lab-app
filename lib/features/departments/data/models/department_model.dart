/// One restoration stage this department owns (`ClinicDepartmentStageDto`).
///
/// The stage belongs to a restoration *type's* route, so the type's name is
/// carried alongside it: "التشطيب" on its own is ambiguous across a lab that
/// finishes crowns and dentures both.
class DepartmentStageModel {
  const DepartmentStageModel({
    required this.id,
    this.name,
    this.order = 0,
    this.isFinal = false,
    this.isCheckpoint = false,
    this.restorationTypeId,
    this.restorationTypeName,
    this.restorationTypeNameAr,
    this.activeCount = 0,
  });

  final String id;
  final String? name;
  final int order;
  final bool isFinal;
  final bool isCheckpoint;

  final String? restorationTypeId;
  final String? restorationTypeName;
  final String? restorationTypeNameAr;

  /// Units sitting on this stage right now — the department's actual queue.
  final int activeCount;

  String get displayName => name?.trim() ?? '';

  String get restorationTypeLabel {
    final ar = restorationTypeNameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return restorationTypeName?.trim() ?? '';
  }

  factory DepartmentStageModel.fromJson(Map<String, dynamic> json) {
    return DepartmentStageModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      order: json['order'] as int? ?? 0,
      isFinal: json['isFinal'] as bool? ?? false,
      isCheckpoint: json['isCheckpoint'] as bool? ?? false,
      restorationTypeId: json['restorationTypeId'] as String?,
      restorationTypeName: json['restorationTypeName'] as String?,
      restorationTypeNameAr: json['restorationTypeNameAr'] as String?,
      activeCount: json['activeCount'] as int? ?? 0,
    );
  }
}

/// A person assigned to a department (`ClinicDepartmentEmployeeDto`).
class DepartmentEmployeeModel {
  const DepartmentEmployeeModel({
    required this.id,
    this.employeeId,
    this.employeeName,
    this.imagePath,
    this.isSupervisor = false,
  });

  /// The membership row, **not** the employee. Saving takes [employeeId].
  final String id;

  final String? employeeId;
  final String? employeeName;
  final String? imagePath;
  final bool isSupervisor;

  String get displayName => employeeName?.trim() ?? '';

  factory DepartmentEmployeeModel.fromJson(Map<String, dynamic> json) {
    return DepartmentEmployeeModel(
      id: json['id'] as String? ?? '',
      employeeId: json['employeeId'] as String?,
      employeeName: json['employeeName'] as String?,
      imagePath: json['imagePath'] as String?,
      isSupervisor: json['isSupervisor'] as bool? ?? false,
    );
  }
}

/// A laboratory department (`ClinicDepartmentDto`).
///
/// A department is the bridge between the org chart and the routes: it holds
/// the people, and it holds the restoration stages those people work. Without
/// it a stage set to "assign to a department" has no department to name, which
/// is why the route editor's department pool was empty until now.
class DepartmentModel {
  const DepartmentModel({
    required this.id,
    this.laboratoryId,
    this.name,
    this.nameAr,
    this.description,
    this.isActive = true,
    this.parentId,
    this.parentName,
    this.stages = const [],
    this.employees = const [],
    this.activeWorkloadCount = 0,
  });

  final String id;
  final String? laboratoryId;
  final String? name;
  final String? nameAr;
  final String? description;
  final bool isActive;

  /// Departments nest: "التشطيب" may sit under "الإنتاج".
  final String? parentId;
  final String? parentName;

  /// The restoration stages this department is responsible for.
  final List<DepartmentStageModel> stages;
  final List<DepartmentEmployeeModel> employees;

  /// Units in the department's hands right now, across all its stages.
  final int activeWorkloadCount;

  String get displayName {
    final ar = nameAr?.trim();
    if (ar != null && ar.isNotEmpty) return ar;
    return name?.trim() ?? '';
  }

  /// A department that works no stage will never be handed anything. Not an
  /// error — a lab may create the box before wiring it — but worth saying.
  bool get isUnwired => stages.isEmpty;

  /// Always growable — the result is sorted below, and sorting a `const []`
  /// is a runtime error waiting for the first department with no stages.
  static List<T> _list<T>(
    dynamic value,
    T Function(Map<String, dynamic>) parse,
  ) =>
      (value as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .map(parse)
          .toList() ??
      <T>[];

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    final stages = _list(json['stages'], DepartmentStageModel.fromJson);

    // Grouped by restoration type in the UI, so a stable order within a type
    // keeps the groups from reshuffling between loads.
    stages.sort((a, b) => a.order.compareTo(b.order));

    return DepartmentModel(
      id: json['id'] as String? ?? '',
      laboratoryId: json['laboratoryId'] as String?,
      name: json['name'] as String?,
      nameAr: json['nameAr'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      parentId: json['parentId'] as String?,
      parentName: json['parentName'] as String?,
      stages: stages,
      employees: _list(json['employees'], DepartmentEmployeeModel.fromJson),
      activeWorkloadCount: json['activeWorkloadCount'] as int? ?? 0,
    );
  }
}

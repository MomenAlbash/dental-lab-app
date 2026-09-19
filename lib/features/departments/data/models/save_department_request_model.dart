/// The body of `POST /Departments` and `PUT /Departments/{id}`
/// (`ClinicSaveDepartmentRequest`).
///
/// A full replace, not a patch: [stageIds] and [employeeIds] are the complete
/// membership after the save, so sending them is how a stage is *unlinked*
/// too. Omitting them entirely leaves the current links alone — which is what
/// a rename should do, and what a membership edit must not.
class SaveDepartmentRequestModel {
  const SaveDepartmentRequestModel({
    required this.name,
    this.nameAr,
    this.description,
    this.isActive = true,
    this.parentId,
    this.stageIds,
    this.employeeIds,
  }) : assert(name.length > 0, 'a department needs a name'),
       assert(name.length <= 150, 'name is capped at 150 by the API');

  final String name;
  final String? nameAr;
  final String? description;
  final bool isActive;

  /// The department this one sits under. Null is a top-level department.
  final String? parentId;

  /// The restoration stages this department will own after the save.
  final List<String>? stageIds;

  final List<String>? employeeIds;

  Map<String, dynamic> toJson() => {
    'name': name,
    if (nameAr != null) 'nameAr': nameAr,
    if (description != null) 'description': description,
    'isActive': isActive,
    if (parentId != null) 'parentId': parentId,
    // Sent whenever non-null, **including empty**: an empty list is how the
    // last stage is taken off a department, and dropping it would silently
    // turn "unlink everything" into "change nothing".
    if (stageIds != null) 'stageIds': stageIds,
    if (employeeIds != null) 'employeeIds': employeeIds,
  };
}

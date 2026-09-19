/// One specific row standing in the way of a delete
/// (`DeletionBlockerItem`) — named so it can be offered for removal.
class DeletionBlockerItemModel {
  const DeletionBlockerItemModel({required this.id, this.label});

  final String id;
  final String? label;

  String get displayLabel => label?.trim().isNotEmpty ?? false ? label! : id;

  factory DeletionBlockerItemModel.fromJson(Map<String, dynamic> json) {
    return DeletionBlockerItemModel(
      id: json['id'] as String? ?? '',
      label: json['label'] as String?,
    );
  }
}

/// One category of blocker a user can clear themselves
/// (`DeletionBlockerStep`) — "this doctor still has a login user".
///
/// [entityType] is the key the client re-enters this same flow with, so
/// resolving one blocker can itself surface a further nested one.
class DeletionBlockerStepModel {
  const DeletionBlockerStepModel({
    this.entityType,
    this.message,
    this.items = const [],
  });

  final String? entityType;
  final String? message;
  final List<DeletionBlockerItemModel> items;

  bool get isResolvable => entityType != null && items.isNotEmpty;

  factory DeletionBlockerStepModel.fromJson(Map<String, dynamic> json) {
    return DeletionBlockerStepModel(
      entityType: json['entityType'] as String?,
      message: json['message'] as String?,
      items: [
        for (final item in json['items'] as List<dynamic>? ?? const [])
          DeletionBlockerItemModel.fromJson(item as Map<String, dynamic>),
      ],
    );
  }
}

/// What it would take to delete one row (`DeletionPlan`).
///
/// Richer than a yes/no with one sentence, and the distinction matters:
///
/// - [hardStops] are blockers nobody should be offered a delete button for.
///   A restoration type used by real cases, a doctor with patients — those
///   name transactional history, and a generic wizard dangling "delete these
///   first" in front of them is how somebody erases a year of records. They
///   are plain sentences with no action, exactly what a disabled button's
///   tooltip already said.
/// - [resolvableSteps] are blockers a service explicitly judged safe to clear
///   (a doctor's login user, say), listed row by row so they can be removed
///   one at a time — each through this same mechanism.
class DeletionPlanModel {
  const DeletionPlanModel({
    this.canDelete = false,
    this.resolvableSteps = const [],
    this.hardStops = const [],
  });

  final bool canDelete;
  final List<DeletionBlockerStepModel> resolvableSteps;
  final List<String> hardStops;

  /// Nothing the user can do from here — the delete is simply not available.
  bool get isBlockedOutright => !canDelete && resolvableSteps.isEmpty;

  /// How many rows would have to go first, across every resolvable step.
  int get resolvableCount =>
      resolvableSteps.fold(0, (sum, step) => sum + step.items.length);

  factory DeletionPlanModel.fromJson(Map<String, dynamic> json) {
    return DeletionPlanModel(
      canDelete: json['canDelete'] as bool? ?? false,
      resolvableSteps: [
        for (final step in json['resolvableSteps'] as List<dynamic>? ?? const [])
          DeletionBlockerStepModel.fromJson(step as Map<String, dynamic>),
      ],
      hardStops: [
        for (final stop in json['hardStops'] as List<dynamic>? ?? const [])
          if (stop is String) stop,
      ],
    );
  }
}

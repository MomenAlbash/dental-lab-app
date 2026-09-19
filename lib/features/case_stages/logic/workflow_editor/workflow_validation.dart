/// How serious a defect is.
enum WorkflowIssueSeverity {
  /// The drawing is broken — cases will silently stop moving.
  error,

  /// Suspicious but survivable.
  warning,
}

/// One defect found in the workflow, reported by `GET /case-statuses/validate`.
///
/// Not a local re-derivation of the flow: the app used to walk the edge set
/// itself (start stages, reachability, cycles), but the API carries no edge
/// table at all — every stage came back flagged "unreachable" and the editor
/// showed nothing but errors nobody could act on. The server validates the
/// route it actually runs and has the last word.
class WorkflowIssue {
  const WorkflowIssue({
    required this.severity,
    required this.message,
    this.stageId,
  });

  final WorkflowIssueSeverity severity;
  final String message;

  /// The stage the issue belongs to, so the editor can mark that row rather
  /// than only listing the problem at the bottom.
  final String? stageId;

  bool get isError => severity == WorkflowIssueSeverity.error;
}

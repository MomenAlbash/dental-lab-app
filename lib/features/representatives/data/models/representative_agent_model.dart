import 'package:dental_lab_app/core/helper/api_time_helper.dart';

/// One spell of a representative reporting to an agent
/// (`RepresentativeAgentDto`).
///
/// The third dated history in this product, and for the same reason as the
/// other two: assigning an agent closes the current spell and opens a new one,
/// so "who did Samir report to last March" stays answerable — which is what
/// any commission or territory question asked about a past month depends on.
class RepresentativeAgentModel {
  const RepresentativeAgentModel({
    required this.id,
    required this.representativeUserId,
    this.representativeName,
    required this.agentUserId,
    this.agentName,
    this.startDate,
    this.endDate,
    this.isActive = false,
    this.note,
  });

  final String id;
  final String representativeUserId;
  final String? representativeName;
  final String agentUserId;
  final String? agentName;

  final DateTime? startDate;

  /// Null on the open spell — the arrangement still in effect.
  final DateTime? endDate;

  /// Server-computed. Not derived from [endDate]: a spell can be dated to
  /// start in the future, which is open-ended but not yet active.
  final bool isActive;

  final String? note;

  String get agentLabel =>
      agentName?.trim().isNotEmpty ?? false ? agentName! : '—';

  String get representativeLabel =>
      representativeName?.trim().isNotEmpty ?? false
      ? representativeName!
      : '—';

  String get periodLabel {
    final start = startDate == null ? '—' : ApiTime.formatDate(startDate!);
    final end = endDate == null ? 'حتى الآن' : ApiTime.formatDate(endDate!);
    return '$start — $end';
  }

  factory RepresentativeAgentModel.fromJson(Map<String, dynamic> json) {
    return RepresentativeAgentModel(
      id: json['id'] as String? ?? '',
      representativeUserId: json['representativeUserId'] as String? ?? '',
      representativeName: json['representativeName'] as String?,
      agentUserId: json['agentUserId'] as String? ?? '',
      agentName: json['agentName'] as String?,
      startDate: DateTime.tryParse(json['startDate'] as String? ?? ''),
      endDate: DateTime.tryParse(json['endDate'] as String? ?? ''),
      isActive: json['isActive'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}

/// `AssignRepresentativeAgentRequest` — opens a new agent spell.
class AssignRepresentativeAgentRequestModel {
  const AssignRepresentativeAgentRequestModel({
    required this.representativeUserId,
    required this.agentUserId,
    this.note,
    this.startDate,
  });

  final String representativeUserId;
  final String agentUserId;
  final String? note;

  /// Null dates it now; back-dating records an arrangement that has already
  /// been in effect.
  final DateTime? startDate;

  Map<String, dynamic> toJson() => {
    'representativeUserId': representativeUserId,
    'agentUserId': agentUserId,
    'note': ?note,
    'startDate': ?startDate?.toIso8601String(),
  };
}

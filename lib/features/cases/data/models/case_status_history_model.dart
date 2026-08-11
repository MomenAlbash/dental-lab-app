import 'package:dental_lab_app/features/cases/data/models/case_status.dart';

/*
{
  "caseStatus": 2,
  "previousCaseStatus": 1,
  "orderNum": 1,
  "changedByName": "أحمد",
  "note": null,
  "changedAt": "2026-08-01T10:12:33.000Z"
}
 */

/// One entry in the case's status timeline (`ClinicCaseStatusHistoryDto`).
class CaseStatusHistoryModel {
  final CaseStatus caseStatus;
  final CaseStatus previousCaseStatus;
  final int orderNum;
  final String? changedByName;
  final String? note;
  final DateTime? changedAt;

  CaseStatusHistoryModel({
    required this.caseStatus,
    required this.previousCaseStatus,
    this.orderNum = 0,
    this.changedByName,
    this.note,
    this.changedAt,
  });

  factory CaseStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return CaseStatusHistoryModel(
      caseStatus: CaseStatus.fromApi(json['caseStatus'] as int?),
      previousCaseStatus: CaseStatus.fromApi(
        json['previousCaseStatus'] as int?,
      ),
      orderNum: json['orderNum'] as int? ?? 0,
      changedByName: json['changedByName'] as String?,
      note: json['note'] as String?,
      changedAt: json['changedAt'] != null
          ? DateTime.tryParse(json['changedAt'] as String)
          : null,
    );
  }
}

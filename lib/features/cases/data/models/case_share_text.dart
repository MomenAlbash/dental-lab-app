import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';

/// A case as a short message — sent to a colleague or a doctor over whatever
/// app they use.
///
/// Only what identifies the case and where it stands: no prices, no notes.
/// A message can be forwarded anywhere, and what it carries leaves the app
/// with it.
abstract final class CaseShareText {
  static String of(CaseDetailModel caseDetail) {
    final restorations = [
      for (final r in caseDetail.restorations)
        r.quantity > 1
            ? '${r.restorationName} × ${r.quantity}'
            : r.restorationName,
    ];

    final lines = <String>[
      'حالة ${_or(caseDetail.caseNumber, 'بدون رقم')}',
      if (_has(caseDetail.patientName))
        'المريض: ${caseDetail.patientName!.trim()}',
      if (_has(caseDetail.doctor?.fullName))
        'الطبيب: ${caseDetail.doctor!.fullName.trim()}',
      if (_has(caseDetail.clinic?.name))
        'العيادة: ${caseDetail.clinic!.name.trim()}',
      if (restorations.isNotEmpty) 'التعويضات: ${restorations.join('، ')}',
      if (caseDetail.phase != null) 'الحالة الآن: ${caseDetail.phase!.label}',
      if (_has(caseDetail.stageLabel)) 'المرحلة: ${caseDetail.stageLabel}',
      if (_has(caseDetail.dueDate))
        'موعد التسليم: ${_dateOnly(caseDetail.dueDate!)}',
    ];
    return lines.join('\n');
  }

  static bool _has(String? value) => value != null && value.trim().isNotEmpty;

  static String _or(String? value, String fallback) =>
      _has(value) ? value!.trim() : fallback;

  /// `2026-10-02T00:00:00Z` → `2026-10-02`: the time of a due date is noise.
  static String _dateOnly(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}

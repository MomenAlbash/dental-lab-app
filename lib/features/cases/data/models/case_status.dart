/// The case's overall status (`CaseStatus`, 1..10). This is a fixed
/// lifecycle owned by the case itself — distinct from the per-restoration
/// workflow stages, which are defined by each restoration type.
enum CaseStatus {
  created(1, 'تم الإنشاء'),
  received(2, 'تم الاستلام'),
  underReview(3, 'قيد المراجعة'),
  approved(4, 'تمت الموافقة'),
  rejected(5, 'مرفوضة'),
  inProgress(6, 'قيد التنفيذ'),
  ready(7, 'جاهزة'),
  inTrying(8, 'قيد التجربة'),
  delivered(9, 'تم التسليم'),
  finished(10, 'منتهية');

  const CaseStatus(this.apiValue, this.arabicLabel);

  final int apiValue;
  final String arabicLabel;

  static CaseStatus fromApi(int? value) {
    return CaseStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => CaseStatus.created,
    );
  }
}

/// `CaseTicketTemplateRowDto.kind` — a fixed vocabulary of 15 string values
/// (`CaseTicketTemplateRowKinds` server-side). Rows print in the order the
/// editor puts them in the array; each kind resolves against
/// `CasePrintTicketModel` at print time.
enum CaseTicketTemplateRowKind {
  masthead('masthead', 'اسم المخبر'),
  qr('qr', 'رمز QR'),
  caseNumber('caseNumber', 'رقم الحالة'),
  referenceNumber('referenceNumber', 'الرقم المرجعي'),
  divider('divider', 'خط فاصل'),
  patient('patient', 'المريض'),
  doctor('doctor', 'الطبيب'),
  location('location', 'الموقع'),
  priority('priority', 'الأولوية'),
  impressionMethod('impressionMethod', 'طريقة الأخذ'),
  createdAt('createdAt', 'تاريخ الإنشاء'),
  receivedAt('receivedAt', 'تاريخ الاستلام'),
  expectedCompletion('expectedCompletion', 'موعد التسليم المتوقع'),
  restorationsTable('restorationsTable', 'جدول التعويضات'),
  notes('notes', 'ملاحظات'),
  customLabel('customLabel', 'نص حر');

  const CaseTicketTemplateRowKind(this.apiValue, this.arabicLabel);

  final String apiValue;
  final String arabicLabel;

  /// Rows whose `label` field overrides a default caption — the label/value
  /// lines, plus a `customLabel` row's own text field is separate (`text`,
  /// not `label`). [masthead]/[divider]/[restorationsTable]/[qr] have no
  /// caption to override.
  bool get hasEditableLabel => switch (this) {
    caseNumber ||
    referenceNumber ||
    patient ||
    doctor ||
    location ||
    priority ||
    impressionMethod ||
    createdAt ||
    receivedAt ||
    expectedCompletion ||
    notes => true,
    _ => false,
  };

  static CaseTicketTemplateRowKind? fromApi(String? value) {
    for (final kind in CaseTicketTemplateRowKind.values) {
      if (kind.apiValue == value) return kind;
    }
    return null;
  }
}

/// `CaseTicketTemplateRowDto.align` — text alignment in reading direction,
/// the same vocabulary the order-form template's `ReportTemplateElementDto.Align`
/// uses. Null on a row means the renderer's own default for that row kind.
enum CaseTicketRowAlign {
  start('start'),
  center('center'),
  end('end');

  const CaseTicketRowAlign(this.apiValue);

  final String apiValue;

  static CaseTicketRowAlign? fromApi(String? value) {
    for (final align in CaseTicketRowAlign.values) {
      if (align.apiValue == value) return align;
    }
    return null;
  }
}

/// Case priority as encoded by the API (`1..4`). Names are undocumented, so
/// the mapping is kept here as the single source of truth.
enum CasePriority {
  low(1, 'منخفضة'),
  normal(2, 'عادية'),
  high(3, 'عالية'),
  urgent(4, 'عاجلة');

  const CasePriority(this.apiValue, this.arabicLabel);

  final int apiValue;
  final String arabicLabel;

  static CasePriority fromApi(int? value) => switch (value) {
    1 => CasePriority.low,
    3 => CasePriority.high,
    4 => CasePriority.urgent,
    _ => CasePriority.normal,
  };
}

/// Client-side shade reference data. The API only stores the chosen shade as
/// free text (`shadeCervical`/`shadeMiddle`/`shadeIncisal`), so the guide
/// picked here ("نوع التقسيمات") only curates which codes are offered — it is
/// never sent to the server.
enum ShadeGuide {
  vitaClassical('Vita Classical'),
  vita3dMaster('Vita 3D-Master');

  const ShadeGuide(this.label);

  final String label;

  List<String> get shades => switch (this) {
    ShadeGuide.vitaClassical => const [
      'A1',
      'A2',
      'A3',
      'A3.5',
      'A4',
      'B1',
      'B2',
      'B3',
      'B4',
      'C1',
      'C2',
      'C3',
      'C4',
      'D2',
      'D3',
      'D4',
    ],
    ShadeGuide.vita3dMaster => const [
      '1M1',
      '1M2',
      '2L1.5',
      '2L2.5',
      '2M1',
      '2M2',
      '2M3',
      '2R1.5',
      '2R2.5',
      '3L1.5',
      '3L2.5',
      '3M1',
      '3M2',
      '3M3',
      '3R1.5',
      '3R2.5',
      '4L1.5',
      '4L2.5',
      '4M1',
      '4M2',
      '4M3',
      '4R1.5',
      '4R2.5',
      '5M1',
      '5M2',
      '5M3',
    ],
  };
}

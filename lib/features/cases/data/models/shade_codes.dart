/// Conversions between the shade labels shown in the UI (Vita Classical /
/// Vita 3D-Master codes, e.g. `'A2'`, `'2M1'`) and the integer enum codes the
/// API actually stores (`ToothShade`, `BaseShade`, `ShadeSystem`).
///
/// The UI and the request/response models only ever deal in labels — these
/// tables exist so the conversion happens once, at the JSON boundary
/// ([CaseRestorationModel.fromJson] / [CaseRestorationRequestModel.toJson]),
/// instead of every screen having to know the wire format.
class ShadeCodes {
  ShadeCodes._();

  /// `ShadeSystem`: 1 = VitaClassical, 2 = Vita3DMaster.
  static const int vitaClassicalSystem = 1;
  static const int vita3dMasterSystem = 2;

  static const String vitaClassicalLabel = 'Vita Classical';
  static const String vita3dMasterLabel = 'Vita 3D-Master';

  static int shadeSystemFor(String? guideLabel) =>
      guideLabel == vita3dMasterLabel
      ? vita3dMasterSystem
      : vitaClassicalSystem;

  static String shadeSystemLabel(int? shadeSystem) =>
      shadeSystem == vita3dMasterSystem
      ? vita3dMasterLabel
      : vitaClassicalLabel;

  /// `ToothShade`, Vita Classical range (0-15).
  static const Map<String, int> _vitaClassicalToothShade = {
    'A1': 0,
    'A2': 1,
    'A3': 2,
    'A3.5': 3,
    'A4': 4,
    'B1': 5,
    'B2': 6,
    'B3': 7,
    'B4': 8,
    'C1': 9,
    'C2': 10,
    'C3': 11,
    'C4': 12,
    'D2': 13,
    'D3': 14,
    'D4': 15,
  };

  /// `ToothShade`, Vita 3D-Master range (100-152, `M3D_*`).
  static const Map<String, int> _vita3dMasterToothShade = {
    '0M1': 100,
    '0M2': 101,
    '0M3': 102,
    '1M1': 110,
    '1M2': 111,
    '2L1.5': 120,
    '2L2.5': 121,
    '2M1': 122,
    '2M2': 123,
    '2M3': 124,
    '2R1.5': 125,
    '2R2.5': 126,
    '3L1.5': 130,
    '3L2.5': 131,
    '3M1': 132,
    '3M2': 133,
    '3M3': 134,
    '3R1.5': 135,
    '3R2.5': 136,
    '4L1.5': 140,
    '4L2.5': 141,
    '4M1': 142,
    '4M2': 143,
    '4M3': 144,
    '4R1.5': 145,
    '4R2.5': 146,
    '5M1': 150,
    '5M2': 151,
    '5M3': 152,
  };

  static final Map<int, String> _vitaClassicalToothShadeReverse = {
    for (final entry in _vitaClassicalToothShade.entries)
      entry.value: entry.key,
  };

  static final Map<int, String> _vita3dMasterToothShadeReverse = {
    for (final entry in _vita3dMasterToothShade.entries) entry.value: entry.key,
  };

  /// `BaseShade` (0-17) — always Vita Classical plus two lab-only shades,
  /// regardless of which guide is selected for the layered shades: the API
  /// has no Vita 3D-Master variant of this field.
  static const Map<String, int> baseShade = {
    'A1': 0,
    'A2': 1,
    'A3': 2,
    'A3.5': 3,
    'A4': 4,
    'B1': 5,
    'B2': 6,
    'B3': 7,
    'B4': 8,
    'C1': 9,
    'C2': 10,
    'C3': 11,
    'C4': 12,
    'D2': 13,
    'D3': 14,
    'D4': 15,
    'Opaque': 16,
    'Clear': 17,
  };

  static final Map<int, String> _baseShadeReverse = {
    for (final entry in baseShade.entries) entry.value: entry.key,
  };

  /// Labels offered for the base tooth color picker, in enum order.
  static const List<String> baseShadeLabels = [
    'A1', 'A2', 'A3', 'A3.5', 'A4', //
    'B1', 'B2', 'B3', 'B4', //
    'C1', 'C2', 'C3', 'C4', //
    'D2', 'D3', 'D4', //
    'Opaque', 'Clear',
  ];

  static int? toothShadeCode(int shadeSystem, String? label) {
    if (label == null) return null;
    final table = shadeSystem == vita3dMasterSystem
        ? _vita3dMasterToothShade
        : _vitaClassicalToothShade;
    return table[label];
  }

  /// Tries the shade system the record says it uses first, then falls back
  /// to the other table: a Vita Classical code and a Vita 3D-Master code
  /// never collide in range, so this recovers a label even if `shadeSystem`
  /// was left off an older record.
  static String? toothShadeLabel(int? shadeSystem, int? code) {
    if (code == null) return null;
    final primary = shadeSystem == vita3dMasterSystem
        ? _vita3dMasterToothShadeReverse
        : _vitaClassicalToothShadeReverse;
    return primary[code] ??
        _vitaClassicalToothShadeReverse[code] ??
        _vita3dMasterToothShadeReverse[code];
  }

  static int? baseShadeCode(String? label) =>
      label == null ? null : baseShade[label];

  static String? baseShadeLabel(int? code) =>
      code == null ? null : _baseShadeReverse[code];
}

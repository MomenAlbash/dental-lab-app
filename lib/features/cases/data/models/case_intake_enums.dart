/// How the case arrived — the fork that decides everything before production
/// (MOBILE-SPEC §15.6).
///
/// A traditional case starts with a physical impression the doctor sends or
/// the lab collects. A digital one starts with a scan, which Control reviews
/// before the case becomes real work.
enum ImpressionMethod {
  traditional(1, 'طبعة تقليدية'),
  digital(2, 'مسح رقمي');

  const ImpressionMethod(this.value, this.label);

  final int value;
  final String label;

  static ImpressionMethod? fromValue(int? value) {
    for (final method in ImpressionMethod.values) {
      if (method.value == value) return method;
    }
    return null;
  }
}

/// Where a digital scan came from (`DigitalScanSource`). Only meaningful when
/// the intake is [ImpressionMethod.digital].
enum DigitalScanSource {
  doctor(1, 'رفعه الطبيب'),
  labScannerSession(2, 'جلسة سكنر من المخبر');

  const DigitalScanSource(this.value, this.label);

  final int value;
  final String label;

  static DigitalScanSource? fromValue(int? value) {
    for (final source in DigitalScanSource.values) {
      if (source.value == value) return source;
    }
    return null;
  }
}

/// Which intake a route stage is cut for (`RouteStageAppliesTo`).
///
/// **The numbers are 1/2/3, not 0/1/2.** MOBILE-SPEC §16 lists this enum as
/// `Any 0 · Traditional 1 · Digital 2`, which disagrees with the live API. The
/// swagger is the authority for wire values, and following the document would
/// have shifted every stage by one — a digital-only stage would be cut onto
/// traditional cases and vice versa.
enum RouteStageAppliesTo {
  /// Retired by the API: the enum it declares now holds 2 and 3 only, and a
  /// stage meant for both intakes is two rows. Kept so an older record that
  /// still carries it parses and stays visible — never offered as a choice.
  any(1, 'كل الحالات'),
  traditionalOnly(2, 'الطبعة التقليدية فقط'),
  digitalOnly(3, 'المسح الرقمي فقط');

  const RouteStageAppliesTo(this.value, this.label);

  final int value;
  final String label;

  /// The choices a stage form may offer. [any] is deliberately absent: the API
  /// declares this enum as {2, 3} only, so a stage saved as "both" would be
  /// refused. A stage that belongs to both intakes is two rows.
  static List<RouteStageAppliesTo> get selectable => const [
    RouteStageAppliesTo.traditionalOnly,
    RouteStageAppliesTo.digitalOnly,
  ];

  /// Whether a stage carrying this flag is cut onto a case taken in via
  /// [method]. A null method means the intake is not decided yet, in which
  /// case only the unconditional stages are certain.
  bool appliesTo(ImpressionMethod? method) => switch (this) {
    RouteStageAppliesTo.any => true,
    RouteStageAppliesTo.traditionalOnly =>
      method == ImpressionMethod.traditional,
    RouteStageAppliesTo.digitalOnly => method == ImpressionMethod.digital,
  };

  static RouteStageAppliesTo fromValue(int? value) {
    for (final applies in RouteStageAppliesTo.values) {
      if (applies.value == value) return applies;
    }
    // An unrecognised flag must not silently prune a stage out of the route;
    // showing an extra stage is recoverable, hiding a required one is not.
    return RouteStageAppliesTo.any;
  }
}

/// Whether a case option is answered once for the whole case or per
/// restoration (`CaseOptionScope`).
enum CaseOptionScope {
  perCase(1),
  perRestoration(2);

  const CaseOptionScope(this.value);

  final int value;

  static CaseOptionScope? fromValue(int? value) {
    for (final scope in CaseOptionScope.values) {
      if (scope.value == value) return scope;
    }
    return null;
  }
}

/// The fixed six-value lifecycle every case runs (`CasePhase`).
///
/// Not lab-drawn and not moved by picking a stage: each step is its own
/// action. A case in [newCase] has no stage moves on offer at all — recording
/// its material is what opens its workflow, which is why the pre-production
/// stages look stuck until then.
enum CasePhase {
  newCase(1, 'جديدة'),
  received(2, 'مستلمة'),
  inProduction(3, 'قيد الإنتاج'),
  qualityCheck(4, 'فحص الجودة'),
  ready(5, 'جاهزة'),
  delivered(6, 'مسلّمة');

  const CasePhase(this.value, this.label);

  final int value;
  final String label;

  static CasePhase? fromValue(int? value) {
    for (final phase in CasePhase.values) {
      if (phase.value == value) return phase;
    }
    return null;
  }
}

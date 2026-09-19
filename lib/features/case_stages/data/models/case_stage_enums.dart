/// Enums shared by the case-stage catalogue and the live plan DTOs.
///
/// The numbering here follows the **live swagger**, which disagrees with the
/// mobile handoff spec in three places (the spec has an older, zero-based
/// numbering). The server is what we parse, so the server wins. Every
/// `fromApi` falls back to a documented value rather than to whichever member
/// happens to be first — an unknown int is a server we do not understand yet,
/// not a reason to crash or to silently claim something specific.
library;

/// Which side of production a case stage sits on.
enum CaseStagePlacement {
  beforeProduction(1),
  afterProduction(2);

  const CaseStagePlacement(this.apiValue);

  final int apiValue;

  String get arabicLabel => switch (this) {
    CaseStagePlacement.beforeProduction => 'قبل الإنتاج',
    CaseStagePlacement.afterProduction => 'بعد الإنتاج',
  };

  /// Defaults to [beforeProduction]: intake stages are the ones a lab draws
  /// first, so an unknown value is least surprising there.
  static CaseStagePlacement fromApi(int? value) => switch (value) {
    2 => CaseStagePlacement.afterProduction,
    _ => CaseStagePlacement.beforeProduction,
  };
}

/// How a stage decides it is ready when several edges feed into it.
enum RouteJoinMode {
  /// Ready as soon as **one** incoming edge is satisfied.
  waitAny(1),

  /// Waits for **every instantiated** predecessor. A branch that was pruned
  /// (because the case did not select that option) is not waited for.
  waitAll(2);

  const RouteJoinMode(this.apiValue);

  final int apiValue;

  /// Defaults to [waitAny] — the permissive mode. Guessing [waitAll] would
  /// make the UI claim a stage is blocked by predecessors it may not have.
  static RouteJoinMode fromApi(int? value) => switch (value) {
    2 => RouteJoinMode.waitAll,
    _ => RouteJoinMode.waitAny,
  };
}

/// What an edge means: the normal flow, or where a failure may send work back.
enum RouteTransitionKind {
  normal(1),
  rework(2);

  const RouteTransitionKind(this.apiValue);

  final int apiValue;

  bool get isRework => this == RouteTransitionKind.rework;

  /// Defaults to [normal]. Mistaking a normal edge for rework would drop it
  /// out of the forward ranking and flatten the whole board.
  static RouteTransitionKind fromApi(int? value) => switch (value) {
    2 => RouteTransitionKind.rework,
    _ => RouteTransitionKind.normal,
  };
}

/// Where a case stage sits relative to the restorations' own routes
/// (`CaseStageTiming`).
///
/// This is the real "قبل الإنتاج / بعد الإنتاج" split, and the only one the
/// server stores. [afterRestorations] is a **barrier**: the step it sits on
/// does not open until every restoration on the case has finished its route,
/// which is what makes final review, packing and invoicing wait for the work
/// to exist. A case with no restorations is never held by it.
enum CaseStageTiming {
  beforeRestorations(1),
  afterRestorations(2);

  const CaseStageTiming(this.apiValue);

  final int apiValue;

  // `beforeRestorations` is NOT a sequential "runs before production starts"
  // step — that reading was the exact mistake the web admin app's UI made
  // and had to correct (MOBILE-SPEC-STAGES-2026-08-28 §4). The stage opens
  // on its own `order` alone; the case's own track and every restoration's
  // route run side by side once `InProduction` opens, and neither waits for
  // the other unless a stage is `afterRestorations`, which is a real
  // barrier.
  String get arabicLabel => switch (this) {
    CaseStageTiming.beforeRestorations => 'بالتوازي مع الإنتاج',
    CaseStageTiming.afterRestorations => 'بعد الإنتاج',
  };

  String get description => switch (this) {
    CaseStageTiming.beforeRestorations =>
      'تعمل بالتوازي مع الإنتاج، ولا تنتظر التعويضات ولا هي تنتظرها',
    CaseStageTiming.afterRestorations => 'لا تُفتح حتى تنتهي كل تعويضات الحالة',
  };

  /// Defaults to [beforeRestorations] — the server's own default, and the
  /// harmless answer: a stage that waits for nothing is never stuck.
  static CaseStageTiming fromApi(int? value) => switch (value) {
    2 => CaseStageTiming.afterRestorations,
    _ => CaseStageTiming.beforeRestorations,
  };
}

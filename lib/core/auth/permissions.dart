/// The API's `PermissionName` enum. The backend serialises these as integers
/// and does not publish names, so the numeric values are the contract — see
/// MOBILE-SPEC §16 ("keep these numeric values exactly").
///
/// The 100s and 200s are the doctor and representative apps' own modules —
/// they ride the same enum server-side (`GET /Roles/permissions` filters by
/// `userType`) but never reach a clinic user's role, and nothing in this app
/// gates on them. They are still carried rather than dropped: a value this app
/// does not act on is one a role may hold, and dropping it would round-trip
/// that grant through the cache silently missing.
///
/// Every clinic module (1-15) now gates a screen here — see [label].
enum PermissionName {
  cases(1),
  caseWorkflow(2),
  finance(3),
  inventory(4),
  suppliers(5),
  statistics(6),
  users(7),
  roles(8),
  branches(9),
  appointments(10),
  scannerControl(11),
  attendance(12),
  payroll(13),
  leaves(14),

  /// **15, not 16.** The backend inserted `Doctor` here and pushed
  /// `RestorationType` out to 16 — this client had 15 mapped to
  /// `RestorationType`, which silently read every "may manage doctors" grant
  /// as "may manage the restoration catalogue" and vice versa.
  doctor(15),
  restorationType(16),
  doctorCases(100),
  doctorAppointments(101),
  doctorScannerSessions(102),
  doctorClinics(103),
  doctorPatients(104),
  doctorBilling(105),
  doctorStatistics(106),
  representativeSessions(200),
  representativeZones(201),
  representativeDoctors(202),
  representativeCollections(203),
  representativeStatistics(204),
  representativeCases(205),

  /// The agent app's own module — carried for the same reason as the 100s and
  /// 200s: a value this app never gates on is still one a role may hold.
  agentRepresentatives(300);

  const PermissionName(this.value);

  final int value;

  static PermissionName? fromValue(int? value) {
    for (final name in PermissionName.values) {
      if (name.value == value) return name;
    }
    return null;
  }

  /// Arabic label for the role-form permission list. Only the modules this
  /// app actually screens for have one — the rest are never shown to a user
  /// here (see the enum doc), so a missing label is a sign that value leaked
  /// somewhere it shouldn't have, not something to paper over with a guess.
  String? get label => switch (this) {
    cases => 'الحالات',
    caseWorkflow => 'سير عمل الحالات',
    finance => 'المحاسبة',
    statistics => 'الإحصائيات',
    users => 'المستخدمون',
    roles => 'الأدوار',
    branches => 'الفروع',
    appointments => 'المواعيد',
    scannerControl => 'جلسات السكانر',
    doctor => 'الأطباء',
    restorationType => 'التعويضات السنية',
    inventory => 'المخزون',
    suppliers => 'الموردون',
    attendance => 'الحضور',
    payroll => 'الرواتب',
    leaves => 'الإجازات',
    _ => null,
  };
}

/// The API's `PermissionType` enum: `Read = 0`, `FullAccess = 1`.
///
/// Ordered so that [fullAccess] satisfies a [read] requirement — a user who may
/// edit may obviously also look.
enum PermissionType {
  read(0),
  fullAccess(1);

  const PermissionType(this.value);

  final int value;

  bool satisfies(PermissionType required) => value >= required.value;

  static PermissionType? fromValue(int? value) {
    for (final type in PermissionType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

/// The API's `UserType` enum, as it scopes `GET /Roles/permissions` and
/// `RoleDto.userType` — which permission catalogue a role draws from. Named
/// `RoleUserType` rather than `UserType` because that name is already taken
/// by the (distinct, employee/doctor-only) account-type enum in the users
/// feature. A role created here is always [employee]: the doctor and
/// representative apps manage their own roles against the same endpoint
/// shape.
enum RoleUserType {
  employee(0),
  doctor(1),
  representative(2);

  const RoleUserType(this.value);

  final int value;
}

/// What the signed-in user is allowed to do.
///
/// Built once from `GET /ClinicAuth/me` (or the login response, which carries
/// the same `ClinicUserDto`) and consulted wherever a screen or a nav entry is
/// gated.
///
/// The rule from the spec is *hidden*, not disabled: a nav row the user cannot
/// use is removed. A greyed row advertises a capability they do not have and
/// invites a support call.
class Permissions {
  const Permissions({required this.isAdmin, required this.granted});

  /// Nobody signed in yet — denies everything except the screens that are open
  /// to any authenticated user.
  static const empty = Permissions(isAdmin: false, granted: {});

  /// Admins bypass permission checks client-side, per the spec. The server
  /// still enforces its own rules; this only decides what is worth showing.
  final bool isAdmin;

  final Map<PermissionName, PermissionType> granted;

  /// Whether the user holds [name] at [type] or better.
  bool has(PermissionName name, [PermissionType type = PermissionType.read]) {
    if (isAdmin) return true;
    final held = granted[name];
    return held != null && held.satisfies(type);
  }

  bool canRead(PermissionName name) => has(name);

  bool canEdit(PermissionName name) => has(name, PermissionType.fullAccess);

  /// Whether this user may look at more than one laboratory at a time.
  ///
  /// The list endpoints take a `laboratoryIds` array, but the server honours
  /// it only for an admin or a holder of `Branches`; everyone else stays
  /// pinned to the `X-Laboratory-Id` header whatever they send. Offering the
  /// control to someone it does nothing for is worse than hiding it — they
  /// pick three labs and get one back, with no explanation.
  bool get canBrowseAllLaboratories =>
      isAdmin || canRead(PermissionName.branches);

  /// Reads the `{ name, type }` pairs off a `ClinicUserDto`.
  ///
  /// Unknown integers are dropped rather than guessed: a permission the app
  /// does not know about cannot gate anything it draws, and inventing an enum
  /// member for it would let a future backend value silently unlock a screen.
  factory Permissions.fromUserJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>?;
    final rawPermissions = role?['permissions'] as List<dynamic>? ?? const [];

    final granted = <PermissionName, PermissionType>{};
    for (final entry in rawPermissions) {
      if (entry is! Map<String, dynamic>) continue;
      final name = PermissionName.fromValue(entry['name'] as int?);
      final type = PermissionType.fromValue(entry['type'] as int?);
      if (name == null || type == null) continue;

      // A user can hold the same module through more than one source; the
      // strongest grant wins rather than whichever arrived last.
      final existing = granted[name];
      if (existing == null || type.satisfies(existing)) {
        granted[name] = type;
      }
    }

    return Permissions(
      isAdmin: json['isAdmin'] as bool? ?? false,
      granted: granted,
    );
  }

  /// Round-trips through the cache so a cold start knows what to draw before
  /// `/ClinicAuth/me` answers.
  Map<String, dynamic> toJson() => {
    'isAdmin': isAdmin,
    'granted': {
      for (final entry in granted.entries)
        '${entry.key.value}': entry.value.value,
    },
  };

  factory Permissions.fromCacheJson(Map<String, dynamic> json) {
    final raw = json['granted'] as Map<String, dynamic>? ?? const {};

    final granted = <PermissionName, PermissionType>{};
    raw.forEach((key, value) {
      final name = PermissionName.fromValue(int.tryParse(key));
      final type = PermissionType.fromValue(value as int?);
      if (name != null && type != null) granted[name] = type;
    });

    return Permissions(
      isAdmin: json['isAdmin'] as bool? ?? false,
      granted: granted,
    );
  }
}

/// Keys used with [CacheHelper] across features — kept in one place so every
/// feature reads/writes the same key for the same value.
class CacheKeys {
  CacheKeys._();

  /// JWT returned by the login endpoint.
  static const String token = 'token';

  /// Id of the currently authenticated user — used to tell "my" messages
  /// apart from the other side's in case messaging.
  static const String userId = 'userId';

  /// Whether the signed-in user is an administrator. Cached from the login
  /// response so permission-gated actions (e.g. deleting someone else's case
  /// message) can be shown or hidden without a refetch.
  static const String isAdmin = 'isAdmin';

  /// The first of [laboratoryIds] — what older code reads as "the session's
  /// laboratory". The headers are built from [laboratoryIds], not this.
  static const String laboratoryId = 'laboratoryId';

  /// Display name of [laboratoryId], so the UI can show it without a refetch.
  static const String laboratoryName = 'laboratoryName';

  /// Every laboratory the session is scoped to, comma-separated — sent on
  /// every GET as the `X-Laboratory-Ids` header. [laboratoryId] keeps the
  /// first of them. Read and written only through `LaboratoryScope`.
  static const String laboratoryIds = 'laboratoryIds';

  /// The names of [laboratoryIds], JSON-encoded, in the same order.
  static const String laboratoryNames = 'laboratoryNames';

  /// The signed-in user's permission grants, cached so a cold start draws the
  /// correct navigation before `/ClinicAuth/me` answers.
  static const String permissions = 'permissions';

  /// The user's manual theme choice: `'light'`, `'dark'`, or `'system'`.
  static const String themeMode = 'themeMode';

  /// The user's text size choice: `'small'`, `'medium'` or `'large'`. Applied
  /// on top of the device's own font scaling, never instead of it.
  static const String fontScale = 'fontScale';

  // ---- Offline list caches ----
  // Each holds the raw JSON array from the last successful fetch of that
  // list, so the repo can fall back to it when offline. Only unfiltered
  // "base" list fetches are cached (see the repos using them).
  static const String cachedPatientsList = 'cache_patients_list';
  static const String cachedDoctorsList = 'cache_doctors_list';
  static const String cachedClinicsList = 'cache_clinics_list';
  static const String cachedCasesList = 'cache_cases_list';
  static const String cachedPriceTiersList = 'cache_price_tiers_list';
  static const String cachedRestorationTypesList =
      'cache_restoration_types_list';
  // Case priorities are cached per scope: the two fetches return different
  // lists, so sharing one key would let an active-only fetch overwrite the
  // full list and silently drop the retired priorities offline.
  static const String cachedCasePrioritiesList = 'cache_case_priorities_list';
  static const String cachedAllCasePrioritiesList =
      'cache_all_case_priorities_list';

  /// The weekly scanner rules. The exceptions and the calendar are both
  /// date-ranged, so a stale copy of either would be worse than none.
  static const String cachedScannerRulesList = 'cache_scanner_rules_list';

  /// The laboratory's case-workflow catalogue. Case *plans* are per-case and
  /// change constantly, so only the catalogue is cached.
  static const String cachedCaseStagesList = 'cache_case_stages_list';
  static const String cachedUsersList = 'cache_users_list';
  static const String cachedEmployeesList = 'cache_employees_list';
  static const String cachedRolesList = 'cache_roles_list';
  static const String cachedCountriesList = 'cache_countries_list';
  static const String cachedCitiesList = 'cache_cities_list';
  static const String cachedLaboratoriesList = 'cache_laboratories_list';

  /// The full (not unread-only) notifications list.
  static const String cachedNotificationsList = 'cache_notifications_list';
}

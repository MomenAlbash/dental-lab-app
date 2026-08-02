/// Keys used with [CacheHelper] across features — kept in one place so every
/// feature reads/writes the same key for the same value.
class CacheKeys {
  CacheKeys._();

  /// JWT returned by the login endpoint.
  static const String token = 'token';

  /// Id of the currently authenticated user — used to tell "my" messages
  /// apart from the other side's in case messaging.
  static const String userId = 'userId';

  /// The laboratory the user is currently operating as. Sent with every
  /// request as the `X-Laboratory-Id` header.
  static const String laboratoryId = 'laboratoryId';

  /// Display name of [laboratoryId], so the UI can show it without a refetch.
  static const String laboratoryName = 'laboratoryName';

  /// The user's manual theme choice: `'light'`, `'dark'`, or `'system'`.
  static const String themeMode = 'themeMode';
}

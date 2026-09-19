import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the signed-in user's permissions for the lifetime of the app.
///
/// A cubit rather than a plain cache read so the drawer and the bottom bar
/// rebuild the moment permissions land: `/ClinicAuth/me` answers slightly after
/// the first screen paints, and without this the nav would show whatever the
/// previous session cached until the user navigated away and back.
///
/// It restores from the cache synchronously on construction so a cold start
/// draws the right nav immediately instead of flashing the full menu and then
/// removing rows — which reads as the app taking things away from the user.
class SessionCubit extends Cubit<Permissions> {
  /// [initial] bypasses the cache. Production leaves it null so the cubit
  /// restores the last session; tests pass a user in directly, because
  /// adopting one afterwards emits asynchronously and the first frame would
  /// still draw an empty menu.
  SessionCubit({Permissions? initial}) : super(initial ?? _readCached());

  static Permissions _readCached() {
    // Guarded because the cubit may be constructed before CacheHelper.init in
    // a test or an early-boot path. "Nothing cached" and "cache not ready" both
    // mean the same thing here — grant nothing until the server says otherwise.
    try {
      final raw = CacheHelper.getJson(key: CacheKeys.permissions);
      if (raw is! Map<String, dynamic>) return Permissions.empty;
      return Permissions.fromCacheJson(raw);
    } catch (_) {
      return Permissions.empty;
    }
  }

  /// Adopts the permissions carried on a `ClinicUserDto` — the login response
  /// and `GET /ClinicAuth/me` return the same shape.
  Future<void> adopt(Permissions permissions) async {
    emit(permissions);
    await CacheHelper.saveJson(
      key: CacheKeys.permissions,
      value: permissions.toJson(),
    );
  }

  /// Drops everything the session knew. Called on sign-out and on any `401`.
  Future<void> clear() async {
    emit(Permissions.empty);
    await CacheHelper.removeData(key: CacheKeys.permissions);
  }
}

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';

/// Registers a signed-in session for a widget test.
///
/// Any screen carrying [AppDrawerWidget] resolves [SessionCubit] to decide
/// which destinations to draw, so a test that pumps one has to say who is
/// signed in. Defaults to an admin: a test about a page's own content should
/// not have to enumerate permissions to get its drawer to render.
///
/// A shared helper rather than a copy per test file so adding a gate later
/// does not mean editing every screen test.
void registerTestSession({Permissions? as}) {
  getIt.registerLazySingleton<SessionCubit>(
    () => SessionCubit(
      initial: as ?? const Permissions(isAdmin: true, granted: {}),
    ),
  );
}

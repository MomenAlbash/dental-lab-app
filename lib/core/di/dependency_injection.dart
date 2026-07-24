import 'package:get_it/get_it.dart';

/// Global service locator. Repositories and cubits are registered here as
/// features are connected to the API. Kept intentionally empty for now
/// (design-only phase).
final GetIt getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // Registrations are added feature-by-feature during the API-wiring phase.
}

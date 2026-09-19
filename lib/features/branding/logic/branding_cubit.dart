import 'package:dental_lab_app/features/branding/data/models/branding_model.dart';
import 'package:dental_lab_app/features/branding/data/repos/branding_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The laboratory's brand, held for the life of the app.
///
/// A singleton the whole tree rebuilds against, not a per-screen cubit: the
/// theme is built from it, so every screen is downstream of this one value.
///
/// The state is the branding itself rather than a sealed union — there is
/// always *a* brand, because a failed fetch falls back to the app's own. A
/// screen asking "is the brand loading" would have nothing useful to do with
/// the answer.
class BrandingCubit extends Cubit<BrandingModel> {
  BrandingCubit(this._repo) : super(BrandingModel.fallback);

  final BrandingRepo _repo;

  /// Reads the lab's brand. Called before the first frame so the login screen
  /// is already dressed, then again after a save.
  ///
  /// A failure leaves the app's own brand standing and is not surfaced: the
  /// user came to sign in, and "could not load branding" is not a problem they
  /// can act on.
  Future<void> load() async {
    final result = await _repo.getBranding();
    if (isClosed) return;

    result.fold((_) {}, emit);
  }

  Future<bool> save(UpdateBrandingRequestModel body) async {
    final result = await _repo.updateBranding(body: body);
    if (isClosed) return false;

    return result.fold((_) => false, (branding) {
      emit(branding);
      return true;
    });
  }

  Future<bool> uploadLogo(String filePath) async {
    final result = await _repo.uploadLogo(filePath: filePath);
    if (isClosed) return false;

    return result.fold((_) => false, (branding) {
      emit(branding);
      return true;
    });
  }

  Future<bool> removeLogo() async {
    final result = await _repo.removeLogo();
    if (isClosed) return false;

    return result.fold((_) => false, (branding) {
      emit(branding);
      return true;
    });
  }
}

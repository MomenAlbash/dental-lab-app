import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Answers "what will this restoration actually run", for the
/// add-restoration form.
///
/// Reads the type's whole route from `GET /routing/routes/{id}` and filters
/// it by intake. The old `/routing/preview` and `/routing/options` calls this
/// used to make were deleted server-side with the graph engine — they had
/// been 404ing, which is why the section showed nothing and the "answer every
/// option" rule it enforced could never fire.
///
/// Optional stages are reported but not folded into the route: the wizard
/// asks about them in its own step, after the restorations are entered, and
/// this screen has no answers to draw with yet.
class RoutePreviewCubit extends Cubit<RoutePreviewState> {
  RoutePreviewCubit(this._repo) : super(const RoutePreviewState());

  final CasesRepo _repo;

  String? _restorationTypeId;
  ImpressionMethod? _intake;

  /// Loads the route for [restorationTypeId] under [impressionMethod].
  Future<void> load({
    required String restorationTypeId,
    ImpressionMethod? impressionMethod,
  }) async {
    _restorationTypeId = restorationTypeId;
    _intake = impressionMethod;

    emit(const RoutePreviewState(isLoading: true));
    await _fetch(restorationTypeId, impressionMethod);
  }

  /// Re-filters for a new intake — for when the parent form's intake changes
  /// under a restoration that is already chosen.
  Future<void> intakeChanged(ImpressionMethod? impressionMethod) async {
    if (_intake == impressionMethod) return;
    _intake = impressionMethod;

    final typeId = _restorationTypeId;
    if (typeId == null) return;

    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetch(typeId, impressionMethod);
  }

  Future<void> _fetch(String typeId, ImpressionMethod? intake) async {
    final result = await _repo.getRouteDefinition(typeId);
    if (isClosed) return;
    // A route that finished arriving after the user picked another type is
    // stale — dropping it keeps the section describing what is on screen.
    if (_restorationTypeId != typeId) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          hasLoaded: true,
          errorMessage: failure.errorMessage,
        ),
      ),
      (route) => emit(
        RoutePreviewState(
          mandatory: route.mandatoryFor(intake),
          optional: route.optionalFor(intake),
          problems: [
            for (final problem in route.problems)
              if ((problem.message ?? '').trim().isNotEmpty)
                problem.message!.trim(),
          ],
          hasLoaded: true,
        ),
      ),
    );
  }
}

import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RestorationTypesCubit extends Cubit<RestorationTypesState> {
  RestorationTypesCubit(this._repo) : super(const RestorationTypesInitial());

  final RestorationTypesRepo _repo;

  Future<void> getRestorationTypes() async {
    emit(const RestorationTypesLoading());

    final result = await _repo.getRestorationTypes();

    result.fold(
      (failure) => emit(RestorationTypesError(failure.errorMessage)),
      (types) => emit(RestorationTypesLoaded(types)),
    );
  }

  /// The catalog priced for [doctorId] — what the case form must load once a
  /// doctor is chosen, instead of the plain list's currency-less
  /// `defaultPrice`. [intake] is the `RouteStageAppliesTo` value (2/3), not
  /// `ImpressionMethod`'s own (1/2); the caller converts.
  ///
  /// Reshapes each row into a [RestorationTypeModel] so every consumer of
  /// this cubit's state — the type dropdown, the currency/price gating in
  /// `AddRestorationPage` — works off one shape regardless of which catalog
  /// fed it. A type nothing prices for this doctor
  /// (`isPriceUnavailable`) is left out entirely rather than offered with no
  /// real price behind it.
  Future<void> getForDoctor({String? doctorId, int? intake}) async {
    emit(const RestorationTypesLoading());

    final result = await _repo.getRestorationTypesLookup(
      doctorId: doctorId,
      intake: intake,
    );

    result.fold(
      (failure) => emit(RestorationTypesError(failure.errorMessage)),
      (types) => emit(
        RestorationTypesLoaded([
          for (final type in types)
            if (!type.isPriceUnavailable) type.toRestorationTypeModel(),
        ]),
      ),
    );
  }

  Future<void> deleteRestorationType(String id) async {
    final result = await _repo.deleteRestorationType(id);

    await result.fold(
      (failure) async => emit(RestorationTypeDeleteError(failure.errorMessage)),
      (_) async {
        emit(const RestorationTypeDeleted());
        await getRestorationTypes();
      },
    );
  }
}

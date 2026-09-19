import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/areas/data/repos/areas_repo.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/zones/data/models/save_zone_request_models.dart';
import 'package:dental_lab_app/features/zones/data/repos/zones_repo.dart';
import 'package:dental_lab_app/features/zones/logic/zone_form/zone_form_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ZoneFormCubit extends Cubit<ZoneFormState> {
  ZoneFormCubit(this._zonesRepo, this._areasRepo, this._usersRepo)
    : super(const ZoneFormInitial());

  final ZonesRepo _zonesRepo;
  final AreasRepo _areasRepo;
  final UsersRepo _usersRepo;

  Future<void> loadCatalog() async {
    emit(const ZoneFormCatalogLoading());

    final areasResult = await _areasRepo.getAreas();
    if (areasResult.isLeft()) {
      emit(
        ZoneFormCatalogError(
          areasResult.fold((f) => f.errorMessage, (_) => ''),
        ),
      );
      return;
    }

    final usersResult = await _usersRepo.getUsers();
    if (usersResult.isLeft()) {
      emit(
        ZoneFormCatalogError(
          usersResult.fold((f) => f.errorMessage, (_) => ''),
        ),
      );
      return;
    }

    final areas = areasResult.fold((_) => const <AreaModel>[], (a) => a);
    final users = usersResult.fold((_) => const <UserModel>[], (u) => u);

    emit(
      ZoneFormCatalogLoaded(
        areas: areas,
        representatives: users
            .where((u) => u.type == UserType.employee && u.isRepresentative)
            .toList(),
      ),
    );
  }

  Future<void> createZone(CreateZoneRequestModel requestBody) async {
    emit(const ZoneFormSubmitting());

    final result = await _zonesRepo.createZone(requestBody);

    result.fold(
      (failure) => emit(ZoneFormError(failure.errorMessage)),
      (zone) => emit(ZoneFormSuccess(zone)),
    );
  }

  Future<void> updateZone({
    required String id,
    required UpdateZoneRequestModel requestBody,
  }) async {
    emit(const ZoneFormSubmitting());

    final result = await _zonesRepo.updateZone(
      id: id,
      requestBody: requestBody,
    );

    result.fold(
      (failure) => emit(ZoneFormError(failure.errorMessage)),
      (zone) => emit(ZoneFormSuccess(zone)),
    );
  }
}

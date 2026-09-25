import 'package:dental_lab_app/features/accounting/data/models/currency_model.dart';
import 'package:dental_lab_app/features/areas/data/models/area_model.dart';
import 'package:dental_lab_app/features/users/data/models/user_model.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';

sealed class ZoneFormState {
  const ZoneFormState();
}

class ZoneFormInitial extends ZoneFormState {
  const ZoneFormInitial();
}

class ZoneFormCatalogLoading extends ZoneFormState {
  const ZoneFormCatalogLoading();
}

/// The areas and candidate representatives the form can offer — not the
/// zone's own picks, and loaded once, independent of submission.
///
/// [representatives] is every user this app can offer as a zone rep: an
/// employee-type account flagged `isRepresentative`. There is no server
/// filter for this, so the whole user list is fetched and narrowed here.
class ZoneFormCatalogLoaded extends ZoneFormState {
  const ZoneFormCatalogLoaded({
    required this.areas,
    required this.representatives,
    this.currencies = const [],
  });
  final List<AreaModel> areas;
  final List<UserModel> representatives;
  final List<CurrencyModel> currencies;
}

class ZoneFormCatalogError extends ZoneFormState {
  const ZoneFormCatalogError(this.message);
  final String message;
}

class ZoneFormSubmitting extends ZoneFormState {
  const ZoneFormSubmitting();
}

class ZoneFormSuccess extends ZoneFormState {
  const ZoneFormSuccess(this.zone);
  final ZoneModel zone;
}

class ZoneFormError extends ZoneFormState {
  const ZoneFormError(this.message);
  final String message;
}

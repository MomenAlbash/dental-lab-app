import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/set_price_tier_doctors_request_model.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_doctors/price_tier_doctors_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives who is billed at one price tier.
class PriceTierDoctorsCubit extends Cubit<PriceTierDoctorsState> {
  PriceTierDoctorsCubit(this._repo) : super(const PriceTierDoctorsInitial());

  final PriceTiersRepo _repo;

  late String _tierId;

  /// Kept so a failed write can put the list back rather than replacing a
  /// working screen with an error.
  List<PriceTierDoctorModel> _lastLoaded = const [];

  Future<void> load(String tierId) async {
    _tierId = tierId;
    emit(const PriceTierDoctorsLoading());

    final result = await _repo.getPriceTierById(tierId);
    if (isClosed) return;

    result.fold(
      (failure) => emit(PriceTierDoctorsError(failure.errorMessage)),
      (tier) {
        _lastLoaded = _sorted(tier.doctors);
        emit(PriceTierDoctorsLoaded(_lastLoaded));
      },
    );
  }

  /// Replaces the assignment wholesale — the endpoint takes the full list, so
  /// this is also how a doctor is removed.
  Future<void> setDoctors(List<String> doctorIds) async {
    final current = state;
    if (current is PriceTierDoctorsLoaded) {
      emit(current.copyWith(isBusy: true));
    }

    final result = await _repo.setPriceTierDoctors(
      id: _tierId,
      body: SetPriceTierDoctorsRequestModel(doctorIds: doctorIds),
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(PriceTierDoctorsMessage(failure.errorMessage, isError: true));
        emit(PriceTierDoctorsLoaded(_lastLoaded));
      },
      (tier) {
        _lastLoaded = _sorted(tier.doctors);
        emit(
          PriceTierDoctorsMessage(
            doctorIds.isEmpty
                ? 'تم إلغاء إسناد الشريحة لكل الأطباء'
                : 'تم إسناد الشريحة إلى ${doctorIds.length} طبيب',
          ),
        );
        emit(PriceTierDoctorsLoaded(_lastLoaded));
      },
    );
  }

  /// By the lab's own doctor number, then by name — the number is what a lab
  /// files by, and a null one sorts last rather than to the top.
  static List<PriceTierDoctorModel> _sorted(List<PriceTierDoctorModel> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      final byNumber = (a.number ?? 1 << 30).compareTo(b.number ?? 1 << 30);
      return byNumber != 0 ? byNumber : a.displayName.compareTo(b.displayName);
    });
    return sorted;
  }
}

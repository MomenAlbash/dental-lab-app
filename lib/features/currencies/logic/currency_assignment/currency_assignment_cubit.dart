import 'package:dental_lab_app/features/currencies/data/models/currency_assignment_model.dart';
import 'package:dental_lab_app/features/currencies/data/repos/currencies_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class CurrencyAssignmentState {
  const CurrencyAssignmentState();
}

class CurrencyAssignmentLoading extends CurrencyAssignmentState {
  const CurrencyAssignmentLoading();
}

class CurrencyAssignmentError extends CurrencyAssignmentState {
  const CurrencyAssignmentError(this.message);
  final String message;
}

class CurrencyAssignmentLoaded extends CurrencyAssignmentState {
  const CurrencyAssignmentLoaded({
    required this.assignment,
    required this.catalogue,
    this.isBusy = false,
  });

  /// What is currently assigned.
  final CurrencyAssignmentModel assignment;

  /// Every currency that exists — what the picker offers. Kept beside the
  /// assignment rather than derived from it: a set of two currencies cannot
  /// tell you what the third one would have been.
  final List<CurrencyModelRef> catalogue;

  final bool isBusy;

  CurrencyAssignmentLoaded copyWith({
    CurrencyAssignmentModel? assignment,
    bool? isBusy,
  }) => CurrencyAssignmentLoaded(
    assignment: assignment ?? this.assignment,
    catalogue: catalogue,
    isBusy: isBusy ?? this.isBusy,
  );
}

class CurrencyAssignmentActionError extends CurrencyAssignmentState {
  const CurrencyAssignmentActionError(this.message);
  final String message;
}

class CurrencyAssignmentSaved extends CurrencyAssignmentState {
  const CurrencyAssignmentSaved(this.message);
  final String message;
}

/// Which currencies a laboratory — or one clinic under it — actually trades in.
///
/// Two scopes through one cubit because the screens are the same shape; which
/// one is in play is decided at [loadForLaboratory] / [loadForClinic] and kept
/// in [_clinicId], so a save can never land on the wrong scope.
class CurrencyAssignmentCubit extends Cubit<CurrencyAssignmentState> {
  CurrencyAssignmentCubit(this._repo)
    : super(const CurrencyAssignmentLoading());

  final CurrenciesRepo _repo;

  /// Null means the laboratory scope.
  String? _clinicId;

  Future<void> loadForLaboratory() {
    _clinicId = null;
    return _load();
  }

  Future<void> loadForClinic(String clinicId) {
    _clinicId = clinicId;
    return _load();
  }

  Future<void> _load() async {
    emit(const CurrencyAssignmentLoading());

    // The catalogue and the assignment are fetched together: a picker that
    // arrives before the list of what it may offer is a picker with nothing
    // in it.
    final catalogue = await _repo.getCurrencies();
    if (isClosed) return;

    final clinicId = _clinicId;
    final assignment = clinicId == null
        ? await _repo.getLaboratoryCurrencies()
        : await _repo.getClinicCurrencies(clinicId);
    if (isClosed) return;

    catalogue.fold((failure) => emit(CurrencyAssignmentError(failure.errorMessage)), (
      list,
    ) {
      assignment.fold(
        (failure) => emit(CurrencyAssignmentError(failure.errorMessage)),
        (value) => emit(
          CurrencyAssignmentLoaded(
            assignment: value,
            catalogue: [
              for (final currency in list)
                (
                  id: currency.id,
                  label: currency.code ?? currency.name ?? '—',
                  name: currency.name ?? '',
                ),
            ],
          ),
        ),
      );
    });
  }

  /// Writes the set for whichever scope was loaded.
  ///
  /// [defaultCurrencyId] is ignored in the clinic scope: a clinic narrows
  /// which of the lab's currencies it trades in, but which one a form
  /// pre-selects stays the laboratory's call.
  Future<void> save({
    required List<String> currencyIds,
    String? defaultCurrencyId,
  }) async {
    final current = state;
    if (current is CurrencyAssignmentLoaded) {
      emit(current.copyWith(isBusy: true));
    }

    final clinicId = _clinicId;
    final result = clinicId == null
        ? await _repo.setLaboratoryCurrencies(
            SetLaboratoryCurrenciesRequestModel(
              currencyIds: currencyIds,
              defaultCurrencyId: defaultCurrencyId,
            ),
          )
        : await _repo.setClinicCurrencies(
            clinicId: clinicId,
            body: SetClinicCurrenciesRequestModel(currencyIds: currencyIds),
          );
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(CurrencyAssignmentActionError(failure.errorMessage));
        if (current is CurrencyAssignmentLoaded) {
          emit(current.copyWith(isBusy: false));
        }
      },
      (saved) {
        emit(
          CurrencyAssignmentSaved(
            // An empty clinic set is not "no currencies" — it is the override
            // cleared, and the clinic back to following the laboratory. Saying
            // "saved" for that would describe the opposite of what happened.
            clinicId != null && currencyIds.isEmpty
                ? 'عادت العيادة إلى عملات المخبر'
                : 'تم حفظ العملات',
          ),
        );
        if (current is CurrencyAssignmentLoaded) {
          emit(current.copyWith(assignment: saved, isBusy: false));
        }
      },
    );
  }
}

/// One row of the picker. A record rather than the full currency model: the
/// picker needs an id and something to show, and nothing else.
typedef CurrencyModelRef = ({String id, String label, String name});

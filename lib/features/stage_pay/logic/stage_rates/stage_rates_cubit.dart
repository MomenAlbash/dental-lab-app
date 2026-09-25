import 'package:dental_lab_app/features/stage_pay/data/models/stage_pay_models.dart';
import 'package:dental_lab_app/features/stage_pay/data/repos/stage_pay_repo.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Edits the price of each production stage.
///
/// Edits collect as drafts and are saved together: a price list is set up in
/// one sitting, and a request per keystroke would both flood the server and
/// save half-typed numbers.
class StageRatesCubit extends Cubit<StageRatesState> {
  StageRatesCubit(this._repo) : super(const StageRatesLoading());

  final StagePayRepo _repo;

  List<StagePayRestorationTypeModel> _types = const [];
  Map<String, StagePayRateDraft> _drafts = const {};

  Future<void> load() async {
    emit(const StageRatesLoading());

    final result = await _repo.getRates();
    if (isClosed) return;

    result.fold((failure) => emit(StageRatesError(failure.errorMessage)), (
      types,
    ) {
      _types = types;
      _drafts = const {};
      _emitLoaded();
    });
  }

  /// Sets one stage's price. Setting it back to what the server has drops
  /// the draft, so "changed" means changed.
  void edit(StagePayRateModel stage, {double? amount, StagePayBasis? basis}) {
    final current =
        _drafts[stage.rootStageId] ??
        StagePayRateDraft(amount: stage.amount, basis: stage.basis);
    final next = StagePayRateDraft(
      amount: amount ?? current.amount,
      basis: basis ?? current.basis,
    );

    final drafts = Map.of(_drafts);
    if (next.amount == stage.amount && next.basis == stage.basis) {
      drafts.remove(stage.rootStageId);
    } else {
      drafts[stage.rootStageId] = next;
    }
    _drafts = drafts;
    _emitLoaded();
  }

  void discard() {
    _drafts = const {};
    _emitLoaded();
  }

  /// Saves every draft — one request per laboratory, since a save names the
  /// single laboratory whose price list it writes.
  Future<void> save() async {
    if (_drafts.isEmpty) return;
    _emitLoaded(isSaving: true);

    final byLaboratory = <String, Map<String, StagePayRateDraft>>{};
    for (final type in _types) {
      for (final stage in type.stages) {
        final draft = _drafts[stage.rootStageId];
        if (draft == null) continue;
        byLaboratory.putIfAbsent(
          type.laboratoryId,
          () => {},
        )[stage.rootStageId] = draft;
      }
    }

    for (final entry in byLaboratory.entries) {
      final result = await _repo.saveRates(
        SaveStagePayRatesRequestModel(
          laboratoryId: entry.key,
          rates: entry.value,
        ),
      );
      if (isClosed) return;

      final failure = result.fold((f) => f, (_) => null);
      if (failure != null) {
        // Drafts are kept so nothing typed is lost. A laboratory saved before
        // this one is already written; the reload on the next success, or a
        // pull-to-refresh, shows it.
        emit(StageRatesSaveError(failure.errorMessage));
        _emitLoaded();
        return;
      }
    }

    emit(const StageRatesSaved());
    await load();
  }

  void _emitLoaded({bool isSaving = false}) {
    emit(StageRatesLoaded(types: _types, drafts: _drafts, isSaving: isSaving));
  }
}

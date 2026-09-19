import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/barcode_scan/barcode_scan_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Turns a scanned barcode into the thing it names.
///
/// The lab prints two kinds of code on a ticket: one for the case and one per
/// restoration. They are told apart by asking — the restoration lookup first,
/// then the case — because the codes are opaque strings and only the server
/// knows which register a given number lives in.
class BarcodeScanCubit extends Cubit<BarcodeScanState> {
  BarcodeScanCubit(this._repo) : super(const BarcodeScanIdle());

  final CasesRepo _repo;

  /// The code being resolved, so the same one arriving again mid-flight (the
  /// camera reports a code many times a second) is ignored.
  String? _inFlight;

  Future<void> resolve(String rawCode) async {
    final code = rawCode.trim();
    if (code.isEmpty || code == _inFlight) return;

    _inFlight = code;
    emit(BarcodeScanResolving(code));

    // Restorations first: a technician scanning a piece is the common case,
    // and a restoration answer also carries its case, so nothing is lost.
    final restoration = await _repo.getRestorationByNumber(code);
    if (isClosed) return;

    final resolved = restoration.fold((_) => null, (scanned) => scanned);
    if (resolved != null && resolved.caseDetail != null) {
      emit(
        BarcodeScanRestorationFound(
          caseDetail: resolved.caseDetail!,
          restorationId: resolved.restorationId,
          restorationNumber: resolved.restorationNumber,
        ),
      );
      return;
    }

    final caseResult = await _repo.getCaseByNumber(code);
    if (isClosed) return;

    caseResult.fold(
      // Reported against the code the user scanned: "not found" about nothing
      // in particular is not something they can act on.
      (failure) => emit(BarcodeScanNotFound(code: code)),
      (caseDetail) => emit(BarcodeScanCaseFound(caseDetail)),
    );
  }

  /// Lets the same code be scanned again after the user dismissed a result.
  void reset() {
    _inFlight = null;
    emit(const BarcodeScanIdle());
  }
}

import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/repos/scanner_availability_repo.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScannerRulesCubit extends Cubit<ScannerRulesState> {
  ScannerRulesCubit(this._repo) : super(const ScannerRulesInitial());

  final ScannerAvailabilityRepo _repo;

  Future<void> getRules() async {
    emit(const ScannerRulesLoading());

    final result = await _repo.getRules();

    result.fold(
      (failure) => emit(ScannerRulesError(failure.errorMessage)),
      (rules) => emit(ScannerRulesLoaded(_sorted(rules))),
    );
  }

  /// Sorted the way the week reads — by day, then by start time. The API
  /// returns them in insertion order, which puts a Tuesday morning rule added
  /// last underneath a Saturday one.
  List<ScannerAvailabilityRuleModel> _sorted(
    List<ScannerAvailabilityRuleModel> rules,
  ) {
    final sorted = [...rules];
    sorted.sort((a, b) {
      final byDay = a.dayOfWeek.compareTo(b.dayOfWeek);
      if (byDay != 0) return byDay;

      final aStart = a.startTime;
      final bStart = b.startTime;
      if (aStart == null || bStart == null) return 0;
      return (aStart.hour * 60 + aStart.minute).compareTo(
        bStart.hour * 60 + bStart.minute,
      );
    });
    return sorted;
  }

  Future<void> saveRule({
    String? id,
    required SaveScannerAvailabilityRuleRequestModel body,
  }) async {
    emit(const ScannerRuleSaving());

    final result = id == null
        ? await _repo.createRule(body)
        : await _repo.updateRule(id: id, saveRequestBody: body);

    await result.fold(
      (failure) async => emit(ScannerRuleSaveError(failure.errorMessage)),
      (_) async {
        emit(const ScannerRuleSaved());
        await getRules();
      },
    );
  }

  Future<void> deleteRule(String id) async {
    final result = await _repo.deleteRule(id);

    await result.fold(
      (failure) async => emit(ScannerRuleDeleteError(failure.errorMessage)),
      (_) async {
        emit(const ScannerRuleDeleted());
        await getRules();
      },
    );
  }
}

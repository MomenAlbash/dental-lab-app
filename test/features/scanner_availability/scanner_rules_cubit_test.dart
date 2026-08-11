import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/repos/scanner_availability_repo.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ScannerAvailabilityRepo {}

ScannerAvailabilityRuleModel _rule(String id, int day, {int hour = 9}) =>
    ScannerAvailabilityRuleModel(
      id: id,
      dayOfWeek: day,
      startTime: TimeOfDay(hour: hour, minute: 0),
      endTime: const TimeOfDay(hour: 17, minute: 0),
    );

const _body = SaveScannerAvailabilityRuleRequestModel(
  dayOfWeek: 1,
  startTime: TimeOfDay(hour: 9, minute: 0),
  endTime: TimeOfDay(hour: 17, minute: 0),
);

void main() {
  late _MockRepo repo;
  late ScannerRulesCubit cubit;

  setUpAll(() => registerFallbackValue(_body));

  setUp(() {
    repo = _MockRepo();
    cubit = ScannerRulesCubit(repo);
  });

  tearDown(() => cubit.close());

  test('orders rules by day, then by start time', () async {
    // The API returns them in insertion order, which reads as random.
    when(() => repo.getRules()).thenAnswer(
      (_) async => right([
        _rule('c', 3),
        _rule('b', 1, hour: 14),
        _rule('a', 1, hour: 8),
      ]),
    );

    await cubit.getRules();

    final rules = (cubit.state as ScannerRulesLoaded).rules;
    expect(rules.map((r) => r.id), ['a', 'b', 'c']);
  });

  test('emits the failure message when the fetch fails', () async {
    when(
      () => repo.getRules(),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await cubit.getRules();

    expect(cubit.state, isA<ScannerRulesError>());
    expect((cubit.state as ScannerRulesError).message, 'لا يوجد اتصال');
  });

  test('a null id creates, an id updates', () async {
    when(() => repo.getRules()).thenAnswer((_) async => right([_rule('a', 1)]));
    when(
      () => repo.createRule(any()),
    ).thenAnswer((_) async => right(_rule('a', 1)));
    when(
      () => repo.updateRule(
        id: any(named: 'id'),
        saveRequestBody: any(named: 'saveRequestBody'),
      ),
    ).thenAnswer((_) async => right(_rule('a', 1)));

    await cubit.saveRule(body: _body);
    verify(() => repo.createRule(any())).called(1);
    verifyNever(
      () => repo.updateRule(
        id: any(named: 'id'),
        saveRequestBody: any(named: 'saveRequestBody'),
      ),
    );

    await cubit.saveRule(id: 'a', body: _body);
    verify(() => repo.updateRule(id: 'a', saveRequestBody: _body)).called(1);
  });

  test('a successful save refetches so the list reflects it', () async {
    when(() => repo.getRules()).thenAnswer((_) async => right([_rule('a', 1)]));
    when(
      () => repo.createRule(any()),
    ).thenAnswer((_) async => right(_rule('a', 1)));

    await cubit.saveRule(body: _body);

    verify(() => repo.getRules()).called(1);
    expect(cubit.state, isA<ScannerRulesLoaded>());
  });

  test('a failed save reports and does not refetch', () async {
    when(
      () => repo.createRule(any()),
    ).thenAnswer((_) async => left(ServerFailure('تعارض بالأوقات')));

    await cubit.saveRule(body: _body);

    expect(cubit.state, isA<ScannerRuleSaveError>());
    expect((cubit.state as ScannerRuleSaveError).message, 'تعارض بالأوقات');
    verifyNever(() => repo.getRules());
  });

  test('a failed delete reports and does not refetch', () async {
    when(
      () => repo.deleteRule(any()),
    ).thenAnswer((_) async => left(ServerFailure('غير مسموح')));

    await cubit.deleteRule('a');

    expect(cubit.state, isA<ScannerRuleDeleteError>());
    verifyNever(() => repo.getRules());
  });
}

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLaboratoriesRepo extends Mock implements LaboratoriesRepo {}

const _a = LaboratoryModel(id: 'a', name: 'أ');
const _b = LaboratoryModel(id: 'b', name: 'ب');

void main() {
  late _MockLaboratoriesRepo repo;
  late LaboratorySelectionCubit cubit;

  setUp(() {
    repo = _MockLaboratoriesRepo();
    when(() => repo.selectLaboratories(any())).thenAnswer((_) async {});
    when(() => repo.selectedLaboratoryIds).thenReturn(const ['b']);
    cubit = LaboratorySelectionCubit(repo);
  });

  tearDown(() => cubit.close());

  void reach(List<LaboratoryModel> labs) => when(
    () => repo.getLaboratories(),
  ).thenAnswer((_) async => Right<Failure, List<LaboratoryModel>>(labs));

  test('one laboratory is chosen without asking', () async {
    reach([_a]);

    await cubit.loadLaboratories();

    expect(cubit.state, isA<LaboratorySelectionConfirmed>());
    verify(() => repo.selectLaboratories([_a])).called(1);
  });

  test('coming back starts from the scope in effect', () async {
    reach([_a, _b]);

    await cubit.loadLaboratories();

    expect((cubit.state as LaboratorySelectionLoaded).selectedIds, {'b'});
  });

  test('several can be confirmed together', () async {
    reach([_a, _b]);
    await cubit.loadLaboratories();

    cubit.toggle('a');
    await cubit.confirm();

    verify(() => repo.selectLaboratories([_a, _b])).called(1);
  });

  test('nothing selected cannot be confirmed', () async {
    reach([_a, _b]);
    await cubit.loadLaboratories();

    cubit.toggle('b');

    expect((cubit.state as LaboratorySelectionLoaded).canConfirm, isFalse);
    await cubit.confirm();
    verifyNever(() => repo.selectLaboratories(any()));
  });
}

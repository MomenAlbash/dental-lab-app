import 'package:dental_lab_app/features/case_stages/data/models/case_stage_enums.dart';
import 'package:dental_lab_app/features/case_stages/data/models/case_stage_model.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/case_stage_groups.dart';
import 'package:flutter_test/flutter_test.dart';

CaseStageModel _stage(String id, {required CaseStageTiming timing}) =>
    CaseStageModel(id: id, nameAr: id, timing: timing);

void main() {
  test('splits the workflow at the production barrier', () {
    // This is what "قبل الإنتاج / بعد الإنتاج" is: `timing` on the stage row,
    // a rule the server enforces — not a display grouping.
    final groups = groupStagesByTiming([
      _stage('review', timing: CaseStageTiming.beforeRestorations),
      _stage('packing', timing: CaseStageTiming.afterRestorations),
      _stage('payment', timing: CaseStageTiming.beforeRestorations),
    ]);

    expect(groups.map((g) => g.title), ['بالتوازي مع الإنتاج', 'بعد الإنتاج']);
    expect(groups.first.stages.map((s) => s.id), ['review', 'payment']);
    expect(groups.last.stages.single.id, 'packing');
  });

  test('the after-production half says why it waits', () {
    // A barred stage is exactly what makes a case look stuck to someone who
    // does not know the rule.
    final groups = groupStagesByTiming([
      _stage('packing', timing: CaseStageTiming.afterRestorations),
    ]);

    expect(groups.single.note, 'لا تبدأ حتى تنتهي كل التعويضات');
  });

  test('an empty half is left out, not shown empty', () {
    final groups = groupStagesByTiming([
      _stage('review', timing: CaseStageTiming.beforeRestorations),
    ]);

    expect(groups.length, 1);
    expect(groups.single.title, 'بالتوازي مع الإنتاج');
    expect(groups.single.note, isNull);
  });

  test('no stages, no groups', () {
    expect(groupStagesByTiming(const []), isEmpty);
  });

  group('CaseStageTiming', () {
    test('an unknown value defaults to running before production', () {
      // The harmless answer: a stage that waits for nothing is never stuck.
      expect(CaseStageTiming.fromApi(null), CaseStageTiming.beforeRestorations);
      expect(CaseStageTiming.fromApi(99), CaseStageTiming.beforeRestorations);
      expect(CaseStageTiming.fromApi(2), CaseStageTiming.afterRestorations);
    });

    test('sends the numbers the API declares', () {
      expect(CaseStageTiming.beforeRestorations.apiValue, 1);
      expect(CaseStageTiming.afterRestorations.apiValue, 2);
    });
  });
}

import 'package:dental_lab_app/features/case_workflow_stages/data/models/case_workflow_stage_model.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/workflow_stages/route_bands.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:flutter_test/flutter_test.dart';

CaseWorkflowStageModel stage(
  String name, {
  int order = 0,
  bool isActive = true,
  RouteStageAppliesTo appliesTo = RouteStageAppliesTo.any,
}) => CaseWorkflowStageModel(
  id: name,
  nameAr: name,
  order: order,
  isActive: isActive,
  appliesTo: appliesTo,
);

List<List<String>> names(List<List<CaseWorkflowStageModel>> bands) => [
  for (final band in bands) band.map((s) => s.displayName).toList(),
];

void main() {
  test('stages sharing an order land in one band', () {
    // The whole point: `order` is a position in the route, not a line number.
    final bands = RouteBands.build([
      stage('التشطيب', order: 2),
      stage('القاعدة', order: 1),
      stage('الأسنان', order: 1),
    ]);

    expect(names(bands), [
      ['الأسنان', 'القاعدة'],
      ['التشطيب'],
    ]);
  });

  test('an empty route yields no bands', () {
    expect(RouteBands.build(const []), isEmpty);
  });

  test('deactivated stages are left out of the drawing', () {
    final bands = RouteBands.build([
      stage('حالية', order: 0),
      stage('متقاعدة', order: 1, isActive: false),
    ]);

    expect(names(bands), [
      ['حالية'],
    ]);
  });

  test('a digital-only stage is pruned from the traditional tab', () {
    final stages = [
      stage('الصب', order: 0, appliesTo: RouteStageAppliesTo.traditionalOnly),
      stage('التصميم', order: 0, appliesTo: RouteStageAppliesTo.digitalOnly),
      stage('التلبيس', order: 1),
    ];

    expect(
      names(RouteBands.build(stages, intake: ImpressionMethod.traditional)),
      [
        ['الصب'],
        ['التلبيس'],
      ],
    );
    expect(names(RouteBands.build(stages, intake: ImpressionMethod.digital)), [
      ['التصميم'],
      ['التلبيس'],
    ]);
  });

  test('no intake filter keeps both heads side by side', () {
    // The "all stages" tab must show the fork, not one arm of it.
    final bands = RouteBands.build([
      stage('الصب', order: 0, appliesTo: RouteStageAppliesTo.traditionalOnly),
      stage('التصميم', order: 0, appliesTo: RouteStageAppliesTo.digitalOnly),
    ]);

    expect(bands.single, hasLength(2));
  });

  test('a band emptied by the filter is dropped, not left blank', () {
    final bands = RouteBands.build([
      stage('التصميم', order: 0, appliesTo: RouteStageAppliesTo.digitalOnly),
      stage('التلبيس', order: 1),
    ], intake: ImpressionMethod.traditional);

    expect(names(bands), [
      ['التلبيس'],
    ]);
  });

  test('gaps in the order numbering do not create empty bands', () {
    // Labs renumber by hand; a jump from 0 to 7 is a gap, not six stages.
    final bands = RouteBands.build([
      stage('أولى', order: 0),
      stage('أخيرة', order: 7),
    ]);

    expect(bands, hasLength(2));
  });
}

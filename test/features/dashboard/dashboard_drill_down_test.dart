import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/case_counts_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/dashboard/data/models/dashboard_breakdown_models.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_breakdown_bars.dart';
import 'package:dental_lab_app/features/dashboard/ui/widgets/dashboard_flow_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  test('each lifecycle phase opens the list tab it belongs to', () {
    expect(CasePhaseTab.forPhase(CasePhase.newCase), CasePhaseTab.newCases);
    expect(CasePhaseTab.forPhase(CasePhase.received), CasePhaseTab.newCases);
    expect(
      CasePhaseTab.forPhase(CasePhase.inProduction),
      CasePhaseTab.inProduction,
    );
    expect(
      CasePhaseTab.forPhase(CasePhase.qualityCheck),
      CasePhaseTab.inProduction,
    );
    expect(CasePhaseTab.forPhase(CasePhase.ready), CasePhaseTab.ready);
    expect(CasePhaseTab.forPhase(CasePhase.delivered), CasePhaseTab.delivered);
  });

  testWidgets('a phase row opens its cases', (tester) async {
    CasePhase? opened;
    await tester.pumpWidget(
      _host(
        DashboardPhaseFunnel(
          phases: const [CasePhaseCountModel(phase: CasePhase.ready, count: 4)],
          onTapPhase: (phase) => opened = phase,
        ),
      ),
    );

    await tester.tap(find.text('4'));

    expect(opened, CasePhase.ready);
  });

  testWidgets('a bar opens what it counts; a plain bar does nothing', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(
        DashboardBreakdownBars(
          bars: [
            BreakdownBar(
              label: 'التصميم',
              value: 3,
              color: Colors.teal,
              onTap: () => taps++,
            ),
            const BreakdownBar(label: 'الإيراد', value: 9, color: Colors.teal),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('التصميم'));
    await tester.tap(find.text('الإيراد'));

    expect(taps, 1);
    expect(find.byType(InkWell), findsOneWidget);
  });
}

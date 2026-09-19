import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/departments/data/models/department_model.dart';
import 'package:dental_lab_app/features/departments/ui/widgets/department_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DepartmentModel department({
  String name = 'التشطيب',
  List<Map<String, dynamic>> stages = const [],
}) => DepartmentModel.fromJson({
  'id': 'd1',
  'nameAr': name,
  'stages': stages,
  'activeWorkloadCount': 4,
});

Future<void> pump(WidgetTester tester, DepartmentModel model) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          // A scrolling parent, which is how the card is actually hosted. It
          // hands down an unbounded height — the constraint the card has to
          // survive.
          body: ListView(
            children: [
              DepartmentCard(
                department: model,
                onEdit: () {},
                onLinkStages: () {},
                onDelete: () {},
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('lays out inside a scrolling list without an infinite height', (
    tester,
  ) async {
    // The card's coloured rail has a width but no height of its own, so a
    // stretched row under unbounded constraints asked it to be infinitely
    // tall. It threw before it ever reached the screen.
    await pump(tester, department());

    expect(tester.takeException(), isNull);
    expect(find.text('التشطيب'), findsOneWidget);
  });

  testWidgets('names its stages with their restoration type', (tester) async {
    await pump(
      tester,
      department(
        stages: const [
          {
            'id': 's1',
            'name': 'التلميع',
            'restorationTypeNameAr': 'زيركون',
            'activeCount': 2,
          },
        ],
      ),
    );

    expect(find.text('التلميع · زيركون'), findsOneWidget);
  });

  testWidgets('carries its own bottom margin so rows do not touch', (
    tester,
  ) async {
    // AdaptiveCollection sets the grid's `mainAxisSpacing` to zero on the
    // understanding that every card supplies this. A card without it renders
    // flush against the next one.
    await pump(tester, department());

    final card = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(DepartmentCard),
            matching: find.byType(Container),
          )
          .first,
    );

    expect(card.margin, isNotNull);
    expect((card.margin as EdgeInsets).bottom, greaterThan(0));
  });

  testWidgets('warns when no stage is linked', (tester) async {
    // A department nothing is routed to looks identical to a working one
    // unless it is said out loud.
    await pump(tester, department());

    expect(find.textContaining('لن يصل هذا القسم أي عمل'), findsOneWidget);
  });
}

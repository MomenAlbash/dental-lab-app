import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/case_list_item_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_breakdown_group.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_list_item_widget.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_restoration_breakdown_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

CaseListItemModel _case({
  List<CaseRestorationBreakdownGroup> breakdown = const [],
  int restorationsCount = 4,
}) => CaseListItemModel(
  id: 'c1',
  caseNumber: '1247',
  patientName: 'منى',
  restorationsCount: restorationsCount,
  restorationBreakdown: breakdown,
);

CaseRestorationBreakdownGroup _group({
  String? stageId = 's1',
  String? stageNameAr = 'التشطيب',
  String typeAr = 'زيركون',
  int count = 1,
}) => CaseRestorationBreakdownGroup(
  restorationTypeNameAr: typeAr,
  stageId: stageId,
  stageNameAr: stageNameAr,
  count: count,
);

/// A bare app — **no `getIt`, no cubit, no provider of any kind.**
///
/// That absence is the point: a sheet that needed a request could not build in
/// this tree at all, so rendering here is proof it makes none.
Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

/// Opens the sheet from a button, the way the row does.
Widget _opener(CaseListItemModel caseItem) => Builder(
  builder: (context) => TextButton(
    onPressed: () =>
        showCaseRestorationBreakdownSheet(context, caseItem: caseItem),
    child: const Text('افتح'),
  ),
);

Widget _row({VoidCallback? onShowBreakdown, VoidCallback? onDelete}) =>
    CaseListItemWidget(
      caseNumber: '1247',
      patientName: 'منى',
      doctorName: 'سامر',
      stageName: 'التشطيب',
      stageColor: Colors.blue,
      isLate: false,
      priorityLabel: 'عادية',
      priorityColor: Colors.grey,
      onTap: () {},
      onShowBreakdown: onShowBreakdown,
      onDelete: onDelete,
    );

Future<void> _pumpAt(WidgetTester tester, Widget child, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap(child));
  await tester.pumpAndSettle();
}

void main() {
  group('the row button', () {
    testWidgets('is hidden when there is no breakdown to show', (tester) async {
      await tester.pumpWidget(_wrap(_row(onDelete: () {})));

      expect(find.byIcon(Icons.account_tree_outlined), findsNothing);
      // Delete is unaffected by the new neighbour.
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('appears beside delete when a breakdown exists', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_row(onShowBreakdown: () {}, onDelete: () {})),
      );

      expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('stands alone on a row that cannot be deleted', (tester) async {
      await tester.pumpWidget(_wrap(_row(onShowBreakdown: () {})));

      expect(find.byIcon(Icons.account_tree_outlined), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('a dashboard-style row carries neither action', (tester) async {
      // The dashboard opts out of both by passing neither — the proof that
      // both parameters are genuinely optional.
      await tester.pumpWidget(_wrap(_row()));

      expect(find.byIcon(Icons.account_tree_outlined), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('the row survives 320dp with both trailing actions', (
      tester,
    ) async {
      // Widget tests default to an 800dp window, which is a tablet — the size
      // must be set explicitly or this silently asserts against the wrong
      // layout. The second button costs the content column 32dp, and the
      // patient name is what gives way.
      await _pumpAt(
        tester,
        _row(onShowBreakdown: () {}, onDelete: () {}),
        const Size(320, 800),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('the sheet', () {
    testWidgets('opens with no provider in the tree, so it makes no request', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_opener(_case(breakdown: [_group()]))),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل التعويضات'), findsOneWidget);
      // No spinner ever appears: there is nothing to wait for.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('lists every group with its count and stage', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _opener(
            _case(
              breakdown: [
                _group(typeAr: 'زيركون', stageNameAr: 'التشطيب', count: 2),
                _group(typeAr: 'بورسلان', stageNameAr: 'الصب'),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.text('زيركون'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.text('التشطيب'), findsOneWidget);
      expect(find.text('بورسلان'), findsOneWidget);
      expect(find.text('الصب'), findsOneWidget);
    });

    testWidgets('says لم تبدأ instead of naming a stage it has none of', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _opener(
            _case(
              breakdown: [_group(stageId: null, stageNameAr: null)],
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.text('لم تبدأ'), findsOneWidget);
      // And explains it, so the phrase does not read as a fault.
      expect(find.text('التعويض يبدأ مساره بعد اعتماد خطّته'), findsOneWidget);
    });

    testWidgets('does not explain itself when every group has started', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(_opener(_case(breakdown: [_group()]))),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.text('التعويض يبدأ مساره بعد اعتماد خطّته'), findsNothing);
    });

    testWidgets('shows the server total, never the sum of the groups', (
      tester,
    ) async {
      // The breakdown sums to 3, the server says 4. The header must say 4 —
      // summing here would publish a figure the server never sent.
      await tester.pumpWidget(
        _wrap(
          _opener(
            _case(
              restorationsCount: 4,
              breakdown: [_group(count: 2), _group(count: 1)],
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      expect(find.textContaining('4 تعويض'), findsOneWidget);
    });

    testWidgets('draws not-started groups after the started ones', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          _opener(
            _case(
              breakdown: [
                _group(stageId: null, stageNameAr: null, typeAr: 'بورسلان'),
                _group(typeAr: 'زيركون'),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      final started = tester.getTopLeft(find.text('زيركون')).dy;
      final notStarted = tester.getTopLeft(find.text('بورسلان')).dy;
      expect(started, lessThan(notStarted));
    });
  });
}

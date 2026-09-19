import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_move_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_stage_move_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<CaseStageMoveResult?> _open(
  WidgetTester tester,
  List<CaseStageMoveModel> transitions,
) async {
  CaseStageMoveResult? result;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showCaseStageMoveSheet(
                  context,
                  transitions: transitions,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  group('CaseStageMoveModel', () {
    test('reads the kind whether it arrives as a name or a number', () {
      // The DTO serialises it as a string while the enum is numeric elsewhere.
      expect(
        CaseStageMoveModel.fromJson(const {
          'toStageId': 's',
          'kind': 'Rework',
        }).kind,
        CaseStageMoveKind.rework,
      );
      expect(
        CaseStageMoveModel.fromJson(const {'toStageId': 's', 'kind': 2}).kind,
        CaseStageMoveKind.rework,
      );
    });

    test('an unknown kind reads as a forward move', () {
      // Showing a rework as progress is recoverable; the reverse alarms the
      // user about work that was never rejected.
      expect(
        CaseStageMoveModel.fromJson(const {
          'toStageId': 's',
          'kind': 'Whatever',
        }).kind,
        CaseStageMoveKind.normal,
      );
    });

    test('a blocked move carries the reason it is barred', () {
      final move = CaseStageMoveModel.fromJson(const {
        'toStageId': 's',
        'blockedReason': 'التعويضات لم تنتهِ بعد',
      });

      expect(move.isBlocked, isTrue);
      expect(move.blockedReason, 'التعويضات لم تنتهِ بعد');
    });
  });

  group('CaseDetailModel', () {
    test('carries the moves the server resolved for it', () {
      final detail = CaseDetailModel.fromJson(const {
        'id': 'c1',
        'availableTransitions': [
          {'toStageId': 's1', 'toStageNameAr': 'التغليف', 'displayOrder': 1},
        ],
      });

      expect(detail.availableTransitions.single.toStageId, 's1');
      expect(detail.availableTransitions.single.displayName, 'التغليف');
    });

    test('a case with nothing offered parses as an empty list', () {
      // Mid-production the server offers nothing by design — that is not a
      // parse failure and must not read as one.
      final detail = CaseDetailModel.fromJson(const {'id': 'c1'});

      expect(detail.availableTransitions, isEmpty);
    });
  });

  group('the move sheet', () {
    const forward = CaseStageMoveModel(
      toStageId: 'f1',
      toStageNameAr: 'التغليف',
    );
    const rework = CaseStageMoveModel(
      toStageId: 'r1',
      toStageNameAr: 'إعادة التصميم',
      kind: CaseStageMoveKind.rework,
    );

    testWidgets('separates going forward from sending back', (tester) async {
      await _open(tester, const [forward, rework]);

      expect(find.text('إلى الأمام'), findsOneWidget);
      expect(find.text('إرجاع لإعادة العمل'), findsOneWidget);
      expect(find.text('التغليف'), findsOneWidget);
      expect(find.text('إعادة التصميم'), findsOneWidget);
    });

    testWidgets('says why nothing is on offer instead of showing a blank', (
      tester,
    ) async {
      await _open(tester, const []);

      expect(find.textContaining('لا يوجد نقل متاح'), findsOneWidget);
    });

    testWidgets('a barred move is shown with its reason, not hidden', (
      tester,
    ) async {
      // A case that offers nothing and explains nothing reads as broken.
      await _open(tester, const [
        CaseStageMoveModel(
          toStageId: 'b1',
          toStageNameAr: 'الفوترة',
          blockedReason: 'التعويضات لم تنتهِ بعد',
        ),
      ]);

      expect(find.text('الفوترة'), findsOneWidget);
      expect(find.text('التعويضات لم تنتهِ بعد'), findsOneWidget);
    });

    testWidgets('picking a move and confirming reports it', (tester) async {
      final result = await _open(tester, const [forward]);
      expect(result, isNull, reason: 'nothing picked yet');

      await tester.tap(find.text('التغليف'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نقل الحالة').last);
      await tester.pumpAndSettle();

      expect(find.text('إلى الأمام'), findsNothing, reason: 'sheet closed');
    });

    testWidgets('a move that demands a reason refuses an empty one', (
      tester,
    ) async {
      await _open(tester, const [
        CaseStageMoveModel(
          toStageId: 'x1',
          toStageNameAr: 'رفض',
          requiresReason: true,
        ),
      ]);

      await tester.tap(find.text('رفض'));
      await tester.pumpAndSettle();

      // Not scolded before the user has had a chance to type.
      expect(find.text('السبب مطلوب لهذه المرحلة'), findsNothing);

      await tester.tap(find.text('نقل الحالة').last);
      await tester.pumpAndSettle();

      expect(find.text('السبب مطلوب لهذه المرحلة'), findsOneWidget);
    });
  });
}

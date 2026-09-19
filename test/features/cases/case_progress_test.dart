import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_flow_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_intake_enums.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:dental_lab_app/features/cases/logic/case_progress/case_progress_state.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_progress_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CaseFlowStageModel _stage(
  String id, {
  required int order,
  CaseFlowNodeStatus status = CaseFlowNodeStatus.pending,
}) => CaseFlowStageModel(stageId: id, nameAr: id, order: order, status: status);

/// A board with two case stages running alongside production, one after it,
/// and a single restoration — the shape almost every lab's flow has.
CaseProgressLoaded _board({
  String? currentCaseStageId,
  String? restorationStageId,
  List<String> restorationRoute = const [],
  bool restorationFinished = false,
}) {
  CaseFlowNodeStatus caseStatus(String id, int index) {
    if (id == currentCaseStageId) return CaseFlowNodeStatus.current;
    final currentIndex = ['استلام', 'كونترول', 'التغليف'].indexOf(
      currentCaseStageId ?? '',
    );
    return currentIndex > index
        ? CaseFlowNodeStatus.done
        : CaseFlowNodeStatus.pending;
  }

  final currentRouteIndex = restorationRoute.indexOf(restorationStageId ?? '');

  final flow = CaseFlowModel(
    caseId: 'c1',
    phases: [
      CaseFlowPhaseModel(
        phase: CasePhase.inProduction,
        status: CaseFlowNodeStatus.current,
        production: CaseFlowProductionModel(
          beforeStages: [
            _stage('استلام', order: 0, status: caseStatus('استلام', 0)),
            _stage('كونترول', order: 1, status: caseStatus('كونترول', 1)),
          ],
          restorations: [
            CaseFlowRestorationModel(
              restorationId: 'r1',
              restorationTypeNameAr: 'زيركون',
              stages: [
                for (var i = 0; i < restorationRoute.length; i++)
                  _stage(
                    restorationRoute[i],
                    order: i,
                    status: restorationFinished
                        ? CaseFlowNodeStatus.done
                        : i == currentRouteIndex
                        ? CaseFlowNodeStatus.current
                        : i < currentRouteIndex
                        ? CaseFlowNodeStatus.done
                        : CaseFlowNodeStatus.pending,
                  ),
              ],
            ),
          ],
          afterStages: [
            _stage('التغليف', order: 2, status: caseStatus('التغليف', 2)),
          ],
        ),
      ),
    ],
  );

  return CaseProgressLoaded(
    caseDetail: CaseDetailModel.fromJson({'id': 'c1'}),
    flow: flow,
    restorations: [
      RestorationProgress(
        flow: flow.restorations.first,
        restoration: CaseRestorationModel(
          id: 'r1',
          isFinished: restorationFinished,
        ),
      ),
    ],
  );
}

void main() {
  group('CaseFlowModel', () {
    test('reads the production sub-tree off whichever phase carries it', () {
      final flow = CaseFlowModel.fromJson({
        'caseId': 'c1',
        'currentPhase': 3,
        'phases': [
          {'phase': 1, 'status': 1},
          {
            'phase': 3,
            'status': 2,
            'production': {
              'beforeStages': [
                {'stageId': 's1', 'nameAr': 'استلام', 'order': 0, 'status': 1},
              ],
              'restorations': [
                {
                  'restorationId': 'r1',
                  'stages': [
                    {'stageId': 'x', 'nameAr': 'تصميم', 'status': 2},
                  ],
                },
              ],
              'afterStages': [
                {'stageId': 's2', 'nameAr': 'تغليف', 'order': 2, 'status': 3},
              ],
            },
          },
        ],
      });

      expect(flow.currentPhase, CasePhase.inProduction);
      expect(flow.beforeStages.single.displayName, 'استلام');
      expect(flow.afterStages.single.displayName, 'تغليف');
      expect(flow.restorations.single.currentStage?.displayName, 'تصميم');
    });

    test('an unknown node status reads as pending, never as done', () {
      // Drawing an unrecognised node as "not there yet" is recoverable;
      // drawing it as finished is a lie about work that may not exist.
      expect(CaseFlowNodeStatus.fromValue(99), CaseFlowNodeStatus.pending);
      expect(CaseFlowNodeStatus.fromValue(null), CaseFlowNodeStatus.pending);
    });

    test('a skipped node counts as finished for the barrier', () {
      // A lab that requires no quality check skips that node; the pieces
      // below must not wait forever on a stage nobody will ever enter.
      final flow = CaseFlowModel(
        caseId: 'c1',
        phases: [
          CaseFlowPhaseModel(
            phase: CasePhase.inProduction,
            production: CaseFlowProductionModel(
              restorations: [
                CaseFlowRestorationModel(
                  restorationId: 'r1',
                  stages: [
                    _stage('a', order: 0, status: CaseFlowNodeStatus.done),
                    _stage('b', order: 1, status: CaseFlowNodeStatus.skipped),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

      expect(flow.restorationsFinished, isTrue);
    });

    test('receivedVia is turned into a sentence, not shown as a key', () {
      const phase = CaseFlowPhaseModel(
        phase: CasePhase.received,
        receivedVia: 'digital-rep-session',
      );
      expect(phase.receivedViaLabel, 'مسح رقمي بجلسة مندوب');

      // An intake route this client has not been taught yet still says
      // something true rather than nothing.
      const unknown = CaseFlowPhaseModel(
        phase: CasePhase.received,
        receivedVia: 'carrier-pigeon',
      );
      expect(unknown.receivedViaLabel, 'carrier-pigeon');
    });
  });

  group('RestorationProgress', () {
    test('takes isFinished from the server, not from position', () {
      // A piece holding a parallel step sits on more than one stage at once,
      // which any client-side "is it on the last one" check gets wrong.
      final progress = RestorationProgress(
        flow: CaseFlowRestorationModel(
          restorationId: 'r1',
          stages: [
            _stage('تصميم', order: 0, status: CaseFlowNodeStatus.done),
            _stage('تزجيج', order: 1, status: CaseFlowNodeStatus.current),
          ],
        ),
        restoration: CaseRestorationModel(id: 'r1', isFinished: true),
      );

      expect(progress.isFinished, isTrue);
      expect(progress.currentStageId, 'تزجيج');
    });

    test('falls back to the flow when the detail row is missing', () {
      final progress = RestorationProgress(
        flow: CaseFlowRestorationModel(
          restorationId: 'r1',
          restorationTypeNameAr: 'زيركون',
          stages: [_stage('تصميم', order: 0, status: CaseFlowNodeStatus.done)],
        ),
      );

      expect(progress.title, 'زيركون');
      expect(progress.isFinished, isTrue);
    });

    test('a piece with no route claims nothing', () {
      final progress = RestorationProgress(
        flow: CaseFlowRestorationModel(restorationId: 'r1'),
      );

      expect(progress.isFinished, isFalse);
      expect(progress.currentStageId, isNull);
    });
  });

  group('CaseProgressLoaded', () {
    test('knows which half the case is standing in', () {
      final onFirst = _board(currentCaseStageId: 'كونترول');
      expect(onFirst.isOnFirstHalf, isTrue);
      expect(onFirst.isOnSecondHalf, isFalse);

      final onSecond = _board(currentCaseStageId: 'التغليف');
      expect(onSecond.isOnSecondHalf, isTrue);
      expect(onSecond.isOnFirstHalf, isFalse);
    });

    test('mid-production the case stands in neither half', () {
      // Its own stages are done and the units are running — that is the
      // restorations band, not a bug.
      final board = _board(currentCaseStageId: 'مرحلة-غير-معروفة');

      expect(board.isOnFirstHalf, isFalse);
      expect(board.isOnSecondHalf, isFalse);
    });

    test('the pieces are released on the last parallel stage', () {
      // Blocking there too was a deadlock: the case cannot leave its last
      // parallel stage except by entering production, and production is what
      // the restorations are.
      expect(_board(currentCaseStageId: 'استلام').blocksRestorations, isTrue);
      expect(_board(currentCaseStageId: 'كونترول').blocksRestorations, isFalse);
    });

    test('the after-production stages are barred while pieces run', () {
      final running = _board(
        currentCaseStageId: 'كونترول',
        restorationStageId: 'تصميم',
        restorationRoute: const ['تصميم', 'تزجيج'],
      );
      expect(running.barredStageIds, {'التغليف'});

      final done = _board(
        currentCaseStageId: 'كونترول',
        restorationRoute: const ['تصميم', 'تزجيج'],
        restorationFinished: true,
      );
      expect(done.barredStageIds, isEmpty);
    });
  });

  group('CaseProgressView', () {
    Widget wrap(CaseProgressLoaded state) => MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: CaseProgressView(
            state: state,
            onMoveCase: () {},
            onMoveRestoration: (_) {},
            phaseCard: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    testWidgets('draws the bands in the order work happens', (tester) async {
      await tester.pumpWidget(wrap(_board(currentCaseStageId: 'كونترول')));
      await tester.pumpAndSettle();

      expect(find.text('دورة حياة الحالة'), findsOneWidget);
      expect(find.text('بالتوازي مع الإنتاج'), findsOneWidget);
      expect(find.text('التعويضات'), findsOneWidget);
      expect(find.text('بعد الإنتاج'), findsOneWidget);
      expect(find.text('1. استلام'), findsOneWidget);
      expect(find.text('2. كونترول'), findsOneWidget);
    });

    testWidgets('marks where the case is standing now', (tester) async {
      await tester.pumpWidget(wrap(_board(currentCaseStageId: 'كونترول')));
      await tester.pumpAndSettle();

      // The case stage, plus the phase node the server marked current.
      expect(find.text('الآن'), findsNWidgets(2));
    });

    testWidgets('offers the move where the stages are being read', (
      tester,
    ) async {
      var moved = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: CaseProgressView(
                state: _board(currentCaseStageId: 'كونترول'),
                onMoveCase: () => moved = true,
                onMoveRestoration: (_) {},
                phaseCard: const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('نقل الحالة'));
      await tester.pumpAndSettle();

      expect(moved, isTrue);
    });

    testWidgets('says why the after-production half is waiting', (
      tester,
    ) async {
      // The barrier is exactly what makes a case look stuck to someone who
      // does not know the rule.
      await tester.pumpWidget(
        wrap(
          _board(
            currentCaseStageId: 'كونترول',
            restorationStageId: 'تصميم',
            restorationRoute: const ['تصميم', 'تزجيج'],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('لا تبدأ حتى تنتهي كل التعويضات'), findsOneWidget);
    });

    testWidgets('a skipped node is drawn, struck through, not hidden', (
      tester,
    ) async {
      // Two cases of the same type must not look like they ran different
      // routes because one lab setting removed a step.
      final board = _board(currentCaseStageId: 'كونترول');
      final flow = CaseFlowModel(
        caseId: 'c1',
        phases: [
          const CaseFlowPhaseModel(
            phase: CasePhase.qualityCheck,
            status: CaseFlowNodeStatus.skipped,
          ),
          ...board.flow.phases,
        ],
      );

      await tester.pumpWidget(
        wrap(
          CaseProgressLoaded(
            caseDetail: board.caseDetail,
            flow: flow,
            restorations: board.restorations,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1. فحص الجودة'), findsOneWidget);
      expect(find.text('متجاوَزة'), findsOneWidget);
    });
  });
}

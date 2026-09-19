import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_stage_summary.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_details_body.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:mocktail/mocktail.dart';

/// The barcode section fetches the case's print ticket as soon as it builds.
class _MockCasesRepo extends Mock implements CasesRepo {}

CaseDetailModel _caseDetail() => CaseDetailModel(
  id: '1',
  caseNumber: 'C-1001',
  referenceNumber: 'REF-77',
  patientName: 'خالد المصري',
  priorityId: 'p1',
  priorityNameAr: 'عاجلة',
  priorityName: 'Urgent',
  stage: const CaseStageSummary(
    stageId: 's1',
    stageNameAr: 'قيد التنفيذ',
    stageBadgeVariant: 'warning',
  ),
  doctor: DoctorModel(id: 'd1', firstName: 'أحمد', lastName: 'الخطيب'),
  clinic: ClinicModel(id: 'c1', name: 'عيادة النور'),
  dueDate: '2026-09-01T00:00:00',
);

Widget _wrap(CaseDetailModel caseDetail) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(
      body: CaseDetailsBody(
        caseDetail: caseDetail,
        isBusy: false,
        onChangeStage: (_) {},
        onAddFile: () {},
        onOpenFile: (_) {},
        onDeleteFile: (_) {},
      ),
    ),
  );
}

void main() {
  setUp(() {
    final repo = _MockCasesRepo();
    when(() => repo.getCasePrintTicket(any())).thenAnswer(
      (_) async => right(
        const CasePrintTicketModel(
          caseNumber: 'C-1001',
          qrPayload: 'CASE-C-1001',
        ),
      ),
    );
    getIt.registerLazySingleton<CasesRepo>(() => repo);
  });

  tearDown(() => getIt.reset());

  testWidgets('shows the identity panel and info tiles at 360dp', (
    tester,
  ) async {
    // Small-phone breakpoint per CLAUDE.md Section C.6.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(_caseDetail()));
    await tester.pumpAndSettle();

    expect(find.text('خالد المصري'), findsOneWidget);
    expect(find.text('رقم الحالة: C-1001'), findsOneWidget);
    // Status and priority read as pills on the panel.
    expect(find.text('قيد التنفيذ'), findsOneWidget);
    expect(find.text('عاجلة'), findsOneWidget);
    // The tile mosaic replaced the divided label/value rows.
    expect(find.text('المعلومات'), findsOneWidget);
    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('عيادة النور'), findsOneWidget);
    // A RenderFlex overflow surfaces here.
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty attributes fall back to a dash, not a blank tile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(CaseDetailModel(id: '1')));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

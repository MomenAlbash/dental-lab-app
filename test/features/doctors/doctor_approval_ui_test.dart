import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_approval_panel.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctors_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

class _MockClinicsRepo extends Mock implements ClinicsRepo {}

DoctorModel _doctor(
  String id,
  String first, {
  DoctorApprovalStatus status = DoctorApprovalStatus.approved,
  String? requestedClinicName,
  String? rejectionReason,
}) => DoctorModel(
  id: id,
  firstName: first,
  lastName: 'الخطيب',
  approvalStatus: status,
  requestedClinicName: requestedClinicName,
  rejectionReason: rejectionReason,
);

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

void main() {
  void usePhoneScreen(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);
  }

  group('the list', () {
    late DoctorsCubit cubit;
    late TextEditingController searchController;

    setUp(() {
      final repo = _MockDoctorsRepo();
      when(
        () => repo.getDoctors(),
      ).thenAnswer((_) async => Right<Failure, List<DoctorModel>>(const []));
      cubit = DoctorsCubit(repo);
      searchController = TextEditingController();
    });

    tearDown(() {
      cubit.close();
      searchController.dispose();
    });

    Widget listOf(List<DoctorModel> doctors) => _wrap(
      BlocProvider.value(
        value: cubit,
        child: DoctorsListView(
          doctors: doctors,
          searchController: searchController,
          searchQuery: '',
          onDelete: (_) {},
        ),
      ),
    );

    testWidgets('a pending doctor is badged on the card', (tester) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(
        listOf([_doctor('1', 'أحمد', status: DoctorApprovalStatus.pending)]),
      );
      await tester.pumpAndSettle();

      expect(find.text('قيد الانتظار'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an approved doctor carries no badge', (tester) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(listOf([_doctor('1', 'أحمد')]));
      await tester.pumpAndSettle();

      expect(find.text('مقبول'), findsNothing);
      expect(find.text('قيد الانتظار'), findsNothing);
    });

    testWidgets('pending doctors are listed first', (tester) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(
        listOf([
          _doctor('1', 'سارة'),
          _doctor('2', 'خالد', status: DoctorApprovalStatus.pending),
          _doctor('3', 'ليلى'),
        ]),
      );
      await tester.pumpAndSettle();

      final pending = tester.getTopLeft(find.text('خالد الخطيب')).dy;
      final approved = tester.getTopLeft(find.text('سارة الخطيب')).dy;
      expect(pending, lessThan(approved));
    });

    testWidgets('the rest keep the order they arrived in', (tester) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(
        listOf([
          _doctor('1', 'سارة'),
          _doctor('2', 'ليلى'),
          _doctor('3', 'خالد', status: DoctorApprovalStatus.pending),
        ]),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('سارة الخطيب')).dy,
        lessThan(tester.getTopLeft(find.text('ليلى الخطيب')).dy),
      );
    });
  });

  group('the review panel', () {
    setUp(() async {
      final clinicsRepo = _MockClinicsRepo();
      when(() => clinicsRepo.getClinics()).thenAnswer(
        (_) async => Right<Failure, List<ClinicModel>>([
          ClinicModel(id: 'c1', name: 'عيادة الشفاء'),
        ]),
      );

      await getIt.reset();
      getIt.registerFactory<ClinicsCubit>(() => ClinicsCubit(clinicsRepo));
    });

    tearDown(() => getIt.reset());

    Widget panelFor(
      DoctorModel doctor, {
      ValueChanged<ApprovalChoice>? onApprove,
      ValueChanged<String>? onReject,
    }) => _wrap(
      DoctorApprovalPanel(
        doctor: doctor,
        isBusy: false,
        onApprove: onApprove ?? (_) {},
        onReject: onReject ?? (_) {},
      ),
    );

    testWidgets('shows nothing at all for an approved doctor', (tester) async {
      await tester.pumpWidget(panelFor(_doctor('1', 'أحمد')));

      expect(find.text('قبول'), findsNothing);
      expect(find.text('رفض'), findsNothing);
    });

    testWidgets('offers both decisions and names the requested clinic', (
      tester,
    ) async {
      usePhoneScreen(tester);

      await tester.pumpWidget(
        panelFor(
          _doctor(
            '1',
            'أحمد',
            status: DoctorApprovalStatus.pending,
            requestedClinicName: 'عيادة النور',
          ),
        ),
      );

      expect(find.text('تسجيل بانتظار المراجعة'), findsOneWidget);
      expect(find.text('العيادة المطلوبة: عيادة النور'), findsOneWidget);
      expect(find.text('قبول'), findsOneWidget);
      expect(find.text('رفض'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('approving creates the clinic the doctor asked for', (
      tester,
    ) async {
      ApprovalChoice? choice;
      await tester.pumpWidget(
        panelFor(
          _doctor(
            '1',
            'أحمد',
            status: DoctorApprovalStatus.pending,
            requestedClinicName: 'عيادة النور',
          ),
          onApprove: (value) => choice = value,
        ),
      );

      await tester.tap(find.text('قبول'));
      await tester.pumpAndSettle();
      // The dialog defaults to creating the requested clinic.
      await tester.tap(find.widgetWithText(TextButton, 'قبول'));
      await tester.pumpAndSettle();

      expect(choice?.newClinicName, 'عيادة النور');
      expect(choice?.clinicId, isNull);
    });

    testWidgets('approving without picking a clinic is blocked', (
      tester,
    ) async {
      // A doctor cannot be approved with no clinic: the rest of the app is
      // organised around the clinic listings, and the doctor form requires one
      // too. There is no "approve without a clinic" option to fall back to.
      ApprovalChoice? choice;
      await tester.pumpWidget(
        panelFor(
          // No requested clinic, so the dialog opens on the existing-clinic
          // list with nothing selected.
          _doctor('1', 'أحمد', status: DoctorApprovalStatus.pending),
          onApprove: (value) => choice = value,
        ),
      );

      await tester.tap(find.text('قبول'));
      await tester.pumpAndSettle();
      expect(find.text('بدون عيادة الآن'), findsNothing);

      await tester.tap(find.widgetWithText(TextButton, 'قبول'));
      await tester.pumpAndSettle();

      expect(find.text('اختر العيادة أولاً'), findsOneWidget);
      expect(choice, isNull);
    });

    testWidgets('approving links the chosen existing clinic', (tester) async {
      ApprovalChoice? choice;
      await tester.pumpWidget(
        panelFor(
          _doctor('1', 'أحمد', status: DoctorApprovalStatus.pending),
          onApprove: (value) => choice = value,
        ),
      );

      await tester.tap(find.text('قبول'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('عيادة الشفاء').last);
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'قبول'));
      await tester.pumpAndSettle();

      expect(choice?.clinicId, 'c1');
      expect(choice?.newClinicName, isNull);
    });

    testWidgets('rejecting requires a reason and passes it along', (
      tester,
    ) async {
      String? reason;
      await tester.pumpWidget(
        panelFor(
          _doctor('1', 'أحمد', status: DoctorApprovalStatus.pending),
          onReject: (value) => reason = value,
        ),
      );

      await tester.tap(find.text('رفض'));
      await tester.pumpAndSettle();

      // Confirming with an empty field must not close the dialog.
      await tester.tap(find.widgetWithText(TextButton, 'رفض'));
      await tester.pumpAndSettle();
      expect(find.text('اكتب سبب الرفض'), findsOneWidget);
      expect(reason, isNull);

      await tester.enterText(find.byType(TextFormField), 'بيانات غير مكتملة');
      await tester.tap(find.widgetWithText(TextButton, 'رفض'));
      await tester.pumpAndSettle();

      expect(reason, 'بيانات غير مكتملة');
    });

    testWidgets('a rejected doctor shows why', (tester) async {
      await tester.pumpWidget(
        panelFor(
          _doctor(
            '1',
            'أحمد',
            status: DoctorApprovalStatus.rejected,
            rejectionReason: 'بيانات غير مكتملة',
          ),
        ),
      );

      expect(find.text('تم رفض التسجيل'), findsOneWidget);
      expect(find.text('السبب: بيانات غير مكتملة'), findsOneWidget);
      // No decision buttons: it has already been made.
      expect(find.text('قبول'), findsNothing);
    });
  });
}

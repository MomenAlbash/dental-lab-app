import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctors_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

DoctorModel _doctor(
  String id,
  String first,
  String last, {
  String? clinic,
  bool isActive = true,
}) {
  return DoctorModel(
    id: id,
    firstName: first,
    lastName: last,
    phoneNumber: '0991234567',
    isActive: isActive,
    clinic: clinic == null ? null : ClinicModel(id: 'c-$id', name: clinic),
  );
}

void main() {
  late _MockDoctorsRepo repo;
  late DoctorsCubit cubit;

  setUp(() {
    repo = _MockDoctorsRepo();
    when(
      () => repo.getDoctors(),
    ).thenAnswer((_) async => Right<Failure, List<DoctorModel>>(const []));
    cubit = DoctorsCubit(repo);
  });

  tearDown(() => cubit.close());

  Widget wrap(
    List<DoctorModel> doctors, {
    ThemeData? theme,
    String searchQuery = '',
    required TextEditingController controller,
    ScrollController? scrollController,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.light,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: BlocProvider.value(
          value: cubit,
          child: DoctorsListView(
            doctors: doctors,
            searchController: controller,
            scrollController: scrollController,
            searchQuery: searchQuery,
            onDelete: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders doctor rows without overflow at 360dp width', (
    tester,
  ) async {
    // Small-phone breakpoint per CLAUDE.md Section C.6.
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap([
        _doctor('1', 'أحمد', 'الخطيب', clinic: 'عيادة النور'),
        _doctor('2', 'سارة', 'العلي'),
      ], controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('سارة العلي'), findsOneWidget);
    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.text('بدون عيادة'), findsOneWidget);
    // A RenderFlex overflow surfaces here.
    expect(tester.takeException(), isNull);
  });

  testWidgets('rows survive a 2.0x text scale at 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: wrap([
          _doctor('1', 'أحمد', 'الخطيب', clinic: 'عيادة النور'),
        ], controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('summary strip counts total, active and paused doctors', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap([
        _doctor('1', 'أحمد', 'الخطيب'),
        _doctor('2', 'سارة', 'العلي'),
        _doctor('3', 'زياد', 'حسن', isActive: false),
      ], controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // total
    expect(find.text('2'), findsOneWidget); // active
    expect(find.text('1'), findsOneWidget); // paused
  });

  testWidgets('tapping a summary tile filters the rows by status', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap([
        _doctor('1', 'أحمد', 'الخطيب'),
        _doctor('3', 'زياد', 'حسن', isActive: false),
      ], controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('زياد حسن'), findsOneWidget);

    await tester.tap(find.text('موقوف'));
    await tester.pumpAndSettle();

    expect(find.text('أحمد الخطيب'), findsNothing);
    expect(find.text('زياد حسن'), findsOneWidget);

    await tester.tap(find.text('الكل'));
    await tester.pumpAndSettle();

    expect(find.text('أحمد الخطيب'), findsOneWidget);
  });

  testWidgets('a status filter with no matches explains itself', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap([_doctor('1', 'أحمد', 'الخطيب')], controller: controller),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('موقوف'));
    await tester.pumpAndSettle();

    // Distinct from the "no doctors yet" copy, so the user knows a filter is
    // hiding the rows rather than the list being empty.
    expect(find.text('لا يوجد دكاترة بهذه الحالة'), findsOneWidget);
  });

  testWidgets('rows show initials, clinic and a call chip', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap([
        _doctor('1', 'أحمد', 'الخطيب', clinic: 'عيادة النور'),
      ], controller: controller),
    );
    await tester.pumpAndSettle();

    // Initials match the detail screen's avatar so the Hero flight is seamless.
    expect(find.text('أا'), findsOneWidget);
    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.text('0991234567'), findsOneWidget);
    expect(find.byIcon(Icons.call_outlined), findsOneWidget);
  });

  testWidgets('pull-to-refresh works on a list shorter than the viewport', (
    tester,
  ) async {
    // Regression: with default physics a short list cannot overscroll, so the
    // gesture never reached the RefreshIndicator and refreshing did nothing.
    //
    // Pinned to a phone width: the default test window is 800dp, which is a
    // tablet, and there the rows are a grid rather than a list.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap([_doctor('1', 'أحمد', 'الخطيب')], controller: controller),
    );
    await tester.pumpAndSettle();

    // One row only — nowhere near filling the viewport.
    verifyNever(() => repo.getDoctors());

    await tester.fling(find.byType(ListView), const Offset(0, 320), 1200);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => repo.getDoctors()).called(1);

    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('drives the supplied scroll controller', (tester) async {
    // The page watches this controller to collapse the add button, so the list
    // must actually attach it. Pinned to a phone width — see above.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    final scrollController = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      wrap(
        [for (var i = 0; i < 15; i++) _doctor('$i', 'دكتور', '$i')],
        controller: controller,
        scrollController: scrollController,
      ),
    );
    await tester.pumpAndSettle();

    expect(scrollController.hasClients, isTrue);
    expect(scrollController.offset, 0);

    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(40));

    // Rows scrolled out mid-drag leave flutter_animate stagger timers behind;
    // drain them so the binding's "timer still pending" check passes.
    await tester.pumpAndSettle(const Duration(seconds: 1));
  });

  testWidgets('shows the empty state when there are no doctors', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(const [], controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد دكاترة بعد'), findsOneWidget);
    expect(find.byIcon(Icons.person_add_alt), findsOneWidget);
  });

  testWidgets('shows the no-results state while searching', (tester) async {
    final controller = TextEditingController(text: 'زياد');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(const [], controller: controller, searchQuery: 'زياد'),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا توجد نتائج'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        [_doctor('1', 'أحمد', 'الخطيب')],
        theme: AppTheme.dark,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

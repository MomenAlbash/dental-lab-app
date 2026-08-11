import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_day_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/repos/scanner_availability_repo.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_calendar/scanner_calendar_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_exceptions/scanner_exceptions_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/scanner_availability_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements ScannerAvailabilityRepo {}

late _MockRepo repo;

Widget _wrap() => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('ar'),
  supportedLocales: const [Locale('ar'), Locale('en')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: const ScannerAvailabilityPage(),
);

Future<void> _pumpAt(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    repo = _MockRepo();

    when(() => repo.getRules()).thenAnswer(
      (_) async => right([
        ScannerAvailabilityRuleModel(
          id: 'r1',
          dayOfWeek: 2,
          startTime: const TimeOfDay(hour: 9, minute: 0),
          endTime: const TimeOfDay(hour: 17, minute: 0),
          slotMinutes: 30,
        ),
      ]),
    );
    when(
      () => repo.getExceptions(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => right([
        ScannerAvailabilityExceptionModel(
          id: 'e1',
          date: DateTime(2026, 4, 1),
          isClosed: true,
          reason: 'عطلة رسمية',
        ),
      ]),
    );
    when(
      () => repo.getCalendar(
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer(
      (_) async => right([
        ScannerDayModel(
          date: DateTime(2026, 4, 3),
          isOpen: true,
          slots: const [
            ScannerSlotModel(isAvailable: true, remainingCapacity: 1),
          ],
        ),
      ]),
    );

    await getIt.reset();
    getIt.registerFactory<ScannerRulesCubit>(() => ScannerRulesCubit(repo));
    getIt.registerFactory<ScannerExceptionsCubit>(
      () => ScannerExceptionsCubit(repo),
    );
    getIt.registerFactory<ScannerCalendarCubit>(
      () => ScannerCalendarCubit(repo),
    );
  });

  tearDown(() => getIt.reset());

  testWidgets('opens on the weekly rules with its add button', (tester) async {
    await _pumpAt(tester, const Size(400, 900));

    expect(find.text('مواعيد السكنر'), findsOneWidget);
    expect(find.text('الثلاثاء'), findsOneWidget);
    expect(find.text('09:00 - 17:00'), findsOneWidget);
    expect(find.text('إضافة موعد'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the exceptions tab lists date overrides', (tester) async {
    await _pumpAt(tester, const Size(400, 900));

    await tester.tap(find.text('استثناءات'));
    await tester.pumpAndSettle();

    expect(find.text('2026-04-01'), findsOneWidget);
    expect(find.text('عطلة رسمية'), findsOneWidget);
    // The add button follows the tab.
    expect(find.text('إضافة استثناء'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the calendar tab is read-only — no add button', (tester) async {
    await _pumpAt(tester, const Size(400, 900));

    await tester.tap(find.text('التقويم'));
    await tester.pumpAndSettle();

    // Availability is changed by editing the rules, not from the preview.
    expect(find.text('إضافة موعد'), findsNothing);
    expect(find.text('إضافة استثناء'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an empty rules list explains the consequence', (tester) async {
    when(
      () => repo.getRules(),
    ).thenAnswer((_) async => right(<ScannerAvailabilityRuleModel>[]));

    await _pumpAt(tester, const Size(400, 900));

    expect(
      find.text('بدون مواعيد أسبوعية لن يتمكن الأطباء من حجز جلسة سكنر'),
      findsOneWidget,
    );
  });

  testWidgets('a failed fetch shows the message instead of an empty list', (
    tester,
  ) async {
    when(
      () => repo.getRules(),
    ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

    await _pumpAt(tester, const Size(400, 900));

    expect(find.text('لا يوجد اتصال'), findsOneWidget);
  });

  testWidgets('renders at the 360dp breakpoint without overflow', (
    tester,
  ) async {
    await _pumpAt(tester, const Size(360, 800));

    expect(find.text('الثلاثاء'), findsOneWidget);
    // A RenderFlex overflow surfaces here.
    expect(tester.takeException(), isNull);
  });
}

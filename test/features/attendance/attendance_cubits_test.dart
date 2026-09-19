import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/daily_attendance_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_state.dart';
import 'package:dental_lab_app/features/attendance/logic/leaves/leaves_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/leaves/leaves_state.dart';
import 'package:dental_lab_app/features/attendance/logic/work_shifts/work_shifts_cubit.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:dental_lab_app/features/payroll/data/repos/payroll_repo.dart';
import 'package:dental_lab_app/features/payroll/logic/payroll/payroll_cubit.dart';
import 'package:dental_lab_app/features/payroll/logic/payroll/payroll_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAttendanceRepo extends Mock implements AttendanceRepo {}

class _MockPayrollRepo extends Mock implements PayrollRepo {}

DailyAttendanceModel _day(String employeeId, {int status = 1}) =>
    DailyAttendanceModel.fromJson({
      'id': 'd-$employeeId',
      'employeeId': employeeId,
      'employeeName': 'موظف $employeeId',
      'status': status,
    });

LeaveModel _leave({int status = 1}) => LeaveModel.fromJson({
  'id': 'l1',
  'employeeId': 'e1',
  'startDate': '2026-03-01',
  'endDate': '2026-03-02',
  'status': status,
});

void main() {
  setUpAll(() {
    registerFallbackValue(
      GeneratePayrollRequestModel(anchorDate: DateTime(2026)),
    );
  });

  group('DailyAttendanceCubit', () {
    late _MockAttendanceRepo repo;
    late DailyAttendanceCubit cubit;

    setUp(() {
      repo = _MockAttendanceRepo();
      when(() => repo.getAttendanceForDay(any())).thenAnswer(
        (_) async => Right<Failure, List<DailyAttendanceModel>>([
          _day('e1'),
          _day('e2', status: 3),
        ]),
      );
      cubit = DailyAttendanceCubit(repo);
    });

    tearDown(() => cubit.close());

    test('counts the day from its own rows, which are the whole lab', () async {
      // This endpoint answers for every employee on one date, so the page is
      // the population — unlike a paged list, where counting would describe
      // only what was fetched.
      await cubit.load();

      final state = cubit.state as DailyAttendanceLoaded;
      expect(state.rows, hasLength(2));
      expect(
        state.countWhere((r) => r.status == DailyAttendanceStatus.absent),
        1,
      );
    });

    test('stepping a day refetches that day', () async {
      await cubit.load();
      final first = cubit.date;

      await cubit.previousDay();

      expect(cubit.date, first.subtract(const Duration(days: 1)));
      verify(() => repo.getAttendanceForDay(any())).called(2);
    });

    test('an edit reloads rather than patching the row', () async {
      // A punch re-derives the day's status, lateness, gaps and overtime —
      // all server-computed. Patching locally would put a number on screen
      // nothing else agrees with.
      when(() => repo.deletePunch(any())).thenAnswer(
        (_) async => Right<Failure, DailyAttendanceModel?>(null),
      );

      await cubit.load();
      await cubit.deletePunch('p1');

      verify(() => repo.getAttendanceForDay(any())).called(2);
    });

    test('a refused edit keeps the day on screen with the server\'s reason', () async {
      when(() => repo.deletePunch(any())).thenAnswer(
        (_) async => Left<Failure, DailyAttendanceModel?>(
          ServerFailure('اليوم ضمن كشف راتب معتمد'),
        ),
      );

      await cubit.load();

      final states = <DailyAttendanceState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.deletePunch('p1');
      await sub.cancel();

      expect(
        states.whereType<DailyAttendanceActionError>().single.message,
        'اليوم ضمن كشف راتب معتمد',
      );
      expect(cubit.state, isA<DailyAttendanceLoaded>());
    });
  });

  group('LeavesCubit', () {
    late _MockAttendanceRepo repo;
    late LeavesCubit cubit;

    setUp(() {
      repo = _MockAttendanceRepo();
      when(
        () => repo.getLeaves(
          employeeId: any(named: 'employeeId'),
          status: any(named: 'status'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<LeaveModel>>([_leave()]),
      );
      cubit = LeavesCubit(repo);
    });

    tearDown(() => cubit.close());

    test('counts what is still waiting on somebody', () async {
      await cubit.load();

      final state = cubit.state as LeavesLoaded;
      expect(state.pendingCount, 1);
    });

    test('tapping the selected status chip clears it', () async {
      await cubit.toggleStatus(LeaveStatus.approved);
      expect(cubit.statusFilter, LeaveStatus.approved);

      await cubit.toggleStatus(LeaveStatus.approved);
      expect(cubit.statusFilter, isNull);
    });

    test('a decision reloads: it re-judges every day the leave covers', () async {
      when(
        () => repo.decideLeave(id: any(named: 'id'), approve: any(named: 'approve')),
      ).thenAnswer((_) async => Right<Failure, LeaveModel>(_leave(status: 2)));

      await cubit.load();
      await cubit.decide(id: 'l1', approve: true);

      verify(
        () => repo.getLeaves(
          employeeId: any(named: 'employeeId'),
          status: any(named: 'status'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(2);
    });
  });

  group('WorkShiftsCubit', () {
    late _MockAttendanceRepo repo;
    late WorkShiftsCubit cubit;

    setUp(() {
      repo = _MockAttendanceRepo();
      when(() => repo.getWorkShifts()).thenAnswer(
        (_) async => Right<Failure, List<WorkShiftModel>>(const [
          WorkShiftModel(id: 's1', name: 'صباحية'),
        ]),
      );
      cubit = WorkShiftsCubit(repo);
    });

    tearDown(() => cubit.close());

    test('recalculates every affected employee after a rules edit', () async {
      // The server does not retroject a shift change: without this the old
      // days keep the verdicts they were given under the old rules.
      when(
        () => repo.recalculateRange(
          employeeId: any(named: 'employeeId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => const Right<Failure, int>(30));

      await cubit.load();
      await cubit.recalculateAfterEdit(
        WorkShiftAttendanceImpactModel(
          employeeIds: const ['e1', 'e2'],
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 3, 1),
        ),
      );

      verify(
        () => repo.recalculateRange(
          employeeId: any(named: 'employeeId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(2);
    });

    test('an empty impact recalculates nothing', () async {
      await cubit.load();
      await cubit.recalculateAfterEdit(
        const WorkShiftAttendanceImpactModel(employeeIds: []),
      );

      verifyNever(
        () => repo.recalculateRange(
          employeeId: any(named: 'employeeId'),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      );
    });
  });

  group('PayrollCubit', () {
    late _MockPayrollRepo repo;
    late PayrollCubit cubit;

    setUp(() {
      repo = _MockPayrollRepo();
      when(
        () => repo.getStatements(
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'),
          employeeId: any(named: 'employeeId'),
          status: any(named: 'status'),
        ),
      ).thenAnswer(
        (_) async => Right<Failure, List<SalaryStatementModel>>(const []),
      );
      when(
        () => repo.getCoverage(anchorDate: any(named: 'anchorDate')),
      ).thenAnswer(
        (_) async => Right<Failure, List<PayrollCoverageEntryModel>>(const [
          PayrollCoverageEntryModel(employeeId: 'e1', hasStatement: false),
          PayrollCoverageEntryModel(employeeId: 'e2', hasStatement: true),
        ]),
      );
      cubit = PayrollCubit(repo);
    });

    tearDown(() => cubit.close());

    test('separates who is still owed a payslip from who has one', () async {
      await cubit.load();

      final state = cubit.state as PayrollLoaded;
      expect(state.coverage, hasLength(2));
      expect(state.uncovered, hasLength(1));
    });

    test('a failed coverage read still shows the statements', () async {
      when(
        () => repo.getCoverage(anchorDate: any(named: 'anchorDate')),
      ).thenAnswer(
        (_) async => Left<Failure, List<PayrollCoverageEntryModel>>(
          ServerFailure('فشل'),
        ),
      );

      await cubit.load();

      final state = cubit.state as PayrollLoaded;
      expect(state.coverage, isEmpty);
      expect(state.statements, isEmpty);
    });

    test('generating takes an anchor date and reloads after', () async {
      when(() => repo.generatePayroll(any())).thenAnswer(
        (_) async => Right<Failure, List<SalaryStatementModel>>(const []),
      );

      await cubit.load();
      await cubit.generate(anchorDate: DateTime(2026, 3, 15));

      expect(cubit.anchorDate, DateTime(2026, 3, 15));
      verify(
        () => repo.getStatements(
          periodStart: any(named: 'periodStart'),
          periodEnd: any(named: 'periodEnd'),
          employeeId: any(named: 'employeeId'),
          status: any(named: 'status'),
        ),
      ).called(2);
    });

    test('a refused approve keeps the list and reports the reason', () async {
      when(() => repo.approveStatement(any())).thenAnswer(
        (_) async => Left<Failure, SalaryStatementModel>(
          ServerFailure('الكشف معتمد مسبقاً'),
        ),
      );

      await cubit.load();

      final states = <PayrollState>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.approve('p1');
      await sub.cancel();

      expect(
        states.whereType<PayrollActionError>().single.message,
        'الكشف معتمد مسبقاً',
      );
      expect(cubit.state, isA<PayrollLoaded>());
    });
  });
}

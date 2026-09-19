import 'package:dental_lab_app/features/attendance/data/models/attendance_enums.dart';
import 'package:dental_lab_app/features/attendance/data/models/daily_attendance_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/employee_work_system_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/leave_model.dart';
import 'package:dental_lab_app/features/attendance/data/models/work_shift_model.dart';
import 'package:dental_lab_app/features/payroll/data/models/payroll_enums.dart';
import 'package:dental_lab_app/features/payroll/data/models/salary_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkShiftDayModel', () {
    test('reads the wall-clock times as times, not timestamps', () {
      // "09:00 on Tuesdays" carries no date and no zone — parsing it as an
      // instant would staple today's date and the device's offset onto a rule
      // that has neither.
      final day = WorkShiftDayModel.fromJson({
        'dayOfWeek': 2,
        'startTime': '09:00:00',
        'endTime': '17:00:00',
      });

      expect(day.dayOfWeek, ApiDayOfWeek.tuesday);
      expect(day.startTime, const TimeOfDay(hour: 9, minute: 0));
      expect(day.spanMinutes, 480);
      expect(day.dayLabel, 'الثلاثاء');
    });

    test('a shift that ends before it starts runs past midnight', () {
      final day = WorkShiftDayModel.fromJson({
        'dayOfWeek': 0,
        'startTime': '22:00:00',
        'endTime': '06:00:00',
      });

      // Eight hours across midnight, not minus sixteen.
      expect(day.spanMinutes, 480);
    });

    test('serialises times back in the shape the API binds', () {
      const day = WorkShiftDayModel(
        dayOfWeek: ApiDayOfWeek.sunday,
        startTime: TimeOfDay(hour: 8, minute: 30),
        endTime: TimeOfDay(hour: 16, minute: 0),
      );

      expect(day.toJson()['startTime'], '08:30:00');
      expect(day.toJson()['dayOfWeek'], 0);
    });
  });

  group('WorkShiftModel', () {
    test('orders the week however the rows arrived', () {
      final shift = WorkShiftModel.fromJson({
        'id': 's1',
        'name': 'صباحية',
        'days': [
          {'dayOfWeek': 4, 'startTime': '09:00:00', 'endTime': '17:00:00'},
          {'dayOfWeek': 1, 'startTime': '09:00:00', 'endTime': '17:00:00'},
        ],
      });

      expect(
        shift.orderedDays.map((d) => d.dayOfWeek),
        [ApiDayOfWeek.monday, ApiDayOfWeek.thursday],
      );
    });

    test('no overtime rate is not the same as a rate of zero', () {
      // Null means overtime is not paid on this shift at all; zero means the
      // lab decided an extra minute is worth nothing.
      final unpaid = WorkShiftModel.fromJson({'id': 's1'});
      final worthless = WorkShiftModel.fromJson({
        'id': 's2',
        'overtimePayPerMinute': 0,
      });

      expect(unpaid.overtimePayPerMinute, isNull);
      expect(worthless.overtimePayPerMinute, 0);
    });
  });

  group('WorkShiftAttendanceImpactModel', () {
    test('an empty impact is nothing to warn about', () {
      final empty = WorkShiftAttendanceImpactModel.fromJson({
        'employeeIds': <String>[],
      });
      expect(empty.isEmpty, isTrue);

      final real = WorkShiftAttendanceImpactModel.fromJson({
        'employeeIds': ['e1'],
        'from': '2026-01-01',
        'to': '2026-03-01',
      });
      expect(real.isEmpty, isFalse);
    });

    test('employees with no attendance yet still count as nothing to redo', () {
      // People are on the shift, but no day was ever judged against its old
      // rules — there is nothing to recalculate.
      final impact = WorkShiftAttendanceImpactModel.fromJson({
        'employeeIds': ['e1'],
      });

      expect(impact.isEmpty, isTrue);
    });
  });

  group('EmployeeWorkSystemModel', () {
    test('an open spell reads as running, not as missing an end', () {
      final spell = EmployeeWorkSystemModel.fromJson({
        'id': 'w1',
        'employeeId': 'e1',
        'startDate': '2026-03-01T00:00:00Z',
        'isActive': true,
        'workShiftName': 'صباحية',
      });

      expect(spell.periodLabel, contains('حتى الآن'));
      expect(spell.shiftLabel, 'صباحية');
    });

    test('no shift is an arrangement, not a missing value', () {
      final spell = EmployeeWorkSystemModel.fromJson({
        'id': 'w1',
        'employeeId': 'e1',
      });

      expect(spell.workShiftId, isNull);
      expect(spell.shiftLabel, 'بلا وردية');
    });
  });

  group('DailyAttendanceModel', () {
    test('excused minutes are kept apart from penalty minutes', () {
      // An excused hour is not a late hour, and the totals must not blend.
      final day = DailyAttendanceModel.fromJson({
        'id': 'd1',
        'employeeId': 'e1',
        'date': '2026-03-02',
        'status': 4,
        'leaveMinutes': 120,
        'delayMinutes': 0,
      });

      expect(day.status, DailyAttendanceStatus.onLeave);
      expect(day.leaveMinutes, 120);
      expect(day.hasPenalty, isFalse);
    });

    test('no work system is not an accusation of absence', () {
      final day = DailyAttendanceModel.fromJson({
        'id': 'd1',
        'employeeId': 'e1',
        'status': 6,
        'hasWorkSystem': false,
      });

      expect(day.status, DailyAttendanceStatus.noWorkSystem);
      expect(day.hasWorkSystem, isFalse);
    });

    test('a day inside a draft payslip says so', () {
      // The statement was generated before this edit and will not pick it up
      // on its own.
      final day = DailyAttendanceModel.fromJson({
        'id': 'd1',
        'employeeId': 'e1',
        'draftSalaryPeriodStart': '2026-03-01',
        'draftSalaryPeriodEnd': '2026-03-31',
      });

      expect(day.affectsDraftSalary, isTrue);
    });
  });

  group('LeaveModel', () {
    test('an hourly leave carries the window it takes out of each day', () {
      final leave = LeaveModel.fromJson({
        'id': 'l1',
        'employeeId': 'e1',
        'startDate': '2026-03-01',
        'endDate': '2026-03-03',
        'durationType': 2,
        'startTime': '09:00:00',
        'endTime': '11:00:00',
        'status': 1,
      });

      expect(leave.durationType, LeaveDurationType.hourly);
      expect(leave.windowLabel, '09:00 — 11:00');
      expect(leave.dayCount, 3);
      expect(leave.isPending, isTrue);
    });

    test('a daily leave has no window at all', () {
      final leave = LeaveModel.fromJson({
        'id': 'l1',
        'employeeId': 'e1',
        'startDate': '2026-03-01',
        'endDate': '2026-03-01',
        'durationType': 1,
      });

      expect(leave.windowLabel, isNull);
      expect(leave.dayCount, 1);
      // One day reads as a date, not as a range from itself to itself.
      expect(leave.periodLabel, '2026-03-01');
    });
  });

  group('CreateLeaveRequestModel', () {
    test('drops the window on a daily leave rather than sending a stale one', () {
      final request = CreateLeaveRequestModel(
        employeeId: 'e1',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 1),
        startTime: const TimeOfDay(hour: 9, minute: 0),
      );

      expect(request.toJson()['startTime'], isNull);
    });

    test('defaults to approved, which is what back-filling needs', () {
      // Without it, entering a leave for a past date would leave the absences
      // it excuses standing until somebody pressed approve.
      final request = CreateLeaveRequestModel(
        employeeId: 'e1',
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 1),
        approve: true,
      );

      expect(request.toJson()['approve'], isTrue);
    });
  });

  group('SaveHolidayRequestModel', () {
    test('a lab-wide holiday sends no employee list', () {
      final request = SaveHolidayRequestModel(
        name: 'عيد',
        date: DateTime(2026, 3, 20),
        employeeIds: const ['e1'],
        allEmployees: true,
      );

      expect(request.toJson()['employeeIds'], isEmpty);
      expect(request.toJson()['allEmployees'], isTrue);
    });
  });

  group('SalaryExceptionModel', () {
    test('only the money kinds carry a currency', () {
      expect(SalaryExceptionKind.salaryIncrease.needsCurrency, isTrue);
      expect(SalaryExceptionKind.delayMinutesOverride.needsCurrency, isFalse);
    });

    test('an override renders as a count, not as an amount', () {
      final override = SalaryExceptionModel.fromJson({
        'id': 'x1',
        'employeeId': 'e1',
        'kind': 2,
        'value': 45,
      });

      expect(override.valueLabel, '45');
    });

    test('a standing exception has no end date', () {
      final standing = SalaryExceptionModel.fromJson({
        'id': 'x1',
        'employeeId': 'e1',
        'kind': 6,
        'startDate': '2026-01-01',
      });

      expect(standing.isStanding, isTrue);
      expect(standing.isSettled, isFalse);
    });
  });

  group('SaveSalaryExceptionRequestModel', () {
    test('drops the currency on an override kind', () {
      // A count of minutes has no currency; sending one would invite the two
      // to disagree.
      final request = SaveSalaryExceptionRequestModel(
        employeeId: 'e1',
        kind: SalaryExceptionKind.gapMinutesOverride,
        value: 10,
        startDate: DateTime(2026, 3, 1),
        reason: 'تسوية',
        currencyId: 'c1',
      );

      expect(request.toJson()['currencyId'], isNull);
    });
  });

  group('SalaryStatementModel', () {
    test('sums the deductions without touching the net the server sent', () {
      final statement = SalaryStatementModel.fromJson({
        'id': 'p1',
        'employeeId': 'e1',
        'grossAmount': 1000.0,
        'absentDeduction': 50.0,
        'delayDeduction': 10.0,
        'earlyLeaveDeduction': 5.0,
        'gapDeduction': 5.0,
        'overtimePay': 20.0,
        'netAmount': 950.0,
        'status': 1,
      });

      expect(statement.totalDeductions, 70.0);
      // The net is the server's arithmetic, never recomputed here.
      expect(statement.netAmount, 950.0);
      expect(statement.isDraft, isTrue);
    });

    test('formats every amount with its currency', () {
      final statement = SalaryStatementModel.fromJson({
        'id': 'p1',
        'employeeId': 'e1',
        'currency': {'id': 'c1', 'code': 'USD', 'symbol': r'$'},
        'netAmount': 950.0,
      });

      expect(statement.format(950), contains(r'$'));
    });
  });

  group('GeneratePayrollRequestModel', () {
    test('sends an anchor date, never a range', () {
      // Each employee's own pay period decides the window; a caller-supplied
      // range would mean something different for a weekly and a monthly
      // employee generated in the same call.
      final request = GeneratePayrollRequestModel(
        anchorDate: DateTime(2026, 3, 15),
      );

      final json = request.toJson();
      expect(json['anchorDate'], '2026-03-15');
      expect(json.containsKey('periodStart'), isFalse);
      expect(json['employeeIds'], isNull);
    });
  });
}

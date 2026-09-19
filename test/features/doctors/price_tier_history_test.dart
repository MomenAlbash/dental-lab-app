import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_price_tier_spell_model.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/price_tier_history_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDoctorsRepo extends Mock implements DoctorsRepo {}

void main() {
  group('DoctorPriceTierSpellModel', () {
    test('parses a closed spell', () {
      final spell = DoctorPriceTierSpellModel.fromJson(const {
        'id': 's1',
        'priceTierId': 't1',
        'priceTierName': 'الذهبية',
        'startDate': '2026-01-01T00:00:00Z',
        'endDate': '2026-03-01T00:00:00Z',
        'isActive': false,
        'note': 'انتقل لشريحة أعلى',
      });

      expect(spell.tierLabel, 'الذهبية');
      expect(spell.startDate, DateTime.parse('2026-01-01T00:00:00Z'));
      expect(spell.endDate, DateTime.parse('2026-03-01T00:00:00Z'));
      expect(spell.isActive, isFalse);
      expect(spell.note, 'انتقل لشريحة أعلى');
    });

    test('the open spell has no end date and reads as the current one', () {
      final spell = DoctorPriceTierSpellModel.fromJson(const {
        'id': 's2',
        'priceTierId': 't2',
        'priceTierName': 'الفضية',
        'startDate': '2026-03-01T00:00:00Z',
        'isActive': true,
      });

      expect(spell.endDate, isNull);
      expect(spell.isActive, isTrue);
    });

    test('a spell off every tier falls back to a plain label', () {
      final spell = DoctorPriceTierSpellModel.fromJson(const {
        'id': 's3',
        'startDate': '2026-01-01T00:00:00Z',
      });

      expect(spell.tierLabel, 'بلا شريحة');
    });
  });

  group('showPriceTierHistorySheet', () {
    late _MockDoctorsRepo repo;

    setUp(() async {
      repo = _MockDoctorsRepo();
      await getIt.reset();
      getIt.registerLazySingleton<DoctorsRepo>(() => repo);
    });

    tearDown(() => getIt.reset());

    Widget wrap() => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ar'),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () =>
                  showPriceTierHistorySheet(context, doctorId: 'd1'),
              child: const Text('فتح'),
            ),
          ),
        ),
      ),
    );

    testWidgets('lists every spell, newest state marked as current', (
      tester,
    ) async {
      when(() => repo.getPriceTierHistory('d1')).thenAnswer(
        (_) async => right(const [
          DoctorPriceTierSpellModel(
            id: 's1',
            priceTierName: 'الفضية',
            isActive: true,
          ),
          DoctorPriceTierSpellModel(id: 's2', priceTierName: 'الذهبية'),
        ]),
      );

      await tester.pumpWidget(wrap());
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();

      expect(find.text('الفضية'), findsOneWidget);
      expect(find.text('الذهبية'), findsOneWidget);
      expect(find.text('الحالية'), findsOneWidget);
    });

    testWidgets('a doctor never on a tier says so, not an empty sheet', (
      tester,
    ) async {
      when(
        () => repo.getPriceTierHistory('d1'),
      ).thenAnswer((_) async => right(const []));

      await tester.pumpWidget(wrap());
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();

      expect(
        find.text('لم يكن هذا الطبيب على أي شريحة سعرية بعد'),
        findsOneWidget,
      );
    });

    testWidgets('a failed fetch reports the reason', (tester) async {
      when(
        () => repo.getPriceTierHistory('d1'),
      ).thenAnswer((_) async => left(ServerFailure('لا يوجد اتصال')));

      await tester.pumpWidget(wrap());
      await tester.tap(find.text('فتح'));
      await tester.pumpAndSettle();

      expect(find.text('لا يوجد اتصال'), findsOneWidget);
    });
  });
}

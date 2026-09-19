import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/core/widgets/doctor_audience_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DoctorModel doctor(String name, {String? cityId, String? cityName}) =>
    DoctorModel(
      id: name,
      firstName: name,
      cityId: cityId,
      city: cityId == null
          ? null
          : CityModel(id: cityId, name: cityName ?? cityId),
    );

Future<List<String>?> openSheet(
  WidgetTester tester, {
  required List<DoctorModel> doctors,
  Set<String> assignedIds = const {},
}) async {
  List<String>? result;

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showDoctorAudienceSheet(
                    context,
                    doctors: doctors,
                    title: 'إسناد',
                    assignedIds: assignedIds,
                  );
                },
                child: const Text('open'),
              ),
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
  testWidgets('cities come from the doctors, each with its count', (
    tester,
  ) async {
    // No cities request: a doctor carries their own city, and the only cities
    // worth offering are the ones somebody practises in.
    await openSheet(
      tester,
      doctors: [
        doctor('أحمد', cityId: 'c1', cityName: 'دمشق'),
        doctor('سارة', cityId: 'c1', cityName: 'دمشق'),
        doctor('خالد', cityId: 'c2', cityName: 'حلب'),
      ],
    );

    await tester.tap(find.text('مدينة'));
    await tester.pumpAndSettle();

    expect(find.text('دمشق (2)'), findsOneWidget);
    expect(find.text('حلب (1)'), findsOneWidget);
  });

  testWidgets('choosing a city names the doctors it will price', (
    tester,
  ) async {
    await openSheet(
      tester,
      doctors: [
        doctor('أحمد', cityId: 'c1', cityName: 'دمشق'),
        doctor('خالد', cityId: 'c2', cityName: 'حلب'),
      ],
    );

    await tester.tap(find.text('مدينة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دمشق (1)'));
    await tester.pumpAndSettle();

    // Named, not counted — a count is not something a user can check before
    // committing a price list.
    expect(find.widgetWithText(Chip, 'أحمد'), findsOneWidget);
    expect(find.widgetWithText(Chip, 'خالد'), findsNothing);
    expect(find.text('إسناد للمدينة (1)'), findsOneWidget);
  });

  testWidgets('doctors with no city are called out', (tester) async {
    // No city choice can reach them. Left unsaid they would simply never get
    // priced and nobody would know.
    await openSheet(
      tester,
      doctors: [
        doctor('أحمد', cityId: 'c1', cityName: 'دمشق'),
        doctor('بلا مدينة'),
      ],
    );

    await tester.tap(find.text('مدينة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('دمشق (1)'));
    await tester.pumpAndSettle();

    expect(find.textContaining('بلا مدينة مسجّلة'), findsOneWidget);
  });

  testWidgets('saving is blocked until a city is chosen', (tester) async {
    // An empty list would quietly unassign the tier.
    await openSheet(
      tester,
      doctors: [doctor('أحمد', cityId: 'c1', cityName: 'دمشق')],
    );

    await tester.tap(find.text('مدينة'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('إسناد للمدينة (0)'),
        matching: find.byType(FilledButton),
      ),
    );

    expect(button.onPressed, isNull);
  });
}

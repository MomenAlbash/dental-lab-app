import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_hero_header.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_info_tiles.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

ClinicModel _clinic({
  String? phone = '0112223344',
  String? email = 'alnoor@example.com',
  String? address = 'المزة، دمشق',
  String? code = 'CL-001',
}) {
  return ClinicModel(
    id: 'cl-1',
    name: 'عيادة النور',
    code: code,
    phoneNumber: phone,
    email: email,
    address: address,
    websiteUrl: 'https://alnoor.example.com',
    city: CityModel(id: 'c1', name: 'دمشق'),
  );
}

void main() {
  Widget wrap(Widget slotHeader, {ThemeData? theme}) {
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
        body: CustomScrollView(
          slivers: [
            slotHeader,
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ClinicQuickActions(clinic: _clinic()),
                    const SizedBox(height: 16),
                    ClinicInfoTiles(clinic: _clinic()),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 800)),
          ],
        ),
      ),
    );
  }

  testWidgets('shows the name exactly once at rest', (tester) async {
    // Regression class: the doctor header once rendered the name twice
    // (panel + collapsed title). Same collapsing mechanism reused here.
    await tester.pumpWidget(
      wrap(ClinicSliverHeader(clinic: _clinic(), onEdit: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);
    // These legitimately appear twice — once in the header chip, once in the
    // info tile below (mirrors the doctor/patient headers' own precedent).
    expect(find.text('CL-001'), findsNWidgets(2));
    expect(find.text('دمشق'), findsNWidgets(2));
  });

  testWidgets('collapsing the header does not overflow at any scroll offset', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(ClinicSliverHeader(clinic: _clinic(), onEdit: () {})),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 12; i++) {
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -25));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('quick actions and info tiles show contact and location data', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(ClinicSliverHeader(clinic: _clinic(), onEdit: () {})),
    );
    await tester.pumpAndSettle();

    expect(find.text('اتصال'), findsOneWidget);
    expect(find.text('واتساب'), findsOneWidget);
    expect(find.text('بريد'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);

    expect(find.text('المزة، دمشق'), findsOneWidget);
    expect(find.text('https://alnoor.example.com'), findsOneWidget);
  });

  testWidgets('falls back to initials when there is no logo', (tester) async {
    await tester.pumpWidget(
      wrap(ClinicSliverHeader(clinic: _clinic(), onEdit: () {})),
    );
    await tester.pumpAndSettle();

    // "عيادة النور" -> first letter of each word: ع + ا.
    expect(find.text('عا'), findsOneWidget);
  });

  testWidgets('quick action tiles stay disabled when contact data is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ClinicSliverHeader(
          clinic: _clinic(phone: null, email: null, address: null),
          onEdit: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Disabled tiles keep the row's shape rather than disappearing.
    expect(find.text('اتصال'), findsOneWidget);
    expect(find.text('الموقع'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('survives a 2.0x text scale at 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: wrap(ClinicSliverHeader(clinic: _clinic(), onEdit: () {})),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    await tester.pumpWidget(
      wrap(
        ClinicSliverHeader(clinic: _clinic(), onEdit: () {}),
        theme: AppTheme.dark,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

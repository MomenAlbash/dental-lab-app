import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinics_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicsRepo extends Mock implements ClinicsRepo {}

ClinicModel _clinic(
  String id,
  String name, {
  String? city,
  String? code,
  String? address,
  String? phone,
}) {
  return ClinicModel(
    id: id,
    name: name,
    code: code,
    address: address,
    phoneNumber: phone,
    city: city == null ? null : CityModel(id: 'c-$id', name: city),
  );
}

void main() {
  late _MockClinicsRepo repo;
  late ClinicsCubit cubit;

  setUp(() {
    repo = _MockClinicsRepo();
    when(
      () => repo.getClinics(),
    ).thenAnswer((_) async => Right<Failure, List<ClinicModel>>(const []));
    cubit = ClinicsCubit(repo);
  });

  tearDown(() => cubit.close());

  Widget wrap(
    List<ClinicModel> clinics, {
    ThemeData? theme,
    String searchQuery = '',
    required TextEditingController controller,
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
          child: ClinicsListView(
            clinics: clinics,
            searchController: controller,
            searchQuery: searchQuery,
            onDelete: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('renders clinic rows without overflow at 360dp width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap([
        _clinic(
          '1',
          'عيادة النور',
          city: 'دمشق',
          code: 'CL-001',
          address: 'المزة، دمشق',
          phone: '0112223344',
        ),
        _clinic('2', 'عيادة الأمل'),
      ], controller: controller),
    );
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.text('عيادة الأمل'), findsOneWidget);
    expect(find.text('دمشق'), findsOneWidget);
    expect(find.text('CL-001'), findsOneWidget);
    expect(find.text('0112223344'), findsOneWidget);
    expect(find.text('بدون عنوان'), findsOneWidget);
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
          _clinic(
            '1',
            'عيادة النور للأسنان والتجميل المتقدم',
            city: 'دمشق العاصمة',
            code: 'CL-00123456',
            address: 'المزة، دمشق، سوريا، بجانب الجامع الكبير',
            phone: '0112223344',
          ),
        ], controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when there are no clinics', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(wrap(const [], controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('لا يوجد عيادات بعد'), findsOneWidget);
  });

  testWidgets('shows the no-results state while searching', (tester) async {
    final controller = TextEditingController(text: 'زياد');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(const [], controller: controller, searchQuery: 'زياد'),
    );
    await tester.pumpAndSettle();

    expect(find.text('لا توجد نتائج'), findsOneWidget);
  });

  testWidgets('renders in the dark theme without exceptions', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      wrap(
        [_clinic('1', 'عيادة النور')],
        theme: AppTheme.dark,
        controller: controller,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

import 'package:dartz/dartz.dart';
import 'package:dental_lab_app/core/errors/failures.dart';
import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cities/data/repos/cities_repo.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClinicsRepo extends Mock implements ClinicsRepo {}

class _MockCitiesRepo extends Mock implements CitiesRepo {}

void main() {
  late ClinicsCubit clinicsCubit;
  late CitiesCubit citiesCubit;
  late GlobalKey<FormState> formKey;
  final controllers = <TextEditingController>[];

  TextEditingController controller([String text = '']) {
    final c = TextEditingController(text: text);
    controllers.add(c);
    return c;
  }

  setUp(() async {
    final clinicsRepo = _MockClinicsRepo();
    when(() => clinicsRepo.getClinics()).thenAnswer(
      (_) async => Right<Failure, List<ClinicModel>>([
        ClinicModel(id: 'c1', name: 'عيادة النور'),
      ]),
    );
    clinicsCubit = ClinicsCubit(clinicsRepo);
    await clinicsCubit.getClinics();

    citiesCubit = CitiesCubit(_MockCitiesRepo());
    formKey = GlobalKey<FormState>();
  });

  tearDown(() {
    clinicsCubit.close();
    citiesCubit.close();
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
  });

  Widget wrap({String? clinicId}) {
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
        body: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: clinicsCubit),
            BlocProvider.value(value: citiesCubit),
          ],
          child: SingleChildScrollView(
            child: DoctorFormFields(
              formKey: formKey,
              firstNameController: controller('أحمد'),
              lastNameController: controller('الخطيب'),
              emailController: controller(),
              phoneController: controller(),
              addressController: controller(),
              gender: DoctorGender.male,
              onGenderChanged: (_) {},
              dateOfBirth: null,
              onPickDate: () {},
              cityId: null,
              onCityChanged: (_) {},
              clinicId: clinicId,
              onClinicChanged: (_) {},
              isEditing: false,
              isActive: true,
              onActiveChanged: (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the form does not validate without a clinic', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('اختر العيادة'), findsWidgets);
  });

  testWidgets('the form validates once a clinic is chosen', (tester) async {
    await tester.pumpWidget(wrap(clinicId: 'c1'));
    await tester.pumpAndSettle();

    expect(formKey.currentState!.validate(), isTrue);
  });
}

import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_filters_model.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubClinicsCubit extends Cubit<ClinicsState> implements ClinicsCubit {
  _StubClinicsCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubDoctorsCubit extends Cubit<DoctorsState> implements DoctorsCubit {
  _StubDoctorsCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrap({required ClinicsState clinics, required DoctorsState doctors}) {
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
            BlocProvider<ClinicsCubit>.value(value: _StubClinicsCubit(clinics)),
            BlocProvider<DoctorsCubit>.value(value: _StubDoctorsCubit(doctors)),
          ],
          child: PatientFiltersSheet(initial: PatientFiltersModel.empty),
        ),
      ),
    );
  }

  Future<void> disposeShimmer(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  testWidgets('shows shimmering placeholders while the lookups load', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(clinics: ClinicsLoading(), doctors: DoctorsLoading()),
    );
    await tester.pump();

    expect(find.byType(GlassFieldSkeleton), findsNWidgets(2));
    expect(find.byType(CaseLookupDropdown), findsNothing);
    expect(find.text('جارٍ تحميل الأطباء...'), findsNothing);
    expect(find.text('جارٍ تحميل العيادات...'), findsNothing);

    await disposeShimmer(tester);
  });

  testWidgets('swaps in the real pickers once loaded', (tester) async {
    await tester.pumpWidget(
      wrap(
        clinics: ClinicsLoaded([ClinicModel(id: 'cl-1', name: 'عيادة النور')]),
        doctors: DoctorsLoaded([
          DoctorModel(id: 'd-1', firstName: 'أحمد', lastName: 'الخطيب'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GlassFieldSkeleton), findsNothing);
    expect(find.byType(CaseLookupDropdown), findsNWidgets(2));
    expect(find.text('كل الأطباء'), findsOneWidget);
    expect(find.text('كل العيادات'), findsOneWidget);
  });
}

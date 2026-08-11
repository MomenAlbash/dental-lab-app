import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the real cubit so the preview's clinic lookup can be driven
/// without touching the network layer.
class _StubClinicsCubit extends Cubit<ClinicsState> implements ClinicsCubit {
  _StubClinicsCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrap(Widget child, {ClinicsState? clinicsState}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<ClinicsCubit>.value(
          value: _StubClinicsCubit(clinicsState ?? const ClinicsInitial()),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets('shows a placeholder before a name is entered', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DoctorFormPreview(
          firstName: '',
          lastName: '',
          clinicId: null,
          gender: DoctorGender.male,
          isActive: true,
          isEditing: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('دكتور جديد'), findsOneWidget);
    expect(find.text('اكتب الاسم ليظهر هنا'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('reflects the typed name and its initials', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DoctorFormPreview(
          firstName: 'أحمد',
          lastName: 'الخطيب',
          clinicId: null,
          gender: DoctorGender.male,
          isActive: true,
          isEditing: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('أحمد الخطيب'), findsOneWidget);
    expect(find.text('أا'), findsOneWidget);
    expect(find.text('ذكر'), findsOneWidget);
  });

  testWidgets('resolves the selected clinic name', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DoctorFormPreview(
          firstName: 'سارة',
          lastName: 'العلي',
          clinicId: 'cl-1',
          gender: DoctorGender.female,
          isActive: true,
          isEditing: false,
        ),
        clinicsState: ClinicsLoaded([
          ClinicModel(id: 'cl-1', name: 'عيادة النور'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.text('أنثى'), findsOneWidget);
  });

  testWidgets('shows the status chip in edit mode', (tester) async {
    await tester.pumpWidget(
      wrap(
        const DoctorFormPreview(
          firstName: 'أحمد',
          lastName: 'الخطيب',
          clinicId: null,
          gender: DoctorGender.male,
          isActive: false,
          isEditing: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعديل بيانات'), findsOneWidget);
    expect(find.text('موقوف'), findsOneWidget);
  });

  testWidgets('survives a 2.0x text scale at 360dp', (tester) async {
    tester.view.physicalSize = const Size(360, 720);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: wrap(
          const DoctorFormPreview(
            firstName: 'عبد الرحمن',
            lastName: 'الخطيب',
            clinicId: null,
            gender: DoctorGender.male,
            isActive: true,
            isEditing: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

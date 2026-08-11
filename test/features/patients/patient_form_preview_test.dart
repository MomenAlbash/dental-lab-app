import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_state.dart';
import 'package:dental_lab_app/features/patients/data/models/patient_gender.dart';
import 'package:dental_lab_app/features/patients/ui/widgets/patient_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubDoctorsCubit extends Cubit<DoctorsState> implements DoctorsCubit {
  _StubDoctorsCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrap(Widget child, {DoctorsState? doctorsState}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<DoctorsCubit>.value(
          value: _StubDoctorsCubit(doctorsState ?? const DoctorsInitial()),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets('shows a placeholder before a name is entered', (tester) async {
    await tester.pumpWidget(
      wrap(
        const PatientFormPreview(
          firstName: '',
          lastName: '',
          doctorId: null,
          gender: PatientGender.male,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مريض جديد'), findsOneWidget);
    expect(find.text('اكتب الاسم ليظهر هنا'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    expect(find.text('اختر الطبيب'), findsOneWidget);
  });

  testWidgets('reflects the typed name and resolves the selected doctor', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const PatientFormPreview(
          firstName: 'خالد',
          lastName: 'العلي',
          doctorId: 'd-1',
          gender: PatientGender.male,
        ),
        doctorsState: DoctorsLoaded([
          DoctorModel(id: 'd-1', firstName: 'أحمد', lastName: 'الخطيب'),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('خالد العلي'), findsOneWidget);
    expect(find.text('خا'), findsOneWidget); // initials: خ + ا

    expect(find.textContaining('أحمد'), findsOneWidget);
    expect(find.text('ذكر'), findsOneWidget);
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
          const PatientFormPreview(
            firstName: 'عبد الرحمن',
            lastName: 'العلي الطويل',
            doctorId: null,
            gender: PatientGender.female,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

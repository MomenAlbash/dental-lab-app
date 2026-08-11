import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stands in for the real cubit so the preview's city lookup can be driven
/// without touching the network layer.
class _StubCitiesCubit extends Cubit<CitiesState> implements CitiesCubit {
  _StubCitiesCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrap(Widget child, {CitiesState? citiesState}) {
    return MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: BlocProvider<CitiesCubit>.value(
          value: _StubCitiesCubit(citiesState ?? const CitiesInitial()),
          child: Padding(padding: const EdgeInsets.all(16), child: child),
        ),
      ),
    );
  }

  testWidgets('shows a placeholder before a name is entered', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ClinicFormPreview(
          name: '',
          code: '',
          cityId: null,
          isEditing: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عيادة جديدة'), findsOneWidget);
    expect(find.text('اكتب اسم العيادة ليظهر هنا'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('reflects the typed name, its initials and code', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ClinicFormPreview(
          name: 'عيادة النور',
          code: 'CL-001',
          cityId: null,
          isEditing: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('عيادة النور'), findsOneWidget);
    expect(find.text('عا'), findsOneWidget);
    expect(find.text('CL-001'), findsOneWidget);
  });

  testWidgets('resolves the selected city name', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ClinicFormPreview(
          name: 'عيادة الأمل',
          code: '',
          cityId: 'c-1',
          isEditing: false,
        ),
        citiesState: CitiesLoaded([CityModel(id: 'c-1', name: 'حلب')]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('حلب'), findsOneWidget);
  });

  testWidgets('shows the edit label in edit mode', (tester) async {
    await tester.pumpWidget(
      wrap(
        const ClinicFormPreview(
          name: 'عيادة النور',
          code: '',
          cityId: null,
          isEditing: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('تعديل عيادة'), findsOneWidget);
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
          const ClinicFormPreview(
            name: 'عيادة النور للأسنان والتجميل المتقدم',
            code: 'CL-00123456',
            cityId: null,
            isEditing: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

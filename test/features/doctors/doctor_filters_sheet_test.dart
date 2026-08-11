import 'package:dental_lab_app/core/theming/app_theme.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/cities/data/models/city_model.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_state.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_state.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_filters_model.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_filters_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Stand-ins so the sheet's lookups can be driven without the network layer.
class _StubClinicsCubit extends Cubit<ClinicsState> implements ClinicsCubit {
  _StubClinicsCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCitiesCubit extends Cubit<CitiesState> implements CitiesCubit {
  _StubCitiesCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget wrap({required ClinicsState clinics, required CitiesState cities}) {
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
            BlocProvider<CitiesCubit>.value(value: _StubCitiesCubit(cities)),
          ],
          child: DoctorFiltersSheet(initial: DoctorFiltersModel.empty),
        ),
      ),
    );
  }

  testWidgets('shows shimmering placeholders while the lookups load', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(clinics: ClinicsLoading(), cities: CitiesLoading()),
    );
    await tester.pump();

    // One per picker (clinic + city), sized like the control they replace.
    expect(find.byType(GlassFieldSkeleton), findsNWidgets(2));
    expect(find.byType(CaseLookupDropdown), findsNothing);

    // The old treatment put this text inside a dead dropdown.
    expect(find.text('جارٍ تحميل العيادات...'), findsNothing);
    expect(find.text('جارٍ تحميل المدن...'), findsNothing);

    await _disposeShimmer(tester);
  });

  testWidgets('swaps in the real pickers once loaded', (tester) async {
    await tester.pumpWidget(
      wrap(
        clinics: ClinicsLoaded([ClinicModel(id: 'cl-1', name: 'عيادة النور')]),
        cities: CitiesLoaded([CityModel(id: 'c-1', name: 'دمشق')]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(GlassFieldSkeleton), findsNothing);
    expect(find.byType(CaseLookupDropdown), findsNWidgets(2));
    expect(find.text('كل العيادات'), findsOneWidget);
    expect(find.text('كل المدن'), findsOneWidget);
  });

  testWidgets(
    'a failed lookup keeps the placeholder rather than a dead control',
    (tester) async {
      await tester.pumpWidget(
        wrap(clinics: ClinicsError('فشل'), cities: CitiesLoading()),
      );
      await tester.pump();

      expect(find.byType(GlassFieldSkeleton), findsNWidgets(2));

      await _disposeShimmer(tester);
    },
  );
}

/// The skeleton's shimmer repeats forever, so it would still be ticking when
/// the test ends and the binding would report a pending timer. Replacing the
/// tree disposes it, which is exactly what happens in the app once the lookup
/// finishes loading.
Future<void> _disposeShimmer(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpAndSettle();
}

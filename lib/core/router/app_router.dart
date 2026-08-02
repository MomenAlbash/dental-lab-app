import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/features/auth/ui/login_page.dart';
import 'package:dental_lab_app/features/cases/ui/case_detail_page.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/cases_shell_page.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/ui/clinic_detail_page.dart';
import 'package:dental_lab_app/features/clinics/ui/clinic_form_page.dart';
import 'package:dental_lab_app/features/clinics/ui/clinics_list_page.dart';
import 'package:dental_lab_app/features/currencies/ui/currencies_list_page.dart';
import 'package:dental_lab_app/features/currencies/ui/currency_detail_page.dart';
import 'package:dental_lab_app/features/currencies/ui/currency_form_page.dart';
import 'package:dental_lab_app/features/cities/ui/cities_list_page.dart';
import 'package:dental_lab_app/features/countries/ui/countries_list_page.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/ui/doctor_detail_page.dart';
import 'package:dental_lab_app/features/doctors/ui/doctor_form_page.dart';
import 'package:dental_lab_app/features/doctors/ui/doctors_list_page.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/ui/employee_detail_page.dart';
import 'package:dental_lab_app/features/employees/ui/employee_form_page.dart';
import 'package:dental_lab_app/features/employees/ui/employees_list_page.dart';
import 'package:dental_lab_app/features/home/ui/main_shell_page.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/ui/laboratories_list_page.dart';
import 'package:dental_lab_app/features/laboratories/ui/laboratory_selection_page.dart';
import 'package:dental_lab_app/features/laboratories/ui/laboratory_detail_page.dart';
import 'package:dental_lab_app/features/laboratories/ui/laboratory_form_page.dart';
import 'package:dental_lab_app/features/laboratories/ui/my_laboratory_page.dart';
import 'package:dental_lab_app/features/patients/ui/patient_detail_page.dart';
import 'package:dental_lab_app/features/patients/ui/patient_form_page.dart';
import 'package:dental_lab_app/features/patients/ui/patients_list_page.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/ui/price_tier_form_page.dart';
import 'package:dental_lab_app/features/price_tiers/ui/price_tier_prices_page.dart';
import 'package:dental_lab_app/features/price_tiers/ui/price_tiers_list_page.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/ui/restoration_type_form_page.dart';
import 'package:dental_lab_app/features/restoration_types/ui/restoration_types_list_page.dart';
import 'package:dental_lab_app/features/roles/ui/role_form_page.dart';
import 'package:dental_lab_app/features/roles/ui/roles_list_page.dart';
import 'package:dental_lab_app/features/users/ui/user_detail_page.dart';
import 'package:dental_lab_app/features/users/ui/user_form_page.dart';
import 'package:dental_lab_app/features/users/ui/users_list_page.dart';
import 'package:go_router/go_router.dart';

/// Application router. New routes are registered here feature-by-feature.
abstract class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.loginScreen,
    routes: [
      GoRoute(
        path: Routes.loginScreen,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.homeScreen,
        builder: (context, state) => const MainShellPage(),
      ),
      GoRoute(
        path: Routes.laboratorySelectionScreen,
        builder: (context, state) => const LaboratorySelectionPage(),
      ),
      GoRoute(
        path: Routes.rolesListScreen,
        builder: (context, state) => const RolesListPage(),
      ),
      GoRoute(
        path: Routes.roleFormScreen,
        builder: (context, state) =>
            RoleFormPage(initialRole: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: Routes.doctorsListScreen,
        builder: (context, state) => const DoctorsListPage(),
      ),
      GoRoute(
        path: Routes.doctorFormScreen,
        builder: (context, state) =>
            DoctorFormPage(initialDoctor: state.extra as DoctorModel?),
      ),
      GoRoute(
        path: Routes.doctorDetailScreen,
        builder: (context, state) =>
            DoctorDetailPage(doctorId: state.extra as String),
      ),
      GoRoute(
        path: Routes.casesShellScreen,
        builder: (context, state) => const CasesShellPage(),
      ),
      GoRoute(
        path: Routes.caseFormScreen,
        builder: (context, state) => const CaseFormPage(),
      ),
      GoRoute(
        path: Routes.caseDetailScreen,
        builder: (context, state) =>
            CaseDetailPage(caseId: state.extra as String),
      ),
      GoRoute(
        path: Routes.restorationTypesListScreen,
        builder: (context, state) => const RestorationTypesListPage(),
      ),
      GoRoute(
        path: Routes.restorationTypeFormScreen,
        builder: (context, state) => RestorationTypeFormPage(
          initialRestorationType: state.extra as RestorationTypeModel?,
        ),
      ),
      GoRoute(
        path: Routes.employeesListScreen,
        builder: (context, state) => const EmployeesListPage(),
      ),
      GoRoute(
        path: Routes.employeeFormScreen,
        builder: (context, state) =>
            EmployeeFormPage(initialEmployee: state.extra as EmployeeModel?),
      ),
      GoRoute(
        path: Routes.employeeDetailScreen,
        builder: (context, state) =>
            EmployeeDetailPage(employeeId: state.extra as String),
      ),
      GoRoute(
        path: Routes.usersListScreen,
        builder: (context, state) => const UsersListPage(),
      ),
      GoRoute(
        path: Routes.userFormScreen,
        builder: (context, state) => const UserFormPage(),
      ),
      GoRoute(
        path: Routes.userDetailScreen,
        builder: (context, state) =>
            UserDetailPage(userId: state.extra as String),
      ),
      GoRoute(
        path: Routes.clinicsListScreen,
        builder: (context, state) => const ClinicsListPage(),
      ),
      GoRoute(
        path: Routes.clinicFormScreen,
        builder: (context, state) =>
            ClinicFormPage(initialClinic: state.extra as ClinicModel?),
      ),
      GoRoute(
        path: Routes.clinicDetailScreen,
        builder: (context, state) =>
            ClinicDetailPage(clinicId: state.extra as String),
      ),
      GoRoute(
        path: Routes.laboratoriesListScreen,
        builder: (context, state) => const LaboratoriesListPage(),
      ),
      GoRoute(
        path: Routes.laboratoryFormScreen,
        builder: (context, state) =>
            LaboratoryFormPage(initialLaboratory: state.extra as LaboratoryModel?),
      ),
      GoRoute(
        path: Routes.laboratoryDetailScreen,
        builder: (context, state) =>
            LaboratoryDetailPage(laboratoryId: state.extra as String),
      ),
      GoRoute(
        path: Routes.myLaboratoryScreen,
        builder: (context, state) => const MyLaboratoryPage(),
      ),
      GoRoute(
        path: Routes.currenciesListScreen,
        builder: (context, state) => const CurrenciesListPage(),
      ),
      GoRoute(
        path: Routes.currencyFormScreen,
        builder: (context, state) =>
            CurrencyFormPage(initialCurrency: state.extra as Map<String, dynamic>?),
      ),
      GoRoute(
        path: Routes.currencyDetailScreen,
        builder: (context, state) =>
            CurrencyDetailPage(currency: state.extra as Map<String, dynamic>),
      ),
      GoRoute(
        path: Routes.countriesListScreen,
        builder: (context, state) => const CountriesListPage(),
      ),
      GoRoute(
        path: Routes.citiesListScreen,
        builder: (context, state) => const CitiesListPage(),
      ),
      GoRoute(
        path: Routes.priceTiersListScreen,
        builder: (context, state) => const PriceTiersListPage(),
      ),
      GoRoute(
        path: Routes.priceTierFormScreen,
        builder: (context, state) =>
            PriceTierFormPage(initialPriceTier: state.extra as PriceTierModel?),
      ),
      GoRoute(
        path: Routes.priceTierPricesScreen,
        builder: (context, state) =>
            PriceTierPricesPage(priceTier: state.extra as PriceTierModel),
      ),
      GoRoute(
        path: Routes.patientsListScreen,
        builder: (context, state) => const PatientsListPage(),
      ),
      GoRoute(
        path: Routes.patientDetailScreen,
        builder: (context, state) =>
            PatientDetailPage(patientId: state.extra as String),
      ),
      GoRoute(
        path: Routes.patientFormScreen,
        builder: (context, state) => const PatientFormPage(),
      ),
    ],
  );
}

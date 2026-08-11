import 'package:dental_lab_app/core/connectivity/connectivity_cubit.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/theming/font_scale_cubit.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/features/auth/data/repos/login_repo.dart';
import 'package:dental_lab_app/features/auth/logic/change_password/change_password_cubit.dart';
import 'package:dental_lab_app/features/auth/logic/login/login_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/data/repos/scanner_availability_repo.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_calendar/scanner_calendar_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_exceptions/scanner_exceptions_cubit.dart';
import 'package:dental_lab_app/features/scanner_availability/logic/scanner_rules/scanner_rules_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/data/repos/case_priorities_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priorities/case_priorities_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/case_priority_form/case_priority_form_cubit.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cities/data/repos/cities_repo.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/countries/data/repos/countries_repo.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_form/doctor_form_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_form/employee_form_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_form/price_tier_form_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_prices/price_tier_prices_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_type_form/restoration_type_form_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/roles/data/repos/roles_repo.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/users/logic/user_details/user_details_cubit.dart';
import 'package:dental_lab_app/features/users/logic/user_form/user_form_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_details/laboratory_details_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_form/laboratory_form_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_cubit.dart';
import 'package:get_it/get_it.dart';

/// Global service locator. Repositories and cubits are registered here as
/// features are connected to the API.
final GetIt getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // ---- Core ----
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  getIt.registerLazySingleton<FontScaleCubit>(() => FontScaleCubit());
  getIt.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());

  // ---- Auth ----
  getIt.registerLazySingleton<LoginRepo>(() => LoginRepo(getIt()));
  getIt.registerFactory<LoginCubit>(() => LoginCubit(getIt()));
  getIt.registerFactory<ChangePasswordCubit>(
    () => ChangePasswordCubit(getIt()),
  );

  // ---- Laboratories ----
  getIt.registerLazySingleton<LaboratoriesRepo>(
    () => LaboratoriesRepo(getIt()),
  );
  getIt.registerFactory<LaboratoriesCubit>(() => LaboratoriesCubit(getIt()));
  getIt.registerFactory<LaboratoryDetailsCubit>(
    () => LaboratoryDetailsCubit(getIt()),
  );
  getIt.registerFactory<LaboratoryFormCubit>(
    () => LaboratoryFormCubit(getIt()),
  );
  getIt.registerFactory<LaboratorySelectionCubit>(
    () => LaboratorySelectionCubit(getIt()),
  );

  // ---- Cities ----
  getIt.registerLazySingleton<CitiesRepo>(() => CitiesRepo(getIt()));
  getIt.registerFactory<CitiesCubit>(() => CitiesCubit(getIt()));

  // ---- Countries ----
  getIt.registerLazySingleton<CountriesRepo>(() => CountriesRepo(getIt()));
  getIt.registerFactory<CountriesCubit>(() => CountriesCubit(getIt()));

  // ---- Clinics ----
  getIt.registerLazySingleton<ClinicsRepo>(() => ClinicsRepo(getIt()));
  getIt.registerFactory<ClinicsCubit>(() => ClinicsCubit(getIt()));
  getIt.registerFactory<ClinicDetailsCubit>(() => ClinicDetailsCubit(getIt()));
  getIt.registerFactory<ClinicFormCubit>(() => ClinicFormCubit(getIt()));

  // ---- Doctors ----
  getIt.registerLazySingleton<DoctorsRepo>(() => DoctorsRepo(getIt()));
  getIt.registerFactory<DoctorsCubit>(() => DoctorsCubit(getIt()));
  getIt.registerFactory<DoctorFormCubit>(() => DoctorFormCubit(getIt()));
  getIt.registerFactory<DoctorDetailsCubit>(() => DoctorDetailsCubit(getIt()));

  // ---- Employees ----
  getIt.registerLazySingleton<EmployeesRepo>(() => EmployeesRepo(getIt()));
  getIt.registerFactory<EmployeesCubit>(() => EmployeesCubit(getIt()));
  getIt.registerFactory<EmployeeFormCubit>(() => EmployeeFormCubit(getIt()));
  getIt.registerFactory<EmployeeDetailsCubit>(
    () => EmployeeDetailsCubit(getIt()),
  );

  // ---- Roles ----
  getIt.registerLazySingleton<RolesRepo>(() => RolesRepo(getIt()));
  getIt.registerFactory<RolesCubit>(() => RolesCubit(getIt()));

  // ---- Users ----
  getIt.registerLazySingleton<UsersRepo>(() => UsersRepo(getIt()));
  getIt.registerFactory<UsersCubit>(() => UsersCubit(getIt()));
  getIt.registerFactory<UserFormCubit>(() => UserFormCubit(getIt()));
  getIt.registerFactory<UserDetailsCubit>(() => UserDetailsCubit(getIt()));

  // ---- Restoration types ----
  getIt.registerLazySingleton<RestorationTypesRepo>(
    () => RestorationTypesRepo(getIt()),
  );
  getIt.registerFactory<RestorationTypesCubit>(
    () => RestorationTypesCubit(getIt()),
  );
  getIt.registerFactory<RestorationTypeFormCubit>(
    () => RestorationTypeFormCubit(getIt()),
  );

  // ---- Price tiers ----
  getIt.registerLazySingleton<PriceTiersRepo>(() => PriceTiersRepo(getIt()));
  getIt.registerFactory<PriceTiersCubit>(() => PriceTiersCubit(getIt()));
  getIt.registerFactory<PriceTierFormCubit>(() => PriceTierFormCubit(getIt()));
  getIt.registerFactory<PriceTierPricesCubit>(
    () => PriceTierPricesCubit(getIt(), getIt()),
  );

  // ---- Patients ----
  getIt.registerLazySingleton<PatientsRepo>(() => PatientsRepo(getIt()));
  getIt.registerFactory<PatientsCubit>(() => PatientsCubit(getIt()));
  getIt.registerFactory<PatientFormCubit>(() => PatientFormCubit(getIt()));
  getIt.registerFactory<PatientDetailsCubit>(
    () => PatientDetailsCubit(getIt()),
  );

  // ---- Scanner availability ----
  getIt.registerLazySingleton<ScannerAvailabilityRepo>(
    () => ScannerAvailabilityRepo(getIt()),
  );
  getIt.registerFactory<ScannerRulesCubit>(() => ScannerRulesCubit(getIt()));
  getIt.registerFactory<ScannerExceptionsCubit>(
    () => ScannerExceptionsCubit(getIt()),
  );
  getIt.registerFactory<ScannerCalendarCubit>(
    () => ScannerCalendarCubit(getIt()),
  );

  // ---- Case priorities ----
  getIt.registerLazySingleton<CasePrioritiesRepo>(
    () => CasePrioritiesRepo(getIt()),
  );
  getIt.registerFactory<CasePrioritiesCubit>(
    () => CasePrioritiesCubit(getIt()),
  );
  getIt.registerFactory<CasePriorityFormCubit>(
    () => CasePriorityFormCubit(getIt()),
  );

  // ---- Cases ----
  getIt.registerLazySingleton<CasesRepo>(() => CasesRepo(getIt()));
  getIt.registerFactory<CasesCubit>(() => CasesCubit(getIt()));
  getIt.registerFactory<CaseFormCubit>(() => CaseFormCubit(getIt()));
  getIt.registerFactory<CaseDetailsCubit>(() => CaseDetailsCubit(getIt()));
  getIt.registerFactory<CaseMessagesCubit>(() => CaseMessagesCubit(getIt()));
}

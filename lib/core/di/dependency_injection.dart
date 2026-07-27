import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/features/auth/data/repos/login_repo.dart';
import 'package:dental_lab_app/features/auth/logic/login/login_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/case_workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/stage_form/stage_form_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/stages/stages_cubit.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/cities/data/repos/cities_repo.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_form/doctor_form_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_form/employee_form_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
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

  // ---- Auth ----
  getIt.registerLazySingleton<LoginRepo>(() => LoginRepo(getIt()));
  getIt.registerFactory<LoginCubit>(() => LoginCubit(getIt()));

  // ---- Laboratories ----
  getIt.registerLazySingleton<LaboratoriesRepo>(
    () => LaboratoriesRepo(getIt()),
  );
  getIt.registerFactory<LaboratoriesCubit>(() => LaboratoriesCubit(getIt()));
  getIt.registerFactory<LaboratoryDetailsCubit>(
    () => LaboratoryDetailsCubit(getIt()),
  );
  getIt.registerFactory<LaboratoryFormCubit>(() => LaboratoryFormCubit(getIt()));
  getIt.registerFactory<LaboratorySelectionCubit>(
    () => LaboratorySelectionCubit(getIt()),
  );

  // ---- Cities ----
  getIt.registerLazySingleton<CitiesRepo>(() => CitiesRepo(getIt()));
  getIt.registerFactory<CitiesCubit>(() => CitiesCubit(getIt()));

  // ---- Clinics ----
  getIt.registerLazySingleton<ClinicsRepo>(() => ClinicsRepo(getIt()));
  getIt.registerFactory<ClinicsCubit>(() => ClinicsCubit(getIt()));
  getIt.registerFactory<ClinicDetailsCubit>(
    () => ClinicDetailsCubit(getIt()),
  );
  getIt.registerFactory<ClinicFormCubit>(() => ClinicFormCubit(getIt()));

  // ---- Doctors ----
  getIt.registerLazySingleton<DoctorsRepo>(() => DoctorsRepo(getIt()));
  getIt.registerFactory<DoctorsCubit>(() => DoctorsCubit(getIt()));
  getIt.registerFactory<DoctorFormCubit>(() => DoctorFormCubit(getIt()));
  getIt.registerFactory<DoctorDetailsCubit>(
    () => DoctorDetailsCubit(getIt()),
  );

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

  // ---- Case workflow stages ----
  getIt.registerLazySingleton<CaseWorkflowStagesRepo>(
    () => CaseWorkflowStagesRepo(getIt()),
  );
  getIt.registerFactory<StagesCubit>(() => StagesCubit(getIt()));
  getIt.registerFactory<StageFormCubit>(() => StageFormCubit(getIt()));

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

  // ---- Cases ----
  getIt.registerLazySingleton<CasesRepo>(() => CasesRepo(getIt()));
  getIt.registerFactory<CasesCubit>(() => CasesCubit(getIt()));
  getIt.registerFactory<CaseFormCubit>(() => CaseFormCubit(getIt()));
  getIt.registerFactory<CaseDetailsCubit>(() => CaseDetailsCubit(getIt()));
}

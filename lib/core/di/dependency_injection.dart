import 'package:dental_lab_app/core/connectivity/connectivity_cubit.dart';
import 'package:dental_lab_app/core/helper/network_helper/api_service.dart';
import 'package:dental_lab_app/core/notifications/push_notification_service.dart';
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
import 'package:dental_lab_app/features/case_priorities/logic/doctor_quota/doctor_quota_cubit.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_allowance/priority_allowance_cubit.dart';
import 'package:dental_lab_app/features/case_stages/data/repos/case_stages_repo.dart';
import 'package:dental_lab_app/features/case_stages/logic/case_stages/case_stages_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/breakage_loss/breakage_loss_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_progress/case_progress_cubit.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:dental_lab_app/features/cases/logic/case_details/case_details_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_form/case_form_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/case_messages/case_messages_cubit.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:dental_lab_app/features/case_stages/logic/workflow_editor/workflow_editor_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/data/repos/workflow_stages_repo.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/route_editor/route_editor_cubit.dart';
import 'package:dental_lab_app/features/case_workflow_stages/logic/workflow_stages/workflow_stages_cubit.dart';
import 'package:dental_lab_app/features/departments/data/repos/departments_repo.dart';
import 'package:dental_lab_app/features/departments/logic/departments/departments_cubit.dart';
import 'package:dental_lab_app/features/notifications/data/repos/notifications_repo.dart';
import 'package:dental_lab_app/features/notifications/logic/notifications_cubit.dart';
import 'package:dental_lab_app/features/notifications/logic/broadcast/broadcast_cubit.dart';
import 'package:dental_lab_app/features/details_questions/data/repos/details_questions_repo.dart';
import 'package:dental_lab_app/features/excel_import/data/repos/excel_import_repo.dart';
import 'package:dental_lab_app/features/excel_import/logic/excel_import/excel_import_cubit.dart';
import 'package:dental_lab_app/features/details_questions/logic/details_questions/details_questions_cubit.dart';
import 'package:dental_lab_app/features/details_questions/logic/person_answers/person_answers_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/barcode_scan/barcode_scan_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/scan_task/scan_task_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/optional_stages/optional_stages_cubit.dart';
import 'package:dental_lab_app/features/cases/logic/route_preview/route_preview_cubit.dart';
import 'package:dental_lab_app/features/scanner_sessions/data/repos/scanner_sessions_repo.dart';
import 'package:dental_lab_app/features/scanner_sessions/logic/scanner_sessions/scanner_sessions_cubit.dart';
import 'package:dental_lab_app/features/scanner_sessions/logic/session_messages/session_messages_cubit.dart';
import 'package:dental_lab_app/features/dashboard/data/repos/dashboard_repo.dart';
import 'package:dental_lab_app/features/dashboard/logic/dashboard/dashboard_cubit.dart';
import 'package:dental_lab_app/features/accounting/data/repos/accounting_repo.dart';
import 'package:dental_lab_app/features/accounting/logic/accounting_statistics/accounting_statistics_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/doctor_statement/doctor_statement_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/cashbox/cashbox_cubit.dart';
import 'package:dental_lab_app/features/assistant/data/repos/assistant_repo.dart';
import 'package:dental_lab_app/features/attendance/data/repos/attendance_repo.dart';
import 'package:dental_lab_app/features/representatives/data/repos/representative_agents_repo.dart';
import 'package:dental_lab_app/features/branding/data/repos/branding_repo.dart';
import 'package:dental_lab_app/features/case_priorities/logic/priority_overview/priority_overview_cubit.dart';
import 'package:dental_lab_app/features/deletion/data/repos/deletion_repo.dart';
import 'package:dental_lab_app/features/branding/logic/branding_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/daily_attendance/daily_attendance_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/holidays/holidays_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/leaves/leaves_cubit.dart';
import 'package:dental_lab_app/features/attendance/logic/work_shifts/work_shifts_cubit.dart';
import 'package:dental_lab_app/features/payroll/data/repos/payroll_repo.dart';
import 'package:dental_lab_app/features/photography_visits/data/repos/photography_visits_repo.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_detail/photography_visit_detail_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visit_form/photography_visit_form_cubit.dart';
import 'package:dental_lab_app/features/photography_visits/logic/photography_visits/photography_visits_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/data/repos/stage_pay_repo.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_earnings/stage_earnings_cubit.dart';
import 'package:dental_lab_app/features/stage_pay/logic/stage_rates/stage_rates_cubit.dart';
import 'package:dental_lab_app/features/payroll/logic/payroll/payroll_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/expenses/expenses_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/invoice_form/invoice_form_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/invoices/invoices_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/manual_payment/manual_payment_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/payments/payments_cubit.dart';
import 'package:dental_lab_app/features/accounting/logic/pending_payments/pending_payments_cubit.dart';
import 'package:dental_lab_app/features/areas/data/repos/areas_repo.dart';
import 'package:dental_lab_app/features/areas/logic/areas/areas_cubit.dart';
import 'package:dental_lab_app/features/currencies/data/repos/currencies_repo.dart';
import 'package:dental_lab_app/features/currencies/logic/currencies/currencies_cubit.dart';
import 'package:dental_lab_app/features/currencies/logic/currency_assignment/currency_assignment_cubit.dart';
import 'package:dental_lab_app/features/inventory/data/repos/inventory_repo.dart';
import 'package:dental_lab_app/features/inventory/logic/inventory/inventory_cubit.dart';
import 'package:dental_lab_app/features/purchases/data/repos/purchases_repo.dart';
import 'package:dental_lab_app/features/purchases/logic/purchase_form/purchase_form_cubit.dart';
import 'package:dental_lab_app/features/purchases/logic/purchases/purchases_cubit.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/repos/case_ticket_templates_repo.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_template_editor/case_ticket_template_editor_cubit.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_templates/case_ticket_templates_cubit.dart';
import 'package:dental_lab_app/features/store_reports/data/repos/store_reports_repo.dart';
import 'package:dental_lab_app/features/store_reports/logic/feasibility/feasibility_cubit.dart';
import 'package:dental_lab_app/features/suppliers/data/repos/suppliers_repo.dart';
import 'package:dental_lab_app/features/suppliers/logic/suppliers/suppliers_cubit.dart';
import 'package:dental_lab_app/features/cities/data/repos/cities_repo.dart';
import 'package:dental_lab_app/features/cities/logic/cities/cities_cubit.dart';
import 'package:dental_lab_app/features/zones/data/repos/zones_repo.dart';
import 'package:dental_lab_app/features/zones/logic/zone_form/zone_form_cubit.dart';
import 'package:dental_lab_app/features/zones/logic/zones/zones_cubit.dart';
import 'package:dental_lab_app/features/clinics/data/repos/clinics_repo.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_details/clinic_details_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinic_form/clinic_form_cubit.dart';
import 'package:dental_lab_app/features/clinics/logic/clinics/clinics_cubit.dart';
import 'package:dental_lab_app/features/countries/data/repos/countries_repo.dart';
import 'package:dental_lab_app/features/countries/logic/countries/countries_cubit.dart';
import 'package:dental_lab_app/features/doctors/data/repos/doctors_repo.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_details/doctor_details_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_excluded_representatives/doctor_excluded_representatives_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctor_form/doctor_form_cubit.dart';
import 'package:dental_lab_app/features/doctors/logic/doctors/doctors_cubit.dart';
import 'package:dental_lab_app/features/employees/data/repos/employees_repo.dart';
import 'package:dental_lab_app/features/employees/logic/employee_details/employee_details_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_form/employee_form_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_hr/employee_hr_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employee_work/employee_work_cubit.dart';
import 'package:dental_lab_app/features/employees/logic/employees/employees_cubit.dart';
import 'package:dental_lab_app/features/patients/data/repos/patients_repo.dart';
import 'package:dental_lab_app/features/patients/logic/patient_details/patient_details_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patient_form/patient_form_cubit.dart';
import 'package:dental_lab_app/features/patients/logic/patients/patients_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/data/repos/price_tiers_repo.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_form/price_tier_form_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_doctors/price_tier_doctors_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tier_prices/price_tier_prices_cubit.dart';
import 'package:dental_lab_app/features/price_tiers/logic/price_tiers/price_tiers_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/data/repos/restoration_types_repo.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_type_form/restoration_type_form_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/roles/data/repos/roles_repo.dart';
import 'package:dental_lab_app/features/roles/logic/role_form/role_form_cubit.dart';
import 'package:dental_lab_app/features/roles/logic/roles/roles_cubit.dart';
import 'package:dental_lab_app/features/users/data/repos/users_repo.dart';
import 'package:dental_lab_app/features/users/logic/user_details/user_details_cubit.dart';
import 'package:dental_lab_app/features/users/logic/user_form/user_form_cubit.dart';
import 'package:dental_lab_app/features/users/logic/users/users_cubit.dart';
import 'package:dental_lab_app/features/laboratories/data/repos/laboratories_repo.dart';
import 'package:dental_lab_app/features/laboratories/logic/printed_identity/printed_identity_cubit.dart';
import 'package:dental_lab_app/features/scan_storage/data/repos/scan_storage_repo.dart';
import 'package:dental_lab_app/features/scan_storage/logic/scan_storage/scan_storage_cubit.dart';
import 'package:dental_lab_app/features/employee_activity/data/repos/employee_activity_repo.dart';
import 'package:dental_lab_app/features/employee_activity/logic/employee_activity/employee_activity_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratories/laboratories_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_details/laboratory_details_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_form/laboratory_form_cubit.dart';
import 'package:dental_lab_app/features/laboratories/logic/laboratory_selection/laboratory_selection_cubit.dart';
import 'package:dental_lab_app/core/printing/label_printer_service.dart';
import 'package:get_it/get_it.dart';

/// Global service locator. Repositories and cubits are registered here as
/// features are connected to the API.
final GetIt getIt = GetIt.instance;

Future<void> setupGetIt() async {
  // ---- Core ----
  getIt.registerLazySingleton<ApiService>(() => ApiService());
  // One instance for the app: the printer connection should survive between
  // the barcode screen and wherever else printing is offered, rather than
  // reconnecting (and re-pairing) every time a sheet opens.
  getIt.registerLazySingleton<LabelPrinterService>(() => LabelPrinterService());
  // One session for the whole app: the drawer, the bottom bar and every gated
  // screen must agree on what the user may do.
  getIt.registerLazySingleton<SessionCubit>(() => SessionCubit());
  getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit());
  getIt.registerLazySingleton<FontScaleCubit>(() => FontScaleCubit());
  getIt.registerLazySingleton<ConnectivityCubit>(() => ConnectivityCubit());
  // Depends on NotificationsRepo (registered below) — fine, since a lazy
  // singleton's factory only runs on first resolution, by which point the
  // whole graph below has already been registered.
  getIt.registerLazySingleton<PushNotificationService>(
    () => PushNotificationService(getIt()),
  );

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

  // ---- Currencies ----
  getIt.registerLazySingleton<CurrenciesRepo>(() => CurrenciesRepo(getIt()));
  getIt.registerFactory<CurrenciesCubit>(() => CurrenciesCubit(getIt()));

  // ---- Inventory ----
  getIt.registerLazySingleton<InventoryRepo>(() => InventoryRepo(getIt()));
  getIt.registerFactory<InventoryCubit>(() => InventoryCubit(getIt()));

  // ---- Suppliers ----
  getIt.registerLazySingleton<SuppliersRepo>(() => SuppliersRepo(getIt()));
  getIt.registerFactory<SuppliersCubit>(() => SuppliersCubit(getIt()));

  // ---- Purchases ----
  getIt.registerLazySingleton<PurchasesRepo>(() => PurchasesRepo(getIt()));
  getIt.registerFactory<PurchasesCubit>(() => PurchasesCubit(getIt()));
  // Depends on SuppliersRepo, InventoryRepo and AccountingRepo (all
  // registered elsewhere in this file) — fine, since a lazy singleton's
  // factory only runs on first resolution.
  getIt.registerFactory<PurchaseFormCubit>(
    () => PurchaseFormCubit(getIt(), getIt(), getIt(), getIt()),
  );

  // ---- Case ticket templates ----
  getIt.registerLazySingleton<CaseTicketTemplatesRepo>(
    () => CaseTicketTemplatesRepo(getIt()),
  );
  getIt.registerFactory<CaseTicketTemplatesCubit>(
    () => CaseTicketTemplatesCubit(getIt()),
  );
  getIt.registerFactory<CaseTicketTemplateEditorCubit>(
    () => CaseTicketTemplateEditorCubit(getIt()),
  );

  // ---- Store reports ----
  getIt.registerLazySingleton<StoreReportsRepo>(
    () => StoreReportsRepo(getIt()),
  );
  getIt.registerFactory<FeasibilityCubit>(() => FeasibilityCubit(getIt()));

  // ---- Areas ----
  getIt.registerLazySingleton<AreasRepo>(() => AreasRepo(getIt()));
  getIt.registerFactory<AreasCubit>(() => AreasCubit(getIt()));

  // ---- Zones ----
  getIt.registerLazySingleton<ZonesRepo>(() => ZonesRepo(getIt()));
  getIt.registerFactory<ZonesCubit>(() => ZonesCubit(getIt()));
  // Depends on AreasRepo and UsersRepo (registered elsewhere in this file) —
  // fine, since a lazy singleton's factory only runs on first resolution.
  getIt.registerFactory<ZoneFormCubit>(
    () => ZoneFormCubit(getIt(), getIt(), getIt(), getIt()),
  );

  // ---- Accounting ----
  getIt.registerLazySingleton<AccountingRepo>(() => AccountingRepo(getIt()));
  getIt.registerFactory<InvoicesCubit>(() => InvoicesCubit(getIt()));
  getIt.registerFactory<AccountingStatisticsCubit>(
    () => AccountingStatisticsCubit(getIt()),
  );
  getIt.registerFactory<PaymentsCubit>(() => PaymentsCubit(getIt()));
  getIt.registerFactory<PendingPaymentsCubit>(
    () => PendingPaymentsCubit(getIt()),
  );
  getIt.registerFactory<ManualPaymentCubit>(() => ManualPaymentCubit(getIt()));
  getIt.registerFactory<ExpensesCubit>(() => ExpensesCubit(getIt()));
  getIt.registerFactory<CashboxCubit>(() => CashboxCubit(getIt()));
  getIt.registerLazySingleton<ScanStorageRepo>(() => ScanStorageRepo(getIt()));
  getIt.registerLazySingleton<ExcelImportRepo>(() => ExcelImportRepo(getIt()));
  getIt.registerFactory<ExcelImportCubit>(() => ExcelImportCubit(getIt()));
  getIt.registerLazySingleton<DetailsQuestionsRepo>(
    () => DetailsQuestionsRepo(getIt()),
  );
  getIt.registerFactory<DetailsQuestionsCubit>(
    () => DetailsQuestionsCubit(getIt()),
  );
  getIt.registerFactory<PersonAnswersCubit>(() => PersonAnswersCubit(getIt()));
  getIt.registerFactory<BroadcastCubit>(() => BroadcastCubit(getIt()));
  getIt.registerFactory<ScanStorageCubit>(() => ScanStorageCubit(getIt()));
  getIt.registerLazySingleton<EmployeeActivityRepo>(
    () => EmployeeActivityRepo(getIt()),
  );
  getIt.registerFactory<EmployeeActivityCubit>(
    () => EmployeeActivityCubit(getIt()),
  );
  getIt.registerFactory<PrintedIdentityCubit>(
    () => PrintedIdentityCubit(getIt()),
  );
  getIt.registerFactory<CurrencyAssignmentCubit>(
    () => CurrencyAssignmentCubit(getIt()),
  );
  getIt.registerFactory<SessionMessagesCubit>(
    () => SessionMessagesCubit(getIt()),
  );
  getIt.registerFactory<PriorityOverviewCubit>(
    () => PriorityOverviewCubit(getIt()),
  );

  // ---- Branding ----
  // A singleton, and eagerly constructed: `main` loads it before the first
  // frame so the login screen is already in the laboratory's own colour.
  getIt.registerLazySingleton<BrandingRepo>(BrandingRepo.new);
  getIt.registerLazySingleton<BrandingCubit>(() => BrandingCubit(getIt()));

  // ---- Assistant & representative agents ----
  getIt.registerLazySingleton<AssistantRepo>(AssistantRepo.new);
  getIt.registerLazySingleton<RepresentativeAgentsRepo>(
    RepresentativeAgentsRepo.new,
  );

  // ---- Employee HR & work ----
  getIt.registerFactory<EmployeeHrCubit>(() => EmployeeHrCubit(getIt()));
  getIt.registerFactory<EmployeeWorkCubit>(
    () => EmployeeWorkCubit(getIt(), getIt()),
  );

  // ---- Generic deletion ----
  // One mechanism for every entity type — see `showDeletionPlanSheet`.
  getIt.registerLazySingleton<DeletionRepo>(DeletionRepo.new);

  // ---- Attendance & payroll ----
  getIt.registerLazySingleton<AttendanceRepo>(() => AttendanceRepo(getIt()));
  getIt.registerLazySingleton<PayrollRepo>(() => PayrollRepo(getIt()));
  getIt.registerFactory<DailyAttendanceCubit>(
    () => DailyAttendanceCubit(getIt()),
  );
  getIt.registerFactory<LeavesCubit>(() => LeavesCubit(getIt()));
  getIt.registerFactory<HolidaysCubit>(() => HolidaysCubit(getIt()));
  getIt.registerFactory<WorkShiftsCubit>(() => WorkShiftsCubit(getIt()));
  getIt.registerFactory<ShiftRosterCubit>(() => ShiftRosterCubit(getIt()));
  getIt.registerFactory<PayrollCubit>(() => PayrollCubit(getIt()));
  getIt.registerLazySingleton<StagePayRepo>(() => StagePayRepo(getIt()));
  getIt.registerLazySingleton<PhotographyVisitsRepo>(
    () => PhotographyVisitsRepo(getIt()),
  );
  getIt.registerFactory<PhotographyVisitsCubit>(
    () => PhotographyVisitsCubit(getIt(), getIt()),
  );
  getIt.registerFactory<PhotographyVisitDetailCubit>(
    () => PhotographyVisitDetailCubit(getIt(), getIt(), getIt()),
  );
  getIt.registerFactory<PhotographyVisitFormCubit>(
    () => PhotographyVisitFormCubit(getIt(), getIt(), getIt(), getIt()),
  );
  getIt.registerFactory<BreakageLossCubit>(
    () => BreakageLossCubit(getIt(), getIt()),
  );
  getIt.registerFactory<StageRatesCubit>(() => StageRatesCubit(getIt()));
  getIt.registerFactory<StageEarningsCubit>(
    () => StageEarningsCubit(getIt(), getIt()),
  );
  getIt.registerFactory<DoctorStatementCubit>(
    () => DoctorStatementCubit(getIt()),
  );
  getIt.registerFactory<InvoiceFormCubit>(
    () => InvoiceFormCubit(getIt(), getIt()),
  );

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
  getIt.registerFactory<DoctorDetailsCubit>(
    () => DoctorDetailsCubit(getIt(), getIt()),
  );
  getIt.registerFactory<DoctorExcludedRepresentativesCubit>(
    () => DoctorExcludedRepresentativesCubit(getIt(), getIt()),
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
  getIt.registerFactory<RoleFormCubit>(() => RoleFormCubit(getIt()));

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
  getIt.registerFactory<PriceTierDoctorsCubit>(
    () => PriceTierDoctorsCubit(getIt()),
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
  getIt.registerFactory<DoctorQuotaCubit>(() => DoctorQuotaCubit(getIt()));
  getIt.registerFactory<PriorityAllowanceCubit>(
    () => PriorityAllowanceCubit(getIt()),
  );
  getIt.registerFactory<CasePriorityFormCubit>(
    () => CasePriorityFormCubit(getIt()),
  );

  // ---- Notifications ----
  getIt.registerLazySingleton<NotificationsRepo>(
    () => NotificationsRepo(getIt()),
  );
  getIt.registerFactory<NotificationsCubit>(() => NotificationsCubit(getIt()));

  // ---- Case stages (the lab's own case workflow) ----
  getIt.registerLazySingleton<CaseStagesRepo>(() => CaseStagesRepo(getIt()));
  getIt.registerFactory<CaseStagesCubit>(() => CaseStagesCubit(getIt()));
  getIt.registerFactory<WorkflowEditorCubit>(
    () => WorkflowEditorCubit(getIt()),
  );

  // ---- Restoration route stages ----
  getIt.registerLazySingleton<WorkflowStagesRepo>(
    () => WorkflowStagesRepo(getIt()),
  );
  getIt.registerFactory<RouteEditorCubit>(() => RouteEditorCubit(getIt()));
  // Reads both stage catalogues, so it is registered where the second one is.
  getIt.registerFactory<BarcodeScanCubit>(() => BarcodeScanCubit(getIt()));
  getIt.registerFactory<ScanTaskCubit>(() => ScanTaskCubit(getIt()));
  getIt.registerFactory<OptionalStagesCubit>(
    () => OptionalStagesCubit(getIt(), getIt()),
  );
  getIt.registerFactory<WorkflowStagesCubit>(
    () => WorkflowStagesCubit(getIt()),
  );

  // ---- Departments ----
  getIt.registerLazySingleton<DepartmentsRepo>(() => DepartmentsRepo(getIt()));
  getIt.registerFactory<DepartmentsCubit>(() => DepartmentsCubit(getIt()));

  // ---- Cases ----
  getIt.registerLazySingleton<CasesRepo>(() => CasesRepo(getIt()));
  getIt.registerFactory<CasesCubit>(() => CasesCubit(getIt()));
  getIt.registerFactory<CaseFormCubit>(() => CaseFormCubit(getIt()));
  getIt.registerFactory<CaseDetailsCubit>(() => CaseDetailsCubit(getIt()));
  // Reads the board from `GET /Cases/{id}/flow` — the server assembles the
  // whole lifecycle, so there is nothing left to compose from catalogues.
  getIt.registerFactory<CaseProgressCubit>(() => CaseProgressCubit(getIt()));
  getIt.registerFactory<CaseMessagesCubit>(() => CaseMessagesCubit(getIt()));
  getIt.registerFactory<RoutePreviewCubit>(() => RoutePreviewCubit(getIt()));

  // ---- Scanner sessions ----
  getIt.registerLazySingleton<ScannerSessionsRepo>(
    () => ScannerSessionsRepo(getIt()),
  );
  getIt.registerFactory<ScannerSessionsCubit>(
    () => ScannerSessionsCubit(getIt()),
  );

  // ---- Dashboard ----
  getIt.registerLazySingleton<DashboardRepo>(() => DashboardRepo(getIt()));
  getIt.registerFactory<DashboardCubit>(() => DashboardCubit(getIt()));
}

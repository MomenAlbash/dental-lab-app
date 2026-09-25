import 'package:dental_lab_app/core/helper/local/cache_keys.dart';
import 'package:dental_lab_app/core/helper/local/cached_helper.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/features/auth/ui/login_page.dart';
import 'package:dental_lab_app/features/scanner_availability/ui/scanner_availability_page.dart';
import 'package:dental_lab_app/features/scanner_sessions/ui/scanner_sessions_page.dart';
import 'package:dental_lab_app/features/case_priorities/data/models/case_priority_model.dart';
import 'package:dental_lab_app/features/case_priorities/ui/case_priorities_list_page.dart';
import 'package:dental_lab_app/features/case_ticket_templates/ui/case_ticket_template_editor_page.dart';
import 'package:dental_lab_app/features/case_ticket_templates/ui/case_ticket_templates_list_page.dart';
import 'package:dental_lab_app/features/case_stages/ui/case_workflow_editor_page.dart';
import 'package:dental_lab_app/features/case_workflow_stages/ui/restoration_route_editor_page.dart';
import 'package:dental_lab_app/features/departments/ui/departments_page.dart';
import 'package:dental_lab_app/features/case_priorities/ui/case_priority_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/case_detail_page.dart';
import 'package:dental_lab_app/features/cases/ui/barcode_scanner_page.dart';
import 'package:dental_lab_app/features/cases/ui/scan_task_page.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/cases_list_page.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:dental_lab_app/features/clinics/ui/clinic_detail_page.dart';
import 'package:dental_lab_app/features/clinics/ui/clinic_form_page.dart';
import 'package:dental_lab_app/features/clinics/ui/clinics_list_page.dart';
import 'package:dental_lab_app/features/currencies/ui/currencies_list_page.dart';
import 'package:dental_lab_app/features/inventory/ui/inventory_list_page.dart';
import 'package:dental_lab_app/features/purchases/ui/purchase_form_page.dart';
import 'package:dental_lab_app/features/purchases/ui/purchases_list_page.dart';
import 'package:dental_lab_app/features/store_reports/ui/feasibility_report_page.dart';
import 'package:dental_lab_app/features/suppliers/ui/suppliers_list_page.dart';
import 'package:dental_lab_app/features/accounting/ui/accounting_overview_page.dart';
import 'package:dental_lab_app/features/accounting/ui/invoice_detail_page.dart';
import 'package:dental_lab_app/features/accounting/ui/doctor_statement_page.dart';
import 'package:dental_lab_app/features/accounting/ui/cashbox_page.dart';
import 'package:dental_lab_app/features/attendance/ui/attendance_hub_page.dart';
import 'package:dental_lab_app/features/attendance/ui/work_shifts_page.dart';
import 'package:dental_lab_app/features/branding/ui/branding_page.dart';
import 'package:dental_lab_app/features/case_priorities/ui/priority_overview_page.dart';
import 'package:dental_lab_app/features/scan_storage/ui/scan_storage_page.dart';
import 'package:dental_lab_app/features/notifications/ui/broadcast_page.dart';
import 'package:dental_lab_app/features/details_questions/ui/details_questions_page.dart';
import 'package:dental_lab_app/features/excel_import/ui/excel_import_page.dart';
import 'package:dental_lab_app/features/employee_activity/ui/employee_activity_page.dart';
import 'package:dental_lab_app/features/payroll/ui/payroll_page.dart';
import 'package:dental_lab_app/features/photography_visits/ui/photography_visit_detail_page.dart';
import 'package:dental_lab_app/features/photography_visits/ui/photography_visit_form_page.dart';
import 'package:dental_lab_app/features/photography_visits/ui/photography_visits_page.dart';
import 'package:dental_lab_app/features/stage_pay/ui/stage_pay_page.dart';
import 'package:dental_lab_app/features/accounting/ui/expenses_list_page.dart';
import 'package:dental_lab_app/features/accounting/ui/invoice_form_page.dart';
import 'package:dental_lab_app/features/accounting/ui/invoices_list_page.dart';
import 'package:dental_lab_app/features/accounting/ui/manual_payment_form_page.dart';
import 'package:dental_lab_app/features/accounting/ui/payments_list_page.dart';
import 'package:dental_lab_app/features/accounting/ui/pending_payments_page.dart';
import 'package:dental_lab_app/features/areas/ui/areas_list_page.dart';
import 'package:dental_lab_app/features/cities/ui/cities_list_page.dart';
import 'package:dental_lab_app/features/zones/data/models/zone_model.dart';
import 'package:dental_lab_app/features/zones/ui/zone_form_page.dart';
import 'package:dental_lab_app/features/zones/ui/zones_list_page.dart';
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
import 'package:dental_lab_app/features/patients/data/models/patient_model.dart';
import 'package:dental_lab_app/features/patients/ui/patient_detail_page.dart';
import 'package:dental_lab_app/features/patients/ui/patient_form_page.dart';
import 'package:dental_lab_app/features/patients/ui/patients_list_page.dart';
import 'package:dental_lab_app/features/price_tiers/data/models/price_tier_model.dart';
import 'package:dental_lab_app/features/price_tiers/ui/price_tier_details_page.dart';
import 'package:dental_lab_app/features/price_tiers/ui/price_tier_form_page.dart';
import 'package:dental_lab_app/features/price_tiers/ui/price_tier_prices_page.dart';
import 'package:dental_lab_app/features/price_tiers/ui/price_tiers_list_page.dart';
import 'package:dental_lab_app/features/restoration_types/data/models/restoration_type_model.dart';
import 'package:dental_lab_app/features/restoration_types/ui/restoration_type_form_page.dart';
import 'package:dental_lab_app/features/restoration_types/ui/restoration_types_list_page.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
import 'package:dental_lab_app/features/roles/ui/role_form_page.dart';
import 'package:dental_lab_app/features/roles/ui/roles_list_page.dart';
import 'package:dental_lab_app/features/settings/ui/settings_page.dart';
import 'package:dental_lab_app/features/users/ui/user_detail_page.dart';
import 'package:dental_lab_app/features/users/ui/user_form_page.dart';
import 'package:dental_lab_app/features/users/ui/users_list_page.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Application router. New routes are registered here feature-by-feature.
abstract class AppRouter {
  /// Fade + slight upward slide, matching the glass design system's motion.
  /// Applied per-route (currently the doctors flow) rather than globally so
  /// untouched screens keep their existing platform transition.
  static CustomTransitionPage<void> _glassPage(
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppMotion.slow,
      reverseTransitionDuration: AppMotion.base,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enter,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static final GoRouter router = GoRouter(
    initialLocation: Routes.loginScreen,
    // Skips straight past login (and laboratory selection, if a lab was
    // already picked) when a session is already cached from a previous run
    // — otherwise every app restart forced the user to log in again.
    redirect: (context, state) {
      if (state.matchedLocation != Routes.loginScreen) return null;

      final token = CacheHelper.getData(key: CacheKeys.token) as String?;
      if (token == null || token.isEmpty) return null;

      final laboratoryId =
          CacheHelper.getData(key: CacheKeys.laboratoryId) as String?;
      return (laboratoryId == null || laboratoryId.isEmpty)
          ? Routes.laboratorySelectionScreen
          : Routes.homeScreen;
    },
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
            RoleFormPage(initialRole: state.extra as RoleModel?),
      ),
      // The doctors flow is the pilot for the glass design system, so it uses
      // the softer fade+slide transition instead of the platform default.
      GoRoute(
        path: Routes.doctorsListScreen,
        pageBuilder: (context, state) =>
            _glassPage(state, const DoctorsListPage()),
      ),
      GoRoute(
        path: Routes.doctorFormScreen,
        pageBuilder: (context, state) => _glassPage(
          state,
          DoctorFormPage(initialDoctor: state.extra as DoctorModel?),
        ),
      ),
      GoRoute(
        path: Routes.doctorDetailScreen,
        pageBuilder: (context, state) => _glassPage(
          state,
          DoctorDetailPage(doctorId: state.extra as String),
        ),
      ),
      GoRoute(
        path: Routes.casesListScreen,
        builder: (context, state) => const CasesListPage(),
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
        path: Routes.barcodeScannerScreen,
        builder: (context, state) => const BarcodeScannerPage(),
      ),
      GoRoute(
        path: Routes.scanTaskScreen,
        builder: (context, state) {
          // The scanner already resolved both — passing them on rather than
          // refetching keeps the technician on one round trip, which is the
          // whole point of scanning the piece's own label.
          final args = state.extra as ScanTaskArgs;
          return ScanTaskPage(
            caseDetail: args.caseDetail,
            restorationId: args.restorationId,
          );
        },
      ),
      GoRoute(
        path: Routes.scannerAvailabilityScreen,
        builder: (context, state) => const ScannerAvailabilityPage(),
      ),
      GoRoute(
        path: Routes.scannerSessionsScreen,
        builder: (context, state) => const ScannerSessionsPage(),
      ),
      GoRoute(
        path: Routes.photographyVisitsScreen,
        builder: (context, state) => const PhotographyVisitsPage(),
      ),
      GoRoute(
        path: Routes.photographyVisitFormScreen,
        builder: (context, state) => const PhotographyVisitFormPage(),
      ),
      GoRoute(
        path: Routes.photographyVisitDetailScreen,
        builder: (context, state) =>
            PhotographyVisitDetailPage(visitId: state.extra as String),
      ),
      GoRoute(
        path: Routes.casePrioritiesListScreen,
        builder: (context, state) => const CasePrioritiesListPage(),
      ),
      GoRoute(
        path: Routes.caseWorkflowEditorScreen,
        builder: (context, state) => const CaseWorkflowEditorPage(),
      ),
      GoRoute(
        path: Routes.restorationRouteEditorScreen,
        builder: (context, state) => RestorationRouteEditorPage(
          args: state.extra as RestorationRouteEditorArgs,
        ),
      ),
      GoRoute(
        path: Routes.departmentsScreen,
        builder: (context, state) => const DepartmentsPage(),
      ),
      GoRoute(
        path: Routes.casePriorityFormScreen,
        builder: (context, state) => CasePriorityFormPage(
          initialPriority: state.extra as CasePriorityModel?,
        ),
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
      // The clinics flow uses the same glass fade+slide transition as the
      // doctors and patients flows.
      GoRoute(
        path: Routes.clinicsListScreen,
        pageBuilder: (context, state) =>
            _glassPage(state, const ClinicsListPage()),
      ),
      GoRoute(
        path: Routes.clinicFormScreen,
        pageBuilder: (context, state) => _glassPage(
          state,
          ClinicFormPage(initialClinic: state.extra as ClinicModel?),
        ),
      ),
      GoRoute(
        path: Routes.clinicDetailScreen,
        pageBuilder: (context, state) => _glassPage(
          state,
          ClinicDetailPage(clinicId: state.extra as String),
        ),
      ),
      GoRoute(
        path: Routes.laboratoriesListScreen,
        builder: (context, state) => const LaboratoriesListPage(),
      ),
      GoRoute(
        path: Routes.laboratoryFormScreen,
        builder: (context, state) => LaboratoryFormPage(
          initialLaboratory: state.extra as LaboratoryModel?,
        ),
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
        path: Routes.inventoryListScreen,
        builder: (context, state) => const InventoryListPage(),
      ),
      GoRoute(
        path: Routes.suppliersListScreen,
        builder: (context, state) => const SuppliersListPage(),
      ),
      GoRoute(
        path: Routes.purchasesListScreen,
        builder: (context, state) => const PurchasesListPage(),
      ),
      GoRoute(
        path: Routes.purchaseFormScreen,
        builder: (context, state) => const PurchaseFormPage(),
      ),
      GoRoute(
        path: Routes.feasibilityReportScreen,
        builder: (context, state) => const FeasibilityReportPage(),
      ),
      GoRoute(
        path: Routes.caseTicketTemplatesListScreen,
        builder: (context, state) => const CaseTicketTemplatesListPage(),
      ),
      GoRoute(
        path: Routes.caseTicketTemplateEditorScreen,
        builder: (context, state) =>
            CaseTicketTemplateEditorPage(templateId: state.extra as String),
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
        path: Routes.areasListScreen,
        builder: (context, state) => const AreasListPage(),
      ),
      GoRoute(
        path: Routes.zonesListScreen,
        builder: (context, state) => const ZonesListPage(),
      ),
      GoRoute(
        path: Routes.zoneFormScreen,
        builder: (context, state) =>
            ZoneFormPage(initialZone: state.extra as ZoneModel?),
      ),
      GoRoute(
        path: Routes.accountingOverviewScreen,
        builder: (context, state) => const AccountingOverviewPage(),
      ),
      GoRoute(
        path: Routes.invoicesListScreen,
        builder: (context, state) => const InvoicesListPage(),
      ),
      GoRoute(
        path: Routes.invoiceDetailScreen,
        builder: (context, state) =>
            InvoiceDetailPage(invoiceId: state.extra as String),
      ),
      GoRoute(
        path: Routes.invoiceFormScreen,
        builder: (context, state) => const InvoiceFormPage(),
      ),
      GoRoute(
        path: Routes.paymentsListScreen,
        builder: (context, state) => const PaymentsListPage(),
      ),
      GoRoute(
        path: Routes.pendingPaymentsScreen,
        builder: (context, state) => const PendingPaymentsPage(),
      ),
      GoRoute(
        path: Routes.expensesListScreen,
        builder: (context, state) => const ExpensesListPage(),
      ),
      GoRoute(
        path: Routes.doctorStatementScreen,
        builder: (context, state) =>
            DoctorStatementPage(initialDoctorId: state.extra as String?),
      ),
      GoRoute(
        path: Routes.cashboxScreen,
        builder: (context, state) => const CashboxPage(),
      ),
      GoRoute(
        path: Routes.attendanceHubScreen,
        builder: (context, state) => const AttendanceHubPage(),
      ),
      GoRoute(
        path: Routes.workShiftsScreen,
        builder: (context, state) => const WorkShiftsPage(),
      ),
      GoRoute(
        path: Routes.payrollScreen,
        builder: (context, state) => const PayrollPage(),
      ),
      GoRoute(
        path: Routes.stagePayScreen,
        builder: (context, state) => const StagePayPage(),
      ),
      GoRoute(
        path: Routes.excelImportScreen,
        builder: (context, state) => const ExcelImportPage(),
      ),
      GoRoute(
        path: Routes.detailsQuestionsScreen,
        builder: (context, state) => const DetailsQuestionsPage(),
      ),
      GoRoute(
        path: Routes.broadcastScreen,
        builder: (context, state) => const BroadcastPage(),
      ),
      GoRoute(
        path: Routes.scanStorageScreen,
        builder: (context, state) => const ScanStoragePage(),
      ),
      GoRoute(
        path: Routes.employeeActivityScreen,
        builder: (context, state) => const EmployeeActivityPage(),
      ),
      GoRoute(
        path: Routes.priorityOverviewScreen,
        builder: (context, state) => const PriorityOverviewPage(),
      ),
      GoRoute(
        path: Routes.brandingScreen,
        builder: (context, state) => const BrandingPage(),
      ),
      GoRoute(
        path: Routes.manualPaymentFormScreen,
        builder: (context, state) {
          final args =
              state.extra
                  as ({
                    String doctorId,
                    String? doctorName,
                    String? invoiceId,
                  })?;
          return ManualPaymentFormPage(
            initialDoctorId: args?.doctorId,
            initialDoctorName: args?.doctorName,
            initialInvoiceId: args?.invoiceId,
          );
        },
      ),
      GoRoute(
        path: Routes.settingsScreen,
        builder: (context, state) => const SettingsPage(),
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
        path: Routes.priceTierDetailsScreen,
        builder: (context, state) =>
            PriceTierDetailsPage(priceTier: state.extra as PriceTierModel),
      ),
      // Same glass fade+slide transition as the doctors flow, now that
      // patients shares its design system.
      GoRoute(
        path: Routes.patientsListScreen,
        pageBuilder: (context, state) =>
            _glassPage(state, const PatientsListPage()),
      ),
      GoRoute(
        path: Routes.patientDetailScreen,
        pageBuilder: (context, state) => _glassPage(
          state,
          PatientDetailPage(patientId: state.extra as String),
        ),
      ),
      GoRoute(
        path: Routes.patientFormScreen,
        pageBuilder: (context, state) => _glassPage(
          state,
          PatientFormPage(initialPatient: state.extra as PatientModel?),
        ),
      ),
    ],
  );
}

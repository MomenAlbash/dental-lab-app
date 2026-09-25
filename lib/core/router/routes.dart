class Routes {
  static const String splashScreen = '/';
  static const String loginScreen = '/login';
  static const String homeScreen = '/home';
  static const String laboratorySelectionScreen = '/laboratories/select';
  static const String rolesListScreen = '/roles';
  static const String roleFormScreen = '/roles/form';
  static const String doctorsListScreen = '/doctors';
  static const String doctorFormScreen = '/doctors/form';
  static const String doctorDetailScreen = '/doctors/detail';
  static const String restorationTypesListScreen = '/restoration-types';
  static const String restorationTypeFormScreen = '/restoration-types/form';
  static const String employeesListScreen = '/employees';
  static const String employeeFormScreen = '/employees/form';
  static const String employeeDetailScreen = '/employees/detail';
  static const String usersListScreen = '/users';
  static const String userFormScreen = '/users/form';
  static const String userDetailScreen = '/users/detail';
  static const String clinicsListScreen = '/clinics';
  static const String clinicFormScreen = '/clinics/form';
  static const String clinicDetailScreen = '/clinics/detail';
  static const String laboratoriesListScreen = '/laboratories';
  static const String laboratoryFormScreen = '/laboratories/form';
  static const String laboratoryDetailScreen = '/laboratories/detail';
  static const String myLaboratoryScreen = '/laboratories/own';
  static const String casesListScreen = '/cases';
  static const String caseFormScreen = '/cases/form';
  static const String caseDetailScreen = '/cases/detail';

  /// Camera scanner for case and restoration barcodes.
  static const String barcodeScannerScreen = '/cases/scan';

  /// What a scanned piece asks of whoever is holding it — the shop-floor
  /// landing screen, distinct from the case sheet a manager reads.
  static const String scanTaskScreen = '/cases/scan/task';
  static const String casePrioritiesListScreen = '/case-priorities';

  /// Where the laboratory draws its own case workflow.
  static const String caseWorkflowEditorScreen = '/case-workflow';

  /// The manufacturing stages of one restoration type's route.
  static const String restorationRouteEditorScreen = '/restoration-route';

  /// The departments, and the restoration stages each one owns.
  static const String departmentsScreen = '/departments';

  /// The doctor-facing buckets stages are grouped under.

  /// Why work came back, and why the clock stopped.
  static const String casePriorityFormScreen = '/case-priorities/form';

  /// Who has what rush-priority allowance, and who has spent it.
  static const String priorityOverviewScreen = '/case-priorities/overview';

  /// What the laboratory's scans cost it in disk.
  static const String scanStorageScreen = '/scan-storage';

  /// How much work moved through whom.
  static const String employeeActivityScreen = '/employee-activity';

  /// Sends one notification to many people at once.
  static const String broadcastScreen = '/notifications/broadcast';

  /// The laboratory's own custom questions.
  static const String detailsQuestionsScreen = '/details-questions';

  /// Bulk import from a spreadsheet.
  static const String excelImportScreen = '/import';
  static const String scannerAvailabilityScreen = '/scanner-availability';

  /// The dispatch board for doctor-requested scanner visits.
  static const String scannerSessionsScreen = '/scanner-sessions';

  /// Standalone photography visits for a doctor — tied to no case.
  static const String photographyVisitsScreen = '/photography-visits';
  static const String photographyVisitFormScreen = '/photography-visits/form';
  static const String photographyVisitDetailScreen =
      '/photography-visits/detail';
  static const String currenciesListScreen = '/currencies';
  static const String priceTiersListScreen = '/price-tiers';
  static const String priceTierFormScreen = '/price-tiers/form';
  static const String priceTierPricesScreen = '/price-tiers/prices';
  static const String priceTierDetailsScreen = '/price-tiers/details';
  static const String patientsListScreen = '/patients';
  static const String patientDetailScreen = '/patients/detail';
  static const String patientFormScreen = '/patients/form';
  static const String countriesListScreen = '/countries';
  static const String citiesListScreen = '/cities';
  static const String areasListScreen = '/areas';
  static const String zonesListScreen = '/zones';
  static const String zoneFormScreen = '/zones/form';
  static const String accountingOverviewScreen = '/accounting';
  static const String invoicesListScreen = '/accounting/invoices';
  static const String invoiceDetailScreen = '/accounting/invoices/detail';
  static const String invoiceFormScreen = '/accounting/invoices/new';
  static const String paymentsListScreen = '/accounting/payments';
  static const String pendingPaymentsScreen = '/accounting/payments/pending';
  static const String manualPaymentFormScreen = '/accounting/payments/manual';
  static const String expensesListScreen = '/accounting/expenses';
  static const String doctorStatementScreen = '/accounting/doctor-statement';

  /// The laboratory's cash drawer — one ledger per currency.
  static const String cashboxScreen = '/accounting/cashbox';

  /// Who was here today, and what excused the ones who weren't.
  static const String attendanceHubScreen = '/attendance';

  /// The hours the laboratory expects, and what missing them costs.
  static const String workShiftsScreen = '/attendance/shifts';

  /// Payslips, and running payroll to produce them.
  static const String payrollScreen = '/payroll';

  /// Stage prices and what finishing stages earned — reached from payroll.
  static const String stagePayScreen = '/payroll/stage-pay';

  /// The laboratory's own colour and logo — applied to the login screen too.
  static const String brandingScreen = '/settings/branding';

  /// Holds the rarely-used reference data (currencies, countries, cities) that
  /// no longer earns a drawer row of its own.
  static const String settingsScreen = '/settings';

  static const String inventoryListScreen = '/inventory';
  static const String suppliersListScreen = '/suppliers';
  static const String purchasesListScreen = '/purchases';
  static const String purchaseFormScreen = '/purchases/new';
  static const String feasibilityReportScreen = '/store/feasibility';

  static const String caseTicketTemplatesListScreen = '/case-ticket-templates';
  static const String caseTicketTemplateEditorScreen =
      '/case-ticket-templates/editor';
  // Feature routes are added incrementally as each feature is built.
}

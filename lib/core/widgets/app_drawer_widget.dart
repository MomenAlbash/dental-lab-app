import 'dart:ui';

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/auth/data/repos/login_repo.dart';
import 'package:dental_lab_app/features/auth/ui/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// The drawer's own colours, resolved from the active theme.
///
/// The sidebar used to be pinned to the logo's charcoal in both themes, with
/// every label hardcoded white on top of it. That made it the one surface in
/// the app that ignored the user's choice: a dark panel beside a light page
/// reads as a different product pasted in, and the white labels only worked
/// because the panel underneath was always dark.
///
/// Every colour here comes from the glass tokens, so the drawer follows the
/// theme the way the rest of the app does. The accent stays the brand's in
/// both, because that is the one thing the theme is not allowed to change.
class _DrawerPalette {
  const _DrawerPalette({
    required this.background,
    required this.hairline,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.selectedFill,
    required this.accent,
    required this.wellFill,
  });

  final Gradient background;

  /// Borders and dividers — the same value for both so the drawer's edges are
  /// one weight.
  final Color hairline;

  final Color onSurface;
  final Color onSurfaceMuted;

  /// Behind the row for the screen the user is on.
  final Color selectedFill;

  /// The brand colour, for the selected row and the logo badge.
  final Color accent;

  /// Recessed panels — the theme switcher's track, the avatar's disc.
  final Color wellFill;

  factory _DrawerPalette.of(BuildContext context) {
    final glass = context.glass;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return _DrawerPalette(
      // Dark keeps the charcoal the logo badge uses; light takes the app's own
      // pane so the drawer reads as part of the page rather than on top of it.
      background: isDark
          ? LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColorsManger.brandCharcoal.withValues(alpha: 0.88),
                AppColorsManger.brandCharcoalLight.withValues(alpha: 0.78),
              ],
            )
          : glass.surfaceGradient,
      hairline: glass.strokeColor,
      onSurface: isDark ? const Color(0xE6FFFFFF) : glass.onGlass,
      onSurfaceMuted: isDark ? const Color(0x8AFFFFFF) : glass.onGlassMuted,
      selectedFill: accent.withValues(alpha: isDark ? 0.22 : 0.12),
      accent: isDark ? AppColorsManger.primaryLight : accent,
      wellFill: isDark ? const Color(0x1AFFFFFF) : glass.fillColor,
    );
  }
}

Future<void> _confirmLogout(
  BuildContext context, {
  required bool isPinned,
}) async {
  final confirmed = await ConfirmDialogWidget.show(
    context,
    title: 'تسجيل الخروج',
    message: 'هل أنت متأكد من تسجيل الخروج؟',
    confirmText: 'تسجيل خروج',
    isDestructive: true,
  );
  if (confirmed != true || !context.mounted) return;

  // Closing the drawer only makes sense while it is a modal route. Pinned,
  // the same pop would take the page out from under it.
  if (!isPinned) Navigator.of(context).pop();
  await getIt<LoginRepo>().logout();
  if (context.mounted) GoRouter.of(context).go(Routes.loginScreen);
}

/// One destination inside a drawer group.
class _Destination {
  const _Destination({
    required this.icon,
    required this.label,
    required this.route,
    this.requires,
  });

  final IconData icon;
  final String label;
  final String route;

  /// Module the user must hold at least `Read` on. Null means the destination
  /// is open to any authenticated user.
  final PermissionName? requires;

  bool isVisibleTo(Permissions permissions) =>
      requires == null || permissions.canRead(requires!);
}

/// A group of related destinations, shown as a single row that opens into its
/// own level.
class _DrawerGroup {
  const _DrawerGroup({
    required this.icon,
    required this.title,
    required this.destinations,
  });

  final IconData icon;
  final String title;
  final List<_Destination> destinations;

  bool contains(String? route) =>
      destinations.any((destination) => destination.route == route);

  /// The rows this user may see. A group whose every destination is gated away
  /// disappears with them — an empty group is a dead end that still costs a tap
  /// to discover.
  List<_Destination> visibleTo(Permissions permissions) =>
      destinations.where((d) => d.isVisibleTo(permissions)).toList();
}

/// The drawer's second level. Everything that is not a daily destination —
/// currencies, countries, cities — lives behind the settings screen instead.
/// Permission mapping follows the spec's module list (§2): `Cases` covers the
/// case list and the restoration catalogue, `CaseWorkflow` the priority and
/// stage editors, `Finance` the price tiers, `Doctor` the doctor/patient/clinic
/// screens, `Users` the login and employee screens,
/// `Roles` the role editor, `Branches` the laboratories, and `ScannerControl`
/// the scanner calendar.
const List<_DrawerGroup> _groups = [
  _DrawerGroup(
    icon: Icons.folder_outlined,
    title: 'الحالات',
    destinations: [
      _Destination(
        icon: Icons.folder_outlined,
        label: 'الحالات',
        route: Routes.casesListScreen,
        requires: PermissionName.cases,
      ),
      _Destination(
        icon: Icons.account_tree_outlined,
        label: 'مسار العمل',
        route: Routes.caseWorkflowEditorScreen,
        requires: PermissionName.caseWorkflow,
      ),
      _Destination(
        icon: Icons.flag_outlined,
        label: 'أولويات الحالات',
        route: Routes.casePrioritiesListScreen,
        requires: PermissionName.caseWorkflow,
      ),
      _Destination(
        icon: Icons.workspace_premium_outlined,
        label: 'حصص الأولويات',
        route: Routes.priorityOverviewScreen,
        requires: PermissionName.caseWorkflow,
      ),
      _Destination(
        icon: Icons.upload_file_outlined,
        label: 'استيراد من Excel',
        route: Routes.excelImportScreen,
        requires: PermissionName.users,
      ),
      _Destination(
        icon: Icons.quiz_outlined,
        label: 'أسئلة إضافية',
        route: Routes.detailsQuestionsScreen,
        requires: PermissionName.users,
      ),
      _Destination(
        icon: Icons.insights_outlined,
        label: 'نشاط الفريق',
        route: Routes.employeeActivityScreen,
        requires: PermissionName.statistics,
      ),
      _Destination(
        icon: Icons.storage_outlined,
        label: 'مساحة المسوحات',
        route: Routes.scanStorageScreen,
        requires: PermissionName.branches,
      ),
      _Destination(
        icon: Icons.apartment_outlined,
        label: 'الأقسام',
        route: Routes.departmentsScreen,
        requires: PermissionName.caseWorkflow,
      ),
      _Destination(
        icon: Icons.category_outlined,
        label: 'التعويضات السنية',
        route: Routes.restorationTypesListScreen,
        requires: PermissionName.restorationType,
      ),
      _Destination(
        icon: Icons.sell_outlined,
        label: 'الشرائح السعرية',
        route: Routes.priceTiersListScreen,
        requires: PermissionName.finance,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.calendar_month_outlined,
    title: 'المواعيد',
    destinations: [
      _Destination(
        icon: Icons.document_scanner_outlined,
        label: 'مواعيد السكنر',
        route: Routes.scannerAvailabilityScreen,
        requires: PermissionName.scannerControl,
      ),
      _Destination(
        icon: Icons.groups_2_outlined,
        label: 'جلسات السكنر',
        route: Routes.scannerSessionsScreen,
        requires: PermissionName.scannerControl,
      ),
      _Destination(
        icon: Icons.photo_camera_outlined,
        label: 'زيارات التصوير',
        route: Routes.photographyVisitsScreen,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.people_outline,
    title: 'الجهات',
    destinations: [
      _Destination(
        icon: Icons.people_outline,
        label: 'المرضى',
        route: Routes.patientsListScreen,
        requires: PermissionName.doctor,
      ),
      _Destination(
        icon: Icons.person_outline,
        label: 'الدكاترة',
        route: Routes.doctorsListScreen,
        requires: PermissionName.doctor,
      ),
      _Destination(
        icon: Icons.local_hospital_outlined,
        label: 'العيادات',
        route: Routes.clinicsListScreen,
        requires: PermissionName.doctor,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.manage_accounts_outlined,
    title: 'المستخدمين',
    destinations: [
      _Destination(
        icon: Icons.manage_accounts_outlined,
        label: 'المستخدمين',
        route: Routes.usersListScreen,
        requires: PermissionName.users,
      ),
      _Destination(
        icon: Icons.groups_outlined,
        label: 'الموظفين',
        route: Routes.employeesListScreen,
        requires: PermissionName.users,
      ),
      _Destination(
        icon: Icons.badge_outlined,
        label: 'الأدوار',
        route: Routes.rolesListScreen,
        requires: PermissionName.roles,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.apartment_outlined,
    title: 'الفروع',
    destinations: [
      _Destination(
        icon: Icons.science_outlined,
        label: 'مختبري',
        route: Routes.myLaboratoryScreen,
        requires: PermissionName.branches,
      ),
      _Destination(
        icon: Icons.filter_alt_outlined,
        label: 'المخابر المعروضة',
        route: Routes.laboratorySelectionScreen,
        requires: PermissionName.branches,
      ),
      _Destination(
        icon: Icons.apartment_outlined,
        label: 'الفروع',
        route: Routes.laboratoriesListScreen,
        requires: PermissionName.branches,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.pin_drop_outlined,
    title: 'المندوبون',
    destinations: [
      _Destination(
        icon: Icons.holiday_village_outlined,
        label: 'الأحياء',
        route: Routes.areasListScreen,
        requires: PermissionName.users,
      ),
      _Destination(
        icon: Icons.map_outlined,
        label: 'المناطق',
        route: Routes.zonesListScreen,
        requires: PermissionName.users,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.receipt_long_outlined,
    title: 'المحاسبة',
    destinations: [
      _Destination(
        icon: Icons.bar_chart_outlined,
        label: 'نظرة عامة',
        route: Routes.accountingOverviewScreen,
        requires: PermissionName.finance,
      ),
      _Destination(
        icon: Icons.receipt_long_outlined,
        label: 'الفواتير',
        route: Routes.invoicesListScreen,
        requires: PermissionName.finance,
      ),
      _Destination(
        icon: Icons.payments_outlined,
        label: 'المدفوعات',
        route: Routes.paymentsListScreen,
        requires: PermissionName.finance,
      ),
      _Destination(
        icon: Icons.hourglass_empty_outlined,
        label: 'بانتظار التحقق',
        route: Routes.pendingPaymentsScreen,
        requires: PermissionName.finance,
      ),
      _Destination(
        icon: Icons.savings_outlined,
        label: 'المصاريف',
        route: Routes.expensesListScreen,
        requires: PermissionName.finance,
      ),
      _Destination(
        icon: Icons.account_balance_wallet_outlined,
        label: 'كشف حساب طبيب',
        route: Routes.doctorStatementScreen,
        requires: PermissionName.finance,
      ),
      _Destination(
        icon: Icons.point_of_sale_outlined,
        label: 'الصندوق',
        route: Routes.cashboxScreen,
        requires: PermissionName.finance,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.badge_outlined,
    title: 'الحضور والرواتب',
    destinations: [
      _Destination(
        icon: Icons.how_to_reg_outlined,
        label: 'الحضور',
        route: Routes.attendanceHubScreen,
        requires: PermissionName.attendance,
      ),
      _Destination(
        icon: Icons.schedule_outlined,
        label: 'ورديات العمل',
        route: Routes.workShiftsScreen,
        requires: PermissionName.attendance,
      ),
      _Destination(
        icon: Icons.receipt_long_outlined,
        label: 'الرواتب',
        route: Routes.payrollScreen,
        requires: PermissionName.payroll,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.inventory_2_outlined,
    title: 'المخزون',
    destinations: [
      _Destination(
        icon: Icons.inventory_2_outlined,
        label: 'المخزون',
        route: Routes.inventoryListScreen,
        requires: PermissionName.inventory,
      ),
      _Destination(
        icon: Icons.local_shipping_outlined,
        label: 'الموردون',
        route: Routes.suppliersListScreen,
        requires: PermissionName.suppliers,
      ),
      _Destination(
        icon: Icons.shopping_cart_outlined,
        label: 'مشتريات المخزون',
        route: Routes.purchasesListScreen,
        requires: PermissionName.inventory,
      ),
      _Destination(
        icon: Icons.trending_up_outlined,
        label: 'الجدوى الاقتصادية',
        route: Routes.feasibilityReportScreen,
        requires: PermissionName.inventory,
      ),
    ],
  ),
];

/// App-wide navigation drawer, on two levels: the root lists the groups, and
/// tapping one slides its destinations in over it.
///
/// The flat version showed all fifteen destinations at once, which took a
/// scroll to get through and gave no clue which ones belonged together.
class AppDrawerWidget extends StatefulWidget {
  const AppDrawerWidget({super.key, this.currentRoute});

  final String? currentRoute;

  @override
  State<AppDrawerWidget> createState() => _AppDrawerWidgetState();
}

class _AppDrawerWidgetState extends State<AppDrawerWidget> {
  /// Null while the root level is showing. The drawer always opens at the
  /// root, even from a page inside a group — predictable beats clever.
  _DrawerGroup? _openGroup;

  String? get currentRoute => widget.currentRoute;

  /// Whether the drawer is a permanent column beside the page rather than a
  /// modal route over it. Read off the window, not this widget's own box:
  /// pinned, the drawer is only 280dp wide, so its constraints would report
  /// "phone" and it would go on trying to pop a route it no longer has.
  ///
  /// Everything that would dismiss a modal drawer stands down when pinned —
  /// those pops would land on the page instead ([GlassScaffold] keeps the
  /// pinned column outside the page's navigator).
  bool get _isPinned => AdaptiveLayout.of(context) != AdaptiveFormFactor.mobile;

  void _open(_DrawerGroup group) => setState(() => _openGroup = group);

  void _backToRoot() => setState(() => _openGroup = null);

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the session lands, so the menu reflects the signed-in user
    // rather than whatever the previous one cached.
    return BlocBuilder<SessionCubit, Permissions>(
      bloc: getIt<SessionCubit>(),
      builder: (context, permissions) => _buildDrawer(context, permissions),
    );
  }

  Widget _buildDrawer(BuildContext context, Permissions permissions) {
    final palette = _DrawerPalette.of(context);

    return PopScope(
      // Inside a group, back should step out to the root rather than close the
      // drawer — the level is where the user is, so it is what back undoes.
      // At the root there is nothing to undo, so the pop runs normally and the
      // drawer closes.
      //
      // Pinned, back belongs to the page: the drawer is always on screen, so
      // swallowing back to walk its levels would trap the user on the page.
      canPop: _isPinned || _openGroup == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToRoot();
      },
      child: Drawer(
        backgroundColor: Colors.transparent,
        elevation: 0,
        // Real blur here: the drawer is one surface, not a repeating row, so the
        // BackdropFilter cost is paid once.
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: context.glass.blurSigma,
            sigmaY: context.glass.blurSigma,
          ),
          child: Container(
            // Follows the theme rather than staying charcoal in both: see
            // [_DrawerPalette].
            decoration: BoxDecoration(
              gradient: palette.background,
              border: Border(right: BorderSide(color: palette.hairline)),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DrawerHeader(),
                  Divider(height: 1, color: palette.hairline),
                  Expanded(
                    child: _LevelSwitcher(
                      openGroup: _openGroup,
                      root: _buildRoot(context, permissions),
                      group: _openGroup == null
                          ? const SizedBox.shrink()
                          : _buildGroup(_openGroup!, permissions),
                    ),
                  ),
                  Divider(height: 1, color: palette.hairline),
                  const _ThemeModeSwitcher(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The root level: home, the four groups, settings, then account actions.
  Widget _buildRoot(BuildContext context, Permissions permissions) {
    return ListView(
      key: const ValueKey('drawer-root'),
      padding: EdgeInsets.zero,
      children:
          [
                _DrawerItem(
                  icon: Icons.home_outlined,
                  label: 'الرئيسية',
                  route: Routes.homeScreen,
                  isSelected: currentRoute == Routes.homeScreen,
                  isPinned: _isPinned,
                ),
                // A group the user has no rows in is dropped entirely — the
                // spec's rule is hidden, not disabled, so an empty level never
                // gets a tap.
                for (final group in _groups)
                  if (group.visibleTo(permissions).isNotEmpty)
                    _GroupTile(
                      group: group,
                      // Highlighted when the page being viewed lives inside it, so the
                      // user can see where they are without opening anything.
                      isCurrent: group.contains(currentRoute),
                      onTap: () => _open(group),
                    ),
                _DrawerItem(
                  icon: Icons.settings_outlined,
                  label: 'الإعدادات',
                  route: Routes.settingsScreen,
                  isSelected: currentRoute == Routes.settingsScreen,
                  isPinned: _isPinned,
                ),
                Divider(
                  height: 24,
                  indent: 20,
                  endIndent: 20,
                  color: _DrawerPalette.of(context).hairline,
                ),
                _DrawerActionItem(
                  icon: Icons.lock_reset_outlined,
                  label: 'تغيير كلمة المرور',
                  onTap: () {
                    if (!_isPinned) Navigator.of(context).pop();
                    showChangePasswordDialog(context);
                  },
                ),
                _DrawerActionItem(
                  icon: Icons.logout_outlined,
                  label: 'تسجيل خروج',
                  isDestructive: true,
                  onTap: () => _confirmLogout(context, isPinned: _isPinned),
                ),
              ]
              // Rows slide in one after another as the level appears.
              .animate(interval: const Duration(milliseconds: 22))
              .fadeIn(duration: AppMotion.base)
              .slideX(
                begin: 0.12,
                duration: AppMotion.base,
                curve: AppMotion.enter,
              ),
    );
  }

  /// One group's destinations, headed by a row that goes back to the root.
  Widget _buildGroup(_DrawerGroup group, Permissions permissions) {
    return ListView(
      key: ValueKey('drawer-group-${group.title}'),
      padding: EdgeInsets.zero,
      children:
          [
                _GroupBackHeader(title: group.title, onBack: _backToRoot),
                for (final destination in group.visibleTo(permissions))
                  _DrawerItem(
                    icon: destination.icon,
                    label: destination.label,
                    route: destination.route,
                    isSelected: currentRoute == destination.route,
                    isPinned: _isPinned,
                    // Leaves the drawer on the root next time it opens, rather than
                    // reopening inside a group the user has since navigated away from.
                    // Pinned it stays where the user left it — there is no
                    // "next time it opens" to reset for.
                    onNavigated: _isPinned ? null : _backToRoot,
                  ),
              ]
              .animate(interval: const Duration(milliseconds: 22))
              .fadeIn(duration: AppMotion.base)
              .slideX(
                begin: 0.12,
                duration: AppMotion.base,
                curve: AppMotion.enter,
              ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader();

  @override
  Widget build(BuildContext context) {
    final palette = _DrawerPalette.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: palette.wellFill,
              shape: BoxShape.circle,
              border: Border.all(color: palette.hairline),
              boxShadow: [
                BoxShadow(
                  color: AppColorsManger.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(Icons.medical_services_outlined, color: palette.accent),
          ),
          const SizedBox(width: 12),
          // Expanded so the title cannot push past the drawer's fixed width —
          // unconstrained it overflowed the row at larger text scales.
          Expanded(
            child: Text(
              'مخبر الأسنان',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font18MediumText.copyWith(
                color: palette.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Manual light/dark/system toggle, pinned above the drawer's bottom edge.
class _ThemeModeSwitcher extends StatelessWidget {
  const _ThemeModeSwitcher();

  static const _options = [
    (
      mode: ThemeMode.system,
      icon: Icons.brightness_auto_outlined,
      label: 'تلقائي',
    ),
    (mode: ThemeMode.light, icon: Icons.light_mode_outlined, label: 'فاتح'),
    (mode: ThemeMode.dark, icon: Icons.dark_mode_outlined, label: 'ليلي'),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      bloc: getIt<ThemeCubit>(),
      builder: (context, current) {
        final palette = _DrawerPalette.of(context);

        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: palette.wellFill,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: _options.map((option) {
                final isSelected = option.mode == current;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => getIt<ThemeCubit>().setThemeMode(option.mode),
                    child: AnimatedContainer(
                      duration: AppMotion.base,
                      curve: AppMotion.enter,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? palette.selectedFill
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedSwitcher(
                            duration: AppMotion.fast,
                            child: Icon(
                              option.icon,
                              key: ValueKey(isSelected),
                              size: 18,
                              color: isSelected
                                  ? palette.accent
                                  : palette.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.label,
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: isSelected
                                  ? palette.accent
                                  : palette.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

/// Small caps-style label separating groups of related drawer items.
/// Cross-fades and slides between the drawer's two levels.
class _LevelSwitcher extends StatelessWidget {
  const _LevelSwitcher({
    required this.openGroup,
    required this.root,
    required this.group,
  });

  final _DrawerGroup? openGroup;
  final Widget root;
  final Widget group;

  @override
  Widget build(BuildContext context) {
    // Direction follows the reading direction: going deeper comes from the
    // end side, going back leaves towards it. Hardcoding it would run
    // backwards in this app, which is RTL.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final sign = isRtl ? -1.0 : 1.0;

    return AnimatedSwitcher(
      duration: AppMotion.base,
      switchInCurve: AppMotion.enter,
      transitionBuilder: (child, animation) {
        final isIncoming =
            child.key ==
            (openGroup == null
                ? const ValueKey('drawer-root')
                : ValueKey('drawer-group-${openGroup!.title}'));

        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(sign * (isIncoming ? 0.25 : -0.25), 0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: openGroup == null ? root : group,
    );
  }
}

/// A row at the root level that opens a group rather than navigating.
class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.isCurrent,
    required this.onTap,
  });

  final _DrawerGroup group;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _DrawerPalette.of(context);
    final Color contentColor = isCurrent ? palette.accent : palette.onSurface;

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Same selection bar the destinations use, so "you are in here"
          // reads the same at both levels.
          Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
              color: isCurrent ? palette.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(group.icon, color: contentColor),
        ],
      ),
      title: Text(
        group.title,
        style: AppTextStyles.font16MediumText.copyWith(color: contentColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${group.destinations.length}',
            style: AppTextStyles.font12RegularHint.copyWith(
              color: palette.onSurfaceMuted,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_left, size: 20, color: palette.onSurfaceMuted),
        ],
      ),
      selected: isCurrent,
      selectedTileColor: palette.selectedFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onTap: onTap,
    );
  }
}

/// The header of a group level: its name and the way back to the root.
class _GroupBackHeader extends StatelessWidget {
  const _GroupBackHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'رجوع',
            icon: Icon(
              Icons.arrow_forward,
              color: _DrawerPalette.of(context).onSurface,
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font16MediumText.copyWith(
                color: _DrawerPalette.of(context).accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A drawer row that runs a callback instead of navigating to a route (used
/// by the account actions — change password, logout).
class _DrawerActionItem extends StatelessWidget {
  const _DrawerActionItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final palette = _DrawerPalette.of(context);
    final Color contentColor = isDestructive
        ? context.glass.error
        : palette.onSurface;

    return ListTile(
      // Left-padded by the width of the selection bar + gap in [_DrawerItem]
      // so action rows line up with navigation rows.
      leading: Padding(
        padding: const EdgeInsets.only(left: 13),
        child: Icon(icon, color: contentColor),
      ),
      title: Text(
        label,
        style: AppTextStyles.font16MediumText.copyWith(color: contentColor),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onTap: onTap,
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    this.isPinned = false,
    this.onNavigated,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;

  /// True when the drawer is a permanent column. Such a row navigates without
  /// closing anything, because there is nothing to close.
  final bool isPinned;

  /// Called once the row has acted, so the drawer can reset itself to the
  /// root level for the next time it opens.
  final VoidCallback? onNavigated;

  @override
  Widget build(BuildContext context) {
    // The active item picks up the brand accent; everything else takes the
    // drawer's own label colour, which follows the theme.
    final palette = _DrawerPalette.of(context);
    final Color contentColor = isSelected ? palette.accent : palette.onSurface;

    return ListTile(
      // An accent bar that grows in on the selected row, so the active
      // destination is readable at a glance and not by tint alone.
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.enter,
            width: 3,
            height: isSelected ? 22 : 0,
            decoration: BoxDecoration(
              color: palette.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: contentColor),
        ],
      ),
      title: Text(
        label,
        style: AppTextStyles.font16MediumText.copyWith(color: contentColor),
      ),
      selected: isSelected,
      selectedTileColor: palette.selectedFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onTap: () {
        // Read before popping the drawer, while this context is still under
        // the page's route.
        final isOnHome =
            GoRouterState.of(context).matchedLocation == Routes.homeScreen;

        // Only a modal drawer has a route of its own to dismiss. Pinned, this
        // pop would take the page down instead.
        if (!isPinned) Navigator.of(context).pop();
        onNavigated?.call();
        if (isSelected) return;

        // The drawer navigates sideways, not deeper: whichever destination it
        // opens replaces the one it was opened from, so the stack never grows
        // past Home + one page and back always lands on Home. Without this,
        // hopping between destinations piled them up and backing out meant
        // walking through every page visited.
        if (route == Routes.homeScreen) {
          context.go(route);
        } else if (isOnHome) {
          // Keeps Home underneath, so back returns to it rather than exiting.
          context.push(route);
        } else {
          context.pushReplacement(route);
        }
      },
    );
  }
}

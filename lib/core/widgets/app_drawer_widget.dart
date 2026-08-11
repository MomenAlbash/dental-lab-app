import 'dart:ui';

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
  });

  final IconData icon;
  final String label;
  final String route;
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
}

/// The drawer's second level. Everything that is not a daily destination —
/// currencies, countries, cities — lives behind the settings screen instead.
const List<_DrawerGroup> _groups = [
  _DrawerGroup(
    icon: Icons.folder_outlined,
    title: 'الحالات',
    destinations: [
      _Destination(
        icon: Icons.folder_outlined,
        label: 'الحالات',
        route: Routes.casesListScreen,
      ),
      _Destination(
        icon: Icons.flag_outlined,
        label: 'أولويات الحالات',
        route: Routes.casePrioritiesListScreen,
      ),
      _Destination(
        icon: Icons.category_outlined,
        label: 'التعويضات السنية',
        route: Routes.restorationTypesListScreen,
      ),
      _Destination(
        icon: Icons.sell_outlined,
        label: 'الشرائح السعرية',
        route: Routes.priceTiersListScreen,
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
      ),
      _Destination(
        icon: Icons.person_outline,
        label: 'الدكاترة',
        route: Routes.doctorsListScreen,
      ),
      _Destination(
        icon: Icons.local_hospital_outlined,
        label: 'العيادات',
        route: Routes.clinicsListScreen,
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
      ),
      _Destination(
        icon: Icons.groups_outlined,
        label: 'الموظفين',
        route: Routes.employeesListScreen,
      ),
      _Destination(
        icon: Icons.badge_outlined,
        label: 'الأدوار',
        route: Routes.rolesListScreen,
      ),
    ],
  ),
  _DrawerGroup(
    icon: Icons.apartment_outlined,
    title: 'المخابر',
    destinations: [
      _Destination(
        icon: Icons.science_outlined,
        label: 'مختبري',
        route: Routes.myLaboratoryScreen,
      ),
      _Destination(
        icon: Icons.apartment_outlined,
        label: 'المخابر',
        route: Routes.laboratoriesListScreen,
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
            // The sidebar mirrors the logo's dark charcoal badge — the app's
            // signature element, kept dark in both light and dark theme. Now
            // translucent so the page behind it shows through the glass.
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColorsManger.brandCharcoal.withValues(alpha: 0.88),
                  AppColorsManger.brandCharcoalLight.withValues(alpha: 0.78),
                ],
              ),
              border: const Border(right: BorderSide(color: Color(0x1FFFFFFF))),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _DrawerHeader(),
                  const Divider(height: 1, color: Color(0x1FFFFFFF)),
                  Expanded(
                    child: _LevelSwitcher(
                      openGroup: _openGroup,
                      root: _buildRoot(context),
                      group: _openGroup == null
                          ? const SizedBox.shrink()
                          : _buildGroup(_openGroup!),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0x1FFFFFFF)),
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
  Widget _buildRoot(BuildContext context) {
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
                for (final group in _groups)
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
                const Divider(
                  height: 24,
                  indent: 20,
                  endIndent: 20,
                  color: Color(0x1FFFFFFF),
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
  Widget _buildGroup(_DrawerGroup group) {
    return ListView(
      key: ValueKey('drawer-group-${group.title}'),
      padding: EdgeInsets.zero,
      children:
          [
                _GroupBackHeader(title: group.title, onBack: _backToRoot),
                for (final destination in group.destinations)
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0x33FFFFFF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0x40FFFFFF)),
              boxShadow: [
                BoxShadow(
                  color: AppColorsManger.primary.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColorsManger.primaryLight,
            ),
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
                color: Colors.white,
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
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
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
                            ? AppColorsManger.primary.withValues(alpha: 0.22)
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
                                  ? AppColorsManger.primaryLight
                                  : const Color(0xE6FFFFFF),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            option.label,
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: isSelected
                                  ? AppColorsManger.primaryLight
                                  : const Color(0xE6FFFFFF),
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
    final Color contentColor = isCurrent
        ? AppColorsManger.primaryLight
        : const Color(0xE6FFFFFF); // white 90%

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
              color: isCurrent
                  ? AppColorsManger.primaryLight
                  : Colors.transparent,
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
              color: const Color(0x8AFFFFFF),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_left, size: 20, color: const Color(0x8AFFFFFF)),
        ],
      ),
      selected: isCurrent,
      selectedTileColor: AppColorsManger.primary.withValues(alpha: 0.18),
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
            icon: const Icon(
              Icons.arrow_forward,
              color: Color(0xE6FFFFFF),
              size: 20,
            ),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.font16MediumText.copyWith(
                color: AppColorsManger.primaryLight,
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
    final Color contentColor = isDestructive
        ? AppColorsManger.error
        : const Color(0xE6FFFFFF); // white 90%

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
    // The active item picks up the brand orange; everything else stays a
    // plain white overlay for contrast against the charcoal background.
    final Color contentColor = isSelected
        ? AppColorsManger.primaryLight
        : const Color(0xE6FFFFFF); // white 90%

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
              color: AppColorsManger.primaryLight,
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
      selectedTileColor: AppColorsManger.primary.withValues(alpha: 0.18),
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

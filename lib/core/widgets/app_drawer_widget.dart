import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// App-wide navigation drawer — design only for now (no auth/permission
/// gating on the items yet). Add new sections here as features are built.
class AppDrawerWidget extends StatelessWidget {
  const AppDrawerWidget({super.key, this.currentRoute});

  final String? currentRoute;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: Container(
        // The sidebar keeps its dark-green identity — the design system's
        // signature element. Diagonal navy → brand-green gradient.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF112437), Color(0xFF117865)],
            stops: [0.0, 0.55],
          ),
        ),
        child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DrawerHeader(),
            const Divider(height: 1, color: Color(0x1FFFFFFF)),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
            _DrawerItem(
              icon: Icons.home_outlined,
              label: 'الرئيسية',
              route: Routes.homeScreen,
              isSelected: currentRoute == Routes.homeScreen,
            ),
            _DrawerItem(
              icon: Icons.folder_outlined,
              label: 'الحالات',
              route: Routes.casesShellScreen,
              isSelected: currentRoute == Routes.casesListScreen,
            ),
            _DrawerItem(
              icon: Icons.science_outlined,
              label: 'مختبري',
              route: Routes.myLaboratoryScreen,
              isSelected: currentRoute == Routes.myLaboratoryScreen,
            ),
            _DrawerItem(
              icon: Icons.badge_outlined,
              label: 'الأدوار',
              route: Routes.rolesListScreen,
              isSelected: currentRoute == Routes.rolesListScreen,
            ),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'الدكاترة',
              route: Routes.doctorsListScreen,
              isSelected: currentRoute == Routes.doctorsListScreen,
            ),
            _DrawerItem(
              icon: Icons.timeline_outlined,
              label: 'مراحل الحالات',
              route: Routes.caseWorkflowStagesListScreen,
              isSelected: currentRoute == Routes.caseWorkflowStagesListScreen,
            ),
            _DrawerItem(
              icon: Icons.category_outlined,
              label: 'التعويضات السنية',
              route: Routes.restorationTypesListScreen,
              isSelected: currentRoute == Routes.restorationTypesListScreen,
            ),
            _DrawerItem(
              icon: Icons.groups_outlined,
              label: 'الموظفين',
              route: Routes.employeesListScreen,
              isSelected: currentRoute == Routes.employeesListScreen,
            ),
            _DrawerItem(
              icon: Icons.manage_accounts_outlined,
              label: 'المستخدمين',
              route: Routes.usersListScreen,
              isSelected: currentRoute == Routes.usersListScreen,
            ),
            _DrawerItem(
              icon: Icons.local_hospital_outlined,
              label: 'العيادات',
              route: Routes.clinicsListScreen,
              isSelected: currentRoute == Routes.clinicsListScreen,
            ),
            _DrawerItem(
              icon: Icons.science_outlined,
              label: 'المخابر',
              route: Routes.laboratoriesListScreen,
              isSelected: currentRoute == Routes.laboratoriesListScreen,
            ),
            _DrawerItem(
              icon: Icons.attach_money_outlined,
              label: 'العملات',
              route: Routes.currenciesListScreen,
              isSelected: currentRoute == Routes.currenciesListScreen,
            ),
                ],
              ),
            ),
          ],
        ),
        ),
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
            decoration: const BoxDecoration(
              color: Color(0x33FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'مخبر الأسنان',
            style: AppTextStyles.font18MediumText.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // Sidebar nav items use hardcoded white overlays (per the design system),
    // not the page tokens — guarantees contrast on the dark-green background.
    final Color contentColor = isSelected
        ? Colors.white
        : const Color(0xE6FFFFFF); // white 90%

    return ListTile(
      leading: Icon(icon, color: contentColor),
      title: Text(
        label,
        style: AppTextStyles.font16MediumText.copyWith(color: contentColor),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0x33FFFFFF), // white 20%
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onTap: () {
        Navigator.of(context).pop();
        if (!isSelected) context.go(route);
      },
    );
  }
}

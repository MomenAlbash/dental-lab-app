import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
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
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _DrawerHeader(),
            const Divider(height: 1, color: AppColorsManger.divider),
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
              color: AppColorsManger.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColorsManger.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text('مخبر الأسنان', style: AppTextStyles.font18MediumText),
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
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColorsManger.primary : AppColorsManger.textSecondary,
      ),
      title: Text(
        label,
        style: isSelected
            ? AppTextStyles.font16MediumText.copyWith(color: AppColorsManger.primary)
            : AppTextStyles.font16MediumText,
      ),
      selected: isSelected,
      selectedTileColor: AppColorsManger.primarySurface,
      onTap: () {
        Navigator.of(context).pop();
        if (!isSelected) context.go(route);
      },
    );
  }
}

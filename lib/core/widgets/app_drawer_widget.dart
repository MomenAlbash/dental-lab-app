import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/theming/theme_cubit.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/auth/data/repos/login_repo.dart';
import 'package:dental_lab_app/features/auth/ui/widgets/change_password_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> _confirmLogout(BuildContext context) async {
  final confirmed = await ConfirmDialogWidget.show(
    context,
    title: 'تسجيل الخروج',
    message: 'هل أنت متأكد من تسجيل الخروج؟',
    confirmText: 'تسجيل خروج',
    isDestructive: true,
  );
  if (confirmed != true || !context.mounted) return;

  Navigator.of(context).pop();
  await getIt<LoginRepo>().logout();
  if (context.mounted) GoRouter.of(context).go(Routes.loginScreen);
}

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
        // The sidebar mirrors the logo's dark charcoal badge — the app's
        // signature element, kept dark in both light and dark theme.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              AppColorsManger.brandCharcoal,
              AppColorsManger.brandCharcoalLight,
            ],
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

            // ---- العمل السريري: الحالات وما يسعّرها ----
            const _DrawerSectionHeader('العمل السريري'),
            _DrawerItem(
              icon: Icons.folder_outlined,
              label: 'الحالات',
              route: Routes.casesShellScreen,
              isSelected: currentRoute == Routes.casesListScreen,
            ),
            _DrawerItem(
              icon: Icons.category_outlined,
              label: 'التعويضات السنية',
              route: Routes.restorationTypesListScreen,
              isSelected: currentRoute == Routes.restorationTypesListScreen,
            ),
            _DrawerItem(
              icon: Icons.sell_outlined,
              label: 'الشرائح السعرية',
              route: Routes.priceTiersListScreen,
              isSelected: currentRoute == Routes.priceTiersListScreen,
            ),

            // ---- الجهات: من ترتبط بهم الحالة ----
            const _DrawerSectionHeader('الجهات'),
            _DrawerItem(
              icon: Icons.people_outline,
              label: 'المرضى',
              route: Routes.patientsListScreen,
              isSelected: currentRoute == Routes.patientsListScreen,
            ),
            _DrawerItem(
              icon: Icons.person_outline,
              label: 'الدكاترة',
              route: Routes.doctorsListScreen,
              isSelected: currentRoute == Routes.doctorsListScreen,
            ),
            _DrawerItem(
              icon: Icons.local_hospital_outlined,
              label: 'العيادات',
              route: Routes.clinicsListScreen,
              isSelected: currentRoute == Routes.clinicsListScreen,
            ),

            // ---- الطاقم والصلاحيات ----
            const _DrawerSectionHeader('الطاقم والصلاحيات'),
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
              icon: Icons.badge_outlined,
              label: 'الأدوار',
              route: Routes.rolesListScreen,
              isSelected: currentRoute == Routes.rolesListScreen,
            ),

            // ---- المختبر: إعدادات وتنظيم عام ----
            const _DrawerSectionHeader('المختبر'),
            _DrawerItem(
              icon: Icons.science_outlined,
              label: 'مختبري',
              route: Routes.myLaboratoryScreen,
              isSelected: currentRoute == Routes.myLaboratoryScreen,
            ),
            _DrawerItem(
              icon: Icons.apartment_outlined,
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
            _DrawerItem(
              icon: Icons.public_outlined,
              label: 'الدول',
              route: Routes.countriesListScreen,
              isSelected: currentRoute == Routes.countriesListScreen,
            ),
            _DrawerItem(
              icon: Icons.location_city_outlined,
              label: 'المدن',
              route: Routes.citiesListScreen,
              isSelected: currentRoute == Routes.citiesListScreen,
            ),

            // ---- الحساب: إجراءات الحساب الحالي ----
            const _DrawerSectionHeader('الحساب'),
            _DrawerActionItem(
              icon: Icons.lock_reset_outlined,
              label: 'تغيير كلمة المرور',
              onTap: () {
                Navigator.of(context).pop();
                showChangePasswordDialog(context);
              },
            ),
            _DrawerActionItem(
              icon: Icons.logout_outlined,
              label: 'تسجيل خروج',
              isDestructive: true,
              onTap: () => _confirmLogout(context),
            ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0x1FFFFFFF)),
            const _ThemeModeSwitcher(),
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
              color: AppColorsManger.primary,
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

/// Manual light/dark/system toggle, pinned above the drawer's bottom edge.
class _ThemeModeSwitcher extends StatelessWidget {
  const _ThemeModeSwitcher();

  static const _options = [
    (mode: ThemeMode.system, icon: Icons.brightness_auto_outlined, label: 'تلقائي'),
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
                    onTap: () =>
                        getIt<ThemeCubit>().setThemeMode(option.mode),
                    child: Container(
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
                          Icon(
                            option.icon,
                            size: 18,
                            color: isSelected
                                ? AppColorsManger.primaryLight
                                : const Color(0xE6FFFFFF),
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
class _DrawerSectionHeader extends StatelessWidget {
  const _DrawerSectionHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
      child: Text(
        label,
        style: AppTextStyles.font14MediumText.copyWith(
          color: const Color(0xB3FFFFFF),
          fontWeight: FontWeight.w700,
        ),
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
      leading: Icon(icon, color: contentColor),
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
  });

  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    // The active item picks up the brand orange; everything else stays a
    // plain white overlay for contrast against the charcoal background.
    final Color contentColor = isSelected
        ? AppColorsManger.primaryLight
        : const Color(0xE6FFFFFF); // white 90%

    return ListTile(
      leading: Icon(icon, color: contentColor),
      title: Text(
        label,
        style: AppTextStyles.font16MediumText.copyWith(color: contentColor),
      ),
      selected: isSelected,
      selectedTileColor: AppColorsManger.primary.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      onTap: () {
        Navigator.of(context).pop();
        if (!isSelected) context.go(route);
      },
    );
  }
}

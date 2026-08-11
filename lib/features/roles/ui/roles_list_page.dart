import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/features/roles/ui/widgets/role_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Roles list screen — design only for now (no Cubit / API wiring yet).
class RolesListPage extends StatefulWidget {
  const RolesListPage({super.key});

  @override
  State<RolesListPage> createState() => _RolesListPageState();
}

class _RolesListPageState extends State<RolesListPage> {
  // Placeholder data until the roles Cubit/repository are wired in.
  final List<Map<String, dynamic>> _roles = [
    {
      'name': 'مدير',
      'description': 'صلاحية كاملة على النظام',
      'permissionsCount': 9,
    },
    {
      'name': 'فني مخبر',
      'description': 'إدارة الحالات والمراحل',
      'permissionsCount': 4,
    },
    {
      'name': 'موظف استقبال',
      'description': 'إدخال حالات العيادات',
      'permissionsCount': 2,
    },
  ];

  Future<void> _confirmDelete(int index) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الدور',
      message: 'هل أنت متأكد من حذف دور "${_roles[index]['name']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _roles.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.rolesListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الأدوار',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'إضافة دور',
            isExtended: true,
            onPressed: () => context.push(Routes.roleFormScreen),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
      body: SafeArea(
        child: _roles.isEmpty
            ? _EmptyState()
            : AdaptiveCollection<Map<String, dynamic>>(
                items: _roles,
                itemBuilder: (context, role, index) => RoleListItemWidget(
                  name: role['name'] as String,
                  description: role['description'] as String,
                  permissionsCount: role['permissionsCount'] as int,
                  onEdit: () =>
                      context.push(Routes.roleFormScreen, extra: role),
                  onDelete: () => _confirmDelete(index),
                ),
              ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.badge_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد أدوار بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول دور بالضغط على زر الإضافة',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

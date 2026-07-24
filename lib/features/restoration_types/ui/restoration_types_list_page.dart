import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/restoration_types/ui/widgets/restoration_type_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Restoration types list screen — design only for now (no Cubit / API
/// wiring yet). These are the dental restoration definitions (crowns,
/// bridges...) an admin sets up so each case can be built from one or more.
class RestorationTypesListPage extends StatefulWidget {
  const RestorationTypesListPage({super.key});

  @override
  State<RestorationTypesListPage> createState() => _RestorationTypesListPageState();
}

class _RestorationTypesListPageState extends State<RestorationTypesListPage> {
  // Placeholder data until the restoration-types Cubit/repository are wired in.
  final List<Map<String, dynamic>> _restorationTypes = [
    {
      'name': 'تاج زيركون',
      'defaultPrice': 250000.0,
      'isActive': true,
      'showInClinicApp': true,
    },
    {
      'name': 'جسر خزفي',
      'defaultPrice': 400000.0,
      'isActive': true,
      'showInClinicApp': false,
    },
    {
      'name': 'طقم متحرك',
      'defaultPrice': 600000.0,
      'isActive': false,
      'showInClinicApp': true,
    },
  ];

  Future<void> _confirmDelete(int index) async {
    final restorationType = _restorationTypes[index];
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف التعويض',
      message: 'هل أنت متأكد من حذف تعويض "${restorationType['name']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _restorationTypes.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.restorationTypesListScreen),
      appBar: AppBar(title: Text('التعويضات السنية', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.restorationTypeFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;

            if (_restorationTypes.isEmpty) {
              return Center(
                child: Text('لا يوجد تعويضات بعد', style: AppTextStyles.font14RegularSecondary),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 32 : 16,
                    vertical: 16,
                  ),
                  itemCount: _restorationTypes.length,
                  itemBuilder: (context, index) {
                    final restorationType = _restorationTypes[index];
                    return RestorationTypeListItemWidget(
                      name: restorationType['name'] as String,
                      defaultPrice: restorationType['defaultPrice'] as double,
                      isActive: restorationType['isActive'] as bool,
                      showInClinicApp: restorationType['showInClinicApp'] as bool,
                      onEdit: () => context.push(
                        Routes.restorationTypeFormScreen,
                        extra: restorationType,
                      ),
                      onDelete: () => _confirmDelete(index),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

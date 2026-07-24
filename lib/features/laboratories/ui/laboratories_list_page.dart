import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/laboratories/ui/widgets/laboratory_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Laboratories list screen — design only for now (no Cubit / API wiring
/// yet). An admin owns one lab by default (see "مختبري") but can create and
/// switch into operating as a different lab, per `/api/clinic/Laboratories`.
class LaboratoriesListPage extends StatefulWidget {
  const LaboratoriesListPage({super.key});

  @override
  State<LaboratoriesListPage> createState() => _LaboratoriesListPageState();
}

class _LaboratoriesListPageState extends State<LaboratoriesListPage> {
  // Placeholder data until the laboratories Cubit/repository are wired in.
  final List<Map<String, dynamic>> _laboratories = [
    {
      'name': 'مخبر الابتسامة الذهبية',
      'address': 'المزة، دمشق',
      'phoneNumber': '0112223344',
      'isActive': true,
      'userCount': 5,
      'doctorCount': 8,
      'caseCount': 142,
    },
    {
      'name': 'مخبر الشام للأسنان',
      'address': 'الميدان، دمشق',
      'phoneNumber': '0119998877',
      'isActive': true,
      'userCount': 2,
      'doctorCount': 3,
      'caseCount': 37,
    },
  ];

  Future<void> _confirmDelete(Map<String, dynamic> laboratory) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف المخبر',
      message: 'هل أنت متأكد من حذف مخبر "${laboratory['name']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _laboratories.remove(laboratory));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.laboratoriesListScreen),
      appBar: AppBar(title: Text('المخابر', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.laboratoryFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;

            if (_laboratories.isEmpty) {
              return Center(
                child: Text('لا يوجد مخابر بعد', style: AppTextStyles.font14RegularSecondary),
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
                  itemCount: _laboratories.length,
                  itemBuilder: (context, index) {
                    final laboratory = _laboratories[index];
                    return LaboratoryListItemWidget(
                      name: laboratory['name'] as String,
                      address: laboratory['address'] as String,
                      isActive: laboratory['isActive'] as bool,
                      onTap: () =>
                          context.push(Routes.laboratoryDetailScreen, extra: laboratory),
                      onEdit: () =>
                          context.push(Routes.laboratoryFormScreen, extra: laboratory),
                      onDelete: () => _confirmDelete(laboratory),
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

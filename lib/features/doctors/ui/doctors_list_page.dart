import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Doctors list screen — design only for now (no Cubit / API wiring yet).
class DoctorsListPage extends StatefulWidget {
  const DoctorsListPage({super.key});

  @override
  State<DoctorsListPage> createState() => _DoctorsListPageState();
}

class _DoctorsListPageState extends State<DoctorsListPage> {
  // Placeholder data until the doctors Cubit/repository are wired in.
  final List<Map<String, dynamic>> _doctors = [
    {
      'firstName': 'أحمد',
      'lastName': 'الخطيب',
      'phoneNumber': '0991234567',
      'email': 'ahmad@example.com',
      'clinicName': 'عيادة النور',
      'isActive': true,
    },
    {
      'firstName': 'سارة',
      'lastName': 'يوسف',
      'phoneNumber': '0997654321',
      'email': 'sara@example.com',
      'clinicName': 'عيادة الأمل',
      'isActive': true,
    },
    {
      'firstName': 'محمد',
      'lastName': 'حسن',
      'phoneNumber': '0999998888',
      'email': '',
      'clinicName': '',
      'isActive': false,
    },
  ];

  Future<void> _confirmDelete(int index) async {
    final doctor = _doctors[index];
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الدكتور',
      message:
          'هل أنت متأكد من حذف الدكتور "${doctor['firstName']} ${doctor['lastName']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _doctors.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.doctorsListScreen),
      appBar: AppBar(title: Text('الدكاترة', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.doctorFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;

            if (_doctors.isEmpty) {
              return Center(
                child: Text('لا يوجد دكاترة بعد', style: AppTextStyles.font14RegularSecondary),
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
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = _doctors[index];
                    return DoctorListItemWidget(
                      fullName: '${doctor['firstName']} ${doctor['lastName']}',
                      phoneNumber: doctor['phoneNumber'] as String,
                      clinicName: doctor['clinicName'] as String,
                      isActive: doctor['isActive'] as bool,
                      onEdit: () => context.push(Routes.doctorFormScreen, extra: doctor),
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

import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/clinics/ui/widgets/clinic_list_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Clinics list screen — design only for now (no Cubit / API wiring yet).
/// A clinic can have more than one doctor linked to it (see the Doctors
/// feature's clinic picker), so this is set up before doctor-clinic linking.
/// Supports filtering by name (mirrors the API's `search` query param,
/// applied locally for now).
class ClinicsListPage extends StatefulWidget {
  const ClinicsListPage({super.key});

  @override
  State<ClinicsListPage> createState() => _ClinicsListPageState();
}

class _ClinicsListPageState extends State<ClinicsListPage> {
  // Placeholder data until the clinics Cubit/repository are wired in.
  final List<Map<String, dynamic>> _clinics = [
    {
      'name': 'عيادة النور',
      'address': 'المزة، دمشق',
      'phoneNumber': '0112223344',
      'email': 'alnoor@example.com',
      'cityName': 'دمشق',
      'priceTierName': 'قياسي',
      'doctorCount': 3,
      'patientCount': 128,
      'isActive': true,
    },
    {
      'name': 'عيادة الأمل',
      'address': 'الفرقان، حلب',
      'phoneNumber': '0212223344',
      'email': '',
      'cityName': 'حلب',
      'priceTierName': 'مميز',
      'doctorCount': 1,
      'patientCount': 42,
      'isActive': true,
    },
    {
      'name': 'عيادة الشفاء',
      'address': '',
      'phoneNumber': '',
      'email': '',
      'cityName': '',
      'priceTierName': '',
      'doctorCount': 0,
      'patientCount': 0,
      'isActive': false,
    },
  ];

  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredClinics {
    if (_searchQuery.isEmpty) return _clinics;
    final query = _searchQuery.toLowerCase();
    return _clinics
        .where((clinic) => (clinic['name'] as String).toLowerCase().contains(query))
        .toList();
  }

  Future<void> _confirmDelete(Map<String, dynamic> clinic) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف العيادة',
      message: 'هل أنت متأكد من حذف عيادة "${clinic['name']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _clinics.remove(clinic));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط الحذف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsManger.background,
      drawer: const AppDrawerWidget(currentRoute: Routes.clinicsListScreen),
      appBar: AppBar(title: Text('العيادات', style: AppTextStyles.font18MediumText)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.clinicFormScreen),
        backgroundColor: AppColorsManger.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 700.0 : constraints.maxWidth;
            final clinics = _filteredClinics;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 32 : 16,
                        vertical: 16,
                      ),
                      child: AppTextFormField(
                        controller: _searchController,
                        hintText: 'ابحث باسم العيادة...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColorsManger.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () => _searchController.clear(),
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColorsManger.textSecondary,
                                ),
                              ),
                        validator: (_) => null,
                      ),
                    ),
                    Expanded(
                      child: clinics.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isEmpty ? 'لا يوجد عيادات بعد' : 'لا توجد نتائج',
                                style: AppTextStyles.font14RegularSecondary,
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 32 : 16,
                              ),
                              itemCount: clinics.length,
                              itemBuilder: (context, index) {
                                final clinic = clinics[index];
                                return ClinicListItemWidget(
                                  name: clinic['name'] as String,
                                  address: clinic['address'] as String,
                                  doctorCount: clinic['doctorCount'] as int,
                                  isActive: clinic['isActive'] as bool,
                                  onTap: () =>
                                      context.push(Routes.clinicDetailScreen, extra: clinic),
                                  onEdit: () =>
                                      context.push(Routes.clinicFormScreen, extra: clinic),
                                  onDelete: () => _confirmDelete(clinic),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

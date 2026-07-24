import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Employee detail screen — design only for now (no Cubit / API wiring yet).
/// Mirrors `EmployeeDto`, plus the image/file upload endpoints
/// (`POST .../image`, `POST .../files`, `DELETE .../files/{fileId}`), all
/// stubbed with local state until the repository is wired in.
class EmployeeDetailPage extends StatefulWidget {
  const EmployeeDetailPage({super.key, required this.employee});

  final Map<String, dynamic> employee;

  @override
  State<EmployeeDetailPage> createState() => _EmployeeDetailPageState();
}

class _EmployeeDetailPageState extends State<EmployeeDetailPage> {
  late final List<Map<String, String>> _files = List<Map<String, String>>.from(
    (widget.employee['files'] as List<Map<String, String>>? ?? const []),
  );
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.employee['imagePath'] as String?;
  }

  void _onUploadImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم ربط رفع الصورة بالـ API لاحقاً')),
    );
  }

  void _onUploadFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سيتم ربط رفع الملف بالـ API لاحقاً')),
    );
  }

  Future<void> _onDeleteFile(int index) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف الملف',
      message: 'هل أنت متأكد من حذف الملف "${_files[index]['fileName']}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && mounted) {
      setState(() => _files.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حذف الملف بالـ API لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = widget.employee;
    final fullName = '${employee['firstName']} ${employee['lastName']}';

    return Scaffold(
      backgroundColor: AppColorsManger.background,
      appBar: AppBar(
        title: Text('تفاصيل الموظف', style: AppTextStyles.font18MediumText),
        actions: [
          IconButton(
            onPressed: () => context.push(Routes.employeeFormScreen, extra: employee),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 560.0 : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 20,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _onUploadImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: AppColorsManger.primarySurface,
                                backgroundImage: _imagePath == null
                                    ? null
                                    : NetworkImage(_imagePath!),
                                child: _imagePath == null
                                    ? const Icon(
                                        Icons.person_outline,
                                        size: 48,
                                        color: AppColorsManger.primary,
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColorsManger.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(child: Text(fullName, style: AppTextStyles.font20BoldText)),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColorsManger.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColorsManger.border),
                        ),
                        child: Column(
                          children: [
                            DetailInfoRowWidget(
                              icon: Icons.numbers_outlined,
                              label: 'رمز الموظف',
                              value: employee['code'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.badge_outlined,
                              label: 'الرقم الوطني',
                              value: employee['nationalNumber'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.wc_outlined,
                              label: 'الجنس',
                              value: employee['gender'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.cake_outlined,
                              label: 'تاريخ الميلاد',
                              value: employee['dateOfBirth'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.location_city_outlined,
                              label: 'المدينة',
                              value: employee['cityName'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.phone_outlined,
                              label: 'رقم الهاتف',
                              value: employee['phoneNumber'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.location_on_outlined,
                              label: 'العنوان',
                              value: employee['address'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.account_balance_outlined,
                              label: 'اسم البنك',
                              value: employee['bankName'] as String? ?? '',
                            ),
                            const Divider(height: 1, color: AppColorsManger.divider),
                            DetailInfoRowWidget(
                              icon: Icons.credit_card_outlined,
                              label: 'رقم الحساب البنكي',
                              value: employee['bankAccountNumber'] as String? ?? '',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text('الملفات المرفقة', style: AppTextStyles.font16MediumText),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _onUploadFile,
                            icon: const Icon(Icons.attach_file, size: 18),
                            label: const Text('إضافة ملف'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_files.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'لا يوجد ملفات مرفقة',
                            style: AppTextStyles.font14RegularSecondary,
                          ),
                        )
                      else
                        ..._files.asMap().entries.map(
                          (entry) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColorsManger.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColorsManger.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_outlined,
                                  color: AppColorsManger.textSecondary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    entry.value['fileName'] ?? '',
                                    style: AppTextStyles.font14MediumText,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _onDeleteFile(entry.key),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColorsManger.error,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

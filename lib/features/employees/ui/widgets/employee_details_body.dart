import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_attachments_section.dart';
import 'package:flutter/material.dart';

/// The employee details section: photo header, contact/bank info card and the
/// attachments section.
class EmployeeDetailsBody extends StatelessWidget {
  const EmployeeDetailsBody({
    super.key,
    required this.employee,
    required this.isBusy,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
  });

  final EmployeeModel employee;
  final bool isBusy;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<EmployeeAttachmentFileModel> onOpenFile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        final contentWidth = isWide ? 560.0 : constraints.maxWidth;

        return Stack(
          children: [
            Center(
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
                      _EmployeeHeader(employee: employee),
                      const SizedBox(height: 24),
                      _EmployeeInfoCard(employee: employee),
                      const SizedBox(height: 24),
                      EmployeeAttachmentsSection(
                        files: employee.files,
                        isBusy: isBusy,
                        onAddFile: onAddFile,
                        onDeleteFile: onDeleteFile,
                        onOpenFile: onOpenFile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isBusy)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        );
      },
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  const _EmployeeHeader({required this.employee});

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(employee.imagePath);

    return Center(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              color: AppColorsManger.primarySurface,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: imageUrl == null
                ? const Icon(
                    Icons.person_outline,
                    size: 44,
                    color: AppColorsManger.primary,
                  )
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person_outline,
                      size: 44,
                      color: AppColorsManger.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            employee.fullName.isEmpty ? '—' : employee.fullName,
            textAlign: TextAlign.center,
            style: AppTextStyles.font20BoldText,
          ),
        ],
      ),
    );
  }
}

class _EmployeeInfoCard extends StatelessWidget {
  const _EmployeeInfoCard({required this.employee});

  final EmployeeModel employee;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            value: employee.code ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.badge_outlined,
            label: 'الرقم الوطني',
            value: employee.nationalNumber ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.wc_outlined,
            label: 'الجنس',
            value: employee.gender?.arabicLabel ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.cake_outlined,
            label: 'تاريخ الميلاد',
            value: employee.dateOfBirth ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.location_city_outlined,
            label: 'المدينة',
            value: employee.cityName ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: employee.phoneNumber ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.location_on_outlined,
            label: 'العنوان',
            value: employee.address ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.account_balance_outlined,
            label: 'اسم البنك',
            value: employee.bankName ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.credit_card_outlined,
            label: 'رقم الحساب البنكي',
            value: employee.bankAccountNumber ?? '',
          ),
        ],
      ),
    );
  }
}

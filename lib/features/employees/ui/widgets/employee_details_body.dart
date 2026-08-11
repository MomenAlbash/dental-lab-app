import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_attachments_section.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_info_tiles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_attachment_file_model.dart';
import 'package:dental_lab_app/features/employees/data/models/employee_model.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_hero_header.dart';
import 'package:dental_lab_app/features/employees/ui/widgets/employee_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Employee detail screen content.
///
/// Built as slivers so the identity panel can collapse into the toolbar as the
/// user scrolls — the page owns its own app bar, which is why the route does
/// not supply one. Mirrors [DoctorDetailsBody]'s structure exactly.
class EmployeeDetailsBody extends StatelessWidget {
  const EmployeeDetailsBody({
    super.key,
    required this.employee,
    required this.isBusy,
    required this.onEdit,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
  });

  final EmployeeModel employee;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<EmployeeAttachmentFileModel> onOpenFile;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final tiles = <GlassInfoTile>[
          GlassInfoTile(
            icon: Icons.numbers_outlined,
            label: 'رمز الموظف',
            value: employee.code,
            color: Theme.of(context).colorScheme.primary,
          ),
          GlassInfoTile(
            icon: Icons.badge_outlined,
            label: 'الرقم الوطني',
            value: employee.nationalNumber,
            color: context.glass.info,
          ),
          GlassInfoTile(
            icon: Icons.wc_outlined,
            label: 'الجنس',
            value: employee.gender?.arabicLabel,
            color: context.glass.primaryDark,
          ),
          GlassInfoTile(
            icon: Icons.cake_outlined,
            label: 'تاريخ الميلاد',
            value: employee.dateOfBirth,
            color: context.glass.warning,
          ),
          GlassInfoTile(
            icon: Icons.location_city_outlined,
            label: 'المدينة',
            value: employee.cityName,
            color: context.glass.info,
          ),
          GlassInfoTile(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: employee.phoneNumber,
            color: context.glass.success,
          ),
          if ((employee.address?.trim().isNotEmpty ?? false))
            GlassInfoTile(
              icon: Icons.location_on_outlined,
              label: 'العنوان',
              value: employee.address,
              color: context.glass.success,
              wide: true,
            ),
          if ((employee.bankName?.trim().isNotEmpty ?? false) ||
              (employee.bankAccountNumber?.trim().isNotEmpty ?? false)) ...[
            GlassInfoTile(
              icon: Icons.account_balance_outlined,
              label: 'اسم البنك',
              value: employee.bankName,
              color: Theme.of(context).colorScheme.primary,
            ),
            GlassInfoTile(
              icon: Icons.credit_card_outlined,
              label: 'رقم الحساب البنكي',
              value: employee.bankAccountNumber,
              color: context.glass.info,
            ),
          ],
        ];

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                EmployeeSliverHeader(employee: employee, onEdit: onEdit),
                SliverToBoxAdapter(
                  child: AdaptiveDetailSections(
                    main: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const GlassSectionTitle('المعلومات'),
                          const SizedBox(height: AppSpacing.md),
                          GlassInfoTiles(tiles: tiles)
                              .animate()
                              .fadeIn(duration: AppMotion.base)
                              .slideY(
                                begin: 0.06,
                                duration: AppMotion.base,
                                curve: AppMotion.enter,
                              ),
                        ],
                      ),
                      GlassAttachmentsSection<EmployeeAttachmentFileModel>(
                        files: employee.files,
                        isBusy: isBusy,
                        onAddFile: onAddFile,
                        onDeleteFile: onDeleteFile,
                        onOpenFile: onOpenFile,
                        idOf: (file) => file.id,
                        fileNameOf: (file) => file.fileName,
                      ),
                    ],
                    side: [
                      EmployeeQuickActions(employee: employee)
                          .animate()
                          .fadeIn(duration: AppMotion.base)
                          .slideY(
                            begin: 0.15,
                            duration: AppMotion.base,
                            curve: AppMotion.enter,
                          ),
                    ],
                  ),
                ),
              ],
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

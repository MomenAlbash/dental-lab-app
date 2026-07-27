import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_attachments_section.dart';
import 'package:flutter/material.dart';

/// The doctor details section: photo header (with change action), status,
/// contact info card and the attachments section.
class DoctorDetailsBody extends StatelessWidget {
  const DoctorDetailsBody({
    super.key,
    required this.doctor,
    required this.isBusy,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
  });

  final DoctorModel doctor;
  final bool isBusy;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<DoctorAttachmentFileModel> onOpenFile;

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
                      _DoctorHeader(doctor: doctor),
                      const SizedBox(height: 24),
                      _DoctorInfoCard(doctor: doctor),
                      const SizedBox(height: 24),
                      DoctorAttachmentsSection(
                        files: doctor.files,
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

class _DoctorHeader extends StatelessWidget {
  const _DoctorHeader({required this.doctor});

  final DoctorModel doctor;

  @override
  Widget build(BuildContext context) {
    final imageUrl = resolveMediaUrl(doctor.imagePath);

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
            doctor.fullName.isEmpty ? '—' : doctor.fullName,
            textAlign: TextAlign.center,
            style: AppTextStyles.font20BoldText,
          ),
          const SizedBox(height: 4),
          _StatusBadge(isActive: doctor.isActive),
        ],
      ),
    );
  }
}

class _DoctorInfoCard extends StatelessWidget {
  const _DoctorInfoCard({required this.doctor});

  final DoctorModel doctor;

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
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: doctor.email ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: doctor.phoneNumber ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.location_on_outlined,
            label: 'العنوان',
            value: doctor.address ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.wc_outlined,
            label: 'الجنس',
            value: doctor.gender?.arabicLabel ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.cake_outlined,
            label: 'تاريخ الميلاد',
            value: doctor.dateOfBirth ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.location_city_outlined,
            label: 'المدينة',
            value: doctor.cityName ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.local_hospital_outlined,
            label: 'العيادة',
            value: doctor.clinicName ?? '',
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColorsManger.success : AppColorsManger.textHint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'نشط' : 'موقوف',
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

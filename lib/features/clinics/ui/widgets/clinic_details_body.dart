import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/features/clinics/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

/// The clinic details section: header (name + code) and the contact info card.
class ClinicDetailsBody extends StatelessWidget {
  const ClinicDetailsBody({super.key, required this.clinic});

  final ClinicModel clinic;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                  _ClinicHeader(clinic: clinic),
                  const SizedBox(height: 24),
                  _ClinicInfoCard(clinic: clinic),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClinicHeader extends StatelessWidget {
  const _ClinicHeader({required this.clinic});

  final ClinicModel clinic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColorsManger.primarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_hospital_outlined,
              size: 36,
              color: AppColorsManger.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            clinic.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.font20BoldText,
          ),
          if (clinic.code != null && clinic.code!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(clinic.code!, style: AppTextStyles.font12RegularHint),
          ],
        ],
      ),
    );
  }
}

class _ClinicInfoCard extends StatelessWidget {
  const _ClinicInfoCard({required this.clinic});

  final ClinicModel clinic;

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
            icon: Icons.location_on_outlined,
            label: 'العنوان',
            value: clinic.address ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.phone_outlined,
            label: 'رقم الهاتف',
            value: clinic.phoneNumber ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.email_outlined,
            label: 'البريد الإلكتروني',
            value: clinic.email ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.location_city_outlined,
            label: 'المدينة',
            value: clinic.cityName ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.language_outlined,
            label: 'الموقع الإلكتروني',
            value: clinic.websiteUrl ?? '',
          ),
        ],
      ),
    );
  }
}

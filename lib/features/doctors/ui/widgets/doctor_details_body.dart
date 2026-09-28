import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/widgets/detail_with_cases_tabs.dart';
import 'package:dental_lab_app/features/accounting/ui/widgets/doctor_account_tab.dart';
import 'package:dental_lab_app/features/case_priorities/ui/widgets/doctor_quota_section.dart';
import 'package:dental_lab_app/features/cases/data/models/case_filters_model.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/filtered_cases_tab.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_approval_panel.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_attachments_section.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_excluded_representatives_section.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_hero_header.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_info_tiles.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_price_tier_section.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Doctor detail screen content: the doctor's details, and their cases.
///
/// Built as slivers so the identity panel can collapse into the toolbar as the
/// user scrolls — the page owns its own app bar, which is why the route does
/// not supply one. The two tabs are pinned under that header, and each tab
/// scrolls on its own beneath it.
class DoctorDetailsBody extends StatelessWidget {
  const DoctorDetailsBody({
    super.key,
    required this.doctor,
    required this.isBusy,
    required this.onEdit,
    required this.onOpenAnswers,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
    required this.onApprove,
    required this.onReject,
    required this.onPriceTierChanged,
    this.onChangePhoto,
  });

  final DoctorModel doctor;
  final bool isBusy;
  final VoidCallback onEdit;

  /// Opens the laboratory's own custom questions for this doctor.
  final VoidCallback onOpenAnswers;

  /// Decisions on a self-registered doctor's application.
  final ValueChanged<ApprovalChoice> onApprove;
  final ValueChanged<String> onReject;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<DoctorAttachmentFileModel> onOpenFile;

  /// Moves the doctor onto a price tier, or off one when null.
  final ValueChanged<String?> onPriceTierChanged;

  /// Replaces the doctor's photo. Null without permission to edit them.
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DetailWithCasesTabs(
          storageKey: 'doctor-details',
          header: (tabBar) => DoctorSliverHeader(
            doctor: doctor,
            onEdit: onEdit,
            onOpenAnswers: onOpenAnswers,
            onChangePhoto: onChangePhoto,
            bottom: tabBar,
          ),
          details: _details(),
          cases: FilteredCasesTab(
            filters: CaseFiltersModel(
              doctorId: doctor.id,
              doctorName: doctor.fullName,
            ),
            formExtra: doctor,
            laboratoryId: doctor.laboratoryId,
          ),
          // The doctor's money, for whoever may see the lab's accounts —
          // the same statement the accounting section shows.
          extraTabs: [
            if (getIt<SessionCubit>().state.canRead(PermissionName.finance))
              (label: 'الحساب', child: DoctorAccountTab(doctorId: doctor.id)),
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
  }

  /// Everything the doctor's page showed before it had tabs.
  Widget _details() {
    return AdaptiveDetailSections(
      // What the doctor *is*.
      main: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SectionTitle('المعلومات'),
            const SizedBox(height: AppSpacing.md),
            DoctorInfoTiles(doctor: doctor)
                .animate(delay: AppMotion.stagger * 2)
                .fadeIn(duration: AppMotion.base)
                .slideY(
                  begin: 0.06,
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                ),
          ],
        ),
        // Both are part of what the doctor *is*, not actions: a
        // standing pricing arrangement the lab reads as often as it
        // edits. The tier comes first — it decides what a case
        // costs at all, while the quota only decides what is free.
        DoctorPriceTierSection(
          doctor: doctor,
          isBusy: isBusy,
          onChanged: onPriceTierChanged,
        ),
        DoctorQuotaSection(doctorId: doctor.id),
        DoctorExcludedRepresentativesSection(
          doctorId: doctor.id,
          zoneId: doctor.zoneId,
        ),
        DoctorAttachmentsSection(
          files: doctor.files,
          isBusy: isBusy,
          onAddFile: onAddFile,
          onDeleteFile: onDeleteFile,
          onOpenFile: onOpenFile,
        ),
      ],
      // What the user can do about them. On a phone these still
      // come first — an application waiting on a decision is the
      // thing to deal with before reading anything else, and it
      // renders nothing once the doctor is approved.
      side: [
        if (doctor.approvalStatus != DoctorApprovalStatus.approved)
          DoctorApprovalPanel(
                doctor: doctor,
                isBusy: isBusy,
                onApprove: onApprove,
                onReject: onReject,
              )
              .animate()
              .fadeIn(duration: AppMotion.base)
              .slideY(
                begin: 0.15,
                duration: AppMotion.base,
                curve: AppMotion.enter,
              ),
        DoctorQuickActions(doctor: doctor)
            .animate()
            .fadeIn(duration: AppMotion.base)
            .slideY(
              begin: 0.15,
              duration: AppMotion.base,
              curve: AppMotion.enter,
            ),
      ],
    );
  }
}

/// Section heading with a short accent rule — cheaper visually than another
/// card, and it stops the page reading as one undifferentiated stack.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.font16MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
        ),
      ],
    );
  }
}

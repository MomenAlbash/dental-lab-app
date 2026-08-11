import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_attachment_file_model.dart';
import 'package:dental_lab_app/features/doctors/data/models/doctor_model.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_approval_panel.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_attachments_section.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_hero_header.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_info_tiles.dart';
import 'package:dental_lab_app/features/doctors/ui/widgets/doctor_quick_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Doctor detail screen content.
///
/// Built as slivers so the identity panel can collapse into the toolbar as the
/// user scrolls — the page owns its own app bar, which is why the route does
/// not supply one.
class DoctorDetailsBody extends StatelessWidget {
  const DoctorDetailsBody({
    super.key,
    required this.doctor,
    required this.isBusy,
    required this.onEdit,
    required this.onAddFile,
    required this.onDeleteFile,
    required this.onOpenFile,
    required this.onApprove,
    required this.onReject,
  });

  final DoctorModel doctor;
  final bool isBusy;
  final VoidCallback onEdit;

  /// Decisions on a self-registered doctor's application.
  final ValueChanged<ApprovalChoice> onApprove;
  final ValueChanged<String> onReject;
  final VoidCallback onAddFile;
  final ValueChanged<String> onDeleteFile;
  final ValueChanged<DoctorAttachmentFileModel> onOpenFile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            DoctorSliverHeader(doctor: doctor, onEdit: onEdit),
            SliverToBoxAdapter(
              child: AdaptiveDetailSections(
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

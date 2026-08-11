import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_detail_sections.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_attachments_section.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_info_tiles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// The case details section: identity panel, info tiles, notes, restorations
/// and attachments.
class CaseDetailsBody extends StatelessWidget {
  const CaseDetailsBody({
    super.key,
    required this.caseDetail,
    required this.isBusy,
    required this.onChangeStage,
    required this.onAddFile,
    required this.onOpenFile,
    required this.onDeleteFile,
  });

  final CaseDetailModel caseDetail;
  final bool isBusy;
  final ValueChanged<CaseRestorationModel> onChangeStage;
  final VoidCallback onAddFile;
  final ValueChanged<CaseFileModel> onOpenFile;
  final ValueChanged<String> onDeleteFile;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          // The hero panel is full-bleed, so the horizontal inset belongs to
          // the content below it rather than to the scroll view.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroHeader(caseDetail: caseDetail),
              AdaptiveDetailSections(
                // The restorations are the case: on a tablet they take the
                // wide column, where a row of stage chips fits on one line.
                main: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlassSectionTitle(
                        'التعويضات',
                        count: caseDetail.restorations.isEmpty
                            ? null
                            : caseDetail.restorations.length,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (caseDetail.restorations.isEmpty)
                        Text(
                          'لا يوجد تعويضات',
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: context.glass.onGlassMuted,
                          ),
                        )
                      else
                        ...caseDetail.restorations.map(
                          (r) => _RestorationCard(
                            restoration: r,
                            isBusy: isBusy,
                            onChangeStage: () => onChangeStage(r),
                          ),
                        ),
                    ],
                  ),
                  GlassAttachmentsSection<CaseFileModel>(
                    files: caseDetail.files,
                    isBusy: isBusy,
                    onAddFile: onAddFile,
                    onOpenFile: onOpenFile,
                    onDeleteFile: onDeleteFile,
                    idOf: (file) => file.id,
                    fileNameOf: (file) => file.fileName,
                  ),
                ],
                // Reference material — read once, then referred back to. It
                // sits alongside the restorations on a tablet instead of
                // pushing them below the fold.
                side: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const GlassSectionTitle('المعلومات'),
                      const SizedBox(height: AppSpacing.md),
                      _InfoTiles(caseDetail: caseDetail)
                          .animate(delay: AppMotion.stagger * 2)
                          .fadeIn(duration: AppMotion.base)
                          .slideY(
                            begin: 0.06,
                            duration: AppMotion.base,
                            curve: AppMotion.enter,
                          ),
                    ],
                  ),
                  if (caseDetail.notes != null && caseDetail.notes!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const GlassSectionTitle('ملاحظات'),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          caseDetail.notes!,
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: context.glass.onGlassMuted,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
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
  }
}

/// Brand identity panel for the case — the same focal point the doctor screen
/// has, instead of an avatar floating above a plain page.
///
/// It does not collapse the way the doctor screen's sliver header does: this
/// body lives
/// inside a tab, and the page's app bar (with the tab strip) already owns the
/// top of the screen, so a second collapsing bar would fight it.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.caseDetail});

  final CaseDetailModel caseDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            gradient: context.glass.brandGradient,
            // Curved bottom edge — the content below reads as sliding under a
            // panel rather than butting against a rectangular banner.
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadius.glassLg),
            ),
          ),
          child: Stack(
            children: [
              // Soft light blobs give the flat gradient depth.
              const Positioned(top: -70, right: -50, child: _Blob(size: 190)),
              const Positioned(bottom: -80, left: -60, child: _Blob(size: 170)),
              Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.folder_outlined,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    caseDetail.patientName ?? '—',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font20BoldText.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  if (caseDetail.caseNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'رقم الحالة: ${caseDetail.caseNumber}',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    alignment: WrapAlignment.center,
                    children: [
                      _HeroPill(label: caseDetail.caseStatusLabel),
                      // Hidden rather than shown as a dash: a case without a
                      // priority has nothing to say here.
                      if (caseDetail.priorityLabel.isNotEmpty)
                        _HeroPill(label: caseDetail.priorityLabel),
                    ],
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .slideY(begin: -0.08, duration: AppMotion.base, curve: AppMotion.enter);
  }
}

/// A pill on the coloured panel. Tinted white rather than by semantic colour —
/// on the brand gradient an accent fill loses its contrast and its meaning.
class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: Colors.white),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// The case's attributes as a tile mosaic — the same treatment the doctor
/// screen uses, via the shared [GlassInfoTiles].
///
/// The divided label/value rows this replaces gave every field the same weight
/// and read like a printed record.
class _InfoTiles extends StatelessWidget {
  const _InfoTiles({required this.caseDetail});

  final CaseDetailModel caseDetail;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassInfoTiles(
      tiles: [
        GlassInfoTile(
          icon: Icons.medical_services_outlined,
          label: 'الطبيب',
          value: caseDetail.doctorName,
          color: Theme.of(context).colorScheme.primary,
        ),
        GlassInfoTile(
          icon: Icons.local_hospital_outlined,
          label: 'العيادة',
          value: caseDetail.clinicName,
          color: glass.info,
        ),
        GlassInfoTile(
          icon: Icons.event_outlined,
          label: 'تاريخ التسليم',
          value: _date(caseDetail.dueDate),
          color: glass.warning,
        ),
        GlassInfoTile(
          icon: Icons.move_to_inbox_outlined,
          label: 'تاريخ الاستلام',
          value: _date(caseDetail.receivedAt),
          color: glass.success,
        ),
        GlassInfoTile(
          icon: Icons.tag_outlined,
          label: 'الرقم المرجعي',
          value: caseDetail.referenceNumber,
          color: glass.primaryDark,
        ),
      ],
    );
  }

  String _date(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// One restoration card in the details view: name, quantity/price, its own
/// teeth (with bridge connections) and shade/alloy info.
class _RestorationCard extends StatelessWidget {
  const _RestorationCard({
    required this.restoration,
    required this.isBusy,
    required this.onChangeStage,
  });

  final CaseRestorationModel restoration;
  final bool isBusy;
  final VoidCallback onChangeStage;

  @override
  Widget build(BuildContext context) {
    final shadeParts = [
      if (restoration.shadeCervical?.isNotEmpty == true)
        'العنقي: ${restoration.shadeCervical}',
      if (restoration.shadeMiddle?.isNotEmpty == true)
        'الوسط: ${restoration.shadeMiddle}',
      if (restoration.shadeIncisal?.isNotEmpty == true)
        'القاطع: ${restoration.shadeIncisal}',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: context.glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: context.glass.strokeColor),
        boxShadow: context.glass.shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: context.glass.brandGradient,
                ),
                child: const Icon(
                  Icons.category_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restoration.restorationName,
                      style: AppTextStyles.font14MediumText.copyWith(
                        color: context.glass.onGlass,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الكمية: ${restoration.quantity}'
                      '${restoration.unitPrice != null ? ' • ${restoration.unitPrice!.toStringAsFixed(0)} ${restoration.currencyName ?? ''}' : ''}',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: context.glass.onGlassMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (restoration.currentStageName != null)
                _Badge(
                  label: restoration.currentStageName!,
                  color: context.glass.success,
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: isBusy ? null : onChangeStage,
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('تغيير المرحلة'),
              ),
            ],
          ),
          if (restoration.teeth.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: restoration.teeth
                  .map(
                    (t) => _Badge(
                      label: t.connectedToToothNumber != null
                          ? '${t.toothNumber} ↔ ${t.connectedToToothNumber}'
                          : '${t.toothNumber}',
                      color: context.glass.info,
                    ),
                  )
                  .toList(),
            ),
          ],
          if (shadeParts.isNotEmpty ||
              restoration.baseToothColor?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (shadeParts.isNotEmpty) shadeParts.join(' • '),
                if (restoration.baseToothColor?.isNotEmpty == true)
                  'لون الأساس: ${restoration.baseToothColor}',
              ].join('  •  '),
              style: AppTextStyles.font12RegularHint.copyWith(
                color: context.glass.onGlassMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/detail_info_row_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_detail_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_file_model.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:flutter/material.dart';

/// The case details section: header, info card, stage action, notes, teeth,
/// restorations and attachments.
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
                      _Header(caseDetail: caseDetail),
                      const SizedBox(height: 16),
                      _InfoCard(caseDetail: caseDetail),
                      if (caseDetail.notes != null &&
                          caseDetail.notes!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle('ملاحظات'),
                        const SizedBox(height: 8),
                        Text(
                          caseDetail.notes!,
                          style: AppTextStyles.font14RegularSecondary,
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SectionTitle('التعويضات'),
                      const SizedBox(height: 8),
                      if (caseDetail.restorations.isEmpty)
                        Text(
                          'لا يوجد تعويضات',
                          style: AppTextStyles.font14RegularSecondary,
                        )
                      else
                        ...caseDetail.restorations.map(
                          (r) => _RestorationCard(
                            restoration: r,
                            isBusy: isBusy,
                            onChangeStage: () => onChangeStage(r),
                          ),
                        ),
                      const SizedBox(height: 24),
                      _Attachments(
                        files: caseDetail.files,
                        isBusy: isBusy,
                        onAddFile: onAddFile,
                        onOpenFile: onOpenFile,
                        onDeleteFile: onDeleteFile,
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

class _Header extends StatelessWidget {
  const _Header({required this.caseDetail});

  final CaseDetailModel caseDetail;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Text(
            caseDetail.patientName ?? '—',
            style: AppTextStyles.font20BoldText,
          ),
          const SizedBox(height: 4),
          Text(
            caseDetail.caseNumber == null
                ? ''
                : 'رقم الحالة: ${caseDetail.caseNumber}',
            style: AppTextStyles.font12RegularHint,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: [
              _Badge(
                label: caseDetail.priority.arabicLabel,
                color: AppColorsManger.warning,
              ),
              _Badge(
                label: caseDetail.caseStatusLabel,
                color: AppColorsManger.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.caseDetail});

  final CaseDetailModel caseDetail;

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
            icon: Icons.medical_services_outlined,
            label: 'الطبيب',
            value: caseDetail.doctorName ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.local_hospital_outlined,
            label: 'العيادة',
            value: caseDetail.clinicName ?? '',
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.event_outlined,
            label: 'تاريخ التسليم',
            value: _date(caseDetail.dueDate),
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.move_to_inbox_outlined,
            label: 'تاريخ الاستلام',
            value: _date(caseDetail.receivedAt),
          ),
          const Divider(height: 1, color: AppColorsManger.divider),
          DetailInfoRowWidget(
            icon: Icons.tag_outlined,
            label: 'الرقم المرجعي',
            value: caseDetail.referenceNumber ?? '',
          ),
        ],
      ),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorsManger.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorsManger.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.category_outlined,
                color: AppColorsManger.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restoration.restorationName,
                      style: AppTextStyles.font14MediumText,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'الكمية: ${restoration.quantity}'
                      '${restoration.unitPrice != null ? ' • ${restoration.unitPrice!.toStringAsFixed(0)} ${restoration.currencyName ?? ''}' : ''}',
                      style: AppTextStyles.font12RegularHint,
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
                  color: AppColorsManger.success,
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
                      color: AppColorsManger.info,
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
              style: AppTextStyles.font12RegularHint,
            ),
          ],
        ],
      ),
    );
  }
}

class _Attachments extends StatelessWidget {
  const _Attachments({
    required this.files,
    required this.isBusy,
    required this.onAddFile,
    required this.onOpenFile,
    required this.onDeleteFile,
  });

  final List<CaseFileModel> files;
  final bool isBusy;
  final VoidCallback onAddFile;
  final ValueChanged<CaseFileModel> onOpenFile;
  final ValueChanged<String> onDeleteFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('المرفقات', style: AppTextStyles.font16MediumText),
            ),
            TextButton.icon(
              onPressed: isBusy ? null : onAddFile,
              icon: const Icon(Icons.attach_file, size: 18),
              label: const Text('إضافة ملف'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لا يوجد مرفقات',
              style: AppTextStyles.font14RegularSecondary,
            ),
          )
        else
          ...files.map(
            (file) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorsManger.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onOpenFile(file),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
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
                            file.fileName?.isNotEmpty == true
                                ? file.fileName!
                                : 'ملف',
                            style: AppTextStyles.font14MediumText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new,
                          size: 18,
                          color: AppColorsManger.textSecondary,
                        ),
                        IconButton(
                          onPressed: isBusy ? null : () => onDeleteFile(file.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColorsManger.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Text(text, style: AppTextStyles.font16MediumText),
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
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

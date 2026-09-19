import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/barcode_sharing.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/case_restoration_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Everything recorded about one restoration, on one screen.
///
/// The card in the list carries only what a glance needs; this is where the
/// bench reads the spec it has to work to — the teeth, the shades, the alloy,
/// the doctor's note — without leaving the case.
Future<void> showRestorationDetailSheet(
  BuildContext context, {
  required CaseRestorationModel restoration,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _RestorationDetailSheet(restoration: restoration),
  );
}

class _RestorationDetailSheet extends StatelessWidget {
  const _RestorationDetailSheet({required this.restoration});

  final CaseRestorationModel restoration;

  Future<void> _copyBarcode(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    showToast(message: 'تم نسخ الباركود', state: ToastState.success);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isAdmin = getIt<SessionCubit>().state.isAdmin;
    final number = restoration.restorationNumber?.trim();

    final shades = [
      if (restoration.shadeCervical?.isNotEmpty == true)
        'العنقي: ${restoration.shadeCervical}',
      if (restoration.shadeMiddle?.isNotEmpty == true)
        'الوسط: ${restoration.shadeMiddle}',
      if (restoration.shadeIncisal?.isNotEmpty == true)
        'القاطع: ${restoration.shadeIncisal}',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            restoration.restorationName,
            style: AppTextStyles.font18MediumText.copyWith(
              color: glass.onGlass,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _Row(label: 'عدد القطع', value: '${restoration.quantity}'),
          if (restoration.currentStageName != null)
            _Row(
              label: 'المرحلة الحالية',
              value: restoration.currentStageName!,
            ),
          if (restoration.teeth.isNotEmpty)
            _Row(
              label: 'الأسنان',
              value: restoration.teeth
                  .map(
                    (tooth) => tooth.connectedToToothNumber != null
                        ? '${tooth.toothNumber}↔${tooth.connectedToToothNumber}'
                        : '${tooth.toothNumber}',
                  )
                  .join('، '),
            ),
          if (shades.isNotEmpty)
            _Row(label: 'درجات اللون', value: shades.join('  •  ')),
          if (restoration.shadeLayout?.isNotEmpty == true)
            _Row(label: 'نظام اللون', value: restoration.shadeLayout!),
          if (restoration.baseToothColor?.isNotEmpty == true)
            _Row(label: 'لون الأساس', value: restoration.baseToothColor!),
          if (restoration.notes?.isNotEmpty == true)
            _Row(label: 'ملاحظات', value: restoration.notes!),

          // Money is admin-only here for the same reason it is on the card and
          // in the form: a technician must not read on one screen what another
          // hid from them.
          if (isAdmin && restoration.unitPrice != null)
            _Row(
              label: 'سعر الوحدة',
              value:
                  '${restoration.unitPrice!.toStringAsFixed(0)} '
                  '${restoration.currencyName ?? ''}',
            ),

          if (number != null && number.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'باركود التعويض',
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "نسخ محتوى الباركود",
                  onPressed: () => _copyBarcode(number),
                  icon: Icon(
                    Icons.copy_outlined,
                    size: 18,
                    color: glass.onGlassMuted,
                  ),
                ),
                IconButton(
                  tooltip: "مشاركة صورة الباركود",
                  onPressed: () => shareBarcodeImage(
                    payload: number,
                    title: restoration.restorationName,
                  ),
                  icon: Icon(
                    Icons.ios_share,
                    size: 18,
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.glass),
                ),
                // The piece's own code encodes its number — that string is
                // what `/Cases/restorations/by-number/{n}` resolves, so it is
                // the barcode, not a label beside one.
                child: QrImageView(
                  data: number,
                  size: 140,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.font14MediumText.copyWith(
                color: glass.onGlass,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

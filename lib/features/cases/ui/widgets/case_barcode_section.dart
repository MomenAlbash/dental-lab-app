import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/barcode_sharing.dart';
import 'package:dental_lab_app/core/printing/label_printer_service.dart';
import 'package:dental_lab_app/core/printing/print_label_sheet.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_ticket_templates/ui/print_case_ticket_sheet.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:dental_lab_app/features/cases/data/repos/cases_repo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The case's barcode, on screen and copyable.
///
/// The lab prints this on the ticket that travels with the work; showing the
/// same code here means a case whose paper was lost — or never printed — can
/// still be scanned off a phone, and the number can be copied into whatever
/// else the lab keeps its records in.
///
/// The payload is fetched, never invented: the server decides what the printed
/// code encodes (`qrPayload`), and a code the app made up would scan to
/// nothing.
class CaseBarcodeSection extends StatefulWidget {
  const CaseBarcodeSection({super.key, required this.caseId});

  final String caseId;

  @override
  State<CaseBarcodeSection> createState() => _CaseBarcodeSectionState();
}

class _CaseBarcodeSectionState extends State<CaseBarcodeSection> {
  CasePrintTicketModel? _ticket;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<CasesRepo>().getCasePrintTicket(widget.caseId);
    if (!mounted) return;

    result.fold(
      (_) => setState(() => _failed = true),
      (ticket) => setState(() => _ticket = ticket),
    );
  }

  Future<void> _copy(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    showToast(message: 'تم نسخ الباركود', state: ToastState.success);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final ticket = _ticket;

    if (_failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GlassSectionTitle('الباركود'),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'تعذّر جلب باركود الحالة',
            style: AppTextStyles.font14RegularSecondary.copyWith(
              color: glass.onGlassMuted,
            ),
          ),
        ],
      );
    }

    if (ticket == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final payload = ticket.qrPayload?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassSectionTitle(
          'الباركود',
          trailing: TextButton.icon(
            onPressed: () => printCaseTicket(context, ticket: ticket),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('طباعة تذكرة الحالة'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            borderRadius: BorderRadius.circular(AppRadius.glass),
            border: Border.all(color: glass.strokeColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (payload == null || payload.isEmpty)
                Text(
                  'لا يوجد باركود لهذه الحالة',
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                )
              else
                _BarcodeBlock(
                  title: 'باركود الحالة',
                  subtitle: ticket.caseNumber,
                  // The payload, not the case number: the number names the
                  // case to a human, the payload is what the printed code
                  // encodes and what a scanner resolves. Copying the number
                  // handed the user something a scanner cannot read.
                  payload: payload,
                  onCopy: () => _copy(payload),
                  onPrint: () async {
                    final tsplBytes = await LabelPrinterService.buildCaseLabel(
                      caseNumber: ticket.caseNumber ?? '',
                      qrPayload: payload,
                    );
                    if (context.mounted) {
                      await printLabel(context, tsplBytes: tsplBytes);
                    }
                  },
                ),

              // Each restoration carries its own code on the printed ticket —
              // the piece on the bench is scanned, not the whole case.
              if (ticket.restorations.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'باركود التعويضات',
                  style: AppTextStyles.font14MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final restoration in ticket.restorations)
                  if (restoration.restorationNumber != null) ...[
                    _BarcodeBlock(
                      title: restoration.displayName.isEmpty
                          ? 'تعويض'
                          : restoration.displayName,
                      subtitle: [
                        'رقم: ${restoration.restorationNumber}',
                        if (restoration.quantity > 1)
                          'العدد: ${restoration.quantity}',
                      ].join(' • '),
                      // A restoration's barcode encodes its own number — the
                      // very string `GET /Cases/restorations/by-number/{n}`
                      // resolves.
                      payload: restoration.restorationNumber!,
                      onCopy: () => _copy(restoration.restorationNumber!),
                      onPrint: () async {
                        final tsplBytes =
                            await LabelPrinterService.buildCaseLabel(
                              caseNumber: restoration.restorationNumber!,
                              qrPayload: restoration.restorationNumber!,
                              patientName: restoration.displayName,
                            );
                        if (context.mounted) {
                          await printLabel(context, tsplBytes: tsplBytes);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One code: the picture a scanner reads, what it belongs to, and the one
/// thing anybody wants to do with it on a phone.
class _BarcodeBlock extends StatelessWidget {
  const _BarcodeBlock({
    required this.title,
    required this.subtitle,
    required this.payload,
    required this.onCopy,
    this.onPrint,
  });

  final String title;
  final String? subtitle;

  /// What the code encodes — the string a scanner resolves, never the
  /// human-facing number that happens to sit beside it.
  final String payload;

  final VoidCallback onCopy;

  /// Null hides the print button — offered even though the printer is
  /// external hardware nothing here can detect ahead of time; the picker it
  /// opens is where "no printer found" actually gets said.
  final VoidCallback? onPrint;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.font14MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                ],
              ),
            ),
            if (onPrint != null)
              IconButton(
                tooltip: "طباعة الملصق",
                onPressed: onPrint,
                icon: Icon(
                  Icons.print_outlined,
                  color: glass.onGlassMuted,
                  size: 18,
                ),
              ),
            IconButton(
              tooltip: "نسخ محتوى الباركود",
              onPressed: onCopy,
              icon: Icon(
                Icons.copy_outlined,
                color: glass.onGlassMuted,
                size: 18,
              ),
            ),
            // The picture, not the text: copying hands over the string the code
            // encodes, which is a number. Somebody sending a code to a doctor
            // wants the sticker itself.
            IconButton(
              tooltip: "مشاركة صورة الباركود",
              onPressed: () =>
                  shareBarcodeImage(payload: payload, title: title),
              icon: Icon(Icons.ios_share, color: glass.onGlassMuted, size: 18),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            // White behind the code on purpose: a scanner needs the contrast,
            // and the glass surface is tinted in dark mode.
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.glass),
            ),
            child: QrImageView(
              data: payload,
              size: 140,
              backgroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

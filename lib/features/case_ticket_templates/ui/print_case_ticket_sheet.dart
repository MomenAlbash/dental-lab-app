import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/printing/print_label_sheet.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/repos/case_ticket_templates_repo.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_render/case_ticket_renderer.dart';
import 'package:dental_lab_app/features/cases/data/models/case_barcode_models.dart';
import 'package:flutter/material.dart';

typedef _ResolvedTemplateSource = Future<CaseTicketTemplateModel?> Function();

/// Lets the user pick which saved layout prints [ticket], then sends it to
/// the connected thermal printer through the same [LabelPrinterService] the
/// case/restoration barcode labels already use.
///
/// A saved template's list row carries no rows of its own — only once picked
/// is its full detail fetched and merged with [ticket] by
/// [CaseTicketRenderer.render], the one function live preview and this print
/// path both go through.
Future<void> printCaseTicket(
  BuildContext context, {
  required CasePrintTicketModel ticket,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CaseTicketTemplatePickerSheet(ticket: ticket),
  );
}

class _CaseTicketTemplatePickerSheet extends StatefulWidget {
  const _CaseTicketTemplatePickerSheet({required this.ticket});

  final CasePrintTicketModel ticket;

  @override
  State<_CaseTicketTemplatePickerSheet> createState() =>
      _CaseTicketTemplatePickerSheetState();
}

class _CaseTicketTemplatePickerSheetState
    extends State<_CaseTicketTemplatePickerSheet> {
  final _repo = getIt<CaseTicketTemplatesRepo>();
  List<CaseTicketTemplateListItemModel> _templates = [];
  bool _isLoading = true;
  String? _resolvingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _repo.getCaseTicketTemplates();
    if (!mounted) return;

    result.fold(
      // A failed list load still leaves the built-in default printable —
      // this sheet's whole point is to never block printing on it.
      (_) => setState(() => _isLoading = false),
      (templates) => setState(() {
        _templates = templates;
        _isLoading = false;
      }),
    );
  }

  Future<void> _printWith(_ResolvedTemplateSource source, String id) async {
    setState(() => _resolvingId = id);

    final template = await source();
    if (!mounted) return;

    if (template == null) {
      setState(() => _resolvingId = null);
      showToast(message: 'تعذّر تحميل القالب', state: ToastState.error);
      return;
    }

    final tsplBytes = await CaseTicketRenderer.render(
      template: template,
      ticket: widget.ticket,
    );

    if (!mounted) return;
    Navigator.of(context).pop();
    await printLabel(context, tsplBytes: tsplBytes);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) => GlassSheetSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                'اختر تصميم تذكرة الحالة',
                style: AppTextStyles.font18MediumText.copyWith(
                  color: glass.onGlass,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.receipt_long_outlined,
                      color: glass.onGlassMuted,
                    ),
                    title: const Text('التصميم الافتراضي'),
                    trailing: _resolvingId == 'default'
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _resolvingId != null
                        ? null
                        : () => _printWith(
                            () async => CaseTicketRenderer.defaultTemplate,
                            'default',
                          ),
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    for (final template in _templates)
                      ListTile(
                        leading: Icon(
                          Icons.description_outlined,
                          color: glass.onGlassMuted,
                        ),
                        title: Text(template.name ?? '—'),
                        trailing: _resolvingId == template.id
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : template.isDefault
                            ? Icon(Icons.star, color: glass.info, size: 18)
                            : null,
                        onTap: _resolvingId != null
                            ? null
                            : () => _printWith(() async {
                                final result = await _repo
                                    .getCaseTicketTemplateById(template.id);
                                return result.fold((_) => null, (t) => t);
                              }, template.id),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

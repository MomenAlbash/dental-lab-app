import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_row_align.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_kind.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_row_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/save_case_ticket_template_request_models.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_template_editor/case_ticket_template_editor_cubit.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_template_editor/case_ticket_template_editor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One template's own editor — its name, paper/font settings, and the
/// ordered row list. Pops `true` once a save lands, so the list screen
/// knows to refresh.
class CaseTicketTemplateEditorPage extends StatelessWidget {
  const CaseTicketTemplateEditorPage({super.key, required this.templateId});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CaseTicketTemplateEditorCubit>()..load(templateId),
      child: _EditorView(templateId: templateId),
    );
  }
}

class _EditorView extends StatefulWidget {
  const _EditorView({required this.templateId});

  final String templateId;

  @override
  State<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends State<_EditorView> {
  final _nameController = TextEditingController();
  final _paperWidthController = TextEditingController();
  final _fontSizeController = TextEditingController();
  final _fontFamilyController = TextEditingController();
  List<CaseTicketTemplateRowModel> _rows = [];

  /// Local state is seeded once from the first successful load — later
  /// reloads (there are none here, but a defensive habit) must not stomp on
  /// whatever the user has typed since.
  bool _seeded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _paperWidthController.dispose();
    _fontSizeController.dispose();
    _fontFamilyController.dispose();
    super.dispose();
  }

  void _seedFrom(CaseTicketTemplateEditorLoaded state) {
    if (_seeded) return;
    _seeded = true;
    final template = state.template;
    _nameController.text = template.name ?? '';
    _paperWidthController.text = template.paperWidthMm.toStringAsFixed(0);
    _fontSizeController.text = template.baseFontSizePx.toStringAsFixed(0);
    _fontFamilyController.text = template.fontFamily ?? '';
    setState(() => _rows = [...template.rows]);
  }

  Future<void> _addRow() async {
    final kind = await showDialog<CaseTicketTemplateRowKind>(
      context: context,
      builder: (_) => const _PickRowKindDialog(),
    );
    if (kind == null) return;

    setState(
      () => _rows.add(
        CaseTicketTemplateRowModel(id: UniqueKey().toString(), kind: kind),
      ),
    );
  }

  Future<void> _editRow(int index) async {
    final updated = await showDialog<CaseTicketTemplateRowModel>(
      context: context,
      builder: (_) => _RowConfigDialog(row: _rows[index]),
    );
    if (updated == null) return;
    setState(() => _rows[index] = updated);
  }

  void _removeRow(int index) => setState(() => _rows.removeAt(index));

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final row = _rows.removeAt(oldIndex);
      _rows.insert(newIndex, row);
    });
  }

  void _save() {
    final paperWidth = double.tryParse(_paperWidthController.text.trim());
    final fontSize = double.tryParse(_fontSizeController.text.trim());
    if (_nameController.text.trim().isEmpty) {
      showToast(message: 'اسم القالب مطلوب', state: ToastState.error);
      return;
    }
    if (paperWidth == null || paperWidth < 20 || paperWidth > 300) {
      showToast(message: 'عرض الورق بين 20 و 300 مم', state: ToastState.error);
      return;
    }
    if (fontSize == null || fontSize < 6 || fontSize > 40) {
      showToast(message: 'حجم الخط بين 6 و 40', state: ToastState.error);
      return;
    }

    context.read<CaseTicketTemplateEditorCubit>().save(
      id: widget.templateId,
      requestBody: UpdateCaseTicketTemplateRequestModel(
        name: _nameController.text.trim(),
        paperWidthMm: paperWidth,
        baseFontSizePx: fontSize,
        fontFamily: _fontFamilyController.text.trim().isEmpty
            ? null
            : _fontFamilyController.text.trim(),
        rows: _rows,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'محرر القالب',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      body: SafeArea(
        child:
            BlocConsumer<
              CaseTicketTemplateEditorCubit,
              CaseTicketTemplateEditorState
            >(
              listener: (context, state) {
                if (state is CaseTicketTemplateEditorLoaded) _seedFrom(state);
                if (state case CaseTicketTemplateEditorMessage(
                  :final message,
                  :final isError,
                )) {
                  showToast(
                    message: message,
                    state: isError ? ToastState.error : ToastState.success,
                  );
                  if (!isError) Navigator.of(context).pop(true);
                }
              },
              builder: (context, state) {
                if (state is CaseTicketTemplateEditorError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.font14RegularSecondary.copyWith(
                          color: glass.onGlassMuted,
                        ),
                      ),
                    ),
                  );
                }
                if (!_seeded) {
                  return const Center(
                    child: CustomCircleProgressIndiacatorWidget(),
                  );
                }

                final isSaving =
                    state is CaseTicketTemplateEditorLoaded && state.isSaving;

                return Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.screen),
                        children: [
                          const _FieldLabel('اسم القالب'),
                          AppTextFormField(
                            controller: _nameController,
                            hintText: 'اسم القالب',
                            enabled: !isSaving,
                            validator: (_) => null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('عرض الورق (mm)'),
                                    AppTextFormField(
                                      controller: _paperWidthController,
                                      hintText: '80',
                                      enabled: !isSaving,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (_) => null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('حجم الخط'),
                                    AppTextFormField(
                                      controller: _fontSizeController,
                                      hintText: '11',
                                      enabled: !isSaving,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      validator: (_) => null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const _FieldLabel('نوع الخط (اختياري)'),
                          AppTextFormField(
                            controller: _fontFamilyController,
                            hintText:
                                'يستخدم خط المُصمّم الافتراضي إذا تُرك فارغاً',
                            enabled: !isSaving,
                            validator: (_) => null,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Row(
                            children: [
                              Text(
                                'صفوف القالب',
                                style: AppTextStyles.font16MediumText,
                              ),
                              const Spacer(),
                              TextButton.icon(
                                onPressed: isSaving ? null : _addRow,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('إضافة صف'),
                              ),
                            ],
                          ),
                          if (_rows.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'لا توجد صفوف بعد — أضف أول صف',
                                style: AppTextStyles.font14RegularSecondary
                                    .copyWith(color: glass.onGlassMuted),
                              ),
                            )
                          else
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _rows.length,
                              onReorderItem: isSaving ? (_, _) {} : _reorder,
                              itemBuilder: (context, index) => _RowTile(
                                key: ValueKey(_rows[index].id),
                                row: _rows[index],
                                onToggleVisible: isSaving
                                    ? null
                                    : () => setState(() {
                                        _rows[index] = _rows[index].copyWith(
                                          visible: !_rows[index].visible,
                                        );
                                      }),
                                onEdit: isSaving ? null : () => _editRow(index),
                                onRemove: isSaving
                                    ? null
                                    : () => _removeRow(index),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.screen),
                      child: isSaving
                          ? const Center(
                              child: CustomCircleProgressIndiacatorWidget(),
                            )
                          : CustomButtonWidget(
                              onPressed: _save,
                              buttonText: 'حفظ القالب',
                            ),
                    ),
                  ],
                );
              },
            ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: AppTextStyles.font14MediumText),
    );
  }
}

class _RowTile extends StatelessWidget {
  const _RowTile({
    super.key,
    required this.row,
    required this.onToggleVisible,
    required this.onEdit,
    required this.onRemove,
  });

  final CaseTicketTemplateRowModel row;
  final VoidCallback? onToggleVisible;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: glass.surfaceColor,
        border: Border.all(color: glass.strokeColor),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          Icon(Icons.drag_handle, color: glass.onGlassMuted, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  row.kind.arabicLabel,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: row.visible ? glass.onGlass : glass.onGlassMuted,
                  ),
                ),
                if (row.label?.trim().isNotEmpty ?? false)
                  Text(
                    row.label!.trim(),
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  )
                else if (row.kind == CaseTicketTemplateRowKind.customLabel &&
                    (row.text?.trim().isNotEmpty ?? false))
                  Text(
                    row.text!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: row.visible ? 'إخفاء الصف' : 'إظهار الصف',
            onPressed: onToggleVisible,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              row.visible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: glass.onGlassMuted,
              size: 18,
            ),
          ),
          IconButton(
            tooltip: 'تعديل',
            onPressed: onEdit,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.tune, color: glass.onGlassMuted, size: 18),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.close, color: glass.error, size: 18),
          ),
        ],
      ),
    );
  }
}

class _PickRowKindDialog extends StatelessWidget {
  const _PickRowKindDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة صف', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final kind in CaseTicketTemplateRowKind.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(kind.arabicLabel),
                  onTap: () => Navigator.of(context).pop(kind),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}

class _RowConfigDialog extends StatefulWidget {
  const _RowConfigDialog({required this.row});

  final CaseTicketTemplateRowModel row;

  @override
  State<_RowConfigDialog> createState() => _RowConfigDialogState();
}

class _RowConfigDialogState extends State<_RowConfigDialog> {
  late final _labelController = TextEditingController(
    text: widget.row.label ?? '',
  );
  late final _textController = TextEditingController(
    text: widget.row.text ?? '',
  );
  late final _fontSizeController = TextEditingController(
    text: widget.row.fontSize?.toStringAsFixed(0) ?? '',
  );
  late final _qrSizeController = TextEditingController(
    text: widget.row.qrSizeMm?.toStringAsFixed(0) ?? '',
  );
  late bool _bold = widget.row.bold ?? false;
  late CaseTicketRowAlign? _align = widget.row.align;
  late bool _showTeeth = widget.row.showTeeth ?? true;
  late bool _showShade = widget.row.showShade ?? true;
  late bool _showNotes = widget.row.showNotes ?? true;

  @override
  void dispose() {
    _labelController.dispose();
    _textController.dispose();
    _fontSizeController.dispose();
    _qrSizeController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    final kind = widget.row.kind;
    Navigator.of(context).pop(
      widget.row.copyWith(
        label: kind.hasEditableLabel && _labelController.text.trim().isNotEmpty
            ? _labelController.text.trim()
            : null,
        clearLabel:
            kind.hasEditableLabel && _labelController.text.trim().isEmpty,
        text: kind == CaseTicketTemplateRowKind.customLabel
            ? _textController.text.trim()
            : null,
        fontSize: double.tryParse(_fontSizeController.text.trim()),
        bold: _bold,
        align: _align,
        qrSizeMm: kind == CaseTicketTemplateRowKind.qr
            ? double.tryParse(_qrSizeController.text.trim())
            : null,
        showTeeth: kind == CaseTicketTemplateRowKind.restorationsTable
            ? _showTeeth
            : null,
        showShade: kind == CaseTicketTemplateRowKind.restorationsTable
            ? _showShade
            : null,
        showNotes: kind == CaseTicketTemplateRowKind.restorationsTable
            ? _showNotes
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.row.kind;

    return AlertDialog(
      title: Text(
        'تعديل: ${kind.arabicLabel}',
        style: AppTextStyles.font18MediumText,
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kind.hasEditableLabel) ...[
                AppTextFormField(
                  controller: _labelController,
                  hintText: 'تسمية مخصّصة (اختياري)',
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
              ],
              if (kind == CaseTicketTemplateRowKind.customLabel) ...[
                AppTextFormField(
                  controller: _textController,
                  hintText: 'النص',
                  maxLines: 2,
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
              ],
              if (kind == CaseTicketTemplateRowKind.qr) ...[
                AppTextFormField(
                  controller: _qrSizeController,
                  hintText: 'حجم رمز QR بالملم (افتراضي 30)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
              ],
              if (kind == CaseTicketTemplateRowKind.restorationsTable) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عرض الأسنان'),
                  value: _showTeeth,
                  onChanged: (v) => setState(() => _showTeeth = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عرض اللون'),
                  value: _showShade,
                  onChanged: (v) => setState(() => _showShade = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عرض الملاحظات'),
                  value: _showNotes,
                  onChanged: (v) => setState(() => _showNotes = v),
                ),
                const SizedBox(height: 12),
              ],
              if (kind != CaseTicketTemplateRowKind.divider) ...[
                AppTextFormField(
                  controller: _fontSizeController,
                  hintText: 'حجم الخط (اختياري، يرث حجم القالب)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('عريض'),
                  value: _bold,
                  onChanged: (v) => setState(() => _bold = v),
                ),
                const SizedBox(height: 8),
                Text('المحاذاة', style: AppTextStyles.font14MediumText),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final align in CaseTicketRowAlign.values)
                      ChoiceChip(
                        label: Text(align.apiValue),
                        selected: _align == align,
                        onSelected: (_) => setState(
                          () => _align = _align == align ? null : align,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('حفظ')),
      ],
    );
  }
}

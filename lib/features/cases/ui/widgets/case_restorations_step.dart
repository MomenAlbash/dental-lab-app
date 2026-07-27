import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/ui/case_form_page.dart';
import 'package:dental_lab_app/features/cases/ui/widgets/case_lookup_dropdown.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_cubit.dart';
import 'package:dental_lab_app/features/restoration_types/logic/restoration_types/restoration_types_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Step 3 — the restoration lines for the case.
class CaseRestorationsStep extends StatelessWidget {
  const CaseRestorationsStep({
    super.key,
    required this.restorations,
    required this.onAdd,
    required this.onRemove,
  });

  final List<RestorationEntry> restorations;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('إضافة تعويض'),
        ),
        const SizedBox(height: 12),
        if (restorations.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لم تتم إضافة تعويضات',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary,
            ),
          )
        else
          ...restorations.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorsManger.border),
              ),
              child: Row(
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
                          entry.value.restorationName,
                          style: AppTextStyles.font14MediumText,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الكمية: ${entry.value.quantity}'
                          '${entry.value.unitPrice != null ? ' • ${entry.value.unitPrice!.toStringAsFixed(0)}' : ''}',
                          style: AppTextStyles.font12RegularHint,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => onRemove(entry.key),
                    icon: const Icon(
                      Icons.close,
                      color: AppColorsManger.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 2),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: AppTextStyles.font14MediumText),
      ),
    );
  }
}

/// Dialog to build one restoration line. Requires a [RestorationTypesCubit] in
/// the tree (provided by the caller).
class AddRestorationDialog extends StatefulWidget {
  const AddRestorationDialog({super.key});

  @override
  State<AddRestorationDialog> createState() => _AddRestorationDialogState();
}

class _AddRestorationDialogState extends State<AddRestorationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _typeId;
  String? _typeName;

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (_typeId == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    Navigator.of(context).pop(
      RestorationEntry(
        restorationTypeId: _typeId!,
        restorationName: _typeName ?? '—',
        quantity: int.tryParse(_quantityController.text.trim()) ?? 1,
        unitPrice: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة تعويض', style: AppTextStyles.font18MediumText),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _FieldLabel('التعويض'),
              BlocBuilder<RestorationTypesCubit, RestorationTypesState>(
                builder: (context, state) {
                  final types = state is RestorationTypesLoaded
                      ? state.types
                      : null;
                  return CaseLookupDropdown(
                    value: _typeId,
                    icon: Icons.category_outlined,
                    hintText: state is RestorationTypesLoading
                        ? 'جارٍ تحميل التعويضات...'
                        : 'اختر التعويض',
                    items: types
                        ?.map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _typeId = value;
                      _typeName = types
                          ?.firstWhere((t) => t.id == value)
                          .displayName;
                    }),
                  );
                },
              ),
              const SizedBox(height: 12),
              const _FieldLabel('الكمية'),
              AppTextFormField(
                controller: _quantityController,
                hintText: 'أدخل الكمية',
                prefixIcon: const Icon(
                  Icons.numbers_outlined,
                  color: AppColorsManger.textSecondary,
                ),
                validator: (v) => (v == null || int.tryParse(v.trim()) == null)
                    ? 'الكمية مطلوبة'
                    : null,
              ),
              const SizedBox(height: 12),
              const _FieldLabel('سعر الوحدة'),
              AppTextFormField(
                controller: _priceController,
                hintText: 'أدخل سعر الوحدة (اختياري)',
                prefixIcon: const Icon(
                  Icons.attach_money_outlined,
                  color: AppColorsManger.textSecondary,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  return double.tryParse(v) == null ? 'رقم غير صالح' : null;
                },
              ),
              const SizedBox(height: 12),
              const _FieldLabel('ملاحظات'),
              AppTextFormField(
                controller: _notesController,
                hintText: 'أدخل ملاحظات (اختياري)',
                prefixIcon: const Icon(
                  Icons.notes_outlined,
                  color: AppColorsManger.textSecondary,
                ),
                validator: (_) => null,
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
        TextButton(onPressed: _onAdd, child: const Text('إضافة')),
      ],
    );
  }
}

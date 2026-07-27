import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/data/models/tooth_mark_model.dart';
import 'package:flutter/material.dart';

/// Step 2 — the marked teeth for the case.
class CaseTeethStep extends StatelessWidget {
  const CaseTeethStep({
    super.key,
    required this.teeth,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ToothMarkModel> teeth;
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
          label: const Text('إضافة سن'),
        ),
        const SizedBox(height: 12),
        if (teeth.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'لم تتم إضافة أسنان',
              textAlign: TextAlign.center,
              style: AppTextStyles.font14RegularSecondary,
            ),
          )
        else
          ...teeth.asMap().entries.map(
            (entry) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorsManger.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColorsManger.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColorsManger.primarySurface,
                    child: Text(
                      '${entry.value.toothNumber}',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: AppColorsManger.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value.description?.isNotEmpty == true
                          ? entry.value.description!
                          : 'بدون وصف',
                      style: AppTextStyles.font14MediumText,
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

/// Dialog to build one tooth mark. Owns its own controllers so they aren't
/// disposed while the dialog is still animating out.
class AddToothDialog extends StatefulWidget {
  const AddToothDialog({super.key});

  @override
  State<AddToothDialog> createState() => _AddToothDialogState();
}

class _AddToothDialogState extends State<AddToothDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onAdd() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      ToothMarkModel(
        toothNumber: int.parse(_numberController.text.trim()),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إضافة سن', style: AppTextStyles.font18MediumText),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextFormField(
                controller: _numberController,
                hintText: 'رقم السن',
                prefixIcon: const Icon(
                  Icons.numbers_outlined,
                  color: AppColorsManger.textSecondary,
                ),
                validator: (v) => (v == null || int.tryParse(v.trim()) == null)
                    ? 'رقم السن مطلوب'
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextFormField(
                controller: _descController,
                hintText: 'وصف (اختياري)',
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

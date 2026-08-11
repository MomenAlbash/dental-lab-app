import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_rule_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_rule_model.dart';
import 'package:flutter/material.dart';

/// Add/edit one weekly scanner window. Pops with the request body, or null if
/// dismissed — the caller sends it, so the dialog owns no cubit.
class ScannerRuleFormDialog extends StatefulWidget {
  const ScannerRuleFormDialog({super.key, this.initialRule});

  final ScannerAvailabilityRuleModel? initialRule;

  @override
  State<ScannerRuleFormDialog> createState() => _ScannerRuleFormDialogState();
}

class _ScannerRuleFormDialogState extends State<ScannerRuleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late int _dayOfWeek = widget.initialRule?.dayOfWeek ?? 0;
  late TimeOfDay _startTime =
      widget.initialRule?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _endTime =
      widget.initialRule?.endTime ?? const TimeOfDay(hour: 17, minute: 0);
  late bool _isActive = widget.initialRule?.isActive ?? true;

  late final _slotController = TextEditingController(
    text: '${widget.initialRule?.slotMinutes ?? 30}',
  );
  late final _gapController = TextEditingController(
    text: '${widget.initialRule?.gapMinutes ?? 0}',
  );
  late final _capacityController = TextEditingController(
    text: '${widget.initialRule?.capacity ?? 1}',
  );

  bool get _isEditing => widget.initialRule != null;

  @override
  void dispose() {
    _slotController.dispose();
    _gapController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  void _onSave() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Caught here rather than by the server: an inverted window is the easiest
    // mistake to make with two time pickers, and the API's message for it
    // would not point at which one is wrong.
    if (ApiTime.minutesOf(_endTime) <= ApiTime.minutesOf(_startTime)) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وقت النهاية يجب أن يكون بعد البداية')),
      );
      return;
    }

    Navigator.of(context).pop(
      SaveScannerAvailabilityRuleRequestModel(
        dayOfWeek: _dayOfWeek,
        startTime: _startTime,
        endTime: _endTime,
        slotMinutes: int.tryParse(_slotController.text.trim()) ?? 30,
        gapMinutes: int.tryParse(_gapController.text.trim()) ?? 0,
        capacity: int.tryParse(_capacityController.text.trim()) ?? 1,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل موعد أسبوعي' : 'إضافة موعد أسبوعي',
        style: AppTextStyles.font18MediumText,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Label('اليوم'),
              // Seven chips rather than a dropdown: the whole week fits, and
              // picking a day is one tap instead of three.
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (var day = 0; day < WeekDays.arabicLabels.length; day++)
                    ChoiceChip(
                      label: Text(WeekDays.labelOf(day)),
                      selected: _dayOfWeek == day,
                      onSelected: (_) => setState(() => _dayOfWeek = day),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const _Label('الدوام'),
              Row(
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'من',
                      value: _startTime,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TimeField(
                      label: 'إلى',
                      value: _endTime,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _Label('مدة الموعد (دقائق)'),
              AppTextFormField(
                controller: _slotController,
                hintText: 'مثال: 30',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.timer_outlined,
                  color: context.glass.onGlassMuted,
                ),
                validator: (value) =>
                    _validateInt(value, min: 5, max: 1440, requiredField: true),
              ),
              const SizedBox(height: 16),
              const _Label('الفاصل بين المواعيد (دقائق)'),
              AppTextFormField(
                controller: _gapController,
                hintText: 'مثال: 0',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                prefixIcon: Icon(
                  Icons.more_horiz_outlined,
                  color: context.glass.onGlassMuted,
                ),
                validator: (value) => _validateInt(value, min: 0, max: 1440),
              ),
              const SizedBox(height: 16),
              const _Label('عدد المواعيد بنفس الوقت'),
              AppTextFormField(
                controller: _capacityController,
                hintText: 'مثال: 1',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                prefixIcon: Icon(
                  Icons.groups_outlined,
                  color: context.glass.onGlassMuted,
                ),
                validator: (value) => _validateInt(value, min: 1, max: 100),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('مفعّل', style: AppTextStyles.font14MediumText),
                value: _isActive,
                activeThumbColor: Theme.of(context).colorScheme.primary,
                onChanged: (value) => setState(() => _isActive = value),
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
        TextButton(onPressed: _onSave, child: const Text('حفظ')),
      ],
    );
  }

  /// Mirrors the API's own bounds so an out-of-range value is caught here
  /// rather than coming back as a 400.
  String? _validateInt(
    String? value, {
    required int min,
    required int max,
    bool requiredField = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return requiredField ? 'الحقل مطلوب' : null;

    final parsed = int.tryParse(text);
    if (parsed == null) return 'الرجاء إدخال رقم صحيح';
    if (parsed < min || parsed > max) {
      return 'القيمة يجب أن تكون بين $min و $max';
    }
    return null;
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.glass),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: context.glass.surfaceGradient,
          borderRadius: BorderRadius.circular(AppRadius.glass),
          border: Border.all(color: context.glass.strokeColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              size: 18,
              color: context.glass.onGlassMuted,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$label ${ApiTime.displayTime(value)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font14MediumText.copyWith(
                  color: context.glass.onGlass,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(text, style: AppTextStyles.font14MediumText),
      ),
    );
  }
}

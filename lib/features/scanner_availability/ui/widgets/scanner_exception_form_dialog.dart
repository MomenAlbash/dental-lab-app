import 'package:dental_lab_app/core/helper/api_time_helper.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/save_scanner_availability_exception_request_model.dart';
import 'package:dental_lab_app/features/scanner_availability/data/models/scanner_availability_exception_model.dart';
import 'package:flutter/material.dart';

/// Add/edit a date override. Pops with the request body, or null if dismissed.
///
/// The API upserts by date, so editing is just saving the same date again —
/// there is no id in the payload.
class ScannerExceptionFormDialog extends StatefulWidget {
  const ScannerExceptionFormDialog({super.key, this.initialException});

  final ScannerAvailabilityExceptionModel? initialException;

  @override
  State<ScannerExceptionFormDialog> createState() =>
      _ScannerExceptionFormDialogState();
}

class _ScannerExceptionFormDialogState
    extends State<ScannerExceptionFormDialog> {
  late DateTime _date = widget.initialException?.date ?? _today;
  late bool _isClosed = widget.initialException?.isClosed ?? true;
  late TimeOfDay _startTime =
      widget.initialException?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
  late TimeOfDay _endTime =
      widget.initialException?.endTime ?? const TimeOfDay(hour: 17, minute: 0);

  late final _reasonController = TextEditingController(
    text: widget.initialException?.reason ?? '',
  );

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _isEditing => widget.initialException != null;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _date = picked);
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
    if (!_isClosed &&
        ApiTime.minutesOf(_endTime) <= ApiTime.minutesOf(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('وقت النهاية يجب أن يكون بعد البداية')),
      );
      return;
    }

    final reason = _reasonController.text.trim();

    Navigator.of(context).pop(
      SaveScannerAvailabilityExceptionRequestModel(
        date: _date,
        isClosed: _isClosed,
        startTime: _isClosed ? null : _startTime,
        endTime: _isClosed ? null : _endTime,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل استثناء' : 'إضافة استثناء',
        style: AppTextStyles.font18MediumText,
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Label('التاريخ'),
            _PickerField(
              icon: Icons.event_outlined,
              text:
                  '${ApiTime.formatDate(_date)} — ${WeekDays.labelOf(WeekDays.fromDateTime(_date))}',
              // Changing the date of an existing exception would upsert a
              // second day and orphan the first, so it is fixed while editing.
              onTap: _isEditing ? null : _pickDate,
            ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'لتغيير التاريخ، احذف الاستثناء وأضف واحداً جديداً',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: context.glass.onGlassMuted,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const _Label('النوع'),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('مغلق')),
                ButtonSegment(value: false, label: Text('دوام مختلف')),
              ],
              selected: {_isClosed},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  setState(() => _isClosed = selection.first),
            ),
            // Hours mean nothing on a closed day, so they come and go with the
            // choice instead of sitting there disabled.
            if (!_isClosed) ...[
              const SizedBox(height: 20),
              const _Label('الدوام'),
              Row(
                children: [
                  Expanded(
                    child: _PickerField(
                      icon: Icons.schedule_outlined,
                      text: 'من ${ApiTime.displayTime(_startTime)}',
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerField(
                      icon: Icons.schedule_outlined,
                      text: 'إلى ${ApiTime.displayTime(_endTime)}',
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            const _Label('السبب'),
            AppTextFormField(
              controller: _reasonController,
              hintText: _isClosed ? 'مثال: عطلة رسمية' : 'السبب (اختياري)',
              textInputAction: TextInputAction.done,
              prefixIcon: Icon(
                Icons.notes_outlined,
                color: context.glass.onGlassMuted,
              ),
              validator: (_) => null,
            ),
            const SizedBox(height: 6),
            Text(
              'يظهر للطبيب مكان الموعد',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: context.glass.onGlassMuted,
              ),
            ),
          ],
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
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final String text;

  /// Null renders the field as read-only.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final color = isEnabled
        ? context.glass.onGlass
        : context.glass.onGlassMuted;

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
            Icon(icon, size: 18, color: context.glass.onGlassMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.font14MediumText.copyWith(color: color),
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

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_movement_reason.dart';
import 'package:dental_lab_app/features/inventory/data/models/record_inventory_movement_request_model.dart';
import 'package:dental_lab_app/features/inventory/data/repos/inventory_repo.dart';
import 'package:flutter/material.dart';

/// One item's stock history — every purchase landing, consumption and
/// correction (`GET /Inventory/{id}/movements`) — plus, for someone who may
/// edit the module, a way to record a manual one.
Future<void> showInventoryMovementsSheet(
  BuildContext context, {
  required InventoryItemModel item,
}) {
  return showGlassBottomSheet<void>(
    context: context,
    builder: (_) => _InventoryMovementsSheet(item: item),
  );
}

class _InventoryMovementsSheet extends StatefulWidget {
  const _InventoryMovementsSheet({required this.item});

  final InventoryItemModel item;

  @override
  State<_InventoryMovementsSheet> createState() =>
      _InventoryMovementsSheetState();
}

class _InventoryMovementsSheetState extends State<_InventoryMovementsSheet> {
  List<InventoryMovementModel>? _movements;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<InventoryRepo>().getInventoryMovements(
      widget.item.id,
    );
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _error = failure.errorMessage;
        _movements = null;
      }),
      (movements) => setState(() {
        _movements = movements;
        _error = null;
      }),
    );
  }

  Future<void> _recordMovement() async {
    final body = await showDialog<RecordInventoryMovementRequestModel>(
      context: context,
      builder: (_) => const _RecordMovementDialog(),
    );
    if (body == null || !mounted) return;

    final result = await getIt<InventoryRepo>().recordInventoryMovement(
      id: widget.item.id,
      requestBody: body,
    );
    if (!mounted) return;

    result.fold(
      (failure) =>
          showToast(message: failure.errorMessage, state: ToastState.error),
      (_) {
        showToast(message: 'تم تسجيل الحركة', state: ToastState.success);
        _load();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.inventory,
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.name ?? '—',
                    style: AppTextStyles.font18MediumText.copyWith(
                      color: glass.onGlass,
                    ),
                  ),
                ),
                if (canEdit)
                  TextButton.icon(
                    onPressed: _recordMovement,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('تسجيل حركة'),
                  ),
              ],
            ),
            Text(
              '${widget.item.quantityOnHand.toStringAsFixed(2)} ${widget.item.unit ?? ''} بالمخزون حالياً',
              style: AppTextStyles.font12RegularHint.copyWith(
                color: glass.onGlassMuted,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_error != null)
              Text(
                _error!,
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.error,
                ),
              )
            else if (_movements == null)
              const Column(
                children: [
                  GlassSkeletonBox(height: 64),
                  SizedBox(height: AppSpacing.sm),
                  GlassSkeletonBox(height: 64),
                ],
              )
            else if (_movements!.isEmpty)
              Text(
                'لا توجد حركات مسجّلة بعد',
                style: AppTextStyles.font12RegularHint.copyWith(
                  color: glass.onGlassMuted,
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _movements!.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _MovementRow(movement: _movements![index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MovementRow extends StatelessWidget {
  const _MovementRow({required this.movement});

  final InventoryMovementModel movement;

  static String _date(DateTime? date) {
    if (date == null) return '؟';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isIncrease = movement.reason.isIncrease;
    final color = isIncrease ? glass.success : glass.error;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: glass.surfaceColor,
        border: Border.all(color: glass.strokeColor),
        borderRadius: BorderRadius.circular(AppRadius.glass),
      ),
      child: Row(
        children: [
          Icon(
            isIncrease
                ? Icons.arrow_circle_up_outlined
                : Icons.arrow_circle_down_outlined,
            color: color,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  movement.reason.arabicLabel,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                Text(
                  [
                    _date(movement.movementDate),
                    if (movement.createdByName?.isNotEmpty ?? false)
                      movement.createdByName!,
                  ].join(' · '),
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                if (movement.note?.trim().isNotEmpty ?? false)
                  Text(
                    movement.note!.trim(),
                    style: AppTextStyles.font12RegularHint.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${isIncrease ? '+' : '-'}${movement.quantity.toStringAsFixed(2)}',
            style: AppTextStyles.font14MediumText.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _RecordMovementDialog extends StatefulWidget {
  const _RecordMovementDialog();

  @override
  State<_RecordMovementDialog> createState() => _RecordMovementDialogState();
}

class _RecordMovementDialogState extends State<_RecordMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  InventoryMovementReason _reason = InventoryMovementReason.consumption;

  @override
  void dispose() {
    _quantityController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      RecordInventoryMovementRequestModel(
        quantity: double.parse(_quantityController.text.trim()),
        reason: _reason,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('تسجيل حركة مخزون', style: AppTextStyles.font18MediumText),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.85,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // The reason never offers "purchase" — a purchase records
                    // its own movement automatically.
                    for (final reason in InventoryMovementReason.manualReasons)
                      ChoiceChip(
                        label: Text(reason.arabicLabel),
                        selected: _reason == reason,
                        onSelected: (_) => setState(() => _reason = reason),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _quantityController,
                  hintText: 'الكمية',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icon(
                    Icons.numbers_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return 'الكمية مطلوبة';
                    final quantity = double.tryParse(trimmed);
                    if (quantity == null || quantity <= 0) {
                      return 'الرجاء إدخال رقم أكبر من صفر';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _noteController,
                  hintText: 'ملاحظة (اختياري)',
                  maxLines: 2,
                  prefixIcon: Icon(
                    Icons.notes_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (_) => null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('تسجيل')),
      ],
    );
  }
}

import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/auth/session.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/app_drawer_widget.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/inventory/data/models/inventory_item_model.dart';
import 'package:dental_lab_app/features/inventory/data/models/save_inventory_item_request_model.dart';
import 'package:dental_lab_app/features/inventory/logic/inventory/inventory_cubit.dart';
import 'package:dental_lab_app/features/inventory/logic/inventory/inventory_state.dart';
import 'package:dental_lab_app/features/inventory/ui/widgets/inventory_movements_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Inventory (`/api/clinic/Inventory`) — the lab's stocked materials
/// (زيركون, resin, ...) and how much of each is on hand.
///
/// Quantity is not editable here: it moves only through a movement — a
/// purchase landing, consumption logged against a case's material use, or a
/// manual correction — all reached from a row's own [InventoryMovementsSheet].
class InventoryListPage extends StatelessWidget {
  const InventoryListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<InventoryCubit>()..getInventoryItems(),
      child: const _InventoryListView(),
    );
  }
}

class _InventoryListView extends StatelessWidget {
  const _InventoryListView();

  Future<void> _openForm(
    BuildContext context, {
    InventoryItemModel? item,
  }) async {
    final cubit = context.read<InventoryCubit>();
    final result = await showDialog<SaveInventoryItemRequestModel>(
      context: context,
      builder: (_) => _InventoryItemFormDialog(initialItem: item),
    );
    if (result == null) return;

    if (item == null) {
      await cubit.addItem(result);
    } else {
      await cubit.editItem(id: item.id, requestBody: result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    InventoryItemModel item,
  ) async {
    if (!item.canDelete) {
      showToast(
        message: item.deleteMessage ?? 'لا يمكن حذف هذا الصنف',
        state: ToastState.error,
      );
      return;
    }

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف صنف',
      message: 'هل أنت متأكد من حذف "${item.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<InventoryCubit>().removeItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.inventory,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.inventoryListScreen),
      appBar: GlassAppBar(
        title: Text(
          'المخزون',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: !canEdit
          ? null
          : GlassAddButton(
              label: 'إضافة صنف',
              isExtended: true,
              onPressed: () => _openForm(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      body: SafeArea(
        child: BlocConsumer<InventoryCubit, InventoryState>(
          listenWhen: (previous, current) => current is InventoryActionError,
          listener: (context, state) {
            if (state case InventoryActionError(:final message)) {
              showToast(message: message, state: ToastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              InventoryLoaded(:final items) =>
                items.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<InventoryItemModel>(
                        items: items,
                        cardHeight: 104,
                        onRefresh: () =>
                            context.read<InventoryCubit>().getInventoryItems(),
                        itemBuilder: (context, item, _) => _InventoryListItem(
                          item: item,
                          onTap: () =>
                              showInventoryMovementsSheet(context, item: item),
                          onEdit: canEdit
                              ? () => _openForm(context, item: item)
                              : null,
                          onDelete: canEdit
                              ? () => _confirmDelete(context, item)
                              : null,
                        ),
                      ),
              InventoryError(:final message) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.font14RegularSecondary.copyWith(
                      color: glass.onGlassMuted,
                    ),
                  ),
                ),
              ),
              _ => const Center(child: CustomCircleProgressIndiacatorWidget()),
            };
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: glass.surfaceGradient,
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد أصناف بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول صنف بالضغط على زر الإضافة',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font14RegularSecondary.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.base)
        .scale(
          begin: const Offset(0.95, 0.95),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        );
  }
}

class _InventoryListItem extends StatelessWidget {
  const _InventoryListItem({
    required this.item,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final InventoryItemModel item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;
    final railColor = item.isLowStock
        ? glass.warning
        : (item.isActive ? accent : glass.onGlassMuted);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(color: glass.strokeColor),
            borderRadius: radius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 4, color: railColor),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: glass.brandGradient,
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.name ?? '—',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.font16MediumText
                                        .copyWith(color: glass.onGlass),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.quantityOnHand.toStringAsFixed(2)} ${item.unit ?? ''}',
                                    style: AppTextStyles.font13MediumPrimary
                                        .copyWith(
                                          color: item.isLowStock
                                              ? glass.warning
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                        ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _Badge(
                                        label: item.isActive
                                            ? 'مفعّل'
                                            : 'موقوف',
                                        color: item.isActive
                                            ? glass.success
                                            : glass.onGlassMuted,
                                      ),
                                      if (item.isLowStock)
                                        _Badge(
                                          label: 'مخزون منخفض',
                                          color: glass.warning,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (onEdit != null || onDelete != null) ...[
                              const SizedBox(width: AppSpacing.xs),
                              if (onEdit != null)
                                IconButton(
                                  tooltip: 'تعديل',
                                  onPressed: onEdit,
                                  icon: Icon(
                                    Icons.edit_outlined,
                                    color: glass.onGlassMuted,
                                  ),
                                ),
                              if (onDelete != null)
                                IconButton(
                                  tooltip: 'حذف',
                                  onPressed: onDelete,
                                  icon: Icon(
                                    Icons.delete_outline,
                                    color: glass.error,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.font12RegularHint.copyWith(color: color),
      ),
    );
  }
}

class _InventoryItemFormDialog extends StatefulWidget {
  const _InventoryItemFormDialog({this.initialItem});

  final InventoryItemModel? initialItem;

  @override
  State<_InventoryItemFormDialog> createState() =>
      _InventoryItemFormDialogState();
}

class _InventoryItemFormDialogState extends State<_InventoryItemFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialItem?.name ?? '',
  );
  late final _unitController = TextEditingController(
    text: widget.initialItem?.unit ?? '',
  );
  late final _thresholdController = TextEditingController(
    text: widget.initialItem?.lowStockThreshold?.toString() ?? '',
  );
  late bool _isActive = widget.initialItem?.isActive ?? true;

  bool get _isEditing => widget.initialItem != null;

  @override
  void dispose() {
    _nameController.dispose();
    _unitController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final threshold = _thresholdController.text.trim();
    Navigator.of(context).pop(
      SaveInventoryItemRequestModel(
        name: _nameController.text.trim(),
        unit: _unitController.text.trim(),
        lowStockThreshold: threshold.isEmpty
            ? null
            : double.tryParse(threshold),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل صنف' : 'إضافة صنف',
        style: AppTextStyles.font18MediumText,
      ),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width * 0.8,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  controller: _nameController,
                  hintText: 'اسم الصنف (مثال: زيركون)',
                  prefixIcon: Icon(
                    Icons.inventory_2_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اسم الصنف مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _unitController,
                  hintText: 'وحدة القياس (مثال: غرام، قطعة)',
                  prefixIcon: Icon(
                    Icons.straighten_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'وحدة القياس مطلوبة'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _thresholdController,
                  hintText: 'حد التنبيه للمخزون المنخفض (اختياري)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icon(
                    Icons.warning_amber_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    return double.tryParse(value.trim()) == null
                        ? 'الرجاء إدخال رقم صحيح'
                        : null;
                  },
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('مفعّل'),
                    value: _isActive,
                    onChanged: (value) => setState(() => _isActive = value),
                  ),
                ],
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
        TextButton(onPressed: _onConfirm, child: const Text('حفظ')),
      ],
    );
  }
}

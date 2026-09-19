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
import 'package:dental_lab_app/features/suppliers/data/models/save_supplier_request_model.dart';
import 'package:dental_lab_app/features/suppliers/data/models/supplier_model.dart';
import 'package:dental_lab_app/features/suppliers/logic/suppliers/suppliers_cubit.dart';
import 'package:dental_lab_app/features/suppliers/logic/suppliers/suppliers_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Suppliers (`/api/clinic/Suppliers`) — who the lab buys inventory from,
/// picked from a purchase's own form.
class SuppliersListPage extends StatelessWidget {
  const SuppliersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SuppliersCubit>()..getSuppliers(),
      child: const _SuppliersListView(),
    );
  }
}

class _SuppliersListView extends StatelessWidget {
  const _SuppliersListView();

  Future<void> _openForm(
    BuildContext context, {
    SupplierModel? supplier,
  }) async {
    final cubit = context.read<SuppliersCubit>();
    final result = await showDialog<SaveSupplierRequestModel>(
      context: context,
      builder: (_) => _SupplierFormDialog(initialSupplier: supplier),
    );
    if (result == null) return;

    if (supplier == null) {
      await cubit.addSupplier(result);
    } else {
      await cubit.editSupplier(id: supplier.id, requestBody: result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SupplierModel supplier,
  ) async {
    if (!supplier.canDelete) {
      showToast(
        message: supplier.deleteMessage ?? 'لا يمكن حذف هذا المورد',
        state: ToastState.error,
      );
      return;
    }

    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف مورد',
      message: 'هل أنت متأكد من حذف "${supplier.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<SuppliersCubit>().removeSupplier(supplier.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final canEdit = getIt<SessionCubit>().state.canEdit(
      PermissionName.suppliers,
    );

    return GlassScaffold(
      drawer: const AppDrawerWidget(currentRoute: Routes.suppliersListScreen),
      appBar: GlassAppBar(
        title: Text(
          'الموردون',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton: !canEdit
          ? null
          : GlassAddButton(
              label: 'إضافة مورد',
              isExtended: true,
              onPressed: () => _openForm(context),
            ).animate().scale(
              duration: AppMotion.base,
              curve: AppMotion.emphasized,
              begin: const Offset(0.6, 0.6),
            ),
      body: SafeArea(
        child: BlocConsumer<SuppliersCubit, SuppliersState>(
          listenWhen: (previous, current) => current is SuppliersActionError,
          listener: (context, state) {
            if (state case SuppliersActionError(:final message)) {
              showToast(message: message, state: ToastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              SuppliersLoaded(:final suppliers) =>
                suppliers.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<SupplierModel>(
                        items: suppliers,
                        cardHeight: 92,
                        onRefresh: () =>
                            context.read<SuppliersCubit>().getSuppliers(),
                        itemBuilder: (context, supplier, _) =>
                            _SupplierListItem(
                              supplier: supplier,
                              onEdit: canEdit
                                  ? () => _openForm(context, supplier: supplier)
                                  : null,
                              onDelete: canEdit
                                  ? () => _confirmDelete(context, supplier)
                                  : null,
                            ),
                      ),
              SuppliersError(:final message) => Center(
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
                    Icons.local_shipping_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا يوجد موردون بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'أضف أول مورد بالضغط على زر الإضافة',
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

class _SupplierListItem extends StatelessWidget {
  const _SupplierListItem({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  final SupplierModel supplier;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final railColor = supplier.isActive ? glass.success : glass.onGlassMuted;

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
                            Icons.local_shipping_outlined,
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
                                supplier.name ?? '—',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font16MediumText.copyWith(
                                  color: glass.onGlass,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                supplier.phone?.trim().isNotEmpty ?? false
                                    ? supplier.phone!
                                    : 'بلا رقم هاتف',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.font12RegularHint.copyWith(
                                  color: glass.onGlassMuted,
                                ),
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
    );
  }
}

class _SupplierFormDialog extends StatefulWidget {
  const _SupplierFormDialog({this.initialSupplier});

  final SupplierModel? initialSupplier;

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialSupplier?.name ?? '',
  );
  late final _phoneController = TextEditingController(
    text: widget.initialSupplier?.phone ?? '',
  );
  late final _notesController = TextEditingController(
    text: widget.initialSupplier?.notes ?? '',
  );
  late bool _isActive = widget.initialSupplier?.isActive ?? true;

  bool get _isEditing => widget.initialSupplier != null;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      SaveSupplierRequestModel(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isEditing ? 'تعديل مورد' : 'إضافة مورد',
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
                  hintText: 'اسم المورد',
                  prefixIcon: Icon(
                    Icons.local_shipping_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'اسم المورد مطلوب'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _phoneController,
                  hintText: 'رقم الهاتف (اختياري)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icon(
                    Icons.phone_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (_) => null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _notesController,
                  hintText: 'ملاحظات (اختياري)',
                  maxLines: 2,
                  prefixIcon: Icon(
                    Icons.notes_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (_) => null,
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

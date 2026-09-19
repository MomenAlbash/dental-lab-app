import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_collection.dart';
import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_add_button.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/case_ticket_templates/data/models/case_ticket_template_list_item_model.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_templates/case_ticket_templates_cubit.dart';
import 'package:dental_lab_app/features/case_ticket_templates/logic/case_ticket_templates/case_ticket_templates_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// طباعة الحالة — the lab's library of thermal-ticket layouts
/// (`GET /CaseTicketTemplates`). Renaming/reordering rows lives in each
/// template's own editor; this screen only picks, creates, deletes, or sets
/// the default.
class CaseTicketTemplatesListPage extends StatelessWidget {
  const CaseTicketTemplatesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CaseTicketTemplatesCubit>()..getTemplates(),
      child: const _CaseTicketTemplatesListView(),
    );
  }
}

class _CaseTicketTemplatesListView extends StatelessWidget {
  const _CaseTicketTemplatesListView();

  Future<void> _openEditor(BuildContext context, String id) async {
    final changed = await context.push<bool>(
      Routes.caseTicketTemplateEditorScreen,
      extra: id,
    );
    if (changed == true && context.mounted) {
      context.read<CaseTicketTemplatesCubit>().getTemplates();
    }
  }

  Future<void> _addTemplate(BuildContext context) async {
    final cubit = context.read<CaseTicketTemplatesCubit>();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _NewTemplateDialog(),
    );
    if (name == null || name.trim().isEmpty) return;

    final created = await cubit.addTemplate(name.trim());
    if (created != null && context.mounted) {
      await _openEditor(context, created.id);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CaseTicketTemplateListItemModel template,
  ) async {
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: 'حذف قالب',
      message: 'هل أنت متأكد من حذف "${template.name}"؟',
      confirmText: 'حذف',
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      await context.read<CaseTicketTemplatesCubit>().removeTemplate(
        template.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;

    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          'قوالب طباعة الحالة',
          style: AppTextStyles.font18MediumText.copyWith(color: glass.onGlass),
        ),
      ),
      floatingActionButton:
          GlassAddButton(
            label: 'قالب جديد',
            isExtended: true,
            onPressed: () => _addTemplate(context),
          ).animate().scale(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            begin: const Offset(0.6, 0.6),
          ),
      body: SafeArea(
        child: BlocConsumer<CaseTicketTemplatesCubit, CaseTicketTemplatesState>(
          listenWhen: (previous, current) =>
              current is CaseTicketTemplatesActionError,
          listener: (context, state) {
            if (state case CaseTicketTemplatesActionError(:final message)) {
              showToast(message: message, state: ToastState.error);
            }
          },
          builder: (context, state) {
            return switch (state) {
              CaseTicketTemplatesLoaded(:final templates) =>
                templates.isEmpty
                    ? const _EmptyState()
                    : AdaptiveCollection<CaseTicketTemplateListItemModel>(
                        items: templates,
                        cardHeight: 92,
                        onRefresh: () => context
                            .read<CaseTicketTemplatesCubit>()
                            .getTemplates(),
                        itemBuilder: (context, template, _) =>
                            _TemplateListItem(
                              template: template,
                              onTap: () => _openEditor(context, template.id),
                              onSetDefault: template.isDefault
                                  ? null
                                  : () => context
                                        .read<CaseTicketTemplatesCubit>()
                                        .setDefault(template.id),
                              onDelete: () => _confirmDelete(context, template),
                            ),
                      ),
              CaseTicketTemplatesError(:final message) => Center(
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
                    Icons.receipt_outlined,
                    size: 40,
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'لا توجد قوالب بعد',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.font16MediumText.copyWith(
                    color: glass.onGlass,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'حتى بدون قالب محفوظ، طباعة الحالة تستخدم تصميماً افتراضياً',
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

class _TemplateListItem extends StatelessWidget {
  const _TemplateListItem({
    required this.template,
    required this.onTap,
    required this.onSetDefault,
    required this.onDelete,
  });

  final CaseTicketTemplateListItemModel template;
  final VoidCallback onTap;

  /// Null when this template already is the default — nothing to set.
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final radius = BorderRadius.circular(AppRadius.glass);
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(borderRadius: radius, boxShadow: glass.shadows),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: glass.surfaceGradient,
            border: Border.all(
              color: template.isDefault ? accent : glass.strokeColor,
              width: template.isDefault ? 1.5 : 1,
            ),
            borderRadius: radius,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
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
                        Icons.receipt_outlined,
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  template.name ?? '—',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.font16MediumText
                                      .copyWith(color: glass.onGlass),
                                ),
                              ),
                              if (template.isDefault) ...[
                                const SizedBox(width: AppSpacing.sm),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.full,
                                    ),
                                  ),
                                  child: Text(
                                    'الافتراضي',
                                    style: AppTextStyles.font12RegularHint
                                        .copyWith(color: accent),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'عرض الورق ${template.paperWidthMm.toStringAsFixed(0)}mm',
                            style: AppTextStyles.font12RegularHint.copyWith(
                              color: glass.onGlassMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onSetDefault != null)
                      IconButton(
                        tooltip: 'تعيين كافتراضي',
                        onPressed: onSetDefault,
                        icon: Icon(
                          Icons.star_outline,
                          color: glass.onGlassMuted,
                        ),
                      ),
                    IconButton(
                      tooltip: 'حذف',
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, color: glass.error),
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

class _NewTemplateDialog extends StatefulWidget {
  const _NewTemplateDialog();

  @override
  State<_NewTemplateDialog> createState() => _NewTemplateDialogState();
}

class _NewTemplateDialogState extends State<_NewTemplateDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('قالب جديد', style: AppTextStyles.font18MediumText),
      content: Form(
        key: _formKey,
        child: AppTextFormField(
          controller: _nameController,
          hintText: 'اسم القالب (مثال: طابعة الاستقبال)',
          prefixIcon: Icon(
            Icons.receipt_outlined,
            color: context.glass.onGlassMuted,
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'اسم القالب مطلوب'
              : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(onPressed: _onConfirm, child: const Text('إنشاء')),
      ],
    );
  }
}

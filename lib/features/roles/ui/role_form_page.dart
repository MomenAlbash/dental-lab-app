import 'package:dental_lab_app/core/auth/permissions.dart';
import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/adaptive_layout.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_skeleton.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/roles/data/models/create_role_request_model.dart';
import 'package:dental_lab_app/features/roles/data/models/role_model.dart';
import 'package:dental_lab_app/features/roles/data/models/update_role_request_model.dart';
import 'package:dental_lab_app/features/roles/logic/role_form/role_form_cubit.dart';
import 'package:dental_lab_app/features/roles/logic/role_form/role_form_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Add/edit role screen — `PermissionName` values with no [PermissionName.label]
/// are modules this app has no screen for yet, and are left out of the
/// checklist entirely rather than offered as a permission nobody here can
/// act on.
class RoleFormPage extends StatelessWidget {
  const RoleFormPage({super.key, this.initialRole});

  final RoleModel? initialRole;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RoleFormCubit>()..loadPermissionCatalog(),
      child: _RoleFormView(initialRole: initialRole),
    );
  }
}

class _RoleFormView extends StatefulWidget {
  const _RoleFormView({this.initialRole});

  final RoleModel? initialRole;

  @override
  State<_RoleFormView> createState() => _RoleFormViewState();
}

class _RoleFormViewState extends State<_RoleFormView> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialRole?.name ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialRole?.description ?? '',
  );

  late final Map<PermissionName, PermissionType?> _selected = {
    for (final p in widget.initialRole?.permissions ?? const <RolePermission>[])
      p.name: p.type,
  };

  bool get _isEditing => widget.initialRole != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<RoleFormCubit>();
    final permissions = [
      for (final entry in _selected.entries)
        if (entry.value != null)
          RolePermission(name: entry.key, type: entry.value!),
    ];

    if (_isEditing) {
      cubit.updateRole(
        id: widget.initialRole!.id,
        updateRequestBody: UpdateRoleRequestModel(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        ),
        permissions: permissions,
      );
    } else {
      cubit.createRole(
        CreateRoleRequestModel(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          permissions: permissions,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: GlassAppBar(
        title: Text(
          _isEditing ? 'تعديل الدور' : 'إضافة دور',
          style: AppTextStyles.font18MediumText.copyWith(
            color: context.glass.onGlass,
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<RoleFormCubit, RoleFormState>(
          listener: (context, state) {
            switch (state) {
              case RoleFormSuccess(:final role):
                showToast(
                  message: _isEditing ? 'تم حفظ التعديلات' : 'تمت إضافة الدور',
                  state: ToastState.success,
                );
                // The role itself, not just a bool — the user-form's
                // "quick add role" dropdown selects it straight off this.
                Navigator.of(context).pop(role);
              case RoleFormError(:final message):
                showToast(message: message, state: ToastState.error);
              case RoleFormCatalogError(:final message):
                showToast(message: message, state: ToastState.error);
              default:
                break;
            }
          },
          builder: (context, state) {
            final catalog = switch (state) {
              RoleFormCatalogLoaded(:final catalog) => catalog,
              RoleFormSubmitting() ||
              RoleFormSuccess() ||
              RoleFormError() => _lastCatalog,
              _ => null,
            };
            if (catalog != null) _lastCatalog = catalog;

            if (catalog == null) {
              return state is RoleFormCatalogError
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          state.message,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.font14RegularSecondary.copyWith(
                            color: context.glass.onGlassMuted,
                          ),
                        ),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.all(24),
                      child: GlassListSkeleton(),
                    );
            }

            final isSubmitting = state is RoleFormSubmitting;

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide =
                    AdaptiveLayout.formFactorFor(constraints.maxWidth) !=
                    AdaptiveFormFactor.mobile;
                final contentWidth = isWide ? 560.0 : constraints.maxWidth;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 32 : 20,
                      vertical: 20,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentWidth),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'اسم الدور',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _nameController,
                              hintText: 'أدخل اسم الدور',
                              textInputAction: TextInputAction.next,
                              enabled: !isSubmitting,
                              prefixIcon: Icon(
                                Icons.badge_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'اسم الدور مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'الوصف',
                              style: AppTextStyles.font14MediumText,
                            ),
                            const SizedBox(height: 8),
                            AppTextFormField(
                              controller: _descriptionController,
                              hintText: 'أدخل وصف الدور (اختياري)',
                              textInputAction: TextInputAction.done,
                              enabled: !isSubmitting,
                              prefixIcon: Icon(
                                Icons.notes_outlined,
                                color: context.glass.onGlassMuted,
                              ),
                              validator: (_) => null,
                            ),
                            const SizedBox(height: 24),
                            const GlassSectionTitle('الصلاحيات'),
                            const SizedBox(height: 4),
                            Text(
                              'فعّل الصلاحية وحدد نوعها',
                              style: AppTextStyles.font12RegularHint.copyWith(
                                color: context.glass.onGlassMuted,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (final name in catalog)
                              if (name.label != null)
                                _PermissionRow(
                                  name: name,
                                  selected: _selected[name],
                                  enabled: !isSubmitting,
                                  onChanged: (type) =>
                                      setState(() => _selected[name] = type),
                                ),
                            const SizedBox(height: 24),
                            if (isSubmitting)
                              const Center(
                                child: CustomCircleProgressIndiacatorWidget(),
                              )
                            else
                              CustomButtonWidget(
                                onPressed: _onSavePressed,
                                buttonText: _isEditing
                                    ? 'حفظ التعديلات'
                                    : 'إضافة الدور',
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// The catalog only ever arrives once; kept so a later Submitting/Success/
  /// Error state does not blank the checklist mid-save.
  List<PermissionName>? _lastCatalog;
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.name,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final PermissionName name;
  final PermissionType? selected;
  final bool enabled;
  final ValueChanged<PermissionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final isEnabled = selected != null;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: glass.surfaceGradient,
        borderRadius: BorderRadius.circular(AppRadius.glass),
        border: Border.all(color: glass.strokeColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(name.label!, style: AppTextStyles.font14MediumText),
          ),
          if (isEnabled)
            SegmentedButton<PermissionType>(
              segments: const [
                ButtonSegment(value: PermissionType.read, label: Text('قراءة')),
                ButtonSegment(
                  value: PermissionType.fullAccess,
                  label: Text('كامل'),
                ),
              ],
              selected: {selected!},
              onSelectionChanged: enabled
                  ? (selection) => onChanged(selection.first)
                  : null,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          Switch(
            value: isEnabled,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: enabled
                ? (value) => onChanged(value ? PermissionType.read : null)
                : null,
          ),
        ],
      ),
    );
  }
}

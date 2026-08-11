import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_app_bar.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_scaffold.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_section_title.dart';
import 'package:flutter/material.dart';

/// The API's permission enums (`PermissionName` 1..9, `PermissionType` 0..1)
/// aren't documented with string labels yet, so they're shown by number
/// until the backend publishes names.
const List<int> _permissionNames = [1, 2, 3, 4, 5, 6, 7, 8, 9];
const List<int> _permissionTypes = [0, 1];

/// Add/edit role screen — design only for now (no Cubit / API wiring yet).
/// Pass [initialRole] (a map with `name`/`description`) to open in edit mode.
class RoleFormPage extends StatefulWidget {
  const RoleFormPage({super.key, this.initialRole});

  final Map<String, dynamic>? initialRole;

  @override
  State<RoleFormPage> createState() => _RoleFormPageState();
}

class _RoleFormPageState extends State<RoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(
    text: widget.initialRole?['name'] as String? ?? '',
  );
  late final _descriptionController = TextEditingController(
    text: widget.initialRole?['description'] as String? ?? '',
  );

  // permissionName -> selected permissionType (or null if not granted).
  final Map<int, int?> _permissions = {
    for (final name in _permissionNames) name: null,
  };

  bool get _isEditing => widget.initialRole != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSavePressed() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط حفظ الدور بالـ API لاحقاً')),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
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
                        Text('الوصف', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _descriptionController,
                          hintText: 'أدخل وصف الدور (اختياري)',
                          textInputAction: TextInputAction.done,
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
                        ..._permissionNames.map(_buildPermissionRow),
                        const SizedBox(height: 24),
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
        ),
      ),
    );
  }

  Widget _buildPermissionRow(int permissionName) {
    final selectedType = _permissions[permissionName];
    final isEnabled = selectedType != null;

    final glass = context.glass;

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
            child: Text(
              'صلاحية رقم $permissionName',
              style: AppTextStyles.font14MediumText,
            ),
          ),
          if (isEnabled)
            SegmentedButton<int>(
              segments: _permissionTypes
                  .map(
                    (type) =>
                        ButtonSegment(value: type, label: Text('نوع $type')),
                  )
                  .toList(),
              selected: {selectedType},
              onSelectionChanged: (selection) {
                setState(() => _permissions[permissionName] = selection.first);
              },
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
            ),
          Switch(
            value: isEnabled,
            activeThumbColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              setState(
                () => _permissions[permissionName] = value
                    ? _permissionTypes.first
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/helper/network_helper/media_url.dart';
import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/glass/glass_bottom_sheet.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/laboratories/data/models/footer_contact_model.dart';
import 'package:dental_lab_app/features/laboratories/data/models/laboratory_model.dart';
import 'package:dental_lab_app/features/laboratories/logic/printed_identity/printed_identity_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// What the laboratory looks like on paper: its logo, and the contact lines
/// printed at the foot of reports and invoices.
///
/// Returns true when anything was saved, so the caller can refetch.
Future<bool?> showPrintedIdentitySheet(
  BuildContext context, {
  required LaboratoryModel laboratory,
}) {
  return showGlassBottomSheet<bool>(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<PrintedIdentityCubit>(),
      child: _PrintedIdentitySheet(laboratory: laboratory),
    ),
  );
}

class _PrintedIdentitySheet extends StatefulWidget {
  const _PrintedIdentitySheet({required this.laboratory});

  final LaboratoryModel laboratory;

  @override
  State<_PrintedIdentitySheet> createState() => _PrintedIdentitySheetState();
}

/// One editable row. Held as controllers rather than plain strings so the
/// fields keep focus and cursor position while the list is being edited.
class _ContactRow {
  _ContactRow({this.id, String name = '', String phone = ''})
    : nameController = TextEditingController(text: name),
      phoneController = TextEditingController(text: phone);

  /// Null on a row the user just added — the server creates it.
  final String? id;
  final TextEditingController nameController;
  final TextEditingController phoneController;

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
  }
}

class _PrintedIdentitySheetState extends State<_PrintedIdentitySheet> {
  late final List<_ContactRow> _rows = [
    for (final contact in widget.laboratory.footerContacts)
      _ContactRow(
        id: contact.id,
        name: contact.name ?? '',
        phone: contact.phoneNumber ?? '',
      ),
  ];

  /// Set by any successful write, and handed back on close so the caller
  /// refetches once rather than after each individual save.
  bool _changed = false;

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  Future<void> _pickLogo(BuildContext context) async {
    final cubit = context.read<PrintedIdentityCubit>();

    final result = await FilePicker.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path == null) return;

    await cubit.uploadLogo(laboratoryId: widget.laboratory.id, filePath: path);
  }

  void _save(BuildContext context) {
    // Blank rows are dropped rather than rejected: an empty row the user left
    // behind is them changing their mind, not an error to scold them for.
    final contacts = [
      for (final row in _rows)
        if (row.nameController.text.trim().isNotEmpty ||
            row.phoneController.text.trim().isNotEmpty)
          SaveFooterContactModel(
            id: row.id,
            name: row.nameController.text.trim(),
            phoneNumber: row.phoneController.text.trim(),
          ),
    ];

    context.read<PrintedIdentityCubit>().saveContacts(
      laboratoryId: widget.laboratory.id,
      contacts: contacts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final logoUrl = resolveMediaUrl(widget.laboratory.logoPath);

    return BlocConsumer<PrintedIdentityCubit, PrintedIdentityState>(
      listener: (context, state) {
        switch (state) {
          case PrintedIdentitySuccess(:final message):
            _changed = true;
            showToast(message: message, state: ToastState.success);
          case PrintedIdentityError(:final message):
            showToast(message: message, state: ToastState.error);
          default:
            break;
        }
      },
      builder: (context, state) {
        final isBusy = state is PrintedIdentityBusy;

        return Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'الهوية المطبوعة',
                        style: AppTextStyles.font16MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(_changed),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  'ما يظهر على التقارير والفواتير المطبوعة',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: glass.surfaceGradient,
                        borderRadius: BorderRadius.circular(AppRadius.glass),
                        border: Border.all(color: glass.strokeColor),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: logoUrl == null
                          ? Icon(
                              Icons.business_outlined,
                              color: glass.onGlassMuted,
                            )
                          : Image.network(
                              logoUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => Icon(
                                Icons.broken_image_outlined,
                                color: glass.onGlassMuted,
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          TextButton.icon(
                            onPressed: isBusy ? null : () => _pickLogo(context),
                            icon: const Icon(Icons.image_outlined, size: 16),
                            label: const Text('تغيير الشعار'),
                          ),
                          if (widget.laboratory.logoPath != null)
                            TextButton.icon(
                              onPressed: isBusy
                                  ? null
                                  : () => context
                                        .read<PrintedIdentityCubit>()
                                        .deleteLogo(widget.laboratory.id),
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('حذف'),
                              style: TextButton.styleFrom(
                                foregroundColor: glass.error,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'أرقام التذييل',
                        style: AppTextStyles.font14MediumText.copyWith(
                          color: glass.onGlass,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'إضافة رقم',
                      onPressed: () => setState(() => _rows.add(_ContactRow())),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                Text(
                  // Said out loud because the order is what gets printed,
                  // and it is not obvious from a list of text fields.
                  'تُطبع بالترتيب الظاهر هنا',
                  style: AppTextStyles.font12RegularHint.copyWith(
                    color: glass.onGlassMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                if (_rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Text(
                      'لا توجد أرقام — لن يُطبع تذييل',
                      style: AppTextStyles.font12RegularHint.copyWith(
                        color: glass.onGlassMuted,
                      ),
                    ),
                  ),

                for (var index = 0; index < _rows.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: AppTextFormField(
                            controller: _rows[index].nameController,
                            hintText: 'الاسم',
                            validator: (_) => null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 3,
                          child: AppTextFormField(
                            controller: _rows[index].phoneController,
                            hintText: 'الرقم',
                            keyboardType: TextInputType.phone,
                            validator: (_) => null,
                          ),
                        ),
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () => setState(() {
                            _rows.removeAt(index).dispose();
                          }),
                          icon: Icon(
                            Icons.remove_circle_outline,
                            color: glass.error,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: AppSpacing.md),
                CustomButtonWidget(
                  buttonText: 'حفظ الأرقام',
                  onPressed: isBusy ? null : () => _save(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/auth/logic/change_password/change_password_cubit.dart';
import 'package:dental_lab_app/features/auth/logic/change_password/change_password_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the change-password dialog (`POST /ClinicAuth/change-password`).
Future<void> showChangePasswordDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (_) => BlocProvider(
      create: (_) => getIt<ChangePasswordCubit>(),
      child: const ChangePasswordDialog(),
    ),
  );
}

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    context.read<ChangePasswordCubit>().changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
      listener: (context, state) {
        switch (state) {
          case ChangePasswordSuccess():
            ShowToast(
              message: 'تم تغيير كلمة المرور',
              state: toastState.success,
            );
            Navigator.of(context).pop();
          case ChangePasswordError(:final message):
            ShowToast(message: message, state: toastState.error);
          default:
            break;
        }
      },
      builder: (context, state) {
        final isSubmitting = state is ChangePasswordSubmitting;

        return AlertDialog(
          title: Text(
            'تغيير كلمة المرور',
            style: AppTextStyles.font18MediumText,
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextFormField(
                  controller: _currentPasswordController,
                  hintText: 'كلمة المرور الحالية',
                  isObscureText: true,
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'كلمة المرور الحالية مطلوبة'
                      : null,
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _newPasswordController,
                  hintText: 'كلمة المرور الجديدة',
                  isObscureText: true,
                  prefixIcon: Icon(
                    Icons.lock_reset_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty)
                      return 'كلمة المرور الجديدة مطلوبة';
                    if (value.length < 4) return 'يجب أن تكون 4 أحرف على الأقل';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextFormField(
                  controller: _confirmPasswordController,
                  hintText: 'تأكيد كلمة المرور الجديدة',
                  isObscureText: true,
                  prefixIcon: Icon(
                    Icons.lock_reset_outlined,
                    color: context.glass.onGlassMuted,
                  ),
                  validator: (value) => value != _newPasswordController.text
                      ? 'كلمتا المرور غير متطابقتين'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            TextButton(
              onPressed: isSubmitting ? null : _onConfirm,
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ'),
            ),
          ],
        );
      },
    );
  }
}

import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

class LoginInputSection extends StatelessWidget {
  const LoginInputSection({
    super.key,
    required this.userNameController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.onTogglePasswordVisibility,
  });

  final TextEditingController userNameController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final VoidCallback onTogglePasswordVisibility;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('اسم المستخدم', style: AppTextStyles.font14MediumText),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: userNameController,
          hintText: 'أدخل اسم المستخدم',
          textInputAction: TextInputAction.next,
          prefixIcon: const Icon(
            Icons.person_outline,
            color: AppColorsManger.textSecondary,
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'اسم المستخدم مطلوب'
              : null,
        ),
        const SizedBox(height: 20),
        Text('كلمة المرور', style: AppTextStyles.font14MediumText),
        const SizedBox(height: 8),
        AppTextFormField(
          controller: passwordController,
          hintText: 'أدخل كلمة المرور',
          textInputAction: TextInputAction.done,
          isObscureText: !isPasswordVisible,
          prefixIcon: const Icon(
            Icons.lock_outline,
            color: AppColorsManger.textSecondary,
          ),
          suffixIcon: IconButton(
            onPressed: onTogglePasswordVisibility,
            icon: Icon(
              isPasswordVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColorsManger.textSecondary,
            ),
          ),
          validator: (value) =>
              (value == null || value.isEmpty) ? 'كلمة المرور مطلوبة' : null,
        ),
      ],
    );
  }
}

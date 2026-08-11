import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_circle_progress_indiacator_widget.dart';
import 'package:dental_lab_app/features/auth/data/models/login_request_model.dart';
import 'package:dental_lab_app/features/auth/logic/login/login_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginActionsSection extends StatelessWidget {
  const LoginActionsSection({
    super.key,
    required this.formKey,
    required this.isLoading,
    required this.userNameController,
    required this.passwordController,
    required this.onValidationFailed,
  });

  final GlobalKey<FormState> formKey;
  final bool isLoading;
  final TextEditingController userNameController;
  final TextEditingController passwordController;
  final VoidCallback onValidationFailed;

  void _onLoginPressed(BuildContext context) {
    if (formKey.currentState?.validate() ?? false) {
      context.read<LoginCubit>().login(
        LoginRequestModel(
          username: userNameController.text.trim(),
          password: passwordController.text,
        ),
      );
    } else {
      onValidationFailed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton(
            onPressed: () {},
            child: Text(
              'نسيت كلمة المرور؟',
              style: AppTextStyles.font13MediumPrimary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: CustomCircleProgressIndiacatorWidget())
        else
          CustomButtonWidget(
            onPressed: () => _onLoginPressed(context),
            buttonText: 'تسجيل الدخول',
          ),
      ],
    );
  }
}

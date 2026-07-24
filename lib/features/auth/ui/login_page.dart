import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:dental_lab_app/core/widgets/custom_button_widget.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:flutter/material.dart';

/// Login screen — design only for now (no Cubit / API wiring yet).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    // Design-only phase: just run client-side validation.
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سيتم ربط تسجيل الدخول لاحقاً')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Cap content width on tablets/foldables (~600dp+), full width on
            // phones. Vertical padding scales with available height.
            final isWide = constraints.maxWidth >= 600;
            final contentWidth = isWide ? 460.0 : constraints.maxWidth;

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 32 : 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentWidth),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _LoginHeader(),
                        const SizedBox(height: 40),
                        Text('اسم المستخدم', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _usernameController,
                          hintText: 'أدخل اسم المستخدم',
                          textInputAction: TextInputAction.next,
                          prefixIcon: const Icon(Icons.person_outline,
                              color: AppColorsManger.textSecondary),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                                  ? 'اسم المستخدم مطلوب'
                                  : null,
                        ),
                        const SizedBox(height: 20),
                        Text('كلمة المرور', style: AppTextStyles.font14MediumText),
                        const SizedBox(height: 8),
                        AppTextFormField(
                          controller: _passwordController,
                          hintText: 'أدخل كلمة المرور',
                          textInputAction: TextInputAction.done,
                          isObscureText: _obscurePassword,
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: AppColorsManger.textSecondary),
                          suffixIcon: IconButton(
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColorsManger.textSecondary,
                            ),
                          ),
                          validator: (value) =>
                              (value == null || value.isEmpty)
                                  ? 'كلمة المرور مطلوبة'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () {},
                            child: Text('نسيت كلمة المرور؟',
                                style: AppTextStyles.font13MediumPrimary),
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButtonWidget(
                          onPressed: _onLoginPressed,
                          buttonText: 'تسجيل الدخول',
                          textColor: Colors.white,
                          backgroundColor: AppColorsManger.primary,
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
}

class _LoginHeader extends StatelessWidget {
  const _LoginHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(
            color: AppColorsManger.primarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.medical_services_outlined,
            size: 44,
            color: AppColorsManger.primary,
          ),
        ),
        const SizedBox(height: 20),
        Text('مرحباً بك', style: AppTextStyles.font24BoldText),
        const SizedBox(height: 6),
        Text(
          'سجّل الدخول للمتابعة إلى مخبر الأسنان',
          textAlign: TextAlign.center,
          style: AppTextStyles.font14RegularSecondary,
        ),
      ],
    );
  }
}

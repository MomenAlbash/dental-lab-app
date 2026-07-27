import 'package:dental_lab_app/core/router/routes.dart';
import 'package:dental_lab_app/core/widgets/show_toast_widget.dart';
import 'package:dental_lab_app/features/auth/logic/login/login_cubit.dart';
import 'package:dental_lab_app/features/auth/logic/login/login_state.dart';
import 'package:dental_lab_app/features/auth/ui/widgets/login_actions_section.dart';
import 'package:dental_lab_app/features/auth/ui/widgets/login_header_section.dart';
import 'package:dental_lab_app/features/auth/ui/widgets/login_input_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginBody extends StatefulWidget {
  const LoginBody({super.key});

  @override
  State<LoginBody> createState() => _LoginBodyState();
}

class _LoginBodyState extends State<LoginBody> {
  late TextEditingController userNameController;
  late TextEditingController passwordController;
  late GlobalKey<FormState> formKey;
  late AutovalidateMode autovalidateMode;

  /// Local UI state only — never business logic (CLAUDE.md §B.1).
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    userNameController = TextEditingController();
    passwordController = TextEditingController();
    formKey = GlobalKey<FormState>();
    autovalidateMode = AutovalidateMode.disabled;
  }

  @override
  void dispose() {
    userNameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state is LoginSuccess) {
          ShowToast(
            message: 'تم تسجيل الدخول بنجاح',
            state: toastState.success,
          );
          GoRouter.of(context).go(Routes.laboratorySelectionScreen);
        }
        if (state is LoginError) {
          ShowToast(message: state.message, state: toastState.error);
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Cap content width on tablets/foldables (~600dp+), full width
              // on phones.
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
                      key: formKey,
                      autovalidateMode: autovalidateMode,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LoginHeaderSection(),
                          const SizedBox(height: 40),
                          LoginInputSection(
                            userNameController: userNameController,
                            passwordController: passwordController,
                            isPasswordVisible: isPasswordVisible,
                            onTogglePasswordVisibility: () => setState(
                              () => isPasswordVisible = !isPasswordVisible,
                            ),
                          ),
                          LoginActionsSection(
                            formKey: formKey,
                            isLoading: isLoading,
                            userNameController: userNameController,
                            passwordController: passwordController,
                            onValidationFailed: () => setState(
                              () => autovalidateMode = AutovalidateMode.always,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

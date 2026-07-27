import 'package:dental_lab_app/core/di/dependency_injection.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/features/auth/logic/login/login_cubit.dart';
import 'package:dental_lab_app/features/auth/ui/widgets/login_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginCubit>(),
      child: const Scaffold(
        backgroundColor: AppColorsManger.background,
        body: LoginBody(),
      ),
    );
  }
}

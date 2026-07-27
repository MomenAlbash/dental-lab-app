import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

class LoginHeaderSection extends StatelessWidget {
  const LoginHeaderSection({super.key});

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

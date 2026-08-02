import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:flutter/material.dart';

class AppTextFormField extends StatelessWidget {
  const AppTextFormField({
    super.key,
    this.contentPadding,
    required this.validator,
    this.textField,
    this.controller,
    this.enableBorder,
    this.focusBorder,
    this.inputTextStyle,
    this.hintStyle,
    required this.hintText,
    this.isObscureText,
    this.suffixIcon,
    this.prefixIcon,
    this.textInputAction,
    this.filColor,
  });
  final EdgeInsets? contentPadding;
  final InputBorder? enableBorder;
  final InputBorder? focusBorder;
  final TextStyle? inputTextStyle;
  final TextStyle? hintStyle;
  final String hintText;
  final bool? isObscureText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final TextInputAction? textInputAction;
  final Color? filColor;
  final TextEditingController? controller;
  final Function(String?) validator;
  final String? textField;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textField != null
            ? Text(textField!, textAlign: TextAlign.end)
            : SizedBox.shrink(),
        SizedBox(height: 2),
        TextFormField(
          controller: controller,
          textAlign: TextAlign.start,
          textInputAction: textInputAction,
          validator: (value) => validator(value),
          decoration: InputDecoration(
            isDense: true,

            contentPadding:
                contentPadding ??
                EdgeInsets.symmetric(horizontal: 20, vertical: 18),

            focusedBorder:
                focusBorder ?? borderType(color: AppColorsManger.mainBlue),
            enabledBorder:
                enableBorder ?? borderType(color: AppColorsManger.lighterGray),
            errorBorder: borderType(color: AppColorsManger.error),
            focusedErrorBorder: borderType(color: AppColorsManger.error),
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: filColor ?? AppColorsManger.moreLightGray,
          ),
          obscureText: isObscureText ?? false,
        ),
      ],
    );
  }

  OutlineInputBorder borderType({required Color color}) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: 1.3),
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
  }
}

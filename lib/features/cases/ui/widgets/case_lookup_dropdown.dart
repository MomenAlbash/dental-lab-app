import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';

/// Full-width, boxed dropdown used across the case form. Null [items] renders
/// a disabled field (while the lookup is loading).
class CaseLookupDropdown extends StatelessWidget {
  const CaseLookupDropdown({
    super.key,
    required this.value,
    required this.icon,
    required this.hintText,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final IconData icon;
  final String hintText;
  final List<DropdownMenuItem<String>>? items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: AppColorsManger.textSecondary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColorsManger.moreLightGray,
        prefixIcon: Icon(icon, color: AppColorsManger.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hintText, style: AppTextStyles.font14RegularSecondary),
      items: items ?? const [],
      onChanged: items == null ? null : onChanged,
    );
  }
}

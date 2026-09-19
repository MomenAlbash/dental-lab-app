import 'dart:async';

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/widgets/custom_text_field_widget.dart';
import 'package:dental_lab_app/features/cases/logic/cases/cases_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Finds a case by its number.
///
/// On the list screen rather than inside the filter sheet: looking up "C26-104"
/// is the most common thing anyone does here, and burying it two taps deep
/// behind a sheet meant for narrowing a browse would make the quick job the
/// slow one.
class CaseSearchField extends StatefulWidget {
  const CaseSearchField({super.key});

  @override
  State<CaseSearchField> createState() => _CaseSearchFieldState();
}

class _CaseSearchFieldState extends State<CaseSearchField> {
  late final TextEditingController _controller;
  Timer? _debounce;

  /// Long enough that typing a case number is one request rather than eight,
  /// short enough that the list feels like it is following along.
  static const _debounceDelay = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    // Seeded from the cubit so the box and the list it filters never disagree
    // after a rebuild.
    _controller = TextEditingController(
      text: context.read<CasesCubit>().search ?? '',
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      context.read<CasesCubit>().setSearch(value);
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    context.read<CasesCubit>().setSearch('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final hasText = _controller.text.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: AppTextFormField(
        controller: _controller,
        hintText: 'ابحث برقم الحالة — مثال: C26',
        textInputAction: TextInputAction.search,
        prefixIcon: Icon(Icons.search, color: glass.onGlassMuted),
        suffixIcon: hasText
            ? IconButton(
                tooltip: 'مسح',
                onPressed: _clear,
                icon: Icon(Icons.close, color: glass.onGlassMuted),
              )
            : null,
        onChanged: (value) {
          // Rebuild for the clear button; the request itself is debounced.
          setState(() {});
          _onChanged(value);
        },
        validator: (_) => null,
      ),
    );
  }
}

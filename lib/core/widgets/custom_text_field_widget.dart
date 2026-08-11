import 'dart:math' as math;

import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/app_motion.dart';
import 'package:dental_lab_app/core/theming/colors.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:dental_lab_app/core/theming/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The app's single text input.
///
/// Glass styled and animated: the pane picks up an accent glow on focus, the
/// label and prefix icon tint with it, and a failed validation shakes the field
/// once so the error registers without being read.
///
/// The public parameter list is intentionally unchanged (including the
/// misspelled `filColor` and the `enableBorder` / `focusBorder` overrides) —
/// this widget is used across every feature and renaming would break ~15 call
/// sites for no user-visible gain. New parameters are all optional.
class AppTextFormField extends StatefulWidget {
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
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.maxLines,
    this.enabled = true,
    this.focusNode,
    this.obscureToggle = false,
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

  /// Optional label rendered above the field; tints toward the accent on focus.
  final String? textField;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final bool enabled;

  /// Supply one to drive focus externally; otherwise an internal node is used.
  final FocusNode? focusNode;

  /// Adds a show/hide eye button. Only meaningful with [isObscureText].
  final bool obscureToggle;

  @override
  State<AppTextFormField> createState() => _AppTextFormFieldState();
}

class _AppTextFormFieldState extends State<AppTextFormField>
    with SingleTickerProviderStateMixin {
  /// Owned only when the caller did not supply one, so we never dispose a node
  /// belonging to the parent.
  FocusNode? _internalFocusNode;
  bool _focused = false;
  bool _obscured = false;

  /// Drives the error shake. This is a controller we own rather than a keyed
  /// `Animate` wrapper: re-keying a wrapper rebuilds the subtree, which would
  /// destroy the `FormField` state and wipe the very error being announced.
  late final AnimationController _shakeController;

  String? _lastError;

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscured = widget.isObscureText ?? false;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant AppTextFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChanged);
      _focusNode.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _internalFocusNode?.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  /// Wraps the caller's validator so we can react to a newly-raised error.
  /// The result is produced during a build pass, so the shake is scheduled for
  /// the next frame rather than calling setState mid-build.
  String? _runValidator(String? value) {
    final error = widget.validator(value) as String?;
    if (error != _lastError) {
      _lastError = error;
      if (error != null) {
        // Runs during a build pass, so the shake starts on the next frame.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _shakeController.forward(from: 0);
        });
      }
    }
    return error;
  }

  /// Damped horizontal oscillation: three full swings that decay to rest.
  double _shakeOffset(double t) {
    if (t == 0 || t == 1) return 0;
    return math.sin(t * math.pi * 6) * 6 * (1 - t);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final accent = Theme.of(context).colorScheme.primary;
    final radius = BorderRadius.circular(AppRadius.glass);

    Widget field = AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: glass.glowColor,
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : glass.shadows,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        textAlign: TextAlign.start,
        textInputAction: widget.textInputAction,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onChanged: widget.onChanged,
        maxLines: _obscured ? 1 : (widget.maxLines ?? 1),
        style:
            widget.inputTextStyle ??
            AppTextStyles.font14MediumText.copyWith(color: glass.onGlass),
        validator: _runValidator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              widget.contentPadding ??
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          focusedBorder:
              widget.focusBorder ??
              _border(color: accent, width: 1.6, radius: radius),
          enabledBorder:
              widget.enableBorder ??
              _border(color: glass.strokeColor, radius: radius),
          disabledBorder: _border(
            color: glass.strokeColor.withValues(alpha: 0.4),
            radius: radius,
          ),
          errorBorder: _border(color: AppColorsManger.error, radius: radius),
          focusedErrorBorder: _border(
            color: AppColorsManger.error,
            width: 1.6,
            radius: radius,
          ),
          hintText: widget.hintText,
          hintStyle:
              widget.hintStyle ??
              AppTextStyles.font14RegularSecondary.copyWith(
                color: glass.onGlassMuted,
              ),
          // Null when absent so the field does not reserve prefix space.
          prefixIcon: widget.prefixIcon == null
              ? null
              : _AnimatedFieldIcon(
                  focused: _focused,
                  accent: accent,
                  idleColor: glass.onGlassMuted,
                  child: widget.prefixIcon!,
                ),
          suffixIcon: _buildSuffix(glass.onGlassMuted),
          filled: true,
          fillColor: widget.filColor ?? glass.fillColor,
        ),
        obscureText: _obscured,
      ),
    );

    // `child` is passed through untouched so the TextFormField keeps its
    // element identity — only the transform above it animates.
    field = AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeOffset(_shakeController.value), 0),
        child: child,
      ),
      child: field,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.textField != null) ...[
          AnimatedDefaultTextStyle(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            style: AppTextStyles.font13MediumPrimary.copyWith(
              color: _focused ? accent : glass.onGlassMuted,
            ),
            child: Text(widget.textField!),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        field,
      ],
    );
  }

  Widget? _buildSuffix(Color idleColor) {
    if (widget.obscureToggle && (widget.isObscureText ?? false)) {
      return IconButton(
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: idleColor,
        ),
      );
    }
    return widget.suffixIcon;
  }

  static OutlineInputBorder _border({
    required Color color,
    required BorderRadius radius,
    double width = 1.2,
  }) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color, width: width),
      borderRadius: radius,
    );
  }
}

/// Tints the prefix icon toward the accent color while the field has focus.
class _AnimatedFieldIcon extends StatelessWidget {
  const _AnimatedFieldIcon({
    required this.focused,
    required this.accent,
    required this.idleColor,
    required this.child,
  });

  final bool focused;
  final Color accent;
  final Color idleColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Color?>(
      duration: AppMotion.fast,
      curve: AppMotion.enter,
      tween: ColorTween(end: focused ? accent : idleColor),
      builder: (context, color, iconChild) => IconTheme.merge(
        data: IconThemeData(color: color),
        child: iconChild!,
      ),
      child: child,
    );
  }
}

import 'package:dental_lab_app/core/widgets/confirm_dialog_widget.dart';
import 'package:flutter/material.dart';

/// Whether [controller] holds something other than what it started with.
///
/// `null` and `''` are the same "not set" to the API, so they must be the same
/// here too: a field seeded from `null` and left blank is clean. Comparing the
/// trimmed text also means typing a letter and deleting it — or typing only
/// spaces — leaves the form clean.
bool isTextDirty(TextEditingController controller, [String? initial]) =>
    controller.text.trim() != (initial?.trim() ?? '');

/// Intercepts back navigation (the app bar's back button and the Android
/// system back gesture) while a form holds unsaved edits, and asks before
/// throwing them away.
///
/// [isDirty] is a callback rather than a bool because form state lives in
/// `TextEditingController`s that never rebuild this widget — a `canPop`
/// computed during `build` would be stale by the time back is pressed. So
/// `canPop` stays `false` and the decision is made inside
/// `onPopInvokedWithResult`, which runs at the moment of the pop attempt.
///
/// Programmatic pops (`Navigator.of(context).pop(result)`, e.g. a page's save
/// success path) are *not* blocked by `canPop: false` — only `maybePop`
/// consults it — so they arrive here with `didPop == true` and are ignored.
class UnsavedChangesGuard extends StatefulWidget {
  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
    this.title = 'تجاهل التعديلات؟',
    this.message = 'لديك تعديلات غير محفوظة، وإذا خرجت الآن ستفقدها.',
    this.confirmText = 'خروج بدون حفظ',
    this.cancelText = 'متابعة التعديل',
  });

  final ValueGetter<bool> isDirty;
  final Widget child;
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;

  @override
  State<UnsavedChangesGuard> createState() => _UnsavedChangesGuardState();
}

class _UnsavedChangesGuardState extends State<UnsavedChangesGuard> {
  /// Guards against a second back press while the confirm dialog is open —
  /// without it the two async paths stack two identical dialogs.
  bool _isAsking = false;

  Future<void> _onPopInvoked(bool didPop, Object? result) async {
    // The route is already going — this was a programmatic pop, or the one we
    // performed ourselves below.
    if (didPop || _isAsking) return;

    // Captured before the await: using `context` across an async gap is not
    // allowed, and the navigator is what we actually need afterwards.
    final navigator = Navigator.of(context);

    if (!widget.isDirty()) {
      navigator.pop(result);
      return;
    }

    // The keyboard would otherwise sit over the dialog on a short screen.
    FocusManager.instance.primaryFocus?.unfocus();

    _isAsking = true;
    final confirmed = await ConfirmDialogWidget.show(
      context,
      title: widget.title,
      message: widget.message,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
      isDestructive: true,
    );
    _isAsking = false;

    if (confirmed == true && mounted) navigator.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: widget.child,
    );
  }
}

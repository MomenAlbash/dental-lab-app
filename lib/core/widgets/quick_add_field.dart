import 'package:dental_lab_app/core/theming/app_dimensions.dart';
import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';

/// A picker field with a "+" button pinned beside it.
///
/// Every form in the app links records that may not exist yet — a patient
/// needs a doctor, a doctor needs a clinic, a user needs an employee/doctor
/// and a role. Sending the user to the other feature's list to create the
/// missing record loses the half-filled form, so the add screen is opened on
/// top instead and the result is fed straight back into [onAdded].
///
/// [onAdd] must return the newly created record (or null if the user backed
/// out). Screens whose add form doesn't hand its record back yet can return
/// null and only refresh their list.
class QuickAddField<T> extends StatelessWidget {
  const QuickAddField({
    super.key,
    required this.field,
    required this.onAdd,
    required this.onAdded,
    required this.tooltip,
    this.onDismissed,
  });

  /// The picker itself — usually a dropdown.
  final Widget field;

  /// Opens the add screen and resolves with whatever it popped.
  final Future<T?> Function() onAdd;

  /// Called with the created record so the caller can refresh its list and
  /// select the new value. Not called when [onAdd] resolves to null.
  final void Function(T created) onAdded;

  /// Called when [onAdd] resolves to null — the user backed out, or the add
  /// screen doesn't hand its record back yet. Pickers whose add screen can't
  /// return a record use this to at least reload the list.
  final VoidCallback? onDismissed;

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    // Matches the height of the surrounding boxed dropdowns, and grows with
    // the user's text setting the same way they do.
    final side = MediaQuery.textScalerOf(context).scale(52).clamp(52.0, 76.0);

    return Row(
      // Top-aligned: a validator error under the field must not push the
      // button off the field's row.
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: field),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          height: side,
          width: side,
          child: Tooltip(
            message: tooltip,
            child: Material(
              color: glass.fillColor,
              borderRadius: BorderRadius.circular(AppRadius.glass),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.glass),
                onTap: () async {
                  final created = await onAdd();
                  if (created != null) {
                    onAdded(created);
                  } else {
                    onDismissed?.call();
                  }
                },
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.glass),
                    border: Border.all(color: glass.strokeColor),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                    semanticLabel: tooltip,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

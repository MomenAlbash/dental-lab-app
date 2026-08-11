import 'package:dental_lab_app/core/theming/glass.dart';
import 'package:flutter/material.dart';

/// Resolves the API's `badgeVariant` strings (case priorities carry one, and
/// so do workflow stages) into a themed colour. The server sends bootstrap-
/// style names; anything unknown — or missing — falls back to the neutral
/// info tint rather than throwing, since the variant is presentation-only.
Color badgeVariantColor(BuildContext context, String? variant) {
  final glass = context.glass;
  return switch (variant?.trim().toLowerCase()) {
    'success' || 'green' => glass.success,
    'warning' || 'orange' || 'yellow' => glass.warning,
    'danger' || 'error' || 'red' => glass.error,
    'secondary' ||
    'muted' ||
    'light' ||
    'dark' ||
    'gray' ||
    'grey' => glass.onGlassMuted,
    'primary' => Theme.of(context).colorScheme.primary,
    _ => glass.info,
  };
}

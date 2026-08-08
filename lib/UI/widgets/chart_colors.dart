import 'package:flutter/material.dart';

/// High-contrast colors for data series on the app's chart surfaces.
abstract final class ChartColors {
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color primary(BuildContext context) =>
      _isDark(context) ? const Color(0xFF72C7FF) : const Color(0xFF0067B9);

  static Color grid(BuildContext context) => Theme.of(
    context,
  ).colorScheme.onSurface.withValues(alpha: _isDark(context) ? 0.24 : 0.18);
}

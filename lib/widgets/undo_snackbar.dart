import 'package:flutter/material.dart';

/// Shared "message + Undo action" pattern for destructive actions across the
/// app. `ScaffoldMessenger`'s `SnackBar` already handles auto-dismiss timing
/// and stacking, so this is mostly a thin wrapper for a consistent contract.
///
/// Rapid-fire actions (e.g. triaging many notes back to back) each replace
/// the previous snackbar and restart its timer, which can make the bar look
/// like it never closes. To bound that, we cap how long any one continuous
/// streak of snackbars can occupy the screen.
const _maxStreakDuration = Duration(seconds: 20);

DateTime? _streakStart;

void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required Future<void> Function() onUndo,
  Duration duration = const Duration(seconds: 6),
}) {
  final now = DateTime.now();
  if (_streakStart == null || now.difference(_streakStart!) >= _maxStreakDuration) {
    _streakStart = now;
  }
  final remaining = _maxStreakDuration - now.difference(_streakStart!);
  final effectiveDuration = duration < remaining ? duration : remaining;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: effectiveDuration,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        action: SnackBarAction(label: 'Undo', onPressed: () => onUndo()),
      ),
    );
}

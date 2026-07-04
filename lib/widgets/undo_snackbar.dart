import 'package:flutter/material.dart';

/// Shared "message + Undo action" pattern for destructive actions across the
/// app. `ScaffoldMessenger`'s `SnackBar` already handles auto-dismiss timing
/// and stacking, so this is just a thin wrapper for a consistent contract.
void showUndoSnackBar(
  BuildContext context, {
  required String message,
  required Future<void> Function() onUndo,
  Duration duration = const Duration(seconds: 6),
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: SnackBarAction(label: 'Undo', onPressed: () => onUndo()),
      ),
    );
}

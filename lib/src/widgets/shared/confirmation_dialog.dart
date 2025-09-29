import 'package:flutter/material.dart';

Future<bool?> showConfirmationDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required String confirmButtonText,
  required VoidCallback onConfirm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: <Widget>[
          TextButton(
            child: const Text('取消'),
            onPressed: () {
              Navigator.of(context).pop(false); // Indicates action was cancelled
            },
          ),
          ElevatedButton(
            child: Text(confirmButtonText),
            onPressed: () {
              Navigator.of(context).pop(true); // Indicates action was confirmed
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      );
    },
  );
}

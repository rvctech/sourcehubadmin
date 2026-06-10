import 'package:flutter/material.dart';

Future<void> showConfirmDeleteDialog({
  required BuildContext context,
  required String title,
  required String message,
  required Future<void> Function() onDelete,
}) {
  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await onDelete();
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

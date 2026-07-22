import 'package:file_manager/features/browser/presentation/providers/browser_provider.dart';
import 'package:file_manager/models/file_item.dart';
import 'package:flutter/material.dart';

void showRenameDialog(
  BuildContext context,
  FileItem item,
  BrowserNotifier notifier,
) {
  final controller = TextEditingController(text: item.name);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty && controller.text != item.name) {
                notifier.renameItem(item, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

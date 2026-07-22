import 'package:flutter/material.dart';

class EmptyFolderState extends StatelessWidget {
  const EmptyFolderState({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 72,
              color: colors.outline,
            ),

            const SizedBox(height: 20),

            Text(
              "No folders yet",
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            Text(
              "Create your first folder to organize your files.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.create_new_folder),
              label: const Text("New Folder"),
            )
          ],
        ),
      ),
    );
  }
}
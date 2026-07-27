import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/features/browser/presentation/providers/browser_provider.dart';
import 'package:file_manager/features/browser/presentation/widgets/file_item_container.dart';

class FoldersPage extends ConsumerWidget {
  final String path;
  const FoldersPage({super.key, this.path = ''});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(browserProviderFor(path));
    final notifier = ref.read(browserProviderFor(path).notifier);

    if (state.isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: ${state.error}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (state.error!.toLowerCase().contains('permission'))
                  ElevatedButton(
                    onPressed: () => notifier.openAppSettings(),
                    child: const Text('Open Settings'),
                  )
                else
                  ElevatedButton(
                    onPressed: () => notifier.refresh(),
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.items.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: Text('Directory is empty')),
      );
    }

    if (state.isGridView) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = state.items[index];
              return FileItemContainer(
                item: item,
                currentPath: state.currentPath,
                isGrid: true,
              );
            },
            childCount: state.items.length,
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = state.items[index];
            return FileItemContainer(
              item: item,
              currentPath: state.currentPath,
              isGrid: false,
            );
          },
          childCount: state.items.length,
        ),
      ),
    );
  }
}
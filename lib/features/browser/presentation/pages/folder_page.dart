import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:file_manager/features/browser/dialogs/create_folder_dialog.dart';
import 'package:file_manager/features/browser/presentation/providers/browser_provider.dart';
import 'package:file_manager/features/browser/presentation/widgets/breadcrumbs_bar.dart';
import 'package:file_manager/features/browser/presentation/widgets/file_item_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FolderPage extends ConsumerStatefulWidget {
  final String path;
  final String? title;

  const FolderPage({
    super.key,
    required this.path,
    this.title,
  });

  @override
  ConsumerState<FolderPage> createState() => _FolderPageState();
}

class _FolderPageState extends ConsumerState<FolderPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(browserProviderFor(widget.path).notifier).loadStorageAndDirectory();
    });
  }

  String _getFolderName() {
    if (widget.title != null && widget.title!.isNotEmpty) {
      return widget.title!;
    }
    if (widget.path.isEmpty) return 'Storage';
    final parts = widget.path.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'Storage';
    return parts.last;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browserProviderFor(widget.path));
    final notifier = ref.read(browserProviderFor(widget.path).notifier);
    final folderName = _getFolderName();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          folderName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              EvaIcons.grid,
              color: state.isGridView
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            onPressed: () => notifier.setGridView(true),
          ),
          IconButton(
            icon: Icon(
              EvaIcons.list,
              color: !state.isGridView
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
            onPressed: () => notifier.setGridView(false),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () => showCreateFolderDialog(context, notifier),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BreadcrumbsBar(
            currentPath: state.currentPath.isEmpty ? widget.path : state.currentPath,
          ),
          Expanded(
            child: _buildBody(context, state, notifier),
          ),
        ],
      ),
      // bottomNavigationBar: Container(
      //   height: 50,
      //   margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      //   decoration: BoxDecoration(
      //     borderRadius: BorderRadius.circular(16.0),
      //     color: Theme.of(context).colorScheme.surface,
      //     border: Border.all(
      //       color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
      //       width: 1,
      //     ),
      //   ),
      //   child: BreadcrumbsBar(
      //     currentPath: state.currentPath.isEmpty ? widget.path : state.currentPath,
      //   ),
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateFolderDialog(context, notifier),
        backgroundColor: const Color(0xFF5C6BC0),
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BrowserState state, BrowserNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
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
      );
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Text(
          'Folder is empty',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    if (state.isGridView) {
      return RefreshIndicator(
        onRefresh: () => notifier.refresh(),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];
            return FileItemContainer(
              item: item,
              currentPath: state.currentPath,
              isGrid: true,
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        itemCount: state.items.length,
        itemBuilder: (context, index) {
          final item = state.items[index];
          return FileItemContainer(
            item: item,
            currentPath: state.currentPath,
            isGrid: false,
          );
        },
      ),
    );
  }
}
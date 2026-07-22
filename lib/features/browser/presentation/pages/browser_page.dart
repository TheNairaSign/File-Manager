import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:file_manager/features/browser/dialogs/create_folder_dialog.dart';
import 'package:file_manager/features/browser/presentation/widgets/file_item_container.dart';
import 'package:file_manager/features/browser/media_category.dart';
import 'package:file_manager/features/browser/presentation/widgets/media_card.dart';
import 'package:file_manager/widgets/browse_search_bar.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_manager/features/browser/presentation/providers/browser_provider.dart';
import 'package:file_manager/core/platform/permission/permission_service.dart';
import 'package:file_manager/core/platform/permission/permission_state.dart';

class BrowserPage extends ConsumerStatefulWidget {
  final String path;
  const BrowserPage({super.key, this.path = ''});

  @override
  ConsumerState<BrowserPage> createState() => _BrowserPageState();
}

class _BrowserPageState extends ConsumerState<BrowserPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handlePermissionFlow(context);
    });
  }

  Future<void> handlePermissionFlow(BuildContext context) async {
    final notifier = ref.read(browserProviderFor(widget.path).notifier);

    // 1. First, check if we even need to ask
    final checkResult = await PermissionService.checkPermissionStatus();

    await checkResult.fold(
      (error) async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to check permissions: ${error.message}")),
        );
      },
      (check) async {
        if (check.status == StoragePermissionStatus.granted) {
          // Proceed to your File Manager dashboard
          print("All good! API Level: ${check.apiLevel}");
          await notifier.loadStorageAndDirectory();
          return;
        }

        // 2. If denied but needs rationale (e.g., they denied it once before)
        if (check.needsRationale) {
          // Show a custom Flutter SnackBar or Dialog explaining WHY you need it
          // before triggering the system prompt again.
          if (!context.mounted) return;
          final proceed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Storage Permission Required"),
              content: const Text(
                "We need storage permission to list and manage files in your directories. "
                "Without this, the app cannot function properly."
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Continue"),
                ),
              ],
            ),
          );

          if (proceed != true) {
            return;
          }
        }

        // 3. Request the permission (this triggers the Java side)
        final request = await PermissionService.requestPermission();

        if (request.granted) {
          // Proceed to File Manager dashboard
          print("Permission granted!");
          await notifier.loadStorageAndDirectory();
        } else if (request.permanentlyDenied) {
          // 4. They ticked "Don't ask again". We MUST redirect them to settings.
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Storage Permission Required"),
              content: const Text("You have permanently denied storage access. Please enable it in Settings to use the File Manager."),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    PermissionService.openAppSettings();
                  },
                  child: const Text("Open Settings"),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(browserProviderFor(widget.path));
    final notifier = ref.read(browserProviderFor(widget.path).notifier);

    return Scaffold(
      body: Column(
        children: [
          // Custom Header
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.backgroundColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 48,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              children: [
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Row(
                //       children: [
                //         if (Navigator.canPop(context))
                //           IconButton(
                //             icon: const Icon(Icons.arrow_back),
                //             onPressed: () => Navigator.maybePop(context),
                //           ),
                //         Text(
                //           widget.path.isEmpty
                //               ? 'File Explorer'
                //               : (widget.path.split('/').where((p) => p.isNotEmpty).isNotEmpty
                //                   ? widget.path.split('/').where((p) => p.isNotEmpty).last
                //                   : 'File Explorer'),
                //           style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                //             fontSize: 22,
                //             fontWeight: FontWeight.bold,
                //           ),
                //         ),
                //       ],
                //     ),
                //     // const CircleAvatar(
                //     //   child: Icon(Icons.person),
                //     // ),
                //   ],
                // ),
                const SizedBox(height: 16),
                // Search Bar
               BrowseSearchBar(
                path: widget.path,
                controller: _searchController,
                onSubmitted: (query) {
                  notifier.search(query);
                },
                hintText: 'Search files in ${widget.path}',
               ),
                const SizedBox(height: 16),
                // Tabs and View Toggle
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            'Internal',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Text(
                            'External',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
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
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Body Content
          Expanded(
            child: _buildBody(context, state, notifier),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateFolderDialog(context, notifier),
        backgroundColor: const Color(0xFF5C6BC0),
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BrowserState state, BrowserNotifier notifier) {
    return CustomScrollView(
      slivers: [
        // Media Categories Section
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Media Categories',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.3,
                  children: MediaTypeItemType.values.map((type) {
                    return MediaCard(
                      mediaType: type,
                      title: type.name,
                      asset: type.svgAsset,
                      color: type.color,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
                Text(
                  'Files & Folders',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),

        // Files & Folders Directory Content
        if (state.isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          SliverFillRemaining(
            child: Center(
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
            ),
          )
        else if (state.items.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('Directory is empty')),
          )
        else if (state.isGridView)
          SliverPadding(
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
          )
        else
          SliverPadding(
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
          ),
      ],
    );
  }
}
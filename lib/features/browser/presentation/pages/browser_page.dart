import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:file_manager/features/browser/dialogs/create_folder_dialog.dart';
import 'package:file_manager/features/browser/media_category.dart';
import 'package:file_manager/features/browser/presentation/widgets/media_card.dart';
import 'package:file_manager/features/browser/presentation/widgets/storage_volume_card.dart';
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
  String? _selectedVolumePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      handlePermissionFlow(context);
    });
  }

  Future<void> handlePermissionFlow(BuildContext context) async {
    final activePath = _selectedVolumePath ?? widget.path;
    final notifier = ref.read(browserProviderFor(activePath).notifier);

    // 1. First, check permission status
    final checkResult = await PermissionService.checkPermissionStatus();

    await checkResult.fold(
      (error) async {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to check permissions: ${error.message}")),
        );
      },
      (check) async {
        if (check.status == StoragePermissionStatus.granted) {
          ref.invalidate(storageVolumesProvider);
          await notifier.loadStorageAndDirectory();
          return;
        }

        // 2. Rationale dialog if denied once before
        if (check.needsRationale) {
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

          if (proceed != true) return;
        }

        // 3. Request permission
        final request = await PermissionService.requestPermission();

        if (request.granted) {
          ref.invalidate(storageVolumesProvider);
          await notifier.loadStorageAndDirectory();
        } else if (request.permanentlyDenied) {
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Text("Storage Permission Required"),
              content: const Text(
                "You have permanently denied storage access. Please enable it in Settings to use the File Manager."
              ),
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
    final volumesAsync = ref.watch(storageVolumesProvider);
    final volumes = volumesAsync.value ?? [];

    final activePath = _selectedVolumePath ??
        (volumes.isNotEmpty ? volumes.first.path : widget.path);

    final state = ref.watch(browserProviderFor(activePath));
    final notifier = ref.read(browserProviderFor(activePath).notifier);

    return Scaffold(
      body: Column(
        children: [
          // Header
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
                const SizedBox(height: 16),
                BrowseSearchBar(
                  path: activePath,
                  controller: _searchController,
                  onSubmitted: (query) {
                    notifier.search(query);
                  },
                  hintText: 'Search files in ${activePath.isEmpty ? "Storage" : (activePath.split('/').where((p) => p.isNotEmpty).isNotEmpty ? activePath.split('/').where((p) => p.isNotEmpty).last : "Storage")}',
                ),
              ],
            ),
          ),

          // Main Scrollable View
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Storage Locations Section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Locations',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        volumesAsync.when(
                          data: (vList) {
                            if (vList.isEmpty) {
                              return const SizedBox.shrink();
                            }
                             return SizedBox(
                              height: 80,
                              child: Row(
                                mainAxisAlignment: .spaceBetween,
                                children: List.generate(vList.length, (index) {
                                  final vol = vList[index];
                                  final isSel = vol.path == activePath || (_selectedVolumePath == null && index == 0);
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: StorageVolumeCard(
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      volume: vol,
                                      isSelected: isSel,
                                      onTap: () {
                                        setState(() {
                                          _selectedVolumePath = vol.path;
                                        });
                                        ref
                                            .read(browserProviderFor(vol.path).notifier)
                                            .loadStorageAndDirectory();
                                      },
                                    ),
                                  );
                                },
                              ),
                            )
                             );
                          },
                          loading: () => const SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (err, stack) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),

                // Media Categories Section
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Media Categories',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        GridView.count(
                          padding: EdgeInsets.zero,
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
                      ],
                    ),
                  )
                ),

                // Files & Folders Directory Content
                // FoldersPage(path: activePath),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCreateFolderDialog(context, notifier),
        child: const Icon(Icons.create_new_folder),
      ),
    );
  }
}
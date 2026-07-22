import 'package:file_manager/core/helpers/byte_converter.dart';
import 'package:file_manager/core/helpers/format_date.dart';
import 'package:file_manager/features/browser/dialogs/delete_dialog.dart';
import 'package:file_manager/features/browser/dialogs/rename_dialog.dart';
import 'package:file_manager/features/browser/presentation/providers/browser_provider.dart';
import 'package:file_manager/models/file_item.dart';
import 'package:file_manager/widgets/media_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:file_manager/features/browser/presentation/pages/folder_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FileItemContainer extends ConsumerStatefulWidget {
  const FileItemContainer({
    super.key,
    required this.item,
    required this.currentPath,
    this.isGrid = false,
  });

  final FileItem item;
  final String currentPath;
  final bool isGrid;

  @override
  ConsumerState<FileItemContainer> createState() => _FileItemContainerState();
}

class _FileItemContainerState extends ConsumerState<FileItemContainer> {
  bool tapped = false;

  void _onTap() {
    if (widget.item.isDirectory) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FolderPage(path: widget.item.path),
          settings: RouteSettings(name: widget.item.path),
        ),
      );
    } else {
      // Open/preview non-directory file
    }
  }

  void _onMenuSelected(String value, BrowserNotifier notifier) {
    if (value == 'delete') {
      showDeleteDialog(context, widget.item, notifier);
    } else if (value == 'rename') {
      showRenameDialog(context, widget.item, notifier);
    } else if (value == 'copy') {
      notifier.copyItem(widget.item);
    } else if (value == 'move') {
      notifier.moveItem(widget.item);
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems() {
    return const [
      PopupMenuItem(value: 'copy', child: Text('Copy')),
      PopupMenuItem(value: 'move', child: Text('Move')),
      PopupMenuItem(value: 'rename', child: Text('Rename')),
      PopupMenuItem(
        value: 'delete',
        child: Text('Delete', style: TextStyle(color: Colors.red)),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(browserProviderFor(widget.currentPath).notifier);

    if (widget.isGrid) {
      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: _onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      alignment: Alignment.center,
                      child: widget.item.isDirectory
                          ? SvgPicture.asset(
                              'assets/svgs/folder-black.svg',
                              height: 28,
                              width: 28,
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).colorScheme.onSurface,
                                BlendMode.srcIn,
                              ),
                            )
                          : MediaIcon.fromItem(widget.item, size: 28),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onSelected: (val) => _onMenuSelected(val, notifier),
                      itemBuilder: (context) => _buildMenuItems(),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.item.isDirectory
                          ? 'Folder'
                          : formatBytes(widget.item.size),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.item.isDirectory
              ? SvgPicture.asset(
                  'assets/svgs/folder-black.svg',
                  height: 20,
                  width: 20,
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onSurface,
                    BlendMode.srcIn,
                  ),
                )
              : MediaIcon.fromItem(widget.item, size: 32),
        ),
        title: Text(
          widget.item.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
        ),
        subtitle: Text(
          '${formatBytes(widget.item.size)} • ${formatDate(widget.item.lastModified)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _onMenuSelected(value, notifier),
          itemBuilder: (context) => _buildMenuItems(),
        ),
        onTap: _onTap,
      ),
    );
  }

 Color _folderColor(FileItem item) {
    // Map folder names to colors similar to design
    Color folderColor = Colors.amber;
    if (item.name.toLowerCase().contains('photo')) {
      folderColor = Colors.blue;
    } else if (item.name.toLowerCase().contains('music')) {
      folderColor = Colors.green;
    } else if (item.name.toLowerCase().contains('video')) {
      folderColor = Colors.red;
    } else if (item.name.toLowerCase().contains('document')) {
      folderColor = Colors.purple;
    } else if (item.name.toLowerCase().contains('application')) {
      folderColor = Colors.pink;
    } else if (item.name.toLowerCase().contains('other')) {
      folderColor = Colors.cyan;
    } else if (item.name.toLowerCase().contains('download')) {
      folderColor = Colors.orange;
    }
    return folderColor;

 }
 }
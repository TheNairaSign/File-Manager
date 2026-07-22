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
import 'package:lottie/lottie.dart';

class FileItemContainer extends ConsumerStatefulWidget {
  const FileItemContainer({super.key, required this.item, required this.currentPath});
  final FileItem item;
  final String currentPath;

  @override
  ConsumerState<FileItemContainer> createState() => _FileItemContainerState();
}

class _FileItemContainerState extends ConsumerState<FileItemContainer> {
  bool tapped = false;
  @override
  Widget build(BuildContext context) {
    final folderColor = _folderColor(widget.item);
    final notifier = ref.read(browserProviderFor(widget.currentPath).notifier);
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
            // color: folderColor.withValues(alpha: 0.1),
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.item.isDirectory
            // ? Lottie.asset(
            //     'assets/lottie/folder-animation.json',
            //     height: 30,
            //     width: 30,
            //     fit: BoxFit.cover,
            //     animate: false
            //   )
            ? SvgPicture.asset(
              'assets/svgs/folder-black.svg',
              height: 20,
              width: 20,
              colorFilter: .mode(Theme.of(context).colorScheme.onSurface, .srcIn),
            )
            : MediaIcon.fromItem(widget.item, size: 32),
        ),
        title: Text(
          widget.item.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        // subtitle: Text(
        //   '${item.subFolders ?? 0} Folder | ${item.itemsCount ?? 0} Items',
        //   style: TextStyle(color: Colors.grey[600], fontSize: 13),
        // ),
        subtitle: Text(
            '${formatBytes(widget.item.size)} • ${formatDate(widget.item.lastModified)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)
          ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'delete') {
              showDeleteDialog(context, widget.item, notifier);
            } else if (value == 'rename') {
              showRenameDialog(context, widget.item, notifier);
            } else if (value == 'copy') {
              notifier.copyItem(widget.item);
            } else if (value == 'move') {
              notifier.moveItem(widget.item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'copy', child: Text('Copy')),
            const PopupMenuItem(value: 'move', child: Text('Move')),
            const PopupMenuItem(value: 'rename', child: Text('Rename')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () {
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
        },
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
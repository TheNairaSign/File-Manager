import 'package:file_manager/core/helpers/byte_converter.dart';
import 'package:file_manager/core/helpers/format_date.dart';
import 'package:file_manager/features/browser/media_category.dart';
import 'package:file_manager/features/browser/presentation/providers/media_provider.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/file_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MediaCategoryPage extends ConsumerWidget {
  final MediaTypeItemType categoryType;
  final String title;

  const MediaCategoryPage({
    super.key,
    required this.categoryType,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mediaProviderFor(categoryType));
    final notifier = ref.read(mediaProviderFor(categoryType).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.refresh(),
          ),
        ],
      ),
      body: _buildBody(context, state, notifier),
    );
  }

  Widget _buildBody(BuildContext context, MediaState state, MediaProvider notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: ${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => notifier.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state.files.isEmpty) {
      return const Center(
        child: Text(
          'No files found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => notifier.refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          
          IconData iconData = Icons.insert_drive_file;
          Color iconColor = Colors.grey;

          switch (categoryType) {
            case MediaTypeItemType.audio:
              iconData = Icons.audiotrack;
              iconColor = Colors.red;
              break;
            case MediaTypeItemType.video:
              iconData = Icons.videocam;
              iconColor = Colors.blue;
              break;
            case MediaTypeItemType.image:
              iconData = Icons.image;
              iconColor = Colors.green;
              break;
            case MediaTypeItemType.document:
              iconData = Icons.description;
              iconColor = Colors.amber;
              break;
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            color: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // leading: Container(
              //   width: 48,
              //   height: 48,
              //   decoration: BoxDecoration(
              //     color: iconColor.withValues(alpha: 0.1),
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   child: Icon(
              //     iconData,
              //     color: iconColor,
              //     size: 28,
              //   ),
              // ),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16)
                ),
                child: FilePreviewWidget(file: file.toFile()),
              ),
              title: Text(
                file.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  // fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${formatBytes(file.size)} • ${formatDate(file.dateModified * 1000)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                // Future extension: open preview
                
              },
            ),
          );
        },
      ),
    );
  }
}

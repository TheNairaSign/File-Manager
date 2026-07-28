import 'package:file_manager/core/helpers/capitalize.dart';
import 'package:file_manager/features/browser/media_category.dart';
import 'package:file_manager/features/browser/presentation/pages/media_category_page.dart';
import 'package:file_manager/features/browser/presentation/providers/media_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class MediaCard extends ConsumerWidget {
  const MediaCard({
    super.key,
    required this.title,
    required this.asset,
    required this.mediaType,
    required this.color,
  });
  final String title;
  final String asset;
  final MediaTypeItemType mediaType;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaState = ref.watch(mediaProviderFor(mediaType));

    final countText = mediaState.isLoading
        ? 'Loading...'
        : mediaState.error != null
            ? 'Error'
            : '${mediaState.files.length} files';

    return Card(
      elevation: 0,
      // color: color.withValues(alpha: 0.1),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MediaCategoryPage(
                categoryType: mediaType,
                title: title,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      asset, 
                      width: 15, 
                      height: 15, 
                      // colorFilter: .mode(color, .srcIn),
                      colorFilter: .mode(Theme.of(context).colorScheme.onSurface, .srcIn),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toCapitalized() ,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(countText, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
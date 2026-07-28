import 'dart:io';

import 'package:file_manager/features/browser/presentation/widgets/preview/preview_file_type.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_service.dart';
import 'package:flutter/material.dart';

/// Fallback tile for file types without a rich preview (archives,
/// spreadsheets, presentations, unknown types) or files that were too large
/// to render inline. Shows a colored icon plus the filename.
class GenericFilePreview extends StatelessWidget {
  const GenericFilePreview({
    super.key,
    required this.file,
    required this.type,
    this.tooLarge = false,
  });

  final File file;
  final PreviewFileType type;
  final bool tooLarge;

  @override
  Widget build(BuildContext context) {
    final color = FilePreviewService.colorFor(type);
    final icon = FilePreviewService.iconFor(type);
    final name = file.path.split('/').last;

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 25),
          // const SizedBox(height: 8),
          // Text(
          //   name,
          //   maxLines: 2,
          //   overflow: TextOverflow.ellipsis,
          //   textAlign: TextAlign.center,
          //   style: Theme.of(context).textTheme.bodySmall,
          // ),
          // if (tooLarge) ...[
          //   const SizedBox(height: 4),
          //   Text(
          //     'File too large to preview',
          //     style: Theme.of(context)
          //         .textTheme
          //         .labelSmall
          //         ?.copyWith(color: Colors.grey),
          //   ),
          // ],
        ],
      ),
    );
  }
}
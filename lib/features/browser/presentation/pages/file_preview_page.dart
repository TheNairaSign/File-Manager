import 'dart:io';

import 'package:file_manager/features/browser/presentation/widgets/preview/file_preview_widget.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_file_type.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_service.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';


/// Full-screen destination for images, video, audio, PDFs, and text/code —
/// the types [FilePreviewWidget] already knows how to render richly.
///
/// Image/PDF get a plain black/surface background so zoom feels natural.
/// Video/audio/text keep the default surface background with an app bar.
class FileViewerPage extends StatelessWidget {
  const FileViewerPage({super.key, required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    final type = FilePreviewService.typeOf(file);
    final name = file.path.split('/').last;
    final isVisualMedia =
        type == PreviewFileType.image || type == PreviewFileType.pdf || type == PreviewFileType.video;

    return Scaffold(
      backgroundColor: isVisualMedia ? Colors.black : null,
      appBar: AppBar(
        backgroundColor: isVisualMedia ? Colors.black : null,
        foregroundColor: isVisualMedia ? Colors.white : null,
        title: Text(name, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => SharePlus.instance.share(
              ShareParams(files: [XFile(file.path)]),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FilePreviewWidget(file: file, mode: PreviewMode.full),
      ),
    );
  }
}
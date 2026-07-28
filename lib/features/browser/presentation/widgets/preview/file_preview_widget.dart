import 'dart:io';

import 'package:file_manager/features/browser/presentation/widgets/preview/audio_file_preview.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/generic_file_preview.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/image_file_preview.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/pdf_file_preview.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_file_type.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_service.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/text_file_preview.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/video_file_preview.dart';
import 'package:flutter/material.dart';

/// Drop this anywhere in the file manager (grid tile, list row, or a full
/// detail screen) to render the right preview for a given [File].
///
/// Usage:
/// ```dart
/// FilePreviewWidget(file: file) // thumbnail-sized, e.g. in a grid
/// FilePreviewWidget(file: file, mode: PreviewMode.full) // detail screen
/// ```
enum PreviewMode { thumbnail, full }

class FilePreviewWidget extends StatefulWidget {
  const FilePreviewWidget({
    super.key,
    required this.file,
    this.mode = PreviewMode.thumbnail,
  });

  final File file;
  final PreviewMode mode;

  @override
  State<FilePreviewWidget> createState() => _FilePreviewWidgetState();
}

class _FilePreviewWidgetState extends State<FilePreviewWidget> {
  late final PreviewFileType _type;
  late final Future<bool> _sizeOkFuture;

  @override
  void initState() {
    super.initState();
    _type = FilePreviewService.typeOf(widget.file);
    _sizeOkFuture = FilePreviewService.isPreviewSizeOk(widget.file);
  }

  @override
  Widget build(BuildContext context) {
    if (!FilePreviewService.hasRichPreview(_type)) {
      return GenericFilePreview(file: widget.file, type: _type);
    }

    return FutureBuilder<bool>(
      future: _sizeOkFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        final sizeOk = snapshot.data!;
        if (!sizeOk) {
          // File is too large to render inline (e.g. a 2 GB video) — fall
          // back to a generic tile with an "open externally" affordance.
          return GenericFilePreview(
            file: widget.file,
            type: _type,
            tooLarge: true,
          );
        }

        return _buildRichPreview(_type);
      },
    );
  }

  Widget _buildRichPreview(PreviewFileType type) {
    final fullScreen = widget.mode == PreviewMode.full;
    switch (type) {
      case PreviewFileType.image:
        return ImageFilePreview(file: widget.file, fullScreen: fullScreen);
      case PreviewFileType.video:
        return VideoFilePreview(file: widget.file, fullScreen: fullScreen);
      case PreviewFileType.audio:
        return AudioFilePreview(file: widget.file, fullScreen: fullScreen);
      case PreviewFileType.pdf:
        return PdfFilePreview(file: widget.file, fullScreen: fullScreen);
      case PreviewFileType.text:
      case PreviewFileType.code:
        return TextFilePreview(
          file: widget.file,
          type: type,
          fullScreen: fullScreen,
        );
      default:
        return GenericFilePreview(file: widget.file, type: type);
    }
  }
}
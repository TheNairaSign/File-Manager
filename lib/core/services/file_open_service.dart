import 'dart:io';

import 'package:file_manager/features/browser/presentation/pages/file_preview_page.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_file_type.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_service.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

/// Central "what happens when the user taps a file" logic.
///
/// - Types we have an in-app viewer for (image, video, audio, pdf,
///   text/code) push [FileViewerPage].
/// - Everything else (docx/xlsx/pptx, archives, unknown types) is handed
///   off to the OS via `open_filex`, which opens it in whatever app the
///   device has registered for that file type.
class FileOpenService {
  FileOpenService._();

  static const _inAppTypes = {
    PreviewFileType.image,
    PreviewFileType.video,
    PreviewFileType.audio,
    PreviewFileType.pdf,
    PreviewFileType.text,
    PreviewFileType.code,
  };

  static Future<void> open(BuildContext context, File file) async {
    final type = FilePreviewService.typeOf(file);

    if (_inAppTypes.contains(type)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => FileViewerPage(file: file)),
      );
      return;
    }

    await _openExternally(context, file);
  }

  static Future<void> _openExternally(BuildContext context, File file) async {
    final result = await OpenFilex.open(file.path);

    if (result.type != ResultType.done && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.type == ResultType.noAppToOpen
                ? 'No app found to open this file'
                : 'Could not open file: ${result.message}',
          ),
        ),
      );
    }
  }
}
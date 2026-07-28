import 'dart:io';

import 'package:file_manager/features/browser/presentation/widgets/preview/preview_file_type.dart';
import 'package:file_manager/features/browser/presentation/widgets/preview/preview_service.dart';
import 'package:flutter/material.dart';

/// Thumbnail mode: a few lines of plain monospace text, clipped, so grid
/// tiles give a quick "peek" without reading the whole file.
/// Full-screen mode: a scrollable monospace view of the (bounded) content
/// loaded by [FilePreviewService.readTextPreview].
///
/// For real syntax highlighting, swap the `Text` in full-screen mode for
/// `package:flutter_highlight`'s `HighlightView`, keyed off the file
/// extension (see PreviewFileTypeResolver.extensionOf).
class TextFilePreview extends StatefulWidget {
  const TextFilePreview({
    super.key,
    required this.file,
    required this.type,
    this.fullScreen = false,
  });

  final File file;
  final PreviewFileType type;
  final bool fullScreen;

  @override
  State<TextFilePreview> createState() => _TextFilePreviewState();
}

class _TextFilePreviewState extends State<TextFilePreview> {
  String? _content;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final text = await FilePreviewService.readTextPreview(widget.file);
    if (mounted) {
      setState(() {
        _content = text;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final content = _content;
    if (content == null) {
      return const Center(
        child: Icon(Icons.warning_amber_outlined),
      );
    }

    final textWidget = Text(
      content,
      style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      maxLines: widget.fullScreen ? null : 6,
      overflow: widget.fullScreen ? TextOverflow.visible : TextOverflow.fade,
    );

    if (!widget.fullScreen) {
      return Padding(padding: const EdgeInsets.all(8), child: textWidget);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: textWidget,
    );
  }
}
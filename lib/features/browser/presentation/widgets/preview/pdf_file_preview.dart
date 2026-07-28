import 'dart:io';

import 'package:flutter/material.dart';
// Requires: pdfx: ^2.6.0 (add to pubspec.yaml)
import 'package:pdfx/pdfx.dart';

/// Thumbnail mode: renders just the first page as a static image.
/// Full-screen mode: a scrollable, pinch-zoomable multi-page `PdfView`.
class PdfFilePreview extends StatefulWidget {
  const PdfFilePreview({
    super.key,
    required this.file,
    this.fullScreen = false,
  });

  final File file;
  final bool fullScreen;

  @override
  State<PdfFilePreview> createState() => _PdfFilePreviewState();
}

class _PdfFilePreviewState extends State<PdfFilePreview> {
  PdfControllerPinch? _pinchController;
  PdfDocument? _thumbDoc;
  PdfPageImage? _thumbImage;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    widget.fullScreen ? _initFullViewer() : _initThumbnail();
  }

  Future<void> _initFullViewer() async {
    try {
      final controller = PdfControllerPinch(
        document: PdfDocument.openFile(widget.file.path),
      );
      if (mounted) setState(() => _pinchController = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _initThumbnail() async {
    try {
      final doc = await PdfDocument.openFile(widget.file.path);
      final page = await doc.getPage(1);
      final image = await page.render(
        width: page.width / 2,
        height: page.height / 2,
        format: PdfPageImageFormat.jpeg,
      );
      await page.close();
      if (mounted) {
        setState(() {
          _thumbDoc = doc;
          _thumbImage = image;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _pinchController?.dispose();
    _thumbDoc?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(child: Icon(Icons.picture_as_pdf_outlined));
    }

    if (!widget.fullScreen) {
      final img = _thumbImage;
      if (img == null) {
        return const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      }
      return Image.memory(img.bytes, fit: BoxFit.cover);
    }

    final controller = _pinchController;
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return PdfViewPinch(controller: controller);
  }
}
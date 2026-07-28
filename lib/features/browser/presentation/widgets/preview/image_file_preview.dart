import 'dart:io';

import 'package:flutter/material.dart';

/// Renders an image file. In thumbnail mode it's a simple cropped
/// `Image.file` inside a tile; in full-screen mode it's wrapped in
/// `InteractiveViewer` for pinch-to-zoom.
///
/// For very large photo libraries, swap `Image.file` for a cached/thumbed
/// variant (e.g. `package:extended_image` or generating a downsized JPEG
/// via `flutter_image_compress`) to avoid decoding full-resolution images
/// in a grid.
class ImageFilePreview extends StatelessWidget {
  const ImageFilePreview({
    super.key,
    required this.file,
    this.fullScreen = false,
  });

  final File file;
  final bool fullScreen;

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      file,
      fit: fullScreen ? BoxFit.contain : BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _errorTile(context),
    );

    if (!fullScreen) return image;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5,
      child: Center(child: image),
    );
  }

  Widget _errorTile(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined),
    );
  }
}
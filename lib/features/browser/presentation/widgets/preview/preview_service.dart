import 'dart:io';
import 'dart:typed_data';

import 'package:file_manager/features/browser/presentation/widgets/preview/preview_file_type.dart';
import 'package:flutter/material.dart';

/// Central service the file manager calls to figure out *how* to preview
/// a given file, and to fetch the data (thumbnail bytes, text snippet, etc.)
/// that the preview widgets need.
///
/// Keep this class free of widget-building logic — it only resolves types
/// and loads data. `FilePreviewWidget` is responsible for turning that into
/// UI. This separation makes the service unit-testable without a widget
/// tester.
class FilePreviewService {
  FilePreviewService._();

  /// Files above this size won't be inline-rendered (e.g. huge videos or
  /// text logs) — the UI should fall back to metadata + an "open externally"
  /// action instead of trying to decode the whole thing.
  static const int maxInlinePreviewBytes = 50 * 1024 * 1024; // 50 MB

  /// Text/code files above this size are read only partially (head of file)
  /// to avoid janking the UI on huge logs.
  static const int maxTextPreviewBytes = 512 * 1024; // 512 KB

  static PreviewFileType typeOf(File file) =>
      PreviewFileTypeResolver.resolve(file.path);

  /// Whether we have a rich, type-specific preview for this file, versus
  /// just falling back to a generic icon tile.
  static bool hasRichPreview(PreviewFileType type) {
    switch (type) {
      case PreviewFileType.image:
      case PreviewFileType.video:
      case PreviewFileType.audio:
      case PreviewFileType.pdf:
      case PreviewFileType.text:
      case PreviewFileType.code:
        return true;
      case PreviewFileType.spreadsheet:
      case PreviewFileType.presentation:
      case PreviewFileType.archive:
      case PreviewFileType.unknown:
        return false;
    }
  }

  /// Returns whether the file is small enough to attempt an inline preview.
  static Future<bool> isPreviewSizeOk(File file) async {
    try {
      final size = await file.length();
      return size <= maxInlinePreviewBytes;
    } catch (_) {
      return false;
    }
  }

  /// Reads a bounded chunk of a text/code file for preview purposes.
  /// Returns null on read failure (e.g. binary content that isn't UTF-8,
  /// permission errors) so the UI can fall back gracefully.
  static Future<String?> readTextPreview(File file) async {
    try {
      final size = await file.length();
      if (size <= maxTextPreviewBytes) {
        return await file.readAsString();
      }
      // Only read the first chunk of large text files.
      final raf = await file.open();
      final bytes = await raf.read(maxTextPreviewBytes);
      await raf.close();
      return '${String.fromCharCodes(bytes)}\n\n… (truncated, file is '
          '${(size / 1024).toStringAsFixed(0)} KB)';
    } catch (_) {
      return null;
    }
  }

  /// Reads raw image bytes for `Image.memory`. For very large images you may
  /// want a native thumbnailer (e.g. `flutter_image_compress`) instead of
  /// loading the full file — this is the naive, dependency-light version.
  static Future<Uint8List?> readImageBytes(File file) async {
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static IconData iconFor(PreviewFileType type) {
    switch (type) {
      case PreviewFileType.image:
        return Icons.image_outlined;
      case PreviewFileType.video:
        return Icons.movie_outlined;
      case PreviewFileType.audio:
        return Icons.audiotrack_outlined;
      case PreviewFileType.pdf:
        return Icons.picture_as_pdf_outlined;
      case PreviewFileType.text:
        return Icons.article_outlined;
      case PreviewFileType.code:
        return Icons.code_outlined;
      case PreviewFileType.spreadsheet:
        return Icons.table_chart_outlined;
      case PreviewFileType.presentation:
        return Icons.slideshow_outlined;
      case PreviewFileType.archive:
        return Icons.folder_zip_outlined;
      case PreviewFileType.unknown:
        return Icons.insert_drive_file_outlined;
    }
  }

  static Color colorFor(PreviewFileType type) {
    switch (type) {
      case PreviewFileType.image:
        return Colors.purple;
      case PreviewFileType.video:
        return Colors.red;
      case PreviewFileType.audio:
        return Colors.orange;
      case PreviewFileType.pdf:
        return Colors.redAccent;
      case PreviewFileType.text:
        return Colors.blueGrey;
      case PreviewFileType.code:
        return Colors.indigo;
      case PreviewFileType.spreadsheet:
        return Colors.green;
      case PreviewFileType.presentation:
        return Colors.deepOrange;
      case PreviewFileType.archive:
        return Colors.brown;
      case PreviewFileType.unknown:
        return Colors.grey;
    }
  }
}
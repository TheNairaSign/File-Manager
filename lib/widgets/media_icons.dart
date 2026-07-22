import 'package:file_manager/models/file_item.dart';
import 'package:flutter/material.dart';

/// Enum representing the category/type of file for icon resolution.
enum FileCategory {
  folder,
  image,
  video,
  audio,
  pdf,
  document,
  spreadsheet,
  presentation,
  archive,
  code,
  apk,
  text,
  unknown,
}

/// A widget and helper class for displaying multimedia icons based on file type/extension.
class MediaIcon extends StatelessWidget {
  const MediaIcon({
    super.key,
    this.item,
    this.fileName,
    this.isDirectory,
    this.mimeType,
    this.size = 28.0,
    this.color,
    this.useDefaultColor = true,
  });

  final FileItem? item;
  final String? fileName;
  final bool? isDirectory;
  final String? mimeType;
  final double size;
  final Color? color;
  final bool useDefaultColor;

  /// Creates a [MediaIcon] directly from a [FileItem].
  factory MediaIcon.fromItem(
    FileItem item, {
    Key? key,
    double size = 28.0,
    Color? color,
    bool useDefaultColor = true,
  }) {
    return MediaIcon(
      key: key,
      item: item,
      size: size,
      color: color,
      useDefaultColor: useDefaultColor,
    );
  }

  /// Creates a [MediaIcon] from a file name and optional metadata.
  factory MediaIcon.fromFileName(
    String fileName, {
    Key? key,
    bool isDirectory = false,
    String? mimeType,
    double size = 28.0,
    Color? color,
    bool useDefaultColor = true,
  }) {
    return MediaIcon(
      key: key,
      fileName: fileName,
      isDirectory: isDirectory,
      mimeType: mimeType,
      size: size,
      color: color,
      useDefaultColor: useDefaultColor,
    );
  }

  /// Determines the [FileCategory] from file name, extension, mimeType or directory flag.
  static FileCategory getFileCategory({
    String? fileName,
    bool isDirectory = false,
    String? mimeType,
  }) {
    if (isDirectory) return FileCategory.folder;

    final mime = mimeType?.toLowerCase() ?? '';
    if (mime.startsWith('image/')) return FileCategory.image;
    if (mime.startsWith('video/')) return FileCategory.video;
    if (mime.startsWith('audio/')) return FileCategory.audio;
    if (mime == 'application/pdf') return FileCategory.pdf;
    if (mime == 'application/vnd.android.package-archive') return FileCategory.apk;

    final name = fileName?.toLowerCase() ?? '';
    final ext = name.contains('.') ? name.split('.').last : '';

    switch (ext) {
      // Images
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
      case 'svg':
      case 'heic':
      case 'raw':
      case 'ico':
        return FileCategory.image;

      // Videos
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'wmv':
      case 'flv':
      case 'webm':
      case '3gp':
      case 'm4v':
      case 'mpeg':
      case 'mpg':
        return FileCategory.video;

      // Audio
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
      case 'm4a':
      case 'wma':
      case 'opus':
      case 'amr':
        return FileCategory.audio;

      // PDF
      case 'pdf':
        return FileCategory.pdf;

      // Documents
      case 'doc':
      case 'docx':
      case 'rtf':
      case 'odt':
        return FileCategory.document;

      // Spreadsheets
      case 'xls':
      case 'xlsx':
      case 'csv':
      case 'ods':
        return FileCategory.spreadsheet;

      // Presentations
      case 'ppt':
      case 'pptx':
      case 'odp':
        return FileCategory.presentation;

      // Archives
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
      case 'gz':
      case 'bz2':
      case 'iso':
      case 'xz':
        return FileCategory.archive;

      // Code & Data
      case 'html':
      case 'htm':
      case 'css':
      case 'js':
      case 'ts':
      case 'jsx':
      case 'tsx':
      case 'dart':
      case 'java':
      case 'py':
      case 'c':
      case 'cpp':
      case 'cs':
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
      case 'sh':
      case 'kt':
      case 'swift':
      case 'php':
      case 'rb':
      case 'go':
      case 'rs':
      case 'sql':
        return FileCategory.code;

      // Text
      case 'txt':
      case 'md':
      case 'log':
      case 'info':
        return FileCategory.text;

      // APK
      case 'apk':
        return FileCategory.apk;

      default:
        return FileCategory.unknown;
    }
  }

  /// Returns [IconData] corresponding to the given [FileCategory].
  static IconData getIconDataForCategory(FileCategory category) {
    switch (category) {
      case FileCategory.folder:
        return Icons.folder;
      case FileCategory.image:
        return Icons.image;
      case FileCategory.video:
        return Icons.movie;
      case FileCategory.audio:
        return Icons.audiotrack;
      case FileCategory.pdf:
        return Icons.picture_as_pdf;
      case FileCategory.document:
        return Icons.description;
      case FileCategory.spreadsheet:
        return Icons.table_chart;
      case FileCategory.presentation:
        return Icons.slideshow;
      case FileCategory.archive:
        return Icons.folder_zip;
      case FileCategory.code:
        return Icons.code;
      case FileCategory.apk:
        return Icons.android;
      case FileCategory.text:
        return Icons.article;
      case FileCategory.unknown:
        return Icons.insert_drive_file;
    }
  }

  /// Returns a default [Color] associated with each [FileCategory].
  static Color getColorForCategory(FileCategory category) {
    switch (category) {
      case FileCategory.folder:
        return Colors.amber;
      case FileCategory.image:
        return Colors.green;
      case FileCategory.video:
        return Colors.blue;
      case FileCategory.audio:
        return Colors.red;
      case FileCategory.pdf:
        return Colors.redAccent;
      case FileCategory.document:
        return Colors.indigo;
      case FileCategory.spreadsheet:
        return Colors.teal;
      case FileCategory.presentation:
        return Colors.deepOrange;
      case FileCategory.archive:
        return Colors.purple;
      case FileCategory.code:
        return Colors.cyan;
      case FileCategory.apk:
        return Colors.lightGreen;
      case FileCategory.text:
        return Colors.blueGrey;
      case FileCategory.unknown:
        return Colors.grey;
    }
  }

  /// Helper method to get [IconData] for a file or [FileItem].
  static IconData getIconData({
    FileItem? item,
    String? fileName,
    bool isDirectory = false,
    String? mimeType,
  }) {
    final category = getFileCategory(
      fileName: item?.name ?? fileName,
      isDirectory: item?.isDirectory ?? isDirectory,
      mimeType: item?.mimeType ?? mimeType,
    );
    return getIconDataForCategory(category);
  }

  /// Helper method to get [Color] for a file or [FileItem].
  static Color getIconColor({
    FileItem? item,
    String? fileName,
    bool isDirectory = false,
    String? mimeType,
  }) {
    final category = getFileCategory(
      fileName: item?.name ?? fileName,
      isDirectory: item?.isDirectory ?? isDirectory,
      mimeType: item?.mimeType ?? mimeType,
    );
    return getColorForCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveFileName = item?.name ?? fileName ?? '';
    final effectiveIsDirectory = item?.isDirectory ?? isDirectory ?? false;
    final effectiveMimeType = item?.mimeType ?? mimeType;

    final category = getFileCategory(
      fileName: effectiveFileName,
      isDirectory: effectiveIsDirectory,
      mimeType: effectiveMimeType,
    );

    final iconData = getIconDataForCategory(category);
    final iconColor = color ?? (useDefaultColor ? getColorForCategory(category) : null);

    return Icon(
      iconData,
      size: size,
      color: iconColor,
    );
  }
}

/// Alias for [MediaIcon] to allow `MediaIcons` usage.
typedef MediaIcons = MediaIcon;
